package com.example.curre

import android.app.SearchManager
import android.app.role.RoleManager
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
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private lateinit var launcherApps: LauncherApps

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        launcherApps = getSystemService(LauncherApps::class.java)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME,
        ).setMethodCallHandler(::handleMethodCall)
    }

    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "listApps" -> result.success(listApps())
                "getIcon" -> result.success(getIcon(call.arguments as String))
                "launch" -> result.success(launchPackage(call.arguments as String))
                "requestHomeRole" -> result.success(requestHomeRole())
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

    private fun requestHomeRole(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val roleManager = getSystemService(RoleManager::class.java)
            if (roleManager.isRoleAvailable(RoleManager.ROLE_HOME)) {
                if (roleManager.isRoleHeld(RoleManager.ROLE_HOME)) return true
                startActivityForResult(
                    roleManager.createRequestRoleIntent(RoleManager.ROLE_HOME),
                    HOME_ROLE_REQUEST,
                )
                return true
            }
        }
        startActivity(Intent(Settings.ACTION_HOME_SETTINGS))
        return true
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
        private const val CHANNEL_NAME = "curre/launcher"
        private const val HOME_ROLE_REQUEST = 7011
        private const val YOUTUBE_PACKAGE = "com.google.android.youtube"
        private const val MAPS_PACKAGE = "com.google.android.apps.maps"
    }
}
