import 'dart:convert';

import 'package:get/get.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/farm_management/farmer/model/farm_access_model.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

/// Drives farm access: who holds it, and giving or taking it away.
///
/// Access is granted by picking people directly. The QR + PIN flow this used to
/// carry — issue a code, scan it, confirm a PIN — has been removed along with
/// its screens and endpoints.
class FarmAccessController extends GetxController {
  /// Everyone who currently holds access to that farm, however they got it.
  ///
  /// This is the list the SERVER consults when it decides who may open a farm.
  /// The Setup Access screen used to be built from `/manager/managers` and
  /// `/partner/parteners` instead — a per-farm address book of names and phone
  /// numbers that is not tied to any login, is readable only by the owner, and
  /// has no bearing on access at all. So somebody who scanned a QR never
  /// appeared there, and somebody typed in by hand appeared but could not open
  /// the farm.
  final members = <FarmMember>[].obs;

  final isLoading = false.obs;
  final isSubmitting = false.obs;

  String get _base => NetworkConfig.baseURL;

  /// Pulls a human-readable error out of an API response body.
  String _messageFrom(String body, String fallback) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        if (decoded['message'] != null) return decoded['message'].toString();
        if (decoded['errors'] is Map) {
          final errors = decoded['errors'] as Map;
          if (errors.isNotEmpty) {
            final first = errors.values.first;
            if (first is List && first.isNotEmpty)
              return first.first.toString();
          }
        }
      }
    } catch (_) {
      // Body was not JSON — fall through to the caller's default.
    }
    return fallback;
  }


  /// Find people to grant access to, by name or mobile.
  ///
  /// Returns `[{id, name, mobile, image}]`. The server requires at least three
  /// characters, so short terms are not worth a round trip.
  Future<List<Map<String, dynamic>>> searchFarmers(String term) async {
    if (term.trim().length < 3) return [];

    try {
      final response = await getRequest(
        endPoint: '$_base/farmer/farmers/search',
        params: '?q=${Uri.encodeQueryComponent(term.trim())}',
        headers: await buildHeader(),
      );

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body)['data'] as List<dynamic>? ?? [];
      return data.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  /// Give one or more people access to a farm directly.
  Future<bool> grantAccessTo({
    required int farmId,
    required List<int> farmerIds,
    required String role,
    required bool canView,
    required bool canEdit,
    required bool canCreate,
    required bool canDelete,
    int? durationDays,
  }) async {
    if (farmerIds.isEmpty) return true;

    try {
      final response = await postRequest(
        endPoint: '$_base/farmer/farm/$farmId/members',
        headers: await buildHeader(),
        body: {
          'farmer_ids': farmerIds,
          'role': role,
          'view_access': canView ? 1 : 0,
          'edit_access': canEdit ? 1 : 0,
          'create_access': canCreate ? 1 : 0,
          'delete_access': canDelete ? 1 : 0,
          if (durationDays != null) 'duration_days': durationDays,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) return true;

      CustomToast.error(_messageFrom(response.body, 'Could not give access'));
    } catch (_) {
      CustomToast.error('Could not give access. Please try again.');
    }

    return false;
  }

  /// Loads everyone who holds access to [farmId], for the Setup Access screen.
  ///
  /// Readable by any member, not just the owner, so a manager passing access
  /// on can see who is already on the farm.
  Future<void> fetchMembers({required int farmId}) async {
    isLoading.value = true;
    try {
      final response = await getRequest(
        endPoint: '$_base/farmer/farm/$farmId/members',
        headers: await buildHeader(),
      );

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body)['data'] as List<dynamic>? ?? [];
        members.value = list
            .map((e) => FarmMember.fromJson(e as Map<String, dynamic>))
            .toList();
        return;
      }

      CustomToast.error(
        _messageFrom(response.body, 'Could not load who has access'),
      );
    } catch (_) {
      CustomToast.error('Could not load who has access');
    } finally {
      isLoading.value = false;
    }
  }

  /// Takes one person's access away.
  ///
  /// The owner may remove anyone; a manager or partner may only remove someone
  /// they themselves admitted — the server enforces that, so a member cannot
  /// lock out the person who let them in.
  Future<bool> revokeMember(int memberId) async {
    isSubmitting.value = true;
    try {
      final response = await postRequest(
        endPoint: '$_base/farmer/members/$memberId/revoke',
        headers: await buildHeader(),
        body: const {},
      );

      if (response.statusCode == 200) {
        members.removeWhere((m) => m.id == memberId);
        CustomToast.success('Access removed');
        return true;
      }

      CustomToast.error(_messageFrom(response.body, 'Could not remove access'));
    } catch (_) {
      CustomToast.error('Could not remove access');
    } finally {
      isSubmitting.value = false;
    }

    return false;
  }


  /// Returns the remaining feed in store when a farm is below its low-feed
  /// limit, or null when it is fine (or the farm has no feed data yet).
  Future<num?> checkFeedLimit(int farmId) async {
    try {
      final response = await getRequest(
        endPoint: '$_base/farmer/feed/check-limit/$farmId',
        headers: await buildHeader(),
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body)['data'];
      if (data is! Map || data['status'] != 'low') return null;

      // The API reports consumption and the limit; the sheet shows the limit
      // that was breached.
      return num.tryParse('${data['limit']}');
    } catch (_) {
      return null;
    }
  }

}
