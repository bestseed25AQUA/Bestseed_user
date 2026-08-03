import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:seedsuser/app/home/controller/home_banner_controller.dart';
import 'package:seedsuser/app/home/controller/home_controller.dart';
import 'package:seedsuser/app/home/controller/location_controller.dart';
import 'package:seedsuser/app/home/view/home_appbar_widget.dart';
import 'package:seedsuser/app/profile/controller/profile_controller.dart';

/// Regression cover for: a blank band between the search field and the category
/// tabs on the Home screen. It looked device-dependent ("only some phones") but
/// it tracks the status-bar inset exactly:  gap = topInset - 29.
///
/// Real status-bar insets, smallest to largest.
const devices = <String, double>{
  'Android (typical)': 24.0,
  'iPhone SE / 8': 20.0,
  'iPhone 13 mini': 50.0,
  'iPhone X / 11 / 12 / 13': 47.0,
  'iPhone 14 Pro (Dynamic Island)': 59.0,
  'iPhone 15 Pro Max': 62.0,
  'tall Android notch': 39.0,
};

/// Old layout: expandedHeight 160, content top-aligned at a fixed offset
/// (5 padding + 32 spacer + 60 weather + 2 + 42 search = 141).
const _oldExpandedHeight = 160.0;
const _oldContentHeight = 141.0;

void main() {
  group('old layout reproduced the bug', () {
    devices.forEach((name, inset) {
      test('$name (inset $inset) had a gap of ${inset - 29}', () {
        final g = homeHeaderGeometry(
          topInset: inset,
          expandedHeight: _oldExpandedHeight,
          contentHeight: _oldContentHeight,
          bottomAligned: false,
        );
        expect(g.gap, inset - 29,
            reason: 'the gap was a pure function of the status-bar inset');
      });
    });

    test('phones with a small inset showed no gap — hence "only some phones"',
        () {
      for (final inset in [20.0, 24.0]) {
        final g = homeHeaderGeometry(
          topInset: inset,
          expandedHeight: _oldExpandedHeight,
          contentHeight: _oldContentHeight,
          bottomAligned: false,
        );
        expect(g.gap, lessThanOrEqualTo(0));
      }
    });

    test('notched iPhones showed a visible gap', () {
      for (final inset in [47.0, 50.0, 59.0, 62.0]) {
        final g = homeHeaderGeometry(
          topInset: inset,
          expandedHeight: _oldExpandedHeight,
          contentHeight: _oldContentHeight,
          bottomAligned: false,
        );
        expect(g.gap, greaterThan(14), reason: 'inset $inset');
      }
    });
  });

  group('new layout is identical on every device', () {
    devices.forEach((name, inset) {
      test('$name (inset $inset): no gap, content starts at the safe area', () {
        final g = homeHeaderGeometry(topInset: inset);

        expect(g.gap, 0, reason: 'search field must sit on the tab strip');
        expect(g.contentTop, inset,
            reason: 'content must start exactly below the status bar');
        expect(g.totalHeight, inset + kHomeHeaderContentHeight + kHomeTabBarHeight);
      });
    });

    test('content height below the status bar is the same on all devices', () {
      final heights = devices.values.map((inset) {
        final g = homeHeaderGeometry(topInset: inset);
        return g.totalHeight - g.contentTop;
      }).toSet();

      expect(heights, hasLength(1),
          reason: 'every device must render the same header below the notch');
      expect(heights.single, kHomeHeaderContentHeight + kHomeTabBarHeight);
    });

    test('header is shorter than before on every device', () {
      devices.forEach((name, inset) {
        final now = homeHeaderGeometry(topInset: inset).totalHeight;
        expect(now, lessThan(inset + _oldExpandedHeight), reason: name);
      });
    });
  });

  group('rendered layout (real Flutter geometry, not just arithmetic)', () {
    /// Builds the same structure HomeAppBar uses — SliverAppBar with the shared
    /// constants, a bottom-aligned content column of kHomeHeaderContentHeight,
    /// and a tab strip of kHomeTabBarHeight — then measures the real gap.
    Widget harness(double inset) {
      return MediaQuery(
        data: MediaQueryData(padding: EdgeInsets.only(top: inset)),
        child: MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  toolbarHeight: 0,
                  expandedHeight: kHomeHeaderContentHeight + kHomeTabBarHeight,
                  automaticallyImplyLeading: false,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      padding: EdgeInsets.only(
                        top: inset,
                        left: 16,
                        right: 16,
                        bottom: kHomeTabBarHeight,
                      ),
                      alignment: Alignment.bottomCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          SizedBox(height: 60, key: Key('weatherRow')),
                          SizedBox(height: 2),
                          SizedBox(height: 42, key: Key('searchBar')),
                        ],
                      ),
                    ),
                  ),
                  bottom: const PreferredSize(
                    preferredSize: Size(double.infinity, kHomeTabBarHeight),
                    child: SizedBox(
                      height: kHomeTabBarHeight,
                      key: Key('tabStrip'),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 1200)),
              ],
            ),
          ),
        ),
      );
    }

    for (final entry in devices.entries) {
      testWidgets('${entry.key} (inset ${entry.value}) renders no gap',
          (tester) async {
        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(harness(entry.value));
        await tester.pumpAndSettle();

        final searchBottom =
            tester.getBottomLeft(find.byKey(const Key('searchBar'))).dy;
        final stripTop =
            tester.getTopLeft(find.byKey(const Key('tabStrip'))).dy;

        expect(stripTop - searchBottom, moreOrLessEquals(0, epsilon: 0.5),
            reason: 'rendered gap must be zero on ${entry.key}');
      });
    }

    /// Binds the assertion to the REAL HomeAppBar, so reverting
    /// expandedHeight / the alignment in the widget fails this test.
    testWidgets('the real HomeAppBar renders no gap on a Dynamic Island iPhone',
        (tester) async {
      tester.view.physicalSize = const Size(1179, 2556);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      Get.testMode = true;
      Get.put(LocationController());
      Get.put(HomeController());
      Get.put(HomeBannerController());
      Get.put(ProfileController());
      addTearDown(Get.reset);

      const inset = 59.0;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.only(top: inset)),
          child: GetMaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                slivers: [
                  const HomeAppBar(
                    bottom: SizedBox(
                      key: Key('realTabStrip'),
                      height: kHomeTabBarHeight,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 1200)),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final searchBottom =
          tester.getBottomLeft(find.byType(AnimatedSearchBar)).dy;
      final stripTop =
          tester.getTopLeft(find.byKey(const Key('realTabStrip'))).dy;

      expect(stripTop - searchBottom, moreOrLessEquals(0, epsilon: 1.0),
          reason: 'the real header must leave no band above the tabs');

      // Unmount so AnimatedSearchBar.dispose() cancels its periodic timer.
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('content never hides under the status bar', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      for (final inset in devices.values) {
        await tester.pumpWidget(harness(inset));
        await tester.pumpAndSettle();

        final weatherTop =
            tester.getTopLeft(find.byKey(const Key('weatherRow'))).dy;
        expect(weatherTop, greaterThanOrEqualTo(inset - 0.5),
            reason: 'content must clear the status bar at inset $inset');
      }
    });
  });
}
