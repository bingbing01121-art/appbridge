package com.example.appbridge

import android.annotation.TargetApi
import android.app.Activity
import android.app.ActivityManager
import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ShortcutInfo
import android.content.pm.ShortcutManager
import android.graphics.drawable.Icon
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.StatFs
import android.provider.Settings
import android.util.Log
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.BufferedReader
import java.io.File
import java.io.FileReader

/** AppbridgePlugin */
class AppbridgePlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var activity: Activity? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.example.appbridge_h5/app")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "openAndroidSettings" -> {
                val section = call.argument<String>("section")
                openAndroidSettings(section, result)
            }
            "minimizeApp" -> {
                activity?.moveTaskToBack(true)
                result.success(true)
            }
            "setVpn" -> {
                val on = call.argument<Boolean>("on") ?: false
                val config = call.argument<Map<String, Any>>("config")
                handleSetVpn(on, config, result)
            }
            "addShortcuts" -> {
                val title = call.argument<String>("title")
                val url = call.argument<String>("url")
                if (title != null && url != null) {
                    addShortcut(title, url, result)
                } else {
                    result.error("INVALID_ARGUMENT", "Title and URL are required for addShortcuts", null)
                }
            }
            "setAppIcon" -> {
                val styleId = call.argument<String>("styleId")
                if (styleId != null) {
                    setAppIcon(styleId, result)
                } else {
                    result.error("INVALID_ARGUMENT", "Style ID is required for setAppIcon", null)
                }
            }

            "getMemoryInfo" -> getMemoryInfo(result)
            "getStorageInfo" -> getStorageInfo(result)
            "getCpuInfo" -> getCpuInfo(result)
            "installApk" -> {
                val path = call.argument<String>("path")
                installApk(path, result)
            }
            "openApp" -> {
                val packageName = call.argument<String>("packageName")
                openApp(packageName, result)
            }
            "isAppInstalled" -> {
                val packageName = call.argument<String>("packageName")
                isAppInstalled(packageName, result)
            }
            else -> result.notImplemented()
        }
    }

    private fun addShortcut(title: String, url: String, result: Result) {
        if (activity == null) {
            result.error("UNAVAILABLE", "Activity is not attached", null)
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val shortcutManager = context.getSystemService(ShortcutManager::class.java)
            if (shortcutManager.isRequestPinShortcutSupported) {
                val shortcutIntent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
                    // Ensure the intent is unique for each shortcut
                    action = Intent.ACTION_VIEW
                    addCategory(Intent.CATEGORY_BROWSABLE)
                    // Add flags to open in a new task if the app is not running
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                }

                val pinShortcutInfo = ShortcutInfo.Builder(context, title)
                    .setIcon(Icon.createWithResource(context, R.mipmap.icon_h5sdk)) // Use your app's icon
                    .setShortLabel(title)
                    .setIntent(shortcutIntent)
                    .build()

                val pinnedShortcutCallbackIntent = shortcutManager.createShortcutResultIntent(pinShortcutInfo)
                val successCallback = PendingIntent.getBroadcast(context, 0, pinnedShortcutCallbackIntent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)

                shortcutManager.requestPinShortcut(pinShortcutInfo, successCallback.intentSender) // Use intentSender
                result.success(true)
            } else {
                result.error("UNAVAILABLE", "Pinning shortcuts is not supported on this device", null)
            }
        } else {
            // Fallback for older Android versions (API < 26)
            // For older versions, we might need a different approach or just return an error
            result.error("UNAVAILABLE", "Adding shortcuts for API < 26 is not fully implemented yet.", null)
        }
    }

    private fun setAppIcon(styleId: String, result: Result) {
        if (activity == null) {
            result.error("UNAVAILABLE", "Activity is not attached", null)
            return
        }

        val packageManager = context.packageManager
        val packageName = context.packageName

        // Define all possible component names for the aliases
        val componentNames = listOf(
            ComponentName(packageName, "$packageName.MainActivity"), // Main activity
            ComponentName(packageName, "$packageName.DefaultLauncherAlias"),
            ComponentName(packageName, "$packageName.FestivalLauncherAlias")
            // Add other aliases here if you have more
        )

        var success = false
        for (componentName in componentNames) {
            val state = if (componentName.className.endsWith(styleId)) {
                // Enable the selected alias
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED
            } else {
                // Disable all other aliases and the main activity
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED
            }

            packageManager.setComponentEnabledSetting(
                componentName,
                state,
                PackageManager.DONT_KILL_APP
            )
            if (state == PackageManager.COMPONENT_ENABLED_STATE_ENABLED) {
                success = true
            }
        }

        if (success) {
            result.success(true)
        } else {
            result.error("INVALID_STYLE_ID", "No matching app icon style found for: $styleId", null)
        }
    }

    private fun openAndroidSettings(section: String?, result: Result) {
        val intent = when (section) {
            "wifi" -> Intent(Settings.ACTION_WIFI_SETTINGS)
            "location" -> Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS)
            "app_details" -> {
                val packageName = context.packageName
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.fromParts("package", packageName, null)
                }
            }
            else -> Intent(Settings.ACTION_SETTINGS)
        }
        if (activity?.packageManager?.let { intent.resolveActivity(it) } != null) {
            activity?.startActivity(intent)
            result.success(true)
        } else {
            result.error("UNAVAILABLE", "No activity found to handle intent", "No activity found to handle intent for section: $section")
        }
    }
    
    private fun handleSetVpn(on: Boolean, config: Map<String, Any>?, result: Result) {
        if (on) {
            val intent = Intent(Settings.ACTION_VPN_SETTINGS)
            if (activity?.packageManager?.let { intent.resolveActivity(it) } != null) {
                activity?.startActivity(intent)
                result.success(true)
            } else {
                result.error("UNAVAILABLE", "No activity found to handle VPN settings intent", null)
            }
        } else {
            val intent = Intent(Settings.ACTION_VPN_SETTINGS)
            if (activity?.packageManager?.let { intent.resolveActivity(it) } != null) {
                activity?.startActivity(intent)
                result.success(true)
            } else {
                result.error("UNAVAILABLE", "No activity found to handle VPN settings intent", null)
            }
        }
    }

    private fun getMemoryInfo(result: Result) {
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val memoryInfo = ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memoryInfo)
        val memoryMap = mapOf(
            "totalMemory" to memoryInfo.totalMem,
            "availableMemory" to memoryInfo.availMem,
            "usedMemory" to (memoryInfo.totalMem - memoryInfo.availMem)
        )
        result.success(memoryMap)
    }

    private fun getStorageInfo(result: Result) {
        val statFs = StatFs(Environment.getDataDirectory().path)
        val blockSize = statFs.blockSizeLong
        val totalBlocks = statFs.blockCountLong
        val availableBlocks = statFs.availableBlocksLong
        val storageMap = mapOf(
            "totalStorage" to (totalBlocks * blockSize),
            "availableStorage" to (availableBlocks * blockSize),
            "usedStorage" to ((totalBlocks - availableBlocks) * blockSize)
        )
        result.success(storageMap)
    }

    @TargetApi(Build.VERSION_CODES.DONUT)
    private fun getCpuInfo(result: Result) {
        val cpuInfoMap = mutableMapOf<String, Any>()
        try {
            cpuInfoMap["cores"] = Runtime.getRuntime().availableProcessors()
            val abiList = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                Build.SUPPORTED_ABIS.joinToString(", ")
            } else {
                @Suppress("DEPRECATION")
                Build.CPU_ABI + (if (Build.CPU_ABI2 != null) ", ${Build.CPU_ABI2}" else "")
            }
            cpuInfoMap["arch"] = abiList
            var maxFreq = "N/A"
            try {
                val reader = BufferedReader(FileReader("/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq"))
                maxFreq = "${reader.readLine().trim().toLong() / 1000} MHz"
                reader.close()
            } catch (e: Exception) {
                Log.e("CpuInfo", "Failed to read max CPU freq: ${e.message}")
            }
            cpuInfoMap["frequency"] = maxFreq
        } catch (e: Exception) {
            result.error("CPU_INFO_ERROR", "Failed to get CPU info: ${e.message}", null)
            return
        }
        result.success(cpuInfoMap)
    }
    
    private fun installApk(path: String?, result: Result) {
        if (path == null) {
            result.error("INVALID_ARGUMENT", "Path cannot be null", null)
            return
        }
        val apkFile = File(path)
        if (!apkFile.exists()) {
            result.error("FILE_NOT_FOUND", "APK file not found at $path", null)
            return
        }
        try {
            val uri: Uri = FileProvider.getUriForFile(context, context.packageName + ".fileprovider", apkFile)
            val installIntent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/vnd.android.package-archive")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION
            }
            activity?.startActivity(installIntent)
            result.success(true)
        } catch (e: Exception) {
            result.error("INSTALL_ERROR", "Failed to install APK: ${e.message}", null)
        }
    }

    private fun openApp(packageName: String?, result: Result) {
        if (packageName == null) {
            result.error("INVALID_ARGUMENT", "Package name is required", null)
            return
        }
        try {
            val launchIntent = context.packageManager.getLaunchIntentForPackage(packageName)
            if (launchIntent != null) {
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                activity?.startActivity(launchIntent)
                result.success(true)
            } else {
                result.error("APP_NOT_FOUND", "App with package name $packageName not found", null)
            }
        } catch (e: Exception) {
            result.error("OPEN_APP_ERROR", "Failed to open app: ${e.message}", null)
        }
    }

    private fun isAppInstalled(packageName: String?, result: Result) {
        if (packageName == null) {
            result.error("INVALID_ARGUMENT", "Package name is required", null)
            return
        }
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                context.packageManager.getPackageInfo(packageName, PackageManager.PackageInfoFlags.of(PackageManager.GET_ACTIVITIES.toLong()))
            } else {
                @Suppress("DEPRECATION")
                context.packageManager.getPackageInfo(packageName, PackageManager.GET_ACTIVITIES)
            }
            result.success(true)
        } catch (e: PackageManager.NameNotFoundException) {
            result.success(false)
        } catch (e: Exception) {
            result.error("CHECK_INSTALL_ERROR", "Failed to check app installation: ${e.message}", null)
        }
    }
}