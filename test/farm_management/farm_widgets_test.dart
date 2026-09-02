import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedsuser/app/farm_management/farmer/widget/farm_empty_state.dart';
import 'package:seedsuser/app/farm_management/farmer/widget/farm_shimmer.dart';
import 'package:seedsuser/app/farm_management/farmer/widget/role_tab_bar.dart';

/// The shared pieces the farm-management screens are assembled from.
///
/// None of them talk to a controller or the network, so they can be driven
/// directly — which is the point: a screen that fails here fails for a reason
/// in the widget, not in a request.
void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('FarmEmptyState', () {
    testWidgets('shows the icon, the title and the explanation', (tester) async {
      await tester.pumpWidget(wrap(const FarmEmptyState(
        icon: Icons.grass,
        title: 'No farms yet',
        message: 'Add your first farm to get started.',
      )));

      expect(find.text('No farms yet'), findsOneWidget);
      expect(find.text('Add your first farm to get started.'), findsOneWidget);
      expect(find.byIcon(Icons.grass), findsOneWidget);
    });

    testWidgets('offers no button when there is nothing to do', (tester) async {
      await tester.pumpWidget(wrap(const FarmEmptyState(
        icon: Icons.people_outline,
        title: 'No managers yet',
        message: 'Nobody has been given access to this farm.',
      )));

      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('shows the action only when both label and callback are given',
        (tester) async {
      // Half a button — a label with no callback — would look tappable and do
      // nothing, so it takes both.
      await tester.pumpWidget(wrap(FarmEmptyState(
        icon: Icons.people_outline,
        title: 'No managers yet',
        message: 'Give someone access to get started.',
        actionLabel: 'Set Up Access',
        onAction: () {},
      )));

      expect(find.text('Set Up Access'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('a label with no callback stays hidden', (tester) async {
      await tester.pumpWidget(wrap(const FarmEmptyState(
        icon: Icons.people_outline,
        title: 'No managers yet',
        message: 'Give someone access to get started.',
        actionLabel: 'Set Up Access',
      )));

      expect(find.text('Set Up Access'), findsNothing);
    });

    testWidgets('the action fires when tapped', (tester) async {
      var taps = 0;

      await tester.pumpWidget(wrap(FarmEmptyState(
        icon: Icons.add,
        title: 'No farms yet',
        message: 'Add your first farm.',
        actionLabel: 'Add Farm Details',
        onAction: () => taps++,
      )));

      await tester.tap(find.text('Add Farm Details'));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('survives a short viewport without overflowing', (tester) async {
      // The empty state sits above a pair of buttons, and the keyboard closing
      // behind a route change briefly leaves that area far shorter than its
      // content — which is exactly where a RenderFlex overflow came from.
      tester.view.physicalSize = const Size(720, 640);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(wrap(const SingleChildScrollView(
        child: SizedBox(
          height: 260,
          child: FarmEmptyState(
            icon: Icons.grass,
            title: 'No farms yet',
            message: 'Add your first farm to get started.',
          ),
        ),
      )));

      expect(tester.takeException(), isNull);
    });
  });

  group('RoleTabBar', () {
    testWidgets('offers both roles', (tester) async {
      await tester.pumpWidget(wrap(RoleTabBar(
        selected: 'partner',
        onChanged: (_) {},
      )));

      expect(find.text('Partners'), findsOneWidget);
      expect(find.text('Manager'), findsOneWidget);
    });

    testWidgets('marks the selected role differently from the other',
        (tester) async {
      await tester.pumpWidget(wrap(RoleTabBar(
        selected: 'partner',
        onChanged: (_) {},
      )));

      Color pillColour(String label) {
        final container = tester.widget<Container>(
          find.ancestor(of: find.text(label), matching: find.byType(Container)).first,
        );
        return (container.decoration! as BoxDecoration).color!;
      }

      expect(pillColour('Partners'), isNot(pillColour('Manager')));
    });

    testWidgets('reports the role that was tapped', (tester) async {
      final tapped = <String>[];

      await tester.pumpWidget(wrap(RoleTabBar(
        selected: 'partner',
        onChanged: tapped.add,
      )));

      await tester.tap(find.text('Manager'));
      await tester.pump();

      expect(tapped, ['manager']);
    });

    testWidgets('re-tapping the selected role still reports it', (tester) async {
      // The parent decides what to do about it; the bar just says what was hit.
      final tapped = <String>[];

      await tester.pumpWidget(wrap(RoleTabBar(
        selected: 'manager',
        onChanged: tapped.add,
      )));

      await tester.tap(find.text('Manager'));
      await tester.pump();

      expect(tapped, ['manager']);
    });
  });

  group('shimmers', () {
    // Placeholders shown on the FIRST load only. They must render on their own
    // — they stand in for a screen whose data has not arrived, so anything they
    // needed from that data would defeat the point.
    testWidgets('the farm list placeholder renders', (tester) async {
      await tester.pumpWidget(wrap(const FarmListShimmer()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(FarmListShimmer), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the tank grid placeholder renders', (tester) async {
      await tester.pumpWidget(wrap(const TankGridShimmer()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });

    testWidgets('the tank history placeholder renders', (tester) async {
      await tester.pumpWidget(wrap(const TankHistoryShimmer()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });

    testWidgets('the list-tile placeholder renders', (tester) async {
      await tester.pumpWidget(wrap(const ListTileShimmer()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });

    testWidgets('a placeholder fits a narrow phone without overflowing',
        (tester) async {
      tester.view.physicalSize = const Size(720, 1280);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(wrap(const FarmListShimmer()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });
  });
}
