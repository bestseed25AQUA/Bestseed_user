import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedsuser/app/farm_management/farmer/widget/start_batch_sheet.dart';

/// The sheet a farmer answers when a tank is put back into service.
///
/// Re-activating starts a NEW crop, so it needs a date to count days from and —
/// only when that date is in the past — a figure for feed already given. The
/// figure is deliberately absent for a tank stocked today: there is no past to
/// account for, and an empty box for one is just something to scroll past.
void main() {
  /// The toast is a platform plugin, which has no implementation in a test.
  /// Swallowing the call lets the validation paths run and be asserted on.
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('PonnamKarthik/fluttertoast'),
      (call) async => null,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('PonnamKarthik/fluttertoast'),
      null,
    );
  });

  /// Opens the sheet over a bare app and hands back the result it pops with.
  Future<StartBatchResult?> openSheet(
    WidgetTester tester, {
    String tankName = 'Tank 2',
  }) async {
    StartBatchResult? result;
    var returned = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showStartBatchSheet(context, tankName: tankName);
                  returned = true;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    addTearDown(() => returned);
    return result;
  }

  /// Drives the date picker to a day offset from today.
  Future<void> pickDate(WidgetTester tester, {required int daysAgo}) async {
    final target = DateTime.now().subtract(Duration(days: daysAgo));

    await tester.tap(find.byType(TextField).first);
    await tester.pumpAndSettle();

    // The picker opens on today; typing the date is steadier than tapping a
    // grid cell that may sit in a different month.
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField).last,
      '${target.month.toString().padLeft(2, '0')}/'
      '${target.day.toString().padLeft(2, '0')}/${target.year}',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  testWidgets('asks about the tank by name, in plain words', (tester) async {
    await openSheet(tester, tankName: 'Tank 4');

    expect(find.text('Activate tank'), findsOneWidget);
    expect(find.text('When was Tank 4 stocked?'), findsOneWidget);
    expect(find.text('Activate'), findsOneWidget);

    // No bookkeeping jargon: the farmer is told what to do, not what the
    // system does behind it.
    expect(find.textContaining('batch'), findsNothing);
    expect(find.textContaining('zero'), findsNothing);
  });

  testWidgets('opens with only the date — no feed box for a crop with no past',
      (tester) async {
    await openSheet(tester);

    expect(find.text('Stocking date'), findsOneWidget);
    expect(find.text('Feed already used'), findsNothing);
  });

  testWidgets('refuses to submit without a date', (tester) async {
    var popped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  await showStartBatchSheet(context, tankName: 'Tank 1');
                  popped = true;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Activate'));
    await tester.pumpAndSettle();

    // Still open: nothing was returned, so the sheet did not accept it.
    expect(popped, isFalse);
    expect(find.text('Activate tank'), findsOneWidget);

    // The rejection raises a toast, which holds a two-second timer. Let it
    // expire, or the test ends with the timer still pending.
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('a past date reveals the feed-already-used field',
      (tester) async {
    await openSheet(tester);
    await pickDate(tester, daysAgo: 5);

    expect(find.text('Feed already used'), findsOneWidget);
  });

  testWidgets('shows the date as dd-MM-yyyy, never as 2026-09-02',
      (tester) async {
    await openSheet(tester);
    await pickDate(tester, daysAgo: 5);

    final expected = DateTime.now().subtract(const Duration(days: 5));
    final shown =
        '${expected.day.toString().padLeft(2, '0')}-'
        '${expected.month.toString().padLeft(2, '0')}-${expected.year}';

    final field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.controller!.text, shown);
  });

  testWidgets('works out the daily rate once a figure is entered',
      (tester) async {
    await openSheet(tester);
    await pickDate(tester, daysAgo: 4); // 5 days inclusive

    await tester.enterText(find.byType(TextField).last, '50');
    await tester.pumpAndSettle();

    // 50 kg over 5 days. The farmer asked to keep this calculation when the
    // surrounding explanatory text was removed.
    expect(find.text('10.00 kg/day across 5 days'), findsOneWidget);
  });

  testWidgets('a past date will not submit without the feed figure',
      (tester) async {
    await openSheet(tester);
    await pickDate(tester, daysAgo: 3);

    await tester.tap(find.text('Activate'));
    await tester.pumpAndSettle();

    expect(find.text('Activate tank'), findsOneWidget, reason: 'still open');

    // Drain the toast's own timer — see the note in the test above.
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('returns the date in ISO and the figure it was given',
      (tester) async {
    StartBatchResult? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showStartBatchSheet(context, tankName: 'Tank 2');
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await pickDate(tester, daysAgo: 6);

    await tester.enterText(find.byType(TextField).last, '120');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Activate'));
    await tester.pumpAndSettle();

    final expected = DateTime.now().subtract(const Duration(days: 6));
    final iso = '${expected.year}-'
        '${expected.month.toString().padLeft(2, '0')}-'
        '${expected.day.toString().padLeft(2, '0')}';

    // ISO on the wire even though the field showed dd-MM-yyyy: the API reads
    // yyyy-MM-dd and would take "02-09-2026" as a different day, or reject it.
    expect(result, isNotNull);
    expect(result!.stockingDate, iso);
    expect(result!.feedUsedBefore, '120');
  });

  testWidgets('closing with the X returns nothing', (tester) async {
    StartBatchResult? result;
    var returned = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showStartBatchSheet(context, tankName: 'Tank 2');
                  returned = true;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(returned, isTrue);
    expect(result, isNull, reason: 'cancelled — leave the tank as it was');
  });
}
