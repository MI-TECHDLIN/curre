package com.mitech.curre

import android.app.Notification
import android.content.Context
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import org.json.JSONArray
import org.json.JSONObject

/**
 * Removes only clearable notifications from apps that are currently hidden.
 * Calls, alarms, full-screen and system notifications never enter the filter.
 * The local missed list stores app label, package, title and time — never body
 * text or message content — and is capped and pruned like Curre history.
 */
class QuietNotificationListenerService : NotificationListenerService() {
    override fun onNotificationPosted(statusBarNotification: StatusBarNotification?) {
        val posted = statusBarNotification ?: return
        val notification = posted.notification ?: return
        val policy = NotificationPolicy.load(this)
        val now = System.currentTimeMillis()
        if (!policy.shouldQuiet(posted.packageName, now)) return
        if (!posted.isClearable || isProtected(posted.packageName, notification)) return

        val appLabel = applicationLabel(posted.packageName)
        val title = notification.extras
            ?.getCharSequence(Notification.EXTRA_TITLE)
            ?.toString()
            ?.trim()
            ?.replace(Regex("\\s+"), " ")
            ?.take(MAX_TITLE_LENGTH)
            ?.takeIf { it.isNotEmpty() }
            ?: "Notification"
        appendMissedNotification(
            this,
            MissedNotification(
                packageName = posted.packageName,
                appLabel = appLabel,
                title = title,
                atMillis = posted.postTime,
            ),
        )
        cancelNotification(posted.key)
    }

    private fun isProtected(packageName: String, notification: Notification): Boolean {
        val category = notification.category
        return packageName == applicationContext.packageName ||
            packageName == "android" ||
            packageName == "com.android.systemui" ||
            packageName == "com.android.permissioncontroller" ||
            packageName == "com.google.android.permissioncontroller" ||
            category == Notification.CATEGORY_CALL ||
            category == Notification.CATEGORY_ALARM ||
            category == Notification.CATEGORY_SYSTEM ||
            notification.fullScreenIntent != null
    }

    @Suppress("DEPRECATION")
    private fun applicationLabel(packageName: String): String = try {
        val info = packageManager.getApplicationInfo(packageName, 0)
        packageManager.getApplicationLabel(info).toString().trim()
            .ifEmpty { packageName }
    } catch (_: Exception) {
        packageName
    }

    private data class NotificationPolicy(
        val enabled: Boolean,
        val monitoredPackages: Set<String>,
        val alwaysAllowedPackages: Set<String>,
        val allowedUntilMillis: Map<String, Long>,
    ) {
        fun shouldQuiet(packageName: String, now: Long): Boolean =
            enabled &&
                packageName in monitoredPackages &&
                packageName !in alwaysAllowedPackages &&
                (allowedUntilMillis[packageName] ?: 0L) <= now

        companion object {
            fun load(context: Context): NotificationPolicy {
                val preferences = context.getSharedPreferences(
                    PREFERENCES,
                    Context.MODE_PRIVATE,
                )
                return NotificationPolicy(
                    enabled = preferences.getBoolean(KEY_ENABLED, false),
                    monitoredPackages = preferences
                        .getStringSet(KEY_MONITORED_PACKAGES, emptySet())
                        .orEmpty()
                        .toSet(),
                    alwaysAllowedPackages = preferences
                        .getStringSet(KEY_ALWAYS_ALLOWED_PACKAGES, emptySet())
                        .orEmpty()
                        .toSet(),
                    allowedUntilMillis = decodeAllowedUntil(
                        preferences.getString(KEY_ALLOWED_UNTIL, null),
                    ),
                )
            }
        }
    }

    private data class MissedNotification(
        val packageName: String,
        val appLabel: String,
        val title: String,
        val atMillis: Long,
    ) {
        fun toJson() = JSONObject()
            .put("package", packageName)
            .put("appLabel", appLabel)
            .put("title", title)
            .put("atMillis", atMillis)

        fun toMap(): Map<String, Any> = mapOf(
            "package" to packageName,
            "appLabel" to appLabel,
            "title" to title,
            "atMillis" to atMillis,
        )

        companion object {
            fun fromJson(json: JSONObject) = MissedNotification(
                packageName = json.getString("package"),
                appLabel = json.getString("appLabel"),
                title = json.getString("title"),
                atMillis = json.getLong("atMillis"),
            )
        }
    }

