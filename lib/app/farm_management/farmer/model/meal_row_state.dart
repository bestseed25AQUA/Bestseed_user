import 'package:flutter/widgets.dart';

/// One editable meal line on a feed card: its number and its quantity.
///
/// The meal number is TYPED, not derived from the row's position. A farmer who
/// gives the second meal of the day but records it first should be able to call
/// it meal 2, and correcting a wrong number should not mean deleting the row
/// and starting again.
///
/// [historyId] is the `tank_feed_histories` row this line came from, or null
/// for a line the farmer has just added. It decides whether saving updates an
/// existing record or writes a new one, and whether the line can simply be
/// taken off the card or has to be deleted from the server.
class MealRowState {
  final int? historyId;
  final TextEditingController number;
  final TextEditingController quantity;

  MealRowState({this.historyId, String number = '', String quantity = ''})
    : number = TextEditingController(text: number),
      quantity = TextEditingController(text: quantity);

  /// True for a line that exists on the server.
  bool get isSaved => historyId != null;

  void dispose() {
    number.dispose();
    quantity.dispose();
  }
}
