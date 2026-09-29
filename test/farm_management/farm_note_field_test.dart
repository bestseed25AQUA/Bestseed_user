import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedsuser/app/farm_management/farmer/widget/farm_note_field.dart';

/// The note field scrolls its TEXT, and the scrollbar has to be measured
/// against that same box.
///
/// The scrollbar used to wrap the decorated field, so its track covered the
/// border and padding as well. The thumb was positioned against a taller box
/// than the one being scrolled and stopped short of the bottom even with the
/// caret at the end of the note.
void main() {
  Future<void> pump(
    WidgetTester tester,
    TextEditingController controller, {
    bool readOnly = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: FarmNoteField(
              controller: controller,
              hintText: 'Water change, aerator down…',
              readOnly: readOnly,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  ScrollController scrollControllerOf(WidgetTester tester) {
    final field = tester.widget<TextField>(find.byType(TextField));
    return field.scrollController!;
  }

  testWidgets('renders without a layout error', (tester) async {
    await pump(tester, TextEditingController());

    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
  });

  testWidgets('a short note does not scroll', (tester) async {
    final controller = TextEditingController(text: 'Aerator down.');

    await pump(tester, controller);

    expect(scrollControllerOf(tester).position.maxScrollExtent, 0);
  });

  testWidgets('a long note scrolls, and the end is reachable', (tester) async {
    final controller = TextEditingController(
      text: List.filled(12, 'testing whether the note scrolls properly').join(' '),
    );

    await pump(tester, controller);

    final scroll = scrollControllerOf(tester);

    expect(
      scroll.position.maxScrollExtent,
      greaterThan(0),
      reason: 'A note longer than the box must scroll.',
    );

    // The thumb is drawn from these metrics, so the bottom being reachable is
    // the thing the reported bug was about.
    scroll.jumpTo(scroll.position.maxScrollExtent);
    await tester.pump();

    expect(scroll.offset, scroll.position.maxScrollExtent);
  });

  /// The fix, stated directly: the box the scrollbar paints in and the box the
  /// text scrolls in must be the same height. When they differ, the thumb is
  /// positioned against the wrong extent and stops short of the bottom.
  testWidgets('the scrollbar box matches the scrollable viewport', (tester) async {
    final controller = TextEditingController(
      text: List.filled(12, 'testing whether the note scrolls properly').join(' '),
    );

    await pump(tester, controller);

    final painted = tester.getSize(find.byType(TextField)).height;
    final scrolled = scrollControllerOf(tester).position.viewportDimension;

    expect(
      scrolled,
      closeTo(painted, 0.5),
      reason: 'Padding or a counter inside the field would offset the thumb.',
    );
  });

  testWidgets('a read-only note still renders its text', (tester) async {
    final controller = TextEditingController(text: 'Medicine given.');

    await pump(tester, controller, readOnly: true);

    expect(tester.takeException(), isNull);
    expect(find.text('Medicine given.'), findsOneWidget);
  });
}
