import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';

/// The free-text note field used on the feed card and the tank history card.
class FarmNoteField extends StatefulWidget {
  final TextEditingController controller;

  final bool readOnly;

  final String label;

  final String hintText;

  /// Height of the field, in lines, before it starts scrolling.
  final int maxLines;

  final int maxLength;

  const FarmNoteField({
    super.key,
    required this.controller,
    required this.hintText,
    this.readOnly = false,
    this.label = 'Notes',
    this.maxLines = 3,
    this.maxLength = 2000,
  });

  @override
  State<FarmNoteField> createState() => _FarmNoteFieldState();
}

class _FarmNoteFieldState extends State<FarmNoteField> {
  final ScrollController _scroll = ScrollController();
  final FocusNode _focus = FocusNode();

  bool _overflows = false;
  bool _focused = false;

  static const double _fontSize = 14;
  static const double _lineHeight = 1.35;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_scheduleCheck);
    _focus.addListener(_onFocusChanged);
    _scheduleCheck();
  }

  @override
  void didUpdateWidget(covariant FarmNoteField old) {
    super.didUpdateWidget(old);

    if (old.controller != widget.controller) {
      old.controller.removeListener(_scheduleCheck);
      widget.controller.addListener(_scheduleCheck);
    }

    _scheduleCheck();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_scheduleCheck);
    _focus.removeListener(_onFocusChanged);
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focus.hasFocus != _focused) {
      setState(() => _focused = _focus.hasFocus);
    }
  }

  /// maxScrollExtent is only meaningful once the field has been laid out, so
  /// the check waits for the frame that follows the change.
  void _scheduleCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final overflows =
          _scroll.hasClients && _scroll.position.maxScrollExtent > 0;

      if (overflows != _overflows) {
        setState(() => _overflows = overflows);
      }
    });
  }

  /// The exact height of [maxLines] lines of text.
  ///
  /// Fixed rather than left to the TextField, so the box the scrollbar paints
  /// in is the same box the text scrolls in. Letting the decoration own the
  /// height put the border and padding inside the scrollbar's track, and the
  /// thumb was then positioned against a taller box than the one being
  /// scrolled — so it sat short of the bottom even with the caret at the end.
  double get _textHeight => _fontSize * _lineHeight * widget.maxLines;

  @override
  Widget build(BuildContext context) {
    final borderColour = _focused ? AppColors.primary : Colors.grey.shade300;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.sticky_note_2_outlined,
              size: 15,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 5),
            Text(
              widget.label,
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
          decoration: BoxDecoration(
            color: widget.readOnly ? Colors.grey.shade100 : null,
            border: Border.all(color: borderColour, width: _focused ? 1.6 : 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SizedBox(
            height: _textHeight,
            child: ScrollbarTheme(
              data: ScrollbarThemeData(
                thumbColor: WidgetStateProperty.all(AppColors.primary),
                trackColor: WidgetStateProperty.all(
                  AppColors.primary.withValues(alpha: 0.12),
                ),
                trackBorderColor: WidgetStateProperty.all(Colors.transparent),
              ),
              child: Scrollbar(
                controller: _scroll,
                thumbVisibility: _overflows,
                trackVisibility: _overflows,
                thickness: 5,
                radius: const Radius.circular(3),
                child: Padding(
                  padding: EdgeInsets.only(right: _overflows ? 12 : 6),
                  child: TextField(
                    controller: widget.controller,
                    scrollController: _scroll,
                    focusNode: _focus,
                    readOnly: widget.readOnly,
                    maxLines: null,
                    expands: true,
                    maxLength: widget.maxLength,
                    textAlignVertical: TextAlignVertical.top,
                    textCapitalization: TextCapitalization.sentences,
                    style: GoogleFonts.roboto(
                      fontSize: _fontSize,
                      height: _lineHeight,
                    ),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      // maxLength reserves room for a counter even when the
                      // decoration is collapsed, and that space came out of
                      // the scrollable box.
                      counterText: '',
                      hintText: widget.hintText,
                      hintStyle: GoogleFonts.roboto(
                        fontSize: 13,
                        height: _lineHeight,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
