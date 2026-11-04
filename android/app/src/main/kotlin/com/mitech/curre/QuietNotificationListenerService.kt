package com.mitech.curre

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import org.json.JSONArray
import org.json.JSONObject
import java.util.concurrent.ConcurrentHashMap

/**
 * Holds, never deletes, ordinary notifications from the apps the user chose
 * to hide, and gives them back when that app may be used again.
 *
 * Holding: Android snoozes the original (so it comes back whole, with its
 * own tap action and replies), and Curre saves a held copy on this phone:
 * app, title, text and time. If Android won't snooze it, Curre takes it out
 * of the shade instead and the held copy is what comes back.
 *
 * Giving back happens whenever the saved policy no longer holds an app: it
 * was opened through "Why now?" or a plan, the user stopped hiding it, a
 * rest day began, the focus ended (`holdUntilMillis`), holding was switched
 * off, or Curre stopped being Home. Curre asks Android to end each snooze
 * now; anything Android no longer has (a phone restart, or a notification
 * that couldn't be snoozed) comes back as one quiet Curre notification per
 * app that opens it. The held list is saved, so a restart loses nothing.
 *
 * Calls, alarms, system, ongoing (not clearable) and full-screen
 * notifications are never touched.
 */
class QuietNotificationListenerService : NotificationListenerService() {
    private val handler = Handler(Looper.getMainLooper())
    private var preferences: SharedPreferences? = null
    private var lastReconcileMillis = 0L

    // Curre saves a new policy when an app is opened or brought back, a
    // rest day starts or Curre stops being Home: give back what it frees.
    private val policyListener =
        SharedPreferences.OnSharedPreferenceChangeListener { _, key ->
            if (key != KEY_MISSED) scheduleReconcile()
        }

    override fun onListenerConnected() {
        super.onListenerConnected()
        instance = this
        val saved = getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
        saved.registerOnSharedPreferenceChangeListener(policyListener)
        preferences = saved
        // After a restart (or access turned back on), the saved held list
        // is checked against the saved policy straight away.
        scheduleReconcile()
    }

    override fun onListenerDisconnected() {
        stopListening()
        super.onListenerDisconnected()
    }

    override fun onDestroy() {
        stopListening()
        super.onDestroy()
    }

    private fun stopListening() {
        preferences?.unregisterOnSharedPreferenceChangeListener(policyListener)
        preferences = null
        handler.removeCallbacksAndMessages(null)
        if (instance === this) instance = null
    }

    override fun onNotificationPosted(statusBarNotification: StatusBarNotification?) {
        val posted = statusBarNotification ?: return
        val notification = posted.notification ?: return
        val now = System.currentTimeMillis()
        val policy = NotificationPolicy.load(this)
        if (!policy.holds(posted.packageName, now, isCurreDefaultHome(this))) {
            // A focus can end, or another home screen be chosen, while Curre
            // is closed: any new notification is a chance to give back what
            // is due.
            if (now - lastReconcileMillis > RECONCILE_THROTTLE_MILLIS) {
                scheduleReconcile()
            }
            return
        }
        if (!posted.isClearable || isProtected(posted.packageName, notification)) return
        hold(posted, notification)
    }

    private fun hold(posted: StatusBarNotification, notification: Notification) {
        val extras = notification.extras
        val title = extras
            ?.getCharSequence(Notification.EXTRA_TITLE)
            ?.toString()
            ?.let { tidy(it) }
            ?.take(MAX_TITLE_LENGTH)
            ?.takeIf { it.isNotEmpty() }
            ?: "Notification"
        val text = (
            extras?.getCharSequence(Notification.EXTRA_TEXT)
                ?: extras?.getCharSequence(Notification.EXTRA_BIG_TEXT)
            )
            ?.toString()
            ?.let { tidy(it) }
            ?.take(MAX_TEXT_LENGTH)
            ?.takeIf { it.isNotEmpty() }
        notification.contentIntent?.let { contentIntents[posted.key] = it }
        val snoozed = try {
            snoozeNotification(posted.key, HOLD_MILLIS)
            true
        } catch (_: Exception) {
            // Android refused the snooze: take it out of the shade instead;
            // the held copy comes back in its place.
            try {
                cancelNotification(posted.key)
            } catch (_: Exception) {
                // Nothing else to do; the original simply stays.
            }
            false
        }
        saveHeld(
            this,
            HeldNotification(
                key = posted.key,
                packageName = posted.packageName,
                appLabel = applicationLabel(posted.packageName),
                title = title,
                text = text,
                atMillis = posted.postTime,
                held = true,
                snoozed = snoozed,
                bootCount = bootCount(this),
                // A group summary repeats its children: held and given back
                // with them, but never listed or summed up.
                isGroupSummary =
                (notification.flags and Notification.FLAG_GROUP_SUMMARY) != 0,
            ),
        )
    }

