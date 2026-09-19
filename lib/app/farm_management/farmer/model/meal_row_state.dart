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

  /// What this line held when it was seeded from the server.
  ///
  /// Kept so the card can tell an untouched line from an edited one, which is
  /// what decides whether Save is offered at all. Without a baseline the only
  /// available question is "is there a value here", and a card showing feed
  /// already recorded would answer yes for ever — so Save sat lit on every
  /// card on the screen, inviting a farmer to re-save what was already saved.
  final String savedNumber;
  final String savedQuantity;

  MealRowState({this.historyId, String number = '', String quantity = ''})
    : number = TextEditingController(text: number),
      quantity = TextEditingController(text: quantity),
      savedNumber = number,
      savedQuantity = quantity;

  /// True for a line that exists on the server.
  bool get isSaved => historyId != null;

  /// True when this line has something to save.
  ///
  /// An empty line is never dirty, however much it was fiddled with and
  /// cleared again: a blank quantity is nothing to record, and treating it as
  /// a change would light Save for a farmer who typed a digit and thought
  /// better of it.
  bool get isDirty {
    final currentQuantity = quantity.text.trim();

    if (currentQuantity.isEmpty) return false;

    return currentQuantity != savedQuantity.trim() ||
        number.text.trim() != savedNumber.trim();
  }

  /// The controllers a card must listen to in order to keep Save in step with
  /// what is being typed.
  List<Listenable> get listenables => [number, quantity];

  void dispose() {
    number.dispose();
    quantity.dispose();
  }
}
