package com.mitech.curre

import android.app.AppOpsManager
import android.app.NotificationManager
import android.app.SearchManager
import android.app.role.RoleManager
import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Intent
import android.content.pm.LauncherApps
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.content.pm.ShortcutInfo
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Build
import android.os.Process
import android.provider.Settings
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private lateinit var launcherApps: LauncherApps
    private lateinit var platformChannel: MethodChannel
    private var homeSurfaceActive = false
    private var pendingHomeRoleResult: MethodChannel.Result? = null
    private var pendingUsageAccessResult: MethodChannel.Result? = null
    private var pendingNotificationAccessResult: MethodChannel.Result? = null
    private val homeRoleLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult(),
    ) {
        val result = pendingHomeRoleResult ?: return@registerForActivityResult
        pendingHomeRoleResult = null
        result.success(isDefaultHome())
    }
    private val usageAccessLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult(),
    ) {
        val result = pendingUsageAccessResult ?: return@registerForActivityResult
        pendingUsageAccessResult = null
        result.success(hasUsageAccess())
    }
    private val notificationAccessLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult(),
    ) {
        val result = pendingNotificationAccessResult
            ?: return@registerForActivityResult
        pendingNotificationAccessResult = null
        result.success(hasNotificationAccess())
    }
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        launcherApps = getSystemService(LauncherApps::class.java)
        platformChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME,
        )
        platformChannel.setMethodCallHandler(::handleMethodCall)
        interceptEvent(intent)?.let {
            platformChannel.invokeMethod("hiddenAppOpened", it)
        }
    }

    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "listApps" -> result.success(listApps())
                "getIcon" -> result.success(getIcon(call.arguments as String))
                "launch" -> result.success(launchPackage(call.arguments as String))
                "requestHomeRole" -> requestHomeRole(result)
                "isDefaultHome" -> result.success(isDefaultHome())
                "hasUsageAccess" -> result.success(hasUsageAccess())
                "requestUsageAccess" -> requestUsageAccess(result)
                "hasNotificationAccess" -> result.success(hasNotificationAccess())
                "requestNotificationAccess" -> requestNotificationAccess(result)
                "configureGentleIntercept" -> {
                    configureGentleIntercept(call.arguments)
                    result.success(null)
                }
                "takePendingIntercept" ->
                    result.success(GentleInterceptService.takePendingIntercept(this))
                "configureQuietNotifications" -> {
                    configureQuietNotifications(call.arguments)
                    result.success(null)
                }
                "listMissedNotifications" -> result.success(
                    QuietNotificationListenerService.listMissedNotifications(this),
                )
                "clearMissedNotifications" -> {
                    QuietNotificationListenerService.clearMissedNotifications(this)
                    result.success(null)
                }
                "openHomeSettings" -> result.success(openHomeSettings())
                "setHomeSurfaceActive" -> {
                    homeSurfaceActive = call.arguments as Boolean
                    result.success(null)
                }
                "hasShortcutHostPermission" ->
                    result.success(launcherApps.hasShortcutHostPermission())
                "getStaticShortcuts" -> result.success(
                    getShortcuts(
                        call.arguments as String,
                        LauncherApps.ShortcutQuery.FLAG_MATCH_MANIFEST,
                        conversationsOnly = false,
                    ),
                )
                "getConversationShortcuts" -> result.success(
                    getShortcuts(
                        call.arguments as String,
                        conversationShortcutFlags(),
                        conversationsOnly = true,
                    ),
                )
                "startShortcut" -> {
                    val arguments = call.arguments as Map<*, *>
                    result.success(
                        startShortcut(
                            arguments["package"] as String,
                            arguments["id"] as String,
                        ),
                    )
                }
                "launchQueryLink" -> {
                    val arguments = call.arguments as Map<*, *>
                    result.success(
                        launchQueryLink(
                            arguments["door"] as String,
                            arguments["query"] as String,
                        ),
                    )
                }
                else -> result.notImplemented()
            }
        } catch (error: SecurityException) {
            result.error("permission_denied", error.message, null)
        } catch (error: Exception) {
            result.error("launcher_error", error.message, null)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (::platformChannel.isInitialized) {
            interceptEvent(intent)?.let {
                platformChannel.invokeMethod("hiddenAppOpened", it)
            }
        }
    }

    private fun interceptEvent(intent: Intent?): Map<String, Any>? {
        val packageName = intent?.getStringExtra(
            GentleInterceptService.EXTRA_INTERCEPT_PACKAGE,
        ) ?: return null
        val atMillis = intent.getLongExtra(
            GentleInterceptService.EXTRA_INTERCEPT_AT_MILLIS,
            System.currentTimeMillis(),
        )
        intent.removeExtra(GentleInterceptService.EXTRA_INTERCEPT_PACKAGE)
        intent.removeExtra(GentleInterceptService.EXTRA_INTERCEPT_AT_MILLIS)
        return mapOf("package" to packageName, "atMillis" to atMillis)
    }

    private fun hasUsageAccess(): Boolean {
        val appOps = getSystemService(AppOpsManager::class.java)
        val mode = appOps.unsafeCheckOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            packageName,
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun requestUsageAccess(result: MethodChannel.Result) {
        if (pendingUsageAccessResult != null) {
            result.error(
                "usage_access_in_progress",
                "The Usage access settings are already open.",
                null,
            )
            return
        }
        if (hasUsageAccess()) {
            result.success(true)
            return
        }
        pendingUsageAccessResult = result
        val appSettings = Intent(
            Settings.ACTION_USAGE_ACCESS_SETTINGS,
            Uri.parse("package:$packageName"),
        )
        try {
            usageAccessLauncher.launch(appSettings)
        } catch (_: Exception) {
            try {
                usageAccessLauncher.launch(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
            } catch (error: Exception) {
                pendingUsageAccessResult = null
                throw error
            }
        }
    }

    private fun configureGentleIntercept(arguments: Any?) {
        val map = arguments as? Map<*, *>
            ?: throw IllegalArgumentException("Gentle intercept configuration is missing")
        val monitoredPackages = (map["monitoredPackages"] as? List<*>)
            .orEmpty()
            .filterIsInstance<String>()
            .toSet()
        val alwaysAllowedPackages = (map["alwaysAllowedPackages"] as? List<*>)
            .orEmpty()
            .filterIsInstance<String>()
            .toSet()
        val allowedUntilMillis = (map["allowedUntilMillis"] as? Map<*, *>)
            .orEmpty()
            .mapNotNull { (key, value) ->
                val packageName = key as? String ?: return@mapNotNull null
                val millis = (value as? Number)?.toLong() ?: return@mapNotNull null
                packageName to millis
            }
            .toMap()
        GentleInterceptService.configure(
            context = this,
            enabled = map["enabled"] as? Boolean ?: false,
            hasUsageAccess = hasUsageAccess(),
            monitoredPackages = monitoredPackages,
            alwaysAllowedPackages = alwaysAllowedPackages,
            allowedUntilMillis = allowedUntilMillis,
        )
    }

    private fun hasNotificationAccess(): Boolean {
        val component = ComponentName(
            this,
            QuietNotificationListenerService::class.java,
        )
        return getSystemService(NotificationManager::class.java)
            .isNotificationListenerAccessGranted(component)
    }

    private fun requestNotificationAccess(result: MethodChannel.Result) {
        if (pendingNotificationAccessResult != null) {
            result.error(
                "notification_access_in_progress",
                "The notification access settings are already open.",
                null,
            )
            return
        }
        if (hasNotificationAccess()) {
            result.success(true)
            return
        }
        pendingNotificationAccessResult = result
        val component = ComponentName(
            this,
            QuietNotificationListenerService::class.java,
        )
        val listenerSettings = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Intent(Settings.ACTION_NOTIFICATION_LISTENER_DETAIL_SETTINGS)
                .putExtra(
                    Settings.EXTRA_NOTIFICATION_LISTENER_COMPONENT_NAME,
                    component.flattenToString(),
                )
        } else {
            Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        }
        try {
            notificationAccessLauncher.launch(listenerSettings)
        } catch (_: Exception) {
            try {
                notificationAccessLauncher.launch(
                    Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS),
                )
            } catch (error: Exception) {
                pendingNotificationAccessResult = null
                throw error
            }
        }
    }

    private fun configureQuietNotifications(arguments: Any?) {
        val map = arguments as? Map<*, *>
            ?: throw IllegalArgumentException("Quiet notification configuration is missing")
        val monitoredPackages = (map["monitoredPackages"] as? List<*>)
            .orEmpty()
            .filterIsInstance<String>()
            .toSet()
        val alwaysAllowedPackages = (map["alwaysAllowedPackages"] as? List<*>)
            .orEmpty()
            .filterIsInstance<String>()
            .toSet()
        val allowedUntilMillis = (map["allowedUntilMillis"] as? Map<*, *>)
            .orEmpty()
            .mapNotNull { (key, value) ->
                val packageName = key as? String ?: return@mapNotNull null
                val millis = (value as? Number)?.toLong() ?: return@mapNotNull null
                packageName to millis
            }
            .toMap()
        QuietNotificationListenerService.configure(
            context = this,
            enabled = map["enabled"] as? Boolean ?: false,
            hasNotificationAccess = hasNotificationAccess(),
            monitoredPackages = monitoredPackages,
            alwaysAllowedPackages = alwaysAllowedPackages,
            allowedUntilMillis = allowedUntilMillis,
        )
    }

    private fun listApps(): List<Map<String, String>> {
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        return queryIntentActivities(intent)
            .distinctBy { it.activityInfo.packageName }
            .map {
                mapOf(
                    "package" to it.activityInfo.packageName,
                    "label" to it.loadLabel(packageManager).toString(),
                )
            }
            .sortedBy { it["label"]?.lowercase() }
    }

    @Suppress("DEPRECATION")
    private fun queryIntentActivities(intent: Intent): List<ResolveInfo> =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.queryIntentActivities(
                intent,
                PackageManager.ResolveInfoFlags.of(0),
            )
        } else {
            packageManager.queryIntentActivities(intent, 0)
        }

    private fun getIcon(packageName: String): ByteArray {
        val drawable = packageManager.getApplicationIcon(packageName)
        return drawableToPng(drawable)
    }

    private fun drawableToPng(drawable: Drawable): ByteArray {
        val size = 144
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, size, size)
        drawable.draw(canvas)
        return ByteArrayOutputStream().use { output ->
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, output)
            output.toByteArray()
        }
    }

    private fun launchPackage(packageName: String): Boolean {
        val intent = packageManager.getLaunchIntentForPackage(packageName) ?: return false
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
        return true
    }

    private fun requestHomeRole(result: MethodChannel.Result) {
        if (pendingHomeRoleResult != null) {
            result.error("home_role_in_progress", "The Home picker is already open.", null)
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val roleManager = getSystemService(RoleManager::class.java)
            if (roleManager.isRoleAvailable(RoleManager.ROLE_HOME)) {
                if (roleManager.isRoleHeld(RoleManager.ROLE_HOME)) {
                    result.success(true)
                    return
                }
                pendingHomeRoleResult = result
                try {
                    homeRoleLauncher.launch(
                        roleManager.createRequestRoleIntent(RoleManager.ROLE_HOME),
                    )
                } catch (error: Exception) {
                    pendingHomeRoleResult = null
                    throw error
                }
                return
            }
        }
        pendingHomeRoleResult = result
        try {
            homeRoleLauncher.launch(Intent(Settings.ACTION_HOME_SETTINGS))
        } catch (error: Exception) {
            pendingHomeRoleResult = null
            throw error
        }
    }

    /**
     * Opens the screen where the user picks their home screen app, so they
     * can leave Curre for another launcher (or come back). Phones that hide
     * that screen get the default-apps list, then the main Settings screen.
     * Returns which one opened, so Flutter can explain the remaining steps.
     */
    private fun openHomeSettings(): String {
        val screens = listOf(
            HOME_SETTINGS_OPENED to Settings.ACTION_HOME_SETTINGS,
            DEFAULT_APPS_OPENED to Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS,
            SETTINGS_OPENED to Settings.ACTION_SETTINGS,
        )
        for ((opened, action) in screens) {
            try {
                startActivity(Intent(action).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                return opened
            } catch (error: ActivityNotFoundException) {
                // This phone has no such screen; try the next one.
            } catch (error: SecurityException) {
                // Some builds protect a settings screen; try the next one.
            }
        }
        return NOTHING_OPENED
    }

    private fun isDefaultHome(): Boolean {
        val roleManager = getSystemService(RoleManager::class.java)
        return roleManager.isRoleAvailable(RoleManager.ROLE_HOME) &&
            roleManager.isRoleHeld(RoleManager.ROLE_HOME)
    }

    @Suppress("DEPRECATION")
    override fun onBackPressed() {
        if (!homeSurfaceActive) super.onBackPressed()
    }

    private fun getShortcuts(
        packageName: String,
        flags: Int,
        conversationsOnly: Boolean,
    ): List<Map<String, Any?>> {
        if (!launcherApps.hasShortcutHostPermission()) {
            throw SecurityException("Curre must be the default Home to read shortcuts")
        }
        val query = LauncherApps.ShortcutQuery()
            .setPackage(packageName)
            .setQueryFlags(flags)
        val shortcuts = launcherApps.getShortcuts(query, Process.myUserHandle()).orEmpty()
        // ShortcutInfo does not expose Person metadata through the public SDK.
        // These labels stay local and Dart matches the requested person on-device.
        return shortcuts
            .map { shortcutMap(it, conversationsOnly) }
    }

    private fun conversationShortcutFlags(): Int {
        var flags = LauncherApps.ShortcutQuery.FLAG_MATCH_DYNAMIC or
            LauncherApps.ShortcutQuery.FLAG_MATCH_PINNED
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            flags = flags or LauncherApps.ShortcutQuery.FLAG_MATCH_CACHED
        }
        return flags
    }

    private fun shortcutMap(
        shortcut: ShortcutInfo,
        isConversationCandidate: Boolean,
    ): Map<String, Any?> = mapOf(
        "package" to shortcut.`package`,
        "id" to shortcut.id,
        "shortLabel" to shortcut.shortLabel.toString(),
        "longLabel" to shortcut.longLabel?.toString(),
        "isConversation" to isConversationCandidate,
        "personNames" to emptyList<String>(),
    )

    private fun startShortcut(packageName: String, shortcutId: String): Boolean {
        if (!launcherApps.hasShortcutHostPermission()) return false
        launcherApps.startShortcut(
            packageName,
            shortcutId,
            null,
            null,
            Process.myUserHandle(),
        )
        return true
    }

    private fun launchQueryLink(door: String, query: String): Boolean {
        if (query.isBlank()) return false
        val intent = when (door) {
            "youtube" -> Intent(
                Intent.ACTION_VIEW,
                Uri.Builder()
                    .scheme("https")
                    .authority("www.youtube.com")
                    .appendPath("results")
                    .appendQueryParameter("search_query", query)
                    .build(),
            ).setPackage(YOUTUBE_PACKAGE)
            "maps" -> Intent(
                Intent.ACTION_VIEW,
                Uri.parse("geo:0,0").buildUpon()
                    .appendQueryParameter("q", query)
                    .build(),
            ).setPackage(MAPS_PACKAGE)
            "web" -> Intent(Intent.ACTION_WEB_SEARCH)
                .putExtra(SearchManager.QUERY, query)
            else -> return false
        }
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
        return true
    }

    companion object {
        private const val CHANNEL_NAME = "com.mitech.curre/launcher"
        private const val HOME_SETTINGS_OPENED = "home"
        private const val DEFAULT_APPS_OPENED = "defaultApps"
        private const val SETTINGS_OPENED = "settings"
        private const val NOTHING_OPENED = "none"
        private const val YOUTUBE_PACKAGE = "com.google.android.youtube"
        private const val MAPS_PACKAGE = "com.google.android.apps.maps"
    }
}
