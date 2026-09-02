package com.app.bestseed

import android.Manifest
import android.app.DownloadManager
import android.content.ActivityNotFoundException
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException

class MainActivity : FlutterActivity() {

    private val storeChannel = "bestseed/store"
    private val downloadsChannel = "bestseed/downloads"
    private val playStorePackage = "com.android.vending"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, storeChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openPlayStore" -> {
                        val appId = call.argument<String>("packageName") ?: packageName
                        result.success(openPlayStore(appId))
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, downloadsChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveToDownloads" -> {
                        val sourcePath = call.argument<String>("sourcePath")
                        val fileName = call.argument<String>("fileName")
                        val mimeType = call.argument<String>("mimeType")
                            ?: "application/octet-stream"

                        if (sourcePath.isNullOrEmpty() || fileName.isNullOrEmpty()) {
                            result.error(
                                "bad_arguments",
                                "sourcePath and fileName are required",
                                null
                            )
                            return@setMethodCallHandler
                        }

                        try {
                            result.success(
                                saveToDownloads(File(sourcePath), fileName, mimeType)
                            )
                        } catch (e: SecurityException) {
                            // Android 9 and below only. Dart asks for the
                            // permission and calls again.
                            result.error("permission_required", e.message, null)
                        } catch (e: Exception) {
                            result.error("save_failed", e.message, null)
                        }
                    }
                    "enqueueDownload" -> {
                        val url = call.argument<String>("url")
                        val fileName = call.argument<String>("fileName")
                        val title = call.argument<String>("title") ?: fileName
                        val mimeType = call.argument<String>("mimeType")
                            ?: "application/octet-stream"

                        if (url.isNullOrEmpty() || fileName.isNullOrEmpty()) {
                            result.error(
                                "bad_arguments",
                                "url and fileName are required",
                                null
                            )
                            return@setMethodCallHandler
                        }

                        try {
                            result.success(
                                enqueueDownload(url, fileName, title ?: fileName, mimeType)
                            )
                        } catch (e: Exception) {
                            // Dart falls back to fetching the file itself.
                            result.error("enqueue_failed", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Hands a URL to Android's own download service.
     *
     * This is what puts the download in the notification shade: the progress
     * bar while it runs, the "download complete" notification that opens the
     * file when tapped, and the entry in the phone's Downloads app. Fetching
     * the file inside the app — which is what we did — produces a perfectly
     * good PDF and no sign anywhere that anything was downloaded, so it did not
     * feel like a download at all.
     *
     * DownloadManager writes into the public Downloads folder itself and needs
     * no storage permission to do it, on any version. It also uniquifies the
     * name, so a second report becomes `Tank1_feed_report-1.pdf` rather than
     * replacing the first.
     *
     * Throws if the service is missing or disabled — some ROMs let it be turned
     * off — and Dart then falls back to fetching and filing the report itself.
     */
    private fun enqueueDownload(
        url: String,
        fileName: String,
        title: String,
        mimeType: String
    ): Long {
        val manager = getSystemService(DOWNLOAD_SERVICE) as? DownloadManager
            ?: throw IOException("The download service is unavailable")

        val request = DownloadManager.Request(Uri.parse(url))
            .setTitle(title)
            .setDescription("Bestseed")
            .setMimeType(mimeType)
            .setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, fileName)
            // Progress while it runs AND a notification when it finishes. The
            // default only notifies on completion.
            .setNotificationVisibility(
                DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED
            )
            .setAllowedOverMetered(true)
            .setAllowedOverRoaming(true)

        return manager.enqueue(request)
    }

    /**
     * Copies a file the app has downloaded into the phone's Downloads folder.
     *
     * The app writes its own copy to `Android/data/<pkg>/files` first, which is
     * private storage: invisible in Files, invisible to a file manager, and
     * deleted with the app. A farmer who tapped Download was told the report had
     * been saved and then could not find it anywhere, because as far as they
     * were concerned it had not been.
     *
     * On Android 10+ this goes through MediaStore, which needs NO permission and
     * no "All files access" — the entitlement Play rejected an earlier build for
     * requesting. On Android 9 and below there is no MediaStore Downloads
     * collection, so it writes the public path under WRITE_EXTERNAL_STORAGE,
     * declared with maxSdkVersion="28" so it is not requested on newer phones.
     *
     * Returns something the app can show the farmer: a content URI on modern
     * Android, an absolute path on old.
     */
    private fun saveToDownloads(source: File, fileName: String, mimeType: String): String {
        if (!source.exists() || source.length() == 0L) {
            throw IOException("Nothing to save")
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = contentResolver

            val pending = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                put(MediaStore.Downloads.MIME_TYPE, mimeType)
                put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                // Hidden from other apps until the bytes are all there, so a
                // file manager cannot open a half-written PDF.
                put(MediaStore.Downloads.IS_PENDING, 1)
            }

            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, pending)
                ?: throw IOException("Downloads folder refused the file")

            try {
                resolver.openOutputStream(uri).use { out ->
                    if (out == null) throw IOException("Could not open the destination")
                    source.inputStream().use { it.copyTo(out) }
                }
            } catch (e: Exception) {
                // Leave no half-written entry behind for the farmer to find.
                resolver.delete(uri, null, null)
                throw e
            }

            resolver.update(
                uri,
                ContentValues().apply { put(MediaStore.Downloads.IS_PENDING, 0) },
                null,
                null
            )

            return uri.toString()
        }

        if (ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.WRITE_EXTERNAL_STORAGE
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            throw SecurityException("Storage permission not granted")
        }

        val dir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        if (!dir.exists() && !dir.mkdirs()) {
            throw IOException("Could not open the Downloads folder")
        }

        val target = uniqueFileIn(dir, fileName)
        source.copyTo(target, overwrite = false)

        // Without this the file exists but nothing lists it until the next
        // media scan — which to the farmer is the same as not being saved.
        MediaScannerConnection.scanFile(
            this,
            arrayOf(target.absolutePath),
            arrayOf(mimeType),
            null
        )

        return target.absolutePath
    }

    /**
     * `report.pdf`, then `report (1).pdf`, and so on.
     *
     * Downloading a second report for the same tank must not silently replace
     * the first. MediaStore does this itself on Android 10+; this is the same
     * courtesy on older phones.
     */
    private fun uniqueFileIn(dir: File, fileName: String): File {
        val candidate = File(dir, fileName)
        if (!candidate.exists()) return candidate

        val dot = fileName.lastIndexOf('.')
        val stem = if (dot > 0) fileName.substring(0, dot) else fileName
        val extension = if (dot > 0) fileName.substring(dot) else ""

        var index = 1
        while (index < 1000) {
            val next = File(dir, "$stem ($index)$extension")
            if (!next.exists()) return next
            index++
        }

        throw IOException("Too many copies of $fileName already saved")
    }

    /**
     * Opens the Play Store listing directly, with no app-chooser dialog.
     *
     * A plain ACTION_VIEW on `market://` (what url_launcher sends) is an
     * implicit intent, so on devices that ship a second app store the system
     * shows a "which store?" picker. Setting the package pins the intent to
     * Play Store, which resolves straight to the listing.
     *
     * Returns false if Play Store is missing or disabled, so the Dart side can
     * fall back to the browser.
     */
    private fun openPlayStore(appId: String): Boolean {
        val intents = listOf(
            // Preferred: the store app's own scheme.
            Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=$appId"))
                .setPackage(playStorePackage),
            // Same listing over https, still pinned to Play Store — covers
            // builds where the market:// activity isn't exported.
            Intent(
                Intent.ACTION_VIEW,
                Uri.parse("https://play.google.com/store/apps/details?id=$appId")
            ).setPackage(playStorePackage)
        )

        for (intent in intents) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            try {
                startActivity(intent)
                return true
            } catch (e: ActivityNotFoundException) {
                // Try the next form; Dart falls back to the browser if none work.
            }
        }
        return false
    }
}
