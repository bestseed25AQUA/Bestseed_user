package com.app.bestseed

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val storeChannel = "bestseed/store"
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
