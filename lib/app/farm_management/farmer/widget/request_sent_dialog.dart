import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Confirmation popup shown after a new farm request is submitted.
class RequestSentDialog extends StatelessWidget {
  const RequestSentDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      constraints: const BoxConstraints(maxWidth: 300, minHeight: 200),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Image.asset('assets/images/SealCheck.png', height: 80, width: 80),
          const SizedBox(height: 20),
          Text(
            'Your \nrequest was sent',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We will notify your farm details soon',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

/// Shows [RequestSentDialog] and dismisses it automatically after [duration].
///
/// The design has no dismiss button, so the popup closes itself. Awaiting this
/// call lets the caller navigate only once the popup is gone — otherwise the
/// pop would close the dialog route instead of the screen underneath.
Future<void> showRequestSentDialog(
  BuildContext context, {
  Duration duration = const Duration(seconds: 2),
}) async {
  late BuildContext dialogContext;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      dialogContext = ctx;
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Material(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            child: RequestSentDialog(),
          ),
        ),
      );
    },
  );

  await Future.delayed(duration);

  if (dialogContext.mounted) {
    Navigator.of(dialogContext).pop();
  }
}
