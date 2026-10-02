import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:seedsuser/app/subscription/model/subscription_models.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

/// The one shared [SubscriptionController].
///
/// Same reasoning as [farmListController]: `Get.put()` REPLACES an existing
/// registration, so several screens each calling it would be handed different
/// objects and a status refreshed on one would be invisible to another — the
/// add-farm button would go on offering the form after a farm was created.
SubscriptionController get subscriptionController =>
    Get.isRegistered<SubscriptionController>()
        ? Get.find<SubscriptionController>()
        : Get.put(SubscriptionController());

/// Whether this farmer may add another farm, and what to offer them if not.
///
/// There is no payment here. The farmer picks a package, rings the Farm
/// Management helpline and pays the person who answers; an admin records it in
/// the panel. This controller only ever reads.
class SubscriptionController extends GetxController {
  final Rx<SubscriptionStatus> status = SubscriptionStatus.unknown().obs;

  final RxBool isLoading = false.obs;

  /// True once a real answer has been received, as opposed to the permissive
  /// placeholder. The banner stays hidden until then so a farmer with a
  /// healthy subscription never sees a flash of the wrong state.
  final RxBool hasLoaded = false.obs;

  /// In flight for [sendRequest]. Separate from [isLoading]: the status call
  /// and the request are different buttons, and one must not spin the other.
  final RxBool isRequesting = false.obs;

  /// True once a request has gone through in this session, so the button can
  /// say so rather than inviting a second tap.
  final RxBool hasRequested = false.obs;

  /// Guard against overlapping fetches — the farm screen refreshes on focus
  /// and on pull-to-refresh, which can both fire at once.
  bool _inFlight = false;

  /// Fetch the farmer's standing.
  ///
  /// Named `load` rather than `refresh`: GetxController already has a
  /// `refresh()` with a different signature, and shadowing it silently breaks
  /// every rebuild that GetX drives through it.
  ///
  /// Never throws and never toasts: this runs behind a button press and on
  /// screen load, and a network blip must not put an error in front of someone
  /// who was only trying to open a form. On failure the status is left
  /// permissive and the server's own check on create becomes the backstop.
  Future<SubscriptionStatus> load({bool force = false}) async {
    if (_inFlight && !force) return status.value;

    _inFlight = true;
    isLoading.value = true;

    try {
      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/subscription/status",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);

        if (body is Map && body['data'] is Map<String, dynamic>) {
          status.value = SubscriptionStatus.fromJson(
            body['data'] as Map<String, dynamic>,
          );
          hasLoaded.value = true;
        }
      } else {
        debugPrint(
          '[SUBSCRIPTION] status ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('[SUBSCRIPTION] status failed: $e');
    } finally {
      _inFlight = false;
      isLoading.value = false;
    }

    return status.value;
  }

  /// Adopt the status the server attached to a rejected create (HTTP 402).
  ///
  /// The refusal carries the same payload as the status endpoint, so the sheet
  /// can be shown straight from it rather than making a second round trip at
  /// the exact moment the farmer is already waiting.
  void adoptFromRefusal(Map<String, dynamic> data) {
    status.value = SubscriptionStatus.fromJson(data);
    hasLoaded.value = true;
  }

  /// Ask the team to make contact, instead of ringing them.
  ///
  /// Not everyone can call — a farmer in the field with no credit, or one
  /// ringing outside office hours — and the sale was being lost at exactly
  /// that point. This leaves a row in the admin panel's Requests tab.
  ///
  /// Returns the message to show, and whether it worked. The server's own
  /// wording is preferred over anything written here, so changing what the
  /// farmer is told is a backend change rather than a store release.
  Future<({bool ok, String message})> sendRequest({
    int? farmId,
    int? planId,
    String? message,
  }) async {
    if (isRequesting.value) {
      return (ok: false, message: 'Sending your request…');
    }

    isRequesting.value = true;

    try {
      final response = await postRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/subscription/request",
        headers: await buildHeader(),
        body: {
          // Only what is known. The endpoint takes both as optional: a farmer
          // may be asking about one locked farm, or simply asking for more.
          if (farmId != null && farmId > 0) 'farm_id': farmId,
          if (planId != null && planId > 0) 'plan_id': planId,
          if (message != null && message.trim().isNotEmpty)
            'message': message.trim(),
        },
      );

      final body = json.decode(response.body);
      final serverMessage = body is Map ? body['message']?.toString() : null;

      if (response.statusCode == 200 || response.statusCode == 201) {
        hasRequested.value = true;

        return (
          ok: true,
          message: serverMessage?.isNotEmpty == true
              ? serverMessage!
              : 'Request sent. Our team will contact you shortly.',
        );
      }

      debugPrint(
        '[SUBSCRIPTION] request ${response.statusCode}: ${response.body}',
      );

      return (
        ok: false,
        message: serverMessage?.isNotEmpty == true
            ? serverMessage!
            : 'Could not send your request. Please try again.',
      );
    } catch (e) {
      debugPrint('[SUBSCRIPTION] request failed: $e');

      return (
        ok: false,
        message: 'Could not send your request. Please check your connection.',
      );
    } finally {
      isRequesting.value = false;
    }
  }

  /// The banner text for the Farm Management screen, or null for silence.
  String? get expiryWarning =>
      hasLoaded.value ? status.value.subscription?.warning : null;
}
