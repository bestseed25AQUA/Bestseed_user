import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/app_color.dart';

/// The pill Save button used on every feed card in Farm Management.
///
/// Exists because the same twenty lines of `ElevatedButton.icon` were written
/// out on the feed screen and again on the tank history screen, with the corner
/// radius and the padding quietly different between them — so the two cards a
/// farmer moves between showed two slightly different buttons.
///
/// Not [CustomButton]: that one is full width, has no icon, and treats loading
/// as its only inactive state. A card's Save sits at the end of a row beside
/// "Add meal" and has to distinguish three states, not two:
///
///   nothing to save  — pale and unclickable, so the card reads as "up to date"
///   ready            — solid, the farmer has typed something worth keeping
///   saving           — a spinner in place of the tick
///
/// [enabled] is the one a caller has to think about. It should mean "there is
/// a change worth writing", not "this field has a value in it" — see
/// [MealRowState.isDirty].
class FarmSaveButton extends StatelessWidget {
  /// Whether there is anything worth saving. False leaves the button pale and
  /// inert rather than hiding it, so the farmer can see that Save exists and
  /// that it has nothing to do yet.
  final bool enabled;

  /// True while the save is in flight. Takes precedence over [enabled]: a
  /// second tap mid-save would write the same rows twice.
  final bool isLoading;

  final VoidCallback onPressed;

  final String label;

  /// 30 on the tank history card, 18 on the feed card — the two were written
  /// separately and never matched. Defaulted here so new call sites agree
  /// without having to know either number.
  final double borderRadius;

  final EdgeInsetsGeometry padding;

  const FarmSaveButton({
    super.key,
    required this.onPressed,
    this.enabled = true,
    this.isLoading = false,
    this.label = 'Save',
    this.borderRadius = 24,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
  });

  @override
  Widget build(BuildContext context) {
    final active = enabled && !isLoading;

    return ElevatedButton.icon(
      onPressed: active ? onPressed : null,
      icon: isLoading
          ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.check, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        // The pale blue of a button with nothing to do. Deliberately the
        // brand colour faded rather than grey: grey reads as broken, faded
        // reads as waiting.
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.35),
        disabledForegroundColor: Colors.white.withValues(alpha: 0.85),
        elevation: active ? 1 : 0,
        padding: padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Rebuilds [builder] whenever any of [inputs] changes.
///
/// Save has to light up on the keystroke that makes a card worth saving, and
/// the cards are StatelessWidgets rebuilt only on their parent's setState.
/// Listening to the text controllers directly keeps the rebuild to the button
/// itself rather than calling setState on a screen that is a long list of
/// cards, each with several fields.
class SaveStateBuilder extends StatelessWidget {
  final List<Listenable> inputs;
  final WidgetBuilder builder;

  const SaveStateBuilder({
    super.key,
    required this.inputs,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    if (inputs.isEmpty) return builder(context);

    return ListenableBuilder(
      listenable: Listenable.merge(inputs),
      builder: (context, _) => builder(context),
    );
  }
}