    private fun scheduleReconcile() {
        handler.removeCallbacks(reconcileRunnable)
        handler.post(reconcileRunnable)
    }

    private val reconcileRunnable = Runnable { reconcile() }

    /** Gives back every held notification the saved policy no longer holds. */
    private fun reconcile() {
        lastReconcileMillis = System.currentTimeMillis()
        val policy = NotificationPolicy.load(this)
        val isHome = isCurreDefaultHome(this)
        val due = synchronized(storageLock) {
            readHeld(this).filter {
                it.held && !policy.holds(it.packageName, lastReconcileMillis, isHome)
            }
        }
        if (due.isNotEmpty()) giveBack(due)
    }

    private fun giveBack(items: List<HeldNotification>) {
        val inAndroid = snoozedKeys()
        val currentBoot = bootCount(this)
        val resumed = mutableListOf<HeldNotification>()
        val repost = mutableListOf<HeldNotification>()
        for (item in items) {
            when {
                item.key in inAndroid -> resumed.add(item)
                // Never snoozed, or snoozed before a restart that Android
                // didn't keep it through: Curre's copy is all that's left.
                !item.snoozed || item.bootCount != currentBoot -> repost.add(item)
                // Snoozed this boot and gone: the app withdrew it itself
                // (read elsewhere, for example), so there is nothing to give.
                else -> Unit
            }
        }
        // Asking for a 1 ms snooze ends the long one: Android posts the
        // original again, and the policy now lets it through.
        for (item in resumed) {
            try {
                snoozeNotification(item.key, 1L)
            } catch (_: Exception) {
                // Checked below.
            }
        }
        markGivenBack(this, items.map { it.key }.toSet())
        postGivenBack(repost)
        if (resumed.isNotEmpty()) {
            handler.postDelayed({ confirmResumed(resumed) }, CONFIRM_DELAY_MILLIS)
        }
    }

    /**
     * Anything Android still holds a few seconds later didn't come back by
     * itself: end its snooze for good and give back Curre's copy instead, so
     * it can't appear twice or stay away.
     */
    private fun confirmResumed(items: List<HeldNotification>) {
        val stillSnoozed = snoozedKeys()
        val stuck = items.filter { it.key in stillSnoozed }
        for (item in stuck) {
            try {
                cancelNotification(item.key)
            } catch (_: Exception) {
                // Its long snooze ends by itself in the end.
            }
        }
        postGivenBack(stuck)
    }

    private fun snoozedKeys(): Set<String> = try {
        snoozedNotifications?.mapNotNull { it?.key }?.toSet().orEmpty()
    } catch (_: Exception) {
        emptySet()
    }

    /** One quiet Curre notification per app for copies given back. */
    private fun postGivenBack(items: List<HeldNotification>) {
        val shown = items.filterNot { it.isGroupSummary }
        if (shown.isEmpty()) return
        val manager = getSystemService(NotificationManager::class.java) ?: return
        if (!manager.areNotificationsEnabled()) return
        createGivenBackChannel(manager)
        for ((packageName, group) in shown.groupBy { it.packageName }) {
            val newest = group.maxBy { it.atMillis }
            val tap = contentIntents[newest.key] ?: launchIntentFor(packageName)
            val style = Notification.InboxStyle()
            group.sortedByDescending { it.atMillis }.take(MAX_SUMMARY_LINES).forEach {
                style.addLine(if (it.text == null) it.title else "${it.title}: ${it.text}")
            }
            val builder = Notification.Builder(this, GIVEN_BACK_CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_stat_curre)
                .setContentTitle(
                    if (group.size == 1) {
                        "${newest.appLabel}: ${newest.title}"
                    } else {
                        "${newest.appLabel}: ${group.size} notifications"
                    },
                )
                .setContentText(newest.text ?: "Held while ${newest.appLabel} was hidden")
                .setSubText("Held while hidden")
                .setStyle(style)
                .setWhen(newest.atMillis)
                .setShowWhen(true)
                .setAutoCancel(true)
                .setOnlyAlertOnce(true)
                .setVisibility(Notification.VISIBILITY_PRIVATE)
            if (tap != null) builder.setContentIntent(tap)
            try {
                manager.notify(GIVEN_BACK_TAG, packageName.hashCode(), builder.build())
            } catch (_: Exception) {
                // The copies stay in Curre's Missed notifications list.
            }
        }
    }

