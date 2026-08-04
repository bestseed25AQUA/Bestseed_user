import 'package:flutter_test/flutter_test.dart';
import 'package:seedsuser/app/home/controller/home_banner_controller.dart';
import 'package:seedsuser/app/model/home_banner_model.dart';

/// Regression cover for: the Prices screen's "Wanted" banner sometimes never
/// appeared, on both iOS and Android, until the app was restarted.
///
/// The banner was fetched exactly once during the launch request burst. The
/// only re-fetch (HomePage.initState) is gated on OTHER banners being empty, so
/// when those loaded and seed_price didn't, nothing ever tried again.
/// [HomeBannerController.ensureSeedPriceBanner] is the recovery path the Prices
/// screen now calls on open and on pull-to-refresh.
class _FakeBannerController extends HomeBannerController {
  _FakeBannerController({this.failures = 0, this.returnsEmpty = false});

  /// How many leading calls should throw before one succeeds.
  int failures;

  /// Simulate a 200 response that genuinely has no banner configured.
  final bool returnsEmpty;

  final List<String> calls = <String>[];

  @override
  Future<List<BannerItem>?> fetchBannerList(String endpoint) async {
    calls.add(endpoint);

    if (failures > 0) {
      failures--;
      throw Exception('simulated HTTP 500 for $endpoint');
    }

    if (returnsEmpty) return null;

    return <BannerItem>[
      BannerItem(
        id: 148,
        title: 'Wanted',
        type: 'image',
        url: 'https://aqua.bestseed.in/uploads/banners/wanted.png',
      ),
    ];
  }
}

void main() {
  group('ensureSeedPriceBanner', () {
    test('fetches the banner when the list is empty', () async {
      final c = _FakeBannerController();
      expect(c.bannersSeedPrice, isEmpty);

      await c.ensureSeedPriceBanner();

      expect(c.calls, ['farmer/seed_price_banner']);
      expect(c.bannersSeedPrice, hasLength(1));
      expect(c.bannersSeedPrice.first.id, 148);
      expect(c.bannersSeedPrice.first.title, 'Wanted');
    });

    test('does nothing when the banner is already loaded', () async {
      final c = _FakeBannerController();
      await c.ensureSeedPriceBanner();
      expect(c.calls, hasLength(1));

      // Simulates re-opening the Prices tab several times.
      await c.ensureSeedPriceBanner();
      await c.ensureSeedPriceBanner();

      expect(c.calls, hasLength(1), reason: 'must not refetch once loaded');
      expect(c.bannersSeedPrice, hasLength(1));
    });

    test('a failed attempt leaves the banner empty and retryable', () async {
      // Every attempt fails — this is the startup-burst failure.
      final c = _FakeBannerController(failures: 999);

      await c.ensureSeedPriceBanner();

      expect(c.bannersSeedPrice, isEmpty);
      expect(c.calls, isNotEmpty, reason: 'it must have tried');
    });

    test('recovers on the next Prices visit after a failure', () async {
      final c = _FakeBannerController(failures: 1);

      // First visit: the fetch throws, banner stays absent.
      await c.ensureSeedPriceBanner();
      expect(c.bannersSeedPrice, isEmpty);

      // Second visit (user taps Prices again, or pulls to refresh).
      await c.ensureSeedPriceBanner();

      expect(c.bannersSeedPrice, hasLength(1),
          reason: 'the whole point of the fix — it heals without a restart');
      expect(c.bannersSeedPrice.first.id, 148);
    });

    test('a 200 with no banner configured is not treated as an error', () async {
      final c = _FakeBannerController(returnsEmpty: true);

      await c.ensureSeedPriceBanner();

      expect(c.bannersSeedPrice, isEmpty);
      expect(c.calls, hasLength(1));
    });

    test('concurrent calls do not double-fetch', () async {
      final c = _FakeBannerController();

      await Future.wait([
        c.ensureSeedPriceBanner(),
        c.ensureSeedPriceBanner(),
        c.ensureSeedPriceBanner(),
      ]);

      expect(c.calls, hasLength(1),
          reason: 'in-flight guard must collapse simultaneous calls');
      expect(c.bannersSeedPrice, hasLength(1));
    });

    test('only the seed price endpoint is requested', () async {
      final c = _FakeBannerController();
      await c.ensureSeedPriceBanner();

      expect(c.calls.every((e) => e == 'farmer/seed_price_banner'), isTrue);
      expect(c.bannersHome, isEmpty);
      expect(c.bannersMedicine, isEmpty);
    });
  });
}
