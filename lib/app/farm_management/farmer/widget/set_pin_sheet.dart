import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_button.dart';

/// Bottom sheet used for both PIN steps of the access flow.
///
/// The farmer sets a PIN when generating a QR; the person scanning enters the
/// same PIN to confirm. Only the copy and button label differ, so one sheet
/// serves both — [title], [subtitle] and [confirmLabel] cover the difference.
class SetPinSheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final String confirmLabel;
  final bool isLoading;

  /// Called with the 4-digit PIN. Returning false keeps the sheet open, which
  /// is what the verify step needs after a wrong PIN.
  /// Handles the entered PIN. Return null when it is accepted, or the message
  /// to show in red under the boxes when it is not.
  final Future<String?> Function(String pin) onConfirm;

  const SetPinSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.confirmLabel,
    required this.onConfirm,
    this.isLoading = false,
  });

  @override
  State<SetPinSheet> createState() => _SetPinSheetState();
}

class _SetPinSheetState extends State<SetPinSheet> {
  final _pinController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pin = _pinController.text.trim();

    if (pin.length != 4) {
      setState(() => _error = 'Enter all 4 digits');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    // null means accepted; anything else is the reason it was not.
    final failure = await widget.onConfirm(pin);

    if (!mounted) return;

    if (failure != null) {
      // Wrong PIN — clear so the next attempt starts from an empty field.
      _pinController.clear();
    }

    setState(() {
      _busy = false;
      _error = failure;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Lift the sheet above the keyboard.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  customBorder: const CircleBorder(),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              widget.subtitle,
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 20),
            PinCodeTextField(
              appContext: context,
              length: 4,
              controller: _pinController,
              // This sheet creates the controller, so this sheet disposes it.
              // PinCodeTextField defaults to disposing whatever it is given,
              // which meant it was released twice — "A TextEditingController
              // was used after being disposed" as the tree was torn down.
              autoDisposeControllers: false,
              keyboardType: TextInputType.number,
              animationType: AnimationType.fade,
              enableActiveFill: false,
              cursorColor: AppColors.primary,
              textStyle: GoogleFonts.roboto(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.underline,
                fieldHeight: 46,
                fieldWidth: 52,
                activeColor: AppColors.primary,
                selectedColor: AppColors.primary,
                inactiveColor: Colors.grey.shade400,
              ),
              onChanged: (value) {
                // Emptying the field in code after a failed attempt lands here
                // too, with an empty value — and that used to wipe the message
                // in the same frame it was set, so nothing was ever shown.
                // Only real typing dismisses it.
                if (value.isEmpty) return;
                if (_error != null) setState(() => _error = null);
              },
              onCompleted: (_) => _submit(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 18,
                      color: Colors.red.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: GoogleFonts.roboto(
                          color: Colors.red.shade700,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: widget.confirmLabel,
                borderRadius: 30,
                isLoading: _busy || widget.isLoading,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens [SetPinSheet] as a modal bottom sheet.
Future<void> showPinSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  required String confirmLabel,
  required Future<String?> Function(String pin) onConfirm,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => SetPinSheet(
      title: title,
      subtitle: subtitle,
      confirmLabel: confirmLabel,
      onConfirm: onConfirm,
    ),
  );
}
