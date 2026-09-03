import 'package:flutter_test/flutter_test.dart';

/// Mirrors _feedUsedLabel — the label names the span the figure is spread over.
String feedUsedLabel(int days) =>
    days > 0 ? 'Feed used past $days days' : 'Feed used';

void main() {
  test('names the span the figure covers', () {
    expect(feedUsedLabel(4), 'Feed used past 4 days');
    expect(feedUsedLabel(33), 'Feed used past 33 days');
  });

  test('falls back when there is no past span', () {
    // The field is only shown for a past date, so this is belt and braces.
    expect(feedUsedLabel(0), 'Feed used');
  });
}
