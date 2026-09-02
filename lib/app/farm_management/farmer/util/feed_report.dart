import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:seedsuser/app/common/custom_toast.dart';

/// Downloading and sharing a tank's feed report.
///
/// Lives apart from any one screen because both the farm detail page and the
/// tank history page offer these, and a screen importing another screen just
/// to reach two functions is a dependency neither of them wants.

/// Turn a tank name into something safe to use as a filename.
///
/// The name reaches WhatsApp as the document's title, so "Tank 2" should
/// arrive as `Tank_2_feed_report.pdf`, not `feed_report.pdf` — and certainly
/// not with a slash in it.
String _reportFileName(String? tankName) {
  final safe = (tankName ?? 'tank')
      .trim()
      .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');

  return '${safe.isEmpty ? 'tank' : safe}_feed_report.pdf';
}

Future<String?> downloadReport(String url, {String? tankName}) async {
  try {
    // FIX URL ISSUE
    if (url.startsWith("https:/") && !url.startsWith("https://")) {
      url = url.replaceFirst("https:/", "https://");
    }

    // Save into the app-owned external storage (Android: /Android/data/<pkg>/files)
    // or the app documents directory (iOS). Neither location requires a
    // runtime permission or MANAGE_EXTERNAL_STORAGE — Play Store rejected
    // the previous /storage/emulated/0/Download path because it needed
    // broad "All files access", which we're not entitled to use.
    Directory? directory;
    if (Platform.isAndroid) {
      directory = await getExternalStorageDirectory();
    } else {
      directory = await getApplicationDocumentsDirectory();
    }
    if (directory == null) {
      CustomToast.error('Feed Report Document Failed To Download');
      return null;
    }

    final filePath = "${directory.path}/${_reportFileName(tankName)}";
    await Dio().download(url, filePath);

    final file = File(filePath);
    if (!file.existsSync()) {
      CustomToast.error('Feed Report Document Failed To Download');
      return null;
    }

    CustomToast.success('Feed Report Document Downloaded Successfully');
    return filePath;
  } catch (e) {
    // Say so. A silent null here left the farmer tapping Download on a dialog
    // that never acknowledged the tap — no file, no message, nothing.
    CustomToast.error('Feed Report Document Failed To Download');
    return null;
  }
}

/// Send the report itself to WhatsApp, Gmail, Drive — whatever the phone offers.
///
/// The PDF is fetched to the app's cache first and shared as a file rather than
/// as a link. A link is no use to whoever receives it: on a development build
/// it points at a LAN address they cannot reach, and even in production it
/// makes them download something before they can read it. A file just opens.
Future<void> shareReport(
  String url, {
  String? tankName,
  Rect? sharePositionOrigin,
}) async {
  if (url.isEmpty) {
    CustomToast.error('No report to share');
    return;
  }

  if (url.startsWith("https:/") && !url.startsWith("https://")) {
    url = url.replaceFirst("https:/", "https://");
  }

  try {
    // The cache, not documents: this copy exists to be handed to another app,
    // and the system is free to reclaim it afterwards.
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/${_reportFileName(tankName)}';

    await Dio().download(url, filePath);

    final file = File(filePath);
    if (!file.existsSync() || await file.length() == 0) {
      CustomToast.error('Could not prepare the report to share');
      return;
    }

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath, mimeType: 'application/pdf')],
        subject: '${tankName ?? 'Tank'} feed report',
        text: 'Feed report for ${tankName ?? 'this tank'}.',
        // Required on iPad, where the share sheet is a popover needing an anchor.
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  } catch (e) {
    CustomToast.error('Could not share the report');
  }
}
