package com.example.appbridge_example

import android.content.Intent
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log

class MainActivity : FlutterActivity() {
    private val APP_CHANNEL = "com.example.appbridge_example/platform"
    private lateinit var appMethodChannel: MethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        appMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_CHANNEL)
        appMethodChannel.setMethodCallHandler {
            call, result ->
            if (call.method == "setAppIcon") {
                val styleId = call.argument<String>("styleId")
                if (styleId != null) {
                    setAppIcon(styleId, result)
                } else {
                    result.error("INVALID_ARGUMENT", "styleId cannot be null", null)
                }
            } else if (call.method == "addShortcuts") {
                val title = call.argument<String>("title")
                val url = call.argument<String>("url")
                if (title != null && url != null) {
                    println("AAAAAAaddShortcuts==title==$title;url=$url");
                    addShortcuts(title, url, result)
                } else {
                    result.error("INVALID_ARGUMENT", "title or url cannot be null", null)
                }
            } else {
                result.notImplemented()
            }
        }
        handleIntentUrl(intent) // Handle initial intent when engine is configured
    }

    private fun addShortcuts(title: String, url: String, result: MethodChannel.Result) {
        val shortcutIntent = Intent(applicationContext, MainActivity::class.java).apply {
            action = Intent.ACTION_MAIN // Or a custom action if needed
            addCategory(Intent.CATEGORY_LAUNCHER)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
            putExtra("shortcut_url", url)
        }

        val shortcut = ShortcutInfoCompat.Builder(applicationContext, title)
            .setShortLabel(title)
            .setLongLabel(title)
            .setIcon(androidx.core.graphics.drawable.IconCompat.createWithResource(applicationContext, R.mipmap.icon_h5sdk_new)) // Use your app's icon
            .setIntent(shortcutIntent)
            .build()

        ShortcutManagerCompat.requestPinShortcut(applicationContext, shortcut, null)
        result.success(true)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntentUrl(intent)
    }

    private fun handleIntentUrl(intent: Intent?) {
        val shortcutUrl = intent?.getStringExtra("shortcut_url")
        if (shortcutUrl != null) {
            Log.d("MainActivity", "Received shortcut URL: $shortcutUrl")
            // Send the URL to the Dart side
            appMethodChannel.invokeMethod("loadShortcutUrl", mapOf("url" to shortcutUrl))
        }
    }

    private fun setAppIcon(styleId: String, result: MethodChannel.Result) {
        val packageManager = applicationContext.packageManager
        val packageName = applicationContext.packageName

        val componentNameDefaultAlias = ComponentName(packageName, "com.example.appbridge_example.DefaultLauncherAlias")
        val componentNameFestivalAlias = ComponentName(packageName, "com.example.appbridge_example.FestivalLauncherAlias")
        val componentNameMainActivity = ComponentName(packageName, "com.example.appbridge_example.MainActivity")

        // Disable all components first
        packageManager.setComponentEnabledSetting(componentNameMainActivity, PackageManager.COMPONENT_ENABLED_STATE_DISABLED, PackageManager.DONT_KILL_APP)
        packageManager.setComponentEnabledSetting(componentNameDefaultAlias, PackageManager.COMPONENT_ENABLED_STATE_DISABLED, PackageManager.DONT_KILL_APP)
        packageManager.setComponentEnabledSetting(componentNameFestivalAlias, PackageManager.COMPONENT_ENABLED_STATE_DISABLED, PackageManager.DONT_KILL_APP)

        when (styleId) {
            "default" -> {
                packageManager.setComponentEnabledSetting(componentNameDefaultAlias, PackageManager.COMPONENT_ENABLED_STATE_ENABLED, PackageManager.DONT_KILL_APP)
                result.success(true)
            }
            "festival" -> {
                packageManager.setComponentEnabledSetting(componentNameFestivalAlias, PackageManager.COMPONENT_ENABLED_STATE_ENABLED, PackageManager.DONT_KILL_APP)
                result.success(true)
            }
            else -> {
                // If an unknown styleId is provided, re-enable the main activity
                packageManager.setComponentEnabledSetting(componentNameDefaultAlias, PackageManager.COMPONENT_ENABLED_STATE_ENABLED, PackageManager.DONT_KILL_APP)
                result.error("INVALID_STYLE_ID", "Unknown styleId: $styleId", null)
            }
        }
    }
}