    companion object {
        private const val PREFERENCES = "curre_quiet_notifications"
        private const val KEY_ENABLED = "enabled"
        private const val KEY_MONITORED_PACKAGES = "monitored_packages"
        private const val KEY_ALWAYS_ALLOWED_PACKAGES = "always_allowed_packages"
        private const val KEY_ALLOWED_UNTIL = "allowed_until"
        private const val KEY_MISSED = "missed"
        private const val MAX_MISSED = 100
        private const val MAX_TITLE_LENGTH = 120
        private const val RETENTION_MILLIS = 30L * 24L * 60L * 60L * 1_000L
        private val storageLock = Any()

        fun configure(
            context: Context,
            enabled: Boolean,
            hasNotificationAccess: Boolean,
            monitoredPackages: Set<String>,
            alwaysAllowedPackages: Set<String>,
            allowedUntilMillis: Map<String, Long>,
        ) {
            context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
                .edit()
                .putBoolean(KEY_ENABLED, enabled && hasNotificationAccess)
                .putStringSet(KEY_MONITORED_PACKAGES, monitoredPackages)
                .putStringSet(KEY_ALWAYS_ALLOWED_PACKAGES, alwaysAllowedPackages)
                .putString(KEY_ALLOWED_UNTIL, encodeAllowedUntil(allowedUntilMillis))
                .apply()
        }

        fun listMissedNotifications(context: Context): List<Map<String, Any>> =
            synchronized(storageLock) {
                val current = readMissedNotifications(context)
                    .filterNot { isExpired(it.atMillis) }
                    .sortedByDescending { it.atMillis }
                    .take(MAX_MISSED)
                writeMissedNotifications(context, current)
                current.map(MissedNotification::toMap)
            }

        fun clearMissedNotifications(context: Context) {
            synchronized(storageLock) {
                context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
                    .edit()
                    .remove(KEY_MISSED)
                    .apply()
            }
        }

        private fun appendMissedNotification(
            context: Context,
            notification: MissedNotification,
        ) {
            synchronized(storageLock) {
                val current = readMissedNotifications(context)
                    .filterNot { isExpired(it.atMillis) }
                    .toMutableList()
                current.add(notification)
                writeMissedNotifications(
                    context,
                    current.sortedByDescending { it.atMillis }.take(MAX_MISSED),
                )
            }
        }

        private fun readMissedNotifications(context: Context): List<MissedNotification> {
            val encoded = context.getSharedPreferences(
                PREFERENCES,
                Context.MODE_PRIVATE,
            ).getString(KEY_MISSED, null) ?: return emptyList()
            return try {
                val values = JSONArray(encoded)
                buildList {
                    for (index in 0 until values.length()) {
                        try {
                            add(MissedNotification.fromJson(values.getJSONObject(index)))
                        } catch (_: Exception) {
                            // One malformed record does not erase the rest.
                        }
                    }
                }
            } catch (_: Exception) {
                emptyList()
            }
        }

        private fun writeMissedNotifications(
            context: Context,
            notifications: List<MissedNotification>,
        ) {
            val json = JSONArray()
            notifications.forEach { json.put(it.toJson()) }
            context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
                .edit()
                .putString(KEY_MISSED, json.toString())
                .apply()
        }

        private fun isExpired(atMillis: Long): Boolean =
            atMillis < System.currentTimeMillis() - RETENTION_MILLIS

        private fun encodeAllowedUntil(values: Map<String, Long>): String =
            JSONObject().apply {
                values.forEach { (packageName, millis) -> put(packageName, millis) }
            }.toString()

        private fun decodeAllowedUntil(encoded: String?): Map<String, Long> {
            if (encoded.isNullOrBlank()) return emptyMap()
            return try {
                val json = JSONObject(encoded)
                buildMap {
                    val keys = json.keys()
                    while (keys.hasNext()) {
                        val key = keys.next()
                        put(key, json.getLong(key))
                    }
                }
            } catch (_: Exception) {
                emptyMap()
            }
        }
    }
}
