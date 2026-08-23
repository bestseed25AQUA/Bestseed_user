import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/farm_management/farmer/controller/farm_access_controller.dart';
import 'package:seedsuser/app/farm_management/farmer/view/access_granted_screen.dart';
import 'package:seedsuser/app/farm_management/farmer/widget/set_pin_sheet.dart';

/// Live QR scanner with a gallery-upload fallback.
///
/// A scanned code is resolved server-side first (which validates expiry and
/// revocation), then the PIN sheet confirms the holder before access is granted.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );

  final _accessController = Get.put(FarmAccessController());
  final _picker = ImagePicker();

  /// Guards against the detector firing repeatedly while a code is in flight.
  bool _handling = false;

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  /// Resolves a scanned token, then asks for the PIN.
  Future<void> _handleToken(String token) async {
    if (_handling) return;
    setState(() => _handling = true);

    await _scanner.stop();

    final preview = await _accessController.redeemToken(token);

    if (!mounted) return;

    if (preview == null) {
      // Invalid, expired or revoked — the controller already explained why.
      // Resume scanning so the user can try another code.
      setState(() => _handling = false);
      await _scanner.start();
      return;
    }

    await showPinSheet(
      context,
      title: 'Verify Access with PIN',
      subtitle: "Enter the 4-digit PIN to confirm it's you and continue.",
      confirmLabel: 'Confirm PIN',
      onConfirm: (pin) async {
        final ok = await _accessController.verifyPin(
          token: preview.token,
          pin: pin,
        );

        if (!ok) return false;

        if (!mounted) return true;

        // Close the PIN sheet, then replace the scanner with the success page.
        Navigator.of(context).pop();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => AccessGrantedScreen(farmName: preview.farmName),
          ),
        );
        return true;
      },
    );

    if (!mounted) return;

    // The sheet was dismissed without completing — allow another scan.
    setState(() => _handling = false);
    await _scanner.start();
  }

  /// Reads a QR out of a saved screenshot, for codes shared over WhatsApp.
  Future<void> _uploadFromGallery() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;

      final result = await _scanner.analyzeImage(file.path);
      final barcode = result?.barcodes.firstOrNull;
      final token = barcode?.rawValue;

      if (token == null || token.isEmpty) {
        CustomToast.error('No QR code found in that image');
        return;
      }

      await _handleToken(token);
    } catch (e) {
      CustomToast.error('Could not read that image');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        title: Text(
          'Scanner',
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
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  controller: _scanner,
                  errorBuilder: (context, error) => _CameraUnavailable(
                    onUpload: _uploadFromGallery,
                  ),
                  onDetect: (capture) {
                    final raw = capture.barcodes.firstOrNull?.rawValue;
                    if (raw != null && raw.isNotEmpty) _handleToken(raw);
                  },
                ),
                // Viewfinder framing the scan area.
                IgnorePointer(
                  child: Container(
                    height: 240,
                    width: 240,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 3),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
                if (_handling)
                  Container(
                    color: Colors.black45,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: Column(
              children: [
                Text(
                  'Scan the QR and then\nenter your PIN to continue.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _uploadFromGallery,
                    icon: const Icon(Icons.upload_outlined),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    label: Text(
                      'Upload',
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when the camera cannot start (denied permission, simulator, etc.).
///
/// The simulator has no camera at all, so without this the scanner screen would
/// look broken during testing — upload still works there.
class _CameraUnavailable extends StatelessWidget {
  final VoidCallback onUpload;

  const _CameraUnavailable({required this.onUpload});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.no_photography_outlined,
              color: Colors.white70, size: 48),
          const SizedBox(height: 12),
          Text(
            'Camera is not available',
            style: GoogleFonts.roboto(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Allow camera access in Settings, or upload a saved QR image '
            'instead.',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onUpload,
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text('Upload QR image'),
          ),
        ],
      ),
    );
  }
}
