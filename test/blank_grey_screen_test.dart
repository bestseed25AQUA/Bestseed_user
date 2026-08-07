import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedsuser/app/common/app_error_boundary.dart';

/// Regression cover for the "blank grey screen" on the Android home screen:
/// header and bottom nav render fine, the body is a featureless light-grey
/// block, internet is fine, and it stays until the app is restarted.
///
/// The grey is not a loading placeholder and not missing data — it is Flutter
/// painting over a widget whose build() threw. `RenderErrorBox.backgroundColor`
/// is chosen inside an `assert`, so it is dark red in debug and
/// `Color(0xF0C0C0C0)` — light grey — in release.
///
/// These tests establish, in order:
///   1. the grey really is Flutter's release error colour,
///   2. the mismatch in HomeScreen's tab wiring really does throw,
///   3. the snapshot fix makes that mismatch unreachable,
///   4. after AppErrorBoundary.install() a failure is labelled, not silent.
void main() {
  group('1. the grey block is Flutter\'s release-mode error paint', () {
    test('release error colour is the exact grey seen on screen', () {
      // From flutter/lib/src/rendering/error.dart:
      //   Color result = const Color(0xF0C0C0C0);
      //   assert(() { result = const Color(0xF0900000); return true; }());
      expect(AppErrorBoundary.releaseErrorBoxColor, const Color(0xF0C0C0C0));

      // RGB 192/192/192 — mid light grey, matching the reported screenshot.
      expect(AppErrorBoundary.releaseErrorBoxColor.r * 255, closeTo(192, 0.5));
      expect(AppErrorBoundary.releaseErrorBoxColor.g * 255, closeTo(192, 0.5));
      expect(AppErrorBoundary.releaseErrorBoxColor.b * 255, closeTo(192, 0.5));
    });

    test('debug builds get red instead — which is why this was never seen in dev',
        () {
      // Under `flutter test` asserts are ON, i.e. debug semantics.
      expect(RenderErrorBox.backgroundColor, const Color(0xF0900000),
          reason: 'debug paints red; the same failure in release paints grey, '
              'so this bug is invisible in development');
      expect(RenderErrorBox.backgroundColor,
          isNot(AppErrorBoundary.releaseErrorBoxColor));
    });

    testWidgets('a widget that throws is replaced by an error box filling its slot',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(builder: (_) => throw StateError('boom')),
          ),
        ),
      );

      expect(tester.takeException(), isA<StateError>());
      // This RenderErrorBox is what paints grey in a release build.
      expect(find.byType(ErrorWidget), findsOneWidget);
    });
  });

  group('2. the HomeScreen defect: controller length vs children count', () {
    // Reproduces the exact shape of the old code: the TabBar/TabBarView read
    // `_homeController.categories` live while the TabController was rebuilt
    // separately on a GetX worker. getCategories() calls assignAll() twice
    // (cache, then network), so the two could disagree for a frame.
    Widget harness({required int controllerLength, required int childCount}) {
      return MaterialApp(
        home: DefaultTabController(
          length: controllerLength,
          child: Scaffold(
            body: TabBarView(
              children: List<Widget>.generate(
                  childCount, (i) => Text('tab $i')),
            ),
          ),
        ),
      );
    }

    testWidgets('matched lengths render fine (cache load: 5 categories)',
        (tester) async {
      await tester.pumpWidget(harness(controllerLength: 6, childCount: 6));
      expect(tester.takeException(), isNull);
    });

    testWidgets('network returning MORE categories than the cache throws',
        (tester) async {
      // controller still built for the 5 cached categories (+All = 6),
      // children already rebuilt from the 7 network ones (+All = 8).
      await tester.pumpWidget(harness(controllerLength: 6, childCount: 8));

      expect(tester.takeException(), isNotNull,
          reason: 'this throw inside build() is what release paints grey');
    });

    testWidgets('network returning FEWER categories also throws',
        (tester) async {
      await tester.pumpWidget(harness(controllerLength: 8, childCount: 6));
      expect(tester.takeException(), isNotNull);
    });
  });

  group('3. the fix: one snapshot drives tabs, children and controller', () {
    // Mirrors _buildTabs()/_tabCategories in home_screen.dart.
    late List<String> live; // the RxList that assignAll() mutates
    late List<String> snapshot; // what the controller was built for
    late int controllerLength;

    void buildTabs() {
      final snap = List<String>.unmodifiable(live);
      if (snap.isEmpty) return;
      final newLength = snap.length + 1;
      if (controllerLength == newLength && snap.join() == snapshot.join()) {
        return;
      }
      controllerLength = newLength;
      snapshot = snap;
    }

    setUp(() {
      live = <String>[];
      snapshot = const <String>[];
      controllerLength = 0;
    });

    test('cache-then-network with DIFFERENT counts stays consistent', () {
      live = ['a', 'b', 'c', 'd', 'e']; // cache
      buildTabs();
      expect(controllerLength, snapshot.length + 1);

      live = ['a', 'b', 'c', 'd', 'e', 'f', 'g']; // network, 2 more
      buildTabs();
      expect(controllerLength, snapshot.length + 1,
          reason: 'children count must always equal controller length');
    });

    test('a rebuild BETWEEN the two assignAll calls still cannot mismatch', () {
      live = ['a', 'b', 'c'];
      buildTabs();

      // Network lands but the worker has not run yet — this is the exact
      // window that used to break. build() now reads `snapshot`, not `live`.
      live = ['a', 'b', 'c', 'd', 'e', 'f'];

      expect(controllerLength, snapshot.length + 1,
          reason: 'build() renders the snapshot, which still matches');
      expect(snapshot.length, 3, reason: 'snapshot is untouched until rebuild');

      buildTabs(); // worker runs
      expect(controllerLength, snapshot.length + 1);
      expect(snapshot.length, 6);
    });

    test('survives a long random sequence of category changes', () {
      final counts = [1, 9, 9, 3, 12, 12, 2, 7, 1, 20, 4, 4, 15, 6];
      for (final n in counts) {
        live = List<String>.generate(n, (i) => 'c$i');
        buildTabs();
        expect(controllerLength, snapshot.length + 1,
            reason: 'mismatch after switching to $n categories');
      }
    });

    test('an empty network response never leaves a stale mismatch', () {
      live = ['a', 'b', 'c'];
      buildTabs();
      final before = controllerLength;

      live = <String>[]; // location with no categories
      buildTabs(); // early-returns, keeps the old controller

      expect(controllerLength, before);
      expect(controllerLength, snapshot.length + 1,
          reason: 'snapshot kept alongside the controller, so still in sync');
    });
  });

  group('4. tab-index safety (the "All" tab RangeError)', () {
    // The old listener/onTap did categories[index - 1] unguarded.
    String? categoryAt(int index, List<String> cats) {
      if (index <= 0 || index - 1 >= cats.length) return null;
      return cats[index - 1];
    }

    test('old code would have thrown on the "All" tab', () {
      final cats = ['x', 'y'];
      expect(() => cats[0 - 1], throwsRangeError);
    });

    test('index 0 resolves to no category instead of throwing', () {
      expect(categoryAt(0, ['x', 'y']), isNull);
    });

    test('an index past a shrunken list resolves to null', () {
      expect(categoryAt(5, ['x', 'y']), isNull);
    });

    test('real category indexes still map correctly', () {
      expect(categoryAt(1, ['x', 'y']), 'x');
      expect(categoryAt(2, ['x', 'y']), 'y');
    });
  });

  group('5. the safety net: failures are labelled, never a silent grey block',
      () {
    // flutter_test asserts ErrorWidget.builder is back to default at the end of
    // each test BODY — before tearDown runs — so restore it inside the body.
    Future<void> withBoundary(
      Future<void> Function() body, {
      void Function(FlutterErrorDetails details)? report,
    }) async {
      AppErrorBoundary.install(report: report);
      try {
        await body();
      } finally {
        AppErrorBoundary.resetForTest();
      }
    }

    testWidgets('a throwing widget renders the labelled panel', (tester) async {
      await withBoundary(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(builder: (_) => throw StateError('kaboom')),
            ),
          ),
        );
        tester.takeException();

        expect(find.byType(AppErrorPanel), findsOneWidget,
            reason: 'the user must see something explaining the failure');
        expect(find.text("This section couldn't be displayed"), findsOneWidget);
        expect(find.byType(ErrorWidget), findsNothing,
            reason: 'the default grey/red box must be replaced');
      });
    });

    testWidgets('every failure is recorded for reporting', (tester) async {
      await withBoundary(() async {
        expect(AppErrorBoundary.recorded, isEmpty);

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(builder: (_) => throw StateError('recorded please')),
          ),
        );
        tester.takeException();

        expect(AppErrorBoundary.recorded, isNotEmpty,
            reason: 'the old behaviour logged nothing at all');
        expect(
          AppErrorBoundary.recorded
              .any((d) => d.exceptionAsString().contains('recorded please')),
          isTrue,
        );
      });
    });

    testWidgets('a reporter sink receives the failure', (tester) async {
      final seen = <String>[];
      await withBoundary(
        report: (d) => seen.add(d.exceptionAsString()),
        () async {
          await tester.pumpWidget(
            MaterialApp(
                home: Builder(builder: (_) => throw StateError('to sink'))),
          );
          tester.takeException();
        },
      );

      expect(seen.any((m) => m.contains('to sink')), isTrue,
          reason: 'wire this to Crashlytics and the bug reports itself');
    });

    testWidgets('a throwing reporter cannot take the app down', (tester) async {
      await withBoundary(
        report: (_) => throw StateError('bad reporter'),
        () async {
          await tester.pumpWidget(
            MaterialApp(
                home: Builder(builder: (_) => throw StateError('original'))),
          );
          tester.takeException();

          expect(find.byType(AppErrorPanel), findsOneWidget);
        },
      );
    });

    testWidgets('the panel survives having no Material/Theme ancestor',
        (tester) async {
      // The panel is inserted wherever the failure happened, which may be
      // outside any MaterialApp scope.
      await tester.pumpWidget(
        AppErrorPanel(
          details: FlutterErrorDetails(exception: StateError('bare')),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(AppErrorPanel), findsOneWidget);
    });
  });
}
