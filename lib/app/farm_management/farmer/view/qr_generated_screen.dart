import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_button.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/farm_management/farmer/model/farm_access_model.dart';

/// Shows a generated access QR together with its PIN, ready to share.
///
/// Rendered as a sheet-style page so it works both right after generating a
/// code and when re-opening one from the QR list.
class QrGeneratedScreen extends StatefulWidget {
  final FarmAccessGrant grant;

  const QrGeneratedScreen({super.key, required this.grant});

  @override
  State<QrGeneratedScreen> createState() => _QrGeneratedScreenState();
}

class _QrGeneratedScreenState extends State<QrGeneratedScreen> {
  /// Wraps the QR so it can be rasterised for sharing.
  final _qrKey = GlobalKey();
  bool _sharing = false;

  /// Captures the on-screen QR as a PNG and hands it to the share sheet.
  ///
  /// Sharing the image rather than the raw token means the recipient can scan
  /// it straight from WhatsApp, which is how the flow is meant to be used.
  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);

    try {
      final boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        CustomToast.error('Could not prepare the QR image');
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        CustomToast.error('Could not prepare the QR image');
        return;
      }

      final bytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/bestseed_access_${widget.grant.id}.png');
      await file.writeAsBytes(bytes);

      final pin = widget.grant.pin ?? '';
      final role = widget.grant.isPartner ? 'Partner' : 'Manager';

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'BestSeed farm access ($role)\n'
              'PIN: $pin\n'
              'Valid for ${widget.grant.durationDays} days.\n'
              'Scan the QR in the BestSeed app and enter the PIN.',
        ),
      );
    } catch (e) {
      CustomToast.error('Could not share the QR');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pin = widget.grant.pin;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        title: Text(
          'QR Generated',
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            RepaintBoundary(
              key: _qrKey,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: QrImageView(
                  data: widget.grant.token,
                  version: QrVersions.auto,
                  size: 240,
                  backgroundColor: Colors.white,
                  // A logo would eat error-correction budget, so keep the code
                  // clean and rely on high correction for reliable scanning.
                  errorCorrectionLevel: QrErrorCorrectLevel.H,
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (pin != null && pin.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'PIN : $pin',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Text(
              'Share the QR and PIN with your Partner or\nManager to give secure access',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Valid for ${widget.grant.durationDays} days',
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Share',
                borderRadius: 30,
                isLoading: _sharing,
                onPressed: _share,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