    private fun launchIntentFor(packageName: String): PendingIntent? {
        val launch = packageManager.getLaunchIntentForPackage(packageName) ?: return null
        launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return PendingIntent.getActivity(
            this,
            packageName.hashCode(),
            launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun createGivenBackChannel(manager: NotificationManager) {
        val channel = NotificationChannel(
            GIVEN_BACK_CHANNEL_ID,
            "Given back from hidden apps",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Notifications Curre held while their app was hidden"
            setSound(null, null)
            enableVibration(false)
            lockscreenVisibility = Notification.VISIBILITY_PRIVATE
        }
        manager.createNotificationChannel(channel)
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
            notification.fullScreenIntent != null ||
            (notification.flags and Notification.FLAG_ONGOING_EVENT) != 0
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
        val holdUntilMillis: Long?,
    ) {
        /** Mirrored by `QuietNotificationPolicy.holds` in Dart. */
        fun holds(packageName: String, now: Long, curreIsHome: Boolean): Boolean =
            enabled &&
                curreIsHome &&
                (holdUntilMillis == null || now < holdUntilMillis) &&
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
                    holdUntilMillis = preferences
                        .getLong(KEY_HOLD_UNTIL, NO_HOLD_UNTIL)
                        .takeIf { it != NO_HOLD_UNTIL },
                )
            }
        }
    }

    /**
     * A held notification, saved on this phone. Its text is kept only while
     * it is held; once given back, the app, title and time stay in Missed
     * notifications for 30 days.
     */
    private data class HeldNotification(
        val key: String,
        val packageName: String,
        val appLabel: String,
        val title: String,
        val text: String?,
        val atMillis: Long,
        val held: Boolean,
        val snoozed: Boolean,
        val bootCount: Int,
        val isGroupSummary: Boolean,
    ) {
        fun toJson(): JSONObject = JSONObject()
            .put("key", key)
            .put("package", packageName)
            .put("appLabel", appLabel)
            .put("title", title)
            .put("text", text ?: JSONObject.NULL)
            .put("atMillis", atMillis)
            .put("held", held)
            .put("snoozed", snoozed)
            .put("bootCount", bootCount)
            .put("groupSummary", isGroupSummary)

        fun toMap(): Map<String, Any> = buildMap<String, Any> {
            put("key", key)
            put("package", packageName)
            put("appLabel", appLabel)
            put("title", title)
            if (text != null) put("text", text)
            put("atMillis", atMillis)
            put("held", held)
        }

        fun givenBack(): HeldNotification = copy(held = false, text = null)

        companion object {
            /** Also reads the app/title/time records older builds saved. */
            fun fromJson(json: JSONObject): HeldNotification {
                val packageName = json.getString("package")
                val atMillis = json.getLong("atMillis")
                return HeldNotification(
                    key = json.optString("key").ifEmpty { "$packageName@$atMillis" },
                    packageName = packageName,
                    appLabel = json.getString("appLabel"),
                    title = json.getString("title"),
                    text = if (json.isNull("text")) null else json.optString("text"),
                    atMillis = atMillis,
                    held = json.optBoolean("held", false),
                    snoozed = json.optBoolean("snoozed", false),
                    bootCount = json.optInt("bootCount", -1),
                    isGroupSummary = json.optBoolean("groupSummary", false),
                )
            }
        }
    }

    companion object {
        private const val PREFERENCES = "curre_quiet_notifications"
        private const val KEY_ENABLED = "enabled"
        private const val KEY_MONITORED_PACKAGES = "monitored_packages"
        private const val KEY_ALWAYS_ALLOWED_PACKAGES = "always_allowed_packages"
        private const val KEY_ALLOWED_UNTIL = "allowed_until"
        private const val KEY_HOLD_UNTIL = "hold_until"
        private const val KEY_MISSED = "missed"
        private const val NO_HOLD_UNTIL = -1L
        private const val MAX_RECORDS = 500
        private const val MAX_TITLE_LENGTH = 120
        private const val MAX_TEXT_LENGTH = 300
        private const val MAX_SUMMARY_LINES = 6
        private const val RETENTION_MILLIS = 30L * 24L * 60L * 60L * 1_000L

        /** Android snoozes a held notification for at most this long. */
        private const val HOLD_MILLIS = 30L * 24L * 60L * 60L * 1_000L
        private const val CONFIRM_DELAY_MILLIS = 5_000L
        private const val RECONCILE_THROTTLE_MILLIS = 15_000L
        private const val GIVEN_BACK_CHANNEL_ID = "curre_given_back"
        private const val GIVEN_BACK_TAG = "curre_given_back"
        private val storageLock = Any()

        /** Tap actions of held notifications, while this process lives. */
        private val contentIntents = ConcurrentHashMap<String, PendingIntent>()

        @Volatile
        private var instance: QuietNotificationListenerService? = null

        fun configure(
            context: Context,
            enabled: Boolean,
            hasNotificationAccess: Boolean,
            monitoredPackages: Set<String>,
            alwaysAllowedPackages: Set<String>,
            allowedUntilMillis: Map<String, Long>,
            holdUntilMillis: Long?,
        ) {
            context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
                .edit()
                .putBoolean(KEY_ENABLED, enabled && hasNotificationAccess)
                .putStringSet(KEY_MONITORED_PACKAGES, monitoredPackages)
                .putStringSet(KEY_ALWAYS_ALLOWED_PACKAGES, alwaysAllowedPackages)
                .putString(KEY_ALLOWED_UNTIL, encodeAllowedUntil(allowedUntilMillis))
                .putLong(KEY_HOLD_UNTIL, holdUntilMillis ?: NO_HOLD_UNTIL)
                .apply()
            // The running listener also hears the change; this covers a
            // write whose values didn't change but whose time has come.
            instance?.scheduleReconcile()
        }

        /** Held notifications first (newest first), then those given back. */
        fun listMissedNotifications(context: Context): List<Map<String, Any>> =
            synchronized(storageLock) {
                val current = prune(readHeld(context))
                writeHeld(context, current)
                current
                    .filterNot { it.isGroupSummary }
                    .sortedWith(
                        compareByDescending<HeldNotification> { it.held }
                            .thenByDescending { it.atMillis },
                    )
                    .map(HeldNotification::toMap)
            }

        /**
         * Clears the list. Notifications still held are given back first,
         * so clearing history never loses one.
         */
        fun clearMissedNotifications(context: Context) {
            val running = instance
            if (running != null) {
                val held = synchronized(storageLock) {
                    readHeld(context).filter { it.held }
                }
                if (held.isNotEmpty()) running.giveBack(held)
            }
            synchronized(storageLock) {
                val keep = if (running == null) {
                    readHeld(context).filter { it.held }
                } else {
                    emptyList()
                }
                writeHeld(context, keep)
            }
            if (running != null) contentIntents.clear()
        }

        /**
         * The tap action of the held notification [key], while Android and
         * this process still have it.
         */
        fun contentIntentFor(key: String): PendingIntent? = contentIntents[key]

        private fun saveHeld(context: Context, notification: HeldNotification) {
            synchronized(storageLock) {
                val current = readHeld(context)
                    .filterNot { it.key == notification.key }
                    .toMutableList()
                current.add(notification)
                writeHeld(context, prune(current))
            }
        }

        private fun markGivenBack(context: Context, keys: Set<String>) {
            synchronized(storageLock) {
                writeHeld(
                    context,
                    readHeld(context).map { if (it.key in keys) it.givenBack() else it },
                )
            }
        }

        /**
         * Given-back records expire after 30 days; held ones never do. Past
         * the cap, given-back records go first.
         */
        private fun prune(records: List<HeldNotification>): List<HeldNotification> {
            val cutoff = System.currentTimeMillis() - RETENTION_MILLIS
            val kept = records.filter { it.held || it.atMillis >= cutoff }
            if (kept.size <= MAX_RECORDS) return kept
            return kept
                .sortedWith(
                    compareByDescending<HeldNotification> { it.held }
                        .thenByDescending { it.atMillis },
                )
                .take(MAX_RECORDS)
        }

        private fun readHeld(context: Context): List<HeldNotification> {
            val encoded = context.getSharedPreferences(
                PREFERENCES,
                Context.MODE_PRIVATE,
            ).getString(KEY_MISSED, null) ?: return emptyList()
            return try {
                val values = JSONArray(encoded)
                buildList {
                    for (index in 0 until values.length()) {
                        try {
                            add(HeldNotification.fromJson(values.getJSONObject(index)))
                        } catch (_: Exception) {
                            // One malformed record does not erase the rest.
                        }
                    }
                }
            } catch (_: Exception) {
                emptyList()
            }
        }

        // commit(), not apply(): the held list must be on disk before the
        // phone can restart.
        private fun writeHeld(context: Context, notifications: List<HeldNotification>) {
            val json = JSONArray()
            notifications.forEach { json.put(it.toJson()) }
            context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
                .edit()
                .putString(KEY_MISSED, json.toString())
                .commit()
        }

        private fun bootCount(context: Context): Int = try {
            Settings.Global.getInt(context.contentResolver, Settings.Global.BOOT_COUNT)
        } catch (_: Exception) {
            -1
        }

        private fun tidy(value: String): String = value.trim().replace(Regex("\\s+"), " ")

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
