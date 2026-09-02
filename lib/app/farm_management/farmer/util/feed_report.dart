import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
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

/// The native side of saving into the phone's own Downloads folder.
const MethodChannel _downloads = MethodChannel('bestseed/downloads');

/// Hand a downloaded file to Android's Downloads folder.
///
/// Returns where it landed, or null if it could not be put there.
///
/// Android 10 and up goes through MediaStore and needs no permission. Android 9
/// and below has no such collection, so the native side writes the public path
/// and reports back that it needs WRITE_EXTERNAL_STORAGE first — asked for here
/// and then retried once, rather than being requested up front on phones that
/// will never need it.
Future<String?> _saveIntoDownloads(String sourcePath, String fileName) async {
  Future<String?> attempt() => _downloads.invokeMethod<String>(
    'saveToDownloads',
    {
      'sourcePath': sourcePath,
      'fileName': fileName,
      'mimeType': 'application/pdf',
    },
  );

  try {
    return await attempt();
  } on PlatformException catch (e) {
    if (e.code != 'permission_required') {
      // Logged, because "Could not save the report" on its own is not
      // something anyone can act on — the native side already knows exactly
      // what went wrong and this is the only place it can say so.
      debugPrint('Report save failed [${e.code}]: ${e.message}');
      return null;
    }

    // Android 9 and below only.
    if (!await Permission.storage.request().isGranted) {
      debugPrint('Report save failed: storage permission refused');
      return null;
    }

    try {
      return await attempt();
    } on PlatformException catch (e) {
      debugPrint('Report save failed after permission [${e.code}]: ${e.message}');
      return null;
    }
  } on MissingPluginException {
    // The running app was built before this channel existed. A hot reload
    // brings the Dart across but not the Kotlin, so the app has to be stopped
    // and run again — no amount of retrying will find the handler.
    debugPrint(
      'Report save failed: the bestseed/downloads channel is missing. '
      'Native code changed — stop the app and run it again rather than hot '
      'reloading.',
    );
    return null;
  }
}

/// Ask Android to download the report itself.
///
/// True when the system has taken the job on — from that point the download
/// lives in the notification shade and in the Downloads app, and finishes
/// whether or not this screen is still open.
///
/// False when the download service is unavailable: it can be disabled on some
/// ROMs, and the channel is missing entirely on an app built before it existed.
/// The caller then fetches and files the report itself, which still works, just
/// without a notification.
Future<bool> _enqueueSystemDownload(
  String url,
  String fileName, {
  required String title,
}) async {
  try {
    await _downloads.invokeMethod<int>('enqueueDownload', {
      'url': url,
      'fileName': fileName,
      'title': title,
      'mimeType': 'application/pdf',
    });
    return true;
  } on PlatformException catch (e) {
    debugPrint('System download refused [${e.code}]: ${e.message}');
    return false;
  } on MissingPluginException {
    debugPrint('System download unavailable: channel missing (rebuild needed)');
    return false;
  }
}

/// Save a tank's feed report where the farmer can actually find it.
///
/// On Android that means the phone's Downloads folder, reachable from Files and
/// from any file manager. The report used to be written to
/// `Android/data/<pkg>/files` — private storage that no file browser lists and
/// that is deleted with the app — under a toast reading "Downloaded
/// Successfully". The file was genuinely there; it just did not exist as far as
/// anyone using the phone was concerned.
///
/// On iOS it stays in the app's Documents directory, which the Files app shows
/// under On My iPhone › Bestseed thanks to the UIFileSharingEnabled and
/// LSSupportsOpeningDocumentsInPlace keys in Info.plist.
Future<String?> downloadReport(String url, {String? tankName}) async {
  try {
    // FIX URL ISSUE
    if (url.startsWith("https:/") && !url.startsWith("https://")) {
      url = url.replaceFirst("https:/", "https://");
    }

    final fileName = _reportFileName(tankName);

    // Android's own download service first, so this behaves like every other
    // download on the phone: a progress notification while it runs, a "download
    // complete" notification that opens the PDF when tapped, and an entry in
    // the Downloads app. Fetching the file ourselves produced a perfectly good
    // report and no sign anywhere that anything had been downloaded.
    if (Platform.isAndroid) {
      final queued = await _enqueueSystemDownload(
        url,
        fileName,
        title: '${tankName ?? 'Tank'} feed report',
      );

      if (queued) {
        // Deliberately not "saved": the system is doing it now, and its own
        // notification reports the outcome. Claiming success here would be a
        // guess about a transfer that has not finished.
        CustomToast.success('Downloading feed report…');
        return url;
      }
      // Fell through: the service is off or unavailable on this ROM. The
      // report is fetched and filed below instead, without a notification.
    }

    // Fetched to private storage first either way. On Android that copy is
    // then handed to Downloads and deleted; the download itself never needs a
    // permission, so a refused one cannot lose the file mid-transfer.
    final staging = Platform.isAndroid
        ? await getTemporaryDirectory()
        : await getApplicationDocumentsDirectory();

    final stagedPath = "${staging.path}/$fileName";
    await Dio().download(url, stagedPath);

    final staged = File(stagedPath);
    if (!staged.existsSync() || await staged.length() == 0) {
      CustomToast.error('Feed Report Document Failed To Download');
      return null;
    }

    if (!Platform.isAndroid) {
      CustomToast.success('Feed report saved to Files');
      return stagedPath;
    }

    final saved = await _saveIntoDownloads(stagedPath, fileName);

    if (saved == null) {
      // The report downloaded but could not be filed. Do NOT claim it was
      // saved — that is the whole complaint this method exists to answer.
      CustomToast.error('Could not save the report to Downloads');
      return null;
    }

    // The staged copy has served its purpose.
    try {
      await staged.delete();
    } catch (_) {
      // Left behind in the cache at worst; the system reclaims it.
    }

    CustomToast.success('Feed report saved to Downloads');
    return saved;
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
