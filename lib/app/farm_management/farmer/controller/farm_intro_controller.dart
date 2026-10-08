import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

/// The one shared [FarmIntroController].
///
/// Same reasoning as the other farm controllers: `Get.put()` REPLACES an
/// existing registration, so two screens each calling it would be handed
/// different objects and the announcement marked as seen on one would pop
/// again on the other.
FarmIntroController get farmIntroController =>
    Get.isRegistered<FarmIntroController>()
    ? Get.find<FarmIntroController>()
    : Get.put(FarmIntroController());

/// What greets the farmer when Farm Management opens.
///
/// Two things, from one request:
///
///   the announcement  a popup, shown EVERY time the screen opens, newest
///                     first. This replaced the banner strip — a banner is
///                     scenery and was being scrolled straight past.
///   the demo video    only for a farmer with no farms yet. It teaches how
///                     the screen works, and somebody already running three
///                     farms does not need teaching.
class FarmIntroController extends GetxController {
  final Rx<FarmAnnouncement?> announcement = Rx<FarmAnnouncement?>(null);
  final Rx<FarmDemoVideo?> demoVideo = Rx<FarmDemoVideo?>(null);

  /// Whether the farmer has any farms, as the SERVER sees it.
  final RxBool hasFarms = true.obs;

  final RxBool hasLoaded = false.obs;

  /// The announcement already shown in this app session.
  ///
  /// The farmer is meant to see it each time they OPEN the screen, not on
  /// every rebuild — and the screen rebuilds on every pull-to-refresh, tab
  /// switch and keyboard dismissal. Reset by [forgetShown] when the screen is
  /// left, so the next entry shows it again.
  int? _shownId;

  bool _inFlight = false;

  Future<void> load({bool force = false}) async {
    if (_inFlight && !force) return;

    _inFlight = true;

    try {
      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/farm-management/intro",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);

        if (body is Map && body['data'] is Map) {
          final data = body['data'] as Map<String, dynamic>;

          announcement.value = data['announcement'] is Map
              ? FarmAnnouncement.fromJson(
                  data['announcement'] as Map<String, dynamic>,
                )
              : null;

          demoVideo.value = data['demo_video'] is Map
              ? FarmDemoVideo.fromJson(
                  data['demo_video'] as Map<String, dynamic>,
                )
              : null;

          hasFarms.value = data['has_farms'] == true;
          hasLoaded.value = true;
        }
      } else {
        debugPrint('[FARM INTRO] ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      // Silent on purpose. This is a greeting, not the screen's work; a
      // network blip must not put an error in front of a farmer who only
      // wanted to record a meal.
      debugPrint('[FARM INTRO] failed: $e');
    } finally {
      _inFlight = false;
    }
  }

  /// The announcement to pop right now, or null.
  ///
  /// Asking marks it as shown, so a caller that rebuilds does not reopen the
  /// same dialog on top of itself.
  FarmAnnouncement? takeAnnouncement() {
    final current = announcement.value;

    if (current == null || current.id == _shownId) return null;

    _shownId = current.id;

    return current;
  }

  /// Let the announcement show again next time the screen is opened.
  void forgetShown() => _shownId = null;
}

/// One announcement aimed at the Farm Management screen.
class FarmAnnouncement {
  final int id;
  final String title;
  final String description;

  /// Absolute URL, resolved server-side. Null when none was uploaded.
  final String? image;

  const FarmAnnouncement({
    required this.id,
    required this.title,
    required this.description,
    this.image,
  });

  factory FarmAnnouncement.fromJson(Map<String, dynamic> json) {
    return FarmAnnouncement(
      id: int.tryParse('${json['id']}') ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      image: (json['image']?.toString().trim().isEmpty ?? true)
          ? null
          : json['image'].toString(),
    );
  }

  bool get hasImage => image != null;
}

/// The "how this works" video, set in the admin panel.
class FarmDemoVideo {
  final String url;
  final String title;

  const FarmDemoVideo({required this.url, required this.title});

  factory FarmDemoVideo.fromJson(Map<String, dynamic> json) {
    return FarmDemoVideo(
      url: json['url']?.toString() ?? '',
      title: json['title']?.toString() ?? 'How Farm Management works',
    );
  }

  bool get isUsable => url.trim().isNotEmpty;
}
