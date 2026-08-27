import 'dart:convert';

import 'package:get/get.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/farm_management/farmer/model/farm_access_model.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

/// Drives the QR + PIN farm-access flows on both sides:
/// the farmer issuing codes, and the manager/partner redeeming one.
class FarmAccessController extends GetxController {
  /// Codes issued for the farm currently being viewed.
  final grants = <FarmAccessGrant>[].obs;

  /// People who have redeemed a code for that farm.
  final grantees = <FarmGrantee>[].obs;

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

  /// Last code generated, so the QR screen can render it straight away.
  final Rx<FarmAccessGrant?> lastGenerated = Rx<FarmAccessGrant?>(null);

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
            if (first is List && first.isNotEmpty) return first.first.toString();
          }
        }
      }
    } catch (_) {
      // Body was not JSON — fall through to the caller's default.
    }
    return fallback;
  }

  /// Issues a new QR + PIN for [farmId]. Returns the grant, or null on failure.
  Future<FarmAccessGrant?> generateAccess({
    required int farmId,
    required String role,
    required int durationDays,
    required String pin,
    required bool canView,
    required bool canEdit,
    required bool canCreate,
    required bool canDelete,
  }) async {
    isSubmitting.value = true;
    try {
      final response = await postRequest(
        endPoint: '$_base/farmer/farm/$farmId/access/generate',
        headers: await buildHeader(),
        body: {
          'role': role,
          'duration_days': durationDays,
          'pin': pin,
          'view_access': canView,
          'edit_access': canEdit,
          'create_access': canCreate,
          'delete_access': canDelete,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body)['data'] as Map<String, dynamic>;
        final grant = FarmAccessGrant.fromJson(data);
        lastGenerated.value = grant;
        grants.insert(0, grant);
        return grant;
      }

      CustomToast.error(_messageFrom(response.body, 'Could not generate QR'));
      return null;
    } catch (e) {
      CustomToast.error('Could not generate QR. Please try again.');
      return null;
    } finally {
      isSubmitting.value = false;
    }
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

  /// Give one or more people access to a farm directly — no QR, no PIN.
  ///
  /// [grantId] ties them to a code that was already generated, which is how
  /// people are added to an existing QR.
  Future<bool> grantAccessTo({
    required int farmId,
    required List<int> farmerIds,
    required String role,
    required bool canView,
    required bool canEdit,
    required bool canCreate,
    required bool canDelete,
    int? durationDays,
    int? grantId,
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
          if (grantId != null) 'grant_id': grantId,
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

  /// Loads issued codes for the "QR CODE" screen, optionally filtered by role.
  Future<void> fetchGrants({required int farmId, String? role}) async {
    isLoading.value = true;
    try {
      final query = role == null ? '' : '?role=$role';
      final response = await getRequest(
        endPoint: '$_base/farmer/farm/$farmId/access$query',
        headers: await buildHeader(),
      );

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body)['data'] as List<dynamic>;
        grants.value = list
            .map((e) => FarmAccessGrant.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      CustomToast.error('Could not load access codes');
    } finally {
      isLoading.value = false;
    }
  }

  /// Loads redeemed access for the "Scanned Details" screen.
  Future<void> fetchGrantees({required int farmId, String? role}) async {
    isLoading.value = true;
    try {
      final query = role == null ? '' : '?role=$role';
      final response = await getRequest(
        endPoint: '$_base/farmer/farm/$farmId/grantees$query',
        headers: await buildHeader(),
      );

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body)['data'] as List<dynamic>;
        grantees.value = list
            .map((e) => FarmGrantee.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      CustomToast.error('Could not load scanned details');
    } finally {
      isLoading.value = false;
    }
  }

  /// Step 1 of scanning — resolves a QR without granting anything yet.
  ///
  /// Returns the preview on success. On failure the reason is surfaced to the
  /// user and null is returned, so the scanner can stay open for a retry.
  Future<ScannedGrantPreview?> redeemToken(String token) async {
    isSubmitting.value = true;
    try {
      final response = await postRequest(
        endPoint: '$_base/farmer/access/redeem',
        headers: await buildHeader(),
        body: {'token': token},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as Map<String, dynamic>;
        return ScannedGrantPreview.fromJson(data);
      }

      CustomToast.error(_messageFrom(response.body, 'This QR code is not valid'));
      return null;
    } catch (_) {
      CustomToast.error('Could not verify this QR code');
      return null;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Step 2 of scanning — confirms the PIN and completes the grant.
  Future<bool> verifyPin({
    required String token,
    required String pin,
    String? name,
    String? phone,
  }) async {
    isSubmitting.value = true;
    try {
      final response = await postRequest(
        endPoint: '$_base/farmer/access/verify-pin',
        headers: await buildHeader(),
        body: {
          'token': token,
          'pin': pin,
          if (name != null) 'name': name,
          if (phone != null) 'phone': phone,
        },
      );

      if (response.statusCode == 200) return true;

      CustomToast.error(_messageFrom(response.body, 'Incorrect PIN'));
      return false;
    } catch (_) {
      CustomToast.error('Could not verify the PIN');
      return false;
    } finally {
      isSubmitting.value = false;
    }
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

  /// Removes an access grant. Revoking also strips the person's permissions.
  Future<bool> revokeAccess(int grantId) async {
    try {
      final response = await postRequest(
        endPoint: '$_base/farmer/access/$grantId/revoke',
        headers: await buildHeader(),
        body: const {},
      );

      if (response.statusCode == 200) {
        grantees.removeWhere((g) => g.grantId == grantId);
        grants.removeWhere((g) => g.id == grantId);
        CustomToast.success('Access removed');
        return true;
      }

      CustomToast.error(_messageFrom(response.body, 'Could not remove access'));
      return false;
    } catch (_) {
      CustomToast.error('Could not remove access');
      return false;
    }
  }
}
