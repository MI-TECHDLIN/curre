package com.mitech.curre

import android.app.ActivityManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.IBinder
import android.os.PowerManager
import android.provider.Settings
import android.telecom.TelecomManager
import org.json.JSONObject

/**
 * A gentle foreground-app observer for Android 10+.
 *
 * It reads only the incremental UsageEvents window, keeps no usage history,
 * and polls every 750 ms only while the screen is interactive. The foreground
 * service notification is the honest cost of keeping that short loop alive.
 * Curre never kills, overlays, or blocks the detected app; it only brings the
 * existing Flutter gate to the front.
 */
class GentleInterceptService : Service() {
    private lateinit var usageStats: UsageStatsManager
    private lateinit var workerThread: HandlerThread
    private lateinit var worker: Handler
    private lateinit var powerManager: PowerManager
    private var receiverRegistered = false
    @Volatile
    private var screenInteractive = false
    private var lastQueryEndMillis = 0L
    private var lastEventMillis = 0L
    private var lastForegroundPackage: String? = null
    private var lastInterceptMillis = 0L
    private val lastInterceptByPackage = mutableMapOf<String, Long>()
    @Volatile
    private var ignoredPackages = emptySet<String>()

    @Volatile
    private var policy = InterceptPolicy.disabled()

    private val pollRunnable = object : Runnable {
        override fun run() {
            if (!screenInteractive || !policy.enabled) return
            pollForegroundApp()
            worker.postDelayed(this, POLL_INTERVAL_MILLIS)
        }
    }

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                Intent.ACTION_SCREEN_ON, Intent.ACTION_USER_PRESENT -> {
                    screenInteractive = true
                    schedulePolling(immediate = true)
                }
                Intent.ACTION_SCREEN_OFF -> {
                    screenInteractive = false
                    worker.removeCallbacks(pollRunnable)
                }
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, serviceNotification())
        usageStats = getSystemService(UsageStatsManager::class.java)
        powerManager = getSystemService(PowerManager::class.java)
        workerThread = HandlerThread("curre-gentle-intercept").also { it.start() }
        worker = Handler(workerThread.looper)
        policy = InterceptPolicy.load(this)
        ignoredPackages = loadIgnoredPackages()
        screenInteractive = powerManager.isInteractive
        registerScreenReceiver()
        if (screenInteractive && policy.enabled) schedulePolling(immediate = true)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        policy = InterceptPolicy.load(this)
        ignoredPackages = loadIgnoredPackages()
        if (!policy.enabled) {
            stopSelf()
            return START_NOT_STICKY
        }
        if (screenInteractive) schedulePolling(immediate = true)
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        worker.removeCallbacksAndMessages(null)
        if (receiverRegistered) unregisterReceiver(screenReceiver)
        workerThread.quitSafely()
        super.onDestroy()
    }

    private fun registerScreenReceiver() {
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_USER_PRESENT)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(screenReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("DEPRECATION")
            registerReceiver(screenReceiver, filter)
        }
        receiverRegistered = true
    }

    private fun schedulePolling(immediate: Boolean) {
        worker.removeCallbacks(pollRunnable)
        if (!screenInteractive || !policy.enabled) return
        worker.postDelayed(pollRunnable, if (immediate) 0L else POLL_INTERVAL_MILLIS)
    }

    private fun pollForegroundApp() {
        val now = System.currentTimeMillis()
        val begin = if (lastQueryEndMillis == 0L) {
            now - INITIAL_LOOKBACK_MILLIS
        } else {
            maxOf(lastQueryEndMillis - QUERY_OVERLAP_MILLIS, now - MAX_LOOKBACK_MILLIS)
        }
        val events = usageStats.queryEvents(begin, now)
        lastQueryEndMillis = now

        var newestPackage: String? = null
        var newestAt = lastEventMillis
        val event = UsageEvents.Event()
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (event.eventType != UsageEvents.Event.ACTIVITY_RESUMED ||
                event.timeStamp <= newestAt
            ) {
                continue
            }
            val packageName = event.packageName
            if (packageName.isNullOrBlank()) continue
            newestPackage = packageName
            newestAt = event.timeStamp
        }

        val packageName = newestPackage ?: return
        lastEventMillis = newestAt
        if (packageName == lastForegroundPackage) return
        lastForegroundPackage = packageName
        if (policy.shouldIntercept(packageName, now, ignoredPackages)) {
            bringGateForward(packageName, now)
        }
    }

    private fun loadIgnoredPackages(): Set<String> = buildSet {
        add(packageName)
        add("android")
        add("com.android.systemui")
        add("com.google.android.permissioncontroller")
        add("com.android.permissioncontroller")

        val homeIntent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
        @Suppress("DEPRECATION")
        for (resolved in packageManager.queryIntentActivities(homeIntent, 0)) {
            resolved.activityInfo?.packageName?.let(::add)
        }

        val dialIntent = Intent(Intent.ACTION_DIAL).setData(
            android.net.Uri.parse("tel:"),
        )
        @Suppress("DEPRECATION")
        for (resolved in packageManager.queryIntentActivities(dialIntent, 0)) {
            resolved.activityInfo?.packageName?.let(::add)
        }

        Settings.Secure.getString(
            contentResolver,
            Settings.Secure.DEFAULT_INPUT_METHOD,
        )?.substringBefore('/')?.takeIf { it.isNotBlank() }?.let(::add)

        getSystemService(TelecomManager::class.java)
            .defaultDialerPackage
            ?.takeIf { it.isNotBlank() }
            ?.let(::add)
    }

    private fun bringGateForward(packageName: String, now: Long) {
        val packageLast = lastInterceptByPackage[packageName] ?: 0L
        if (now - packageLast < PACKAGE_COOLDOWN_MILLIS ||
            now - lastInterceptMillis < GLOBAL_COOLDOWN_MILLIS
        ) {
            return
        }
        lastInterceptByPackage[packageName] = now
        lastInterceptMillis = now
        savePendingIntercept(this, packageName, now)

        val activityIntent = Intent(this, MainActivity::class.java)
            .putExtra(EXTRA_INTERCEPT_PACKAGE, packageName)
            .putExtra(EXTRA_INTERCEPT_AT_MILLIS, now)
            .addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT,
            )
        // Moving Curre's own task helps launcher builds whose Home task is still
        // resident. It is best effort because some vendor builds restrict it.
        try {
            getSystemService(ActivityManager::class.java)
                .appTasks
                .firstOrNull()
                ?.moveToFront()
        } catch (_: Exception) {
            // startActivity below still covers a cold or restricted task.
        }
        try {
            startActivity(activityIntent)
        } catch (_: Exception) {
            // Some vendor builds may still reject a background activity
            // start. The ongoing notification keeps the service honest and
            // the pending event is delivered when Curre next resumes.
        }
    }

    private fun createNotificationChannel() {
        val manager = getSystemService(NotificationManager::class.java)
        val channel = NotificationChannel(
            NOTIFICATION_CHANNEL_ID,
            "Hidden app checks",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Keeps Curre ready to ask why when a hidden app opens"
            setSound(null, null)
            enableVibration(false)
            setShowBadge(false)
            lockscreenVisibility = Notification.VISIBILITY_PRIVATE
        }
        manager.createNotificationChannel(channel)
    }

    private fun serviceNotification(): Notification {
        val openCurre = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        return Notification.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_curre)
            .setContentTitle("Hidden app check is on")
            .setContentText("Curre asks why. Usage stays on this phone.")
            .setContentIntent(openCurre)
            .setCategory(Notification.CATEGORY_SERVICE)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .build()
    }

    private data class InterceptPolicy(
        val enabled: Boolean,
        val monitoredPackages: Set<String>,
        val alwaysAllowedPackages: Set<String>,
        val allowedUntilMillis: Map<String, Long>,
    ) {
        fun shouldIntercept(
            packageName: String,
            now: Long,
            ignoredPackages: Set<String>,
        ): Boolean {
            if (!enabled || packageName !in monitoredPackages) return false
            if (packageName in ignoredPackages || packageName in alwaysAllowedPackages) {
                return false
            }
            return (allowedUntilMillis[packageName] ?: 0L) <= now
        }

        companion object {
            fun disabled() = InterceptPolicy(
                enabled = false,
                monitoredPackages = emptySet(),
                alwaysAllowedPackages = emptySet(),
                allowedUntilMillis = emptyMap(),
            )

            fun load(context: Context): InterceptPolicy {
                val preferences = context.getSharedPreferences(
                    PREFERENCES,
                    Context.MODE_PRIVATE,
                )
                return InterceptPolicy(
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

    companion object {
        const val EXTRA_INTERCEPT_PACKAGE = "curre_intercept_package"
        const val EXTRA_INTERCEPT_AT_MILLIS = "curre_intercept_at_millis"

        private const val PREFERENCES = "curre_gentle_intercept"
        private const val KEY_ENABLED = "enabled"
        private const val KEY_MONITORED_PACKAGES = "monitored_packages"
        private const val KEY_ALWAYS_ALLOWED_PACKAGES = "always_allowed_packages"
        private const val KEY_ALLOWED_UNTIL = "allowed_until"
        private const val KEY_PENDING_PACKAGE = "pending_package"
        private const val KEY_PENDING_AT = "pending_at"
        private const val NOTIFICATION_CHANNEL_ID = "curre_gentle_intercept"
        private const val NOTIFICATION_ID = 7042
        private const val POLL_INTERVAL_MILLIS = 750L
        private const val QUERY_OVERLAP_MILLIS = 250L
        private const val INITIAL_LOOKBACK_MILLIS = 2_000L
        private const val MAX_LOOKBACK_MILLIS = 5_000L
        private const val PACKAGE_COOLDOWN_MILLIS = 4_000L
        private const val GLOBAL_COOLDOWN_MILLIS = 1_000L
        private const val PENDING_MAX_AGE_MILLIS = 30_000L

        fun configure(
            context: Context,
            enabled: Boolean,
            hasUsageAccess: Boolean,
            monitoredPackages: Set<String>,
            alwaysAllowedPackages: Set<String>,
            allowedUntilMillis: Map<String, Long>,
        ) {
            val shouldRun = enabled && hasUsageAccess
            context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
                .edit()
                .putBoolean(KEY_ENABLED, shouldRun)
                .putStringSet(KEY_MONITORED_PACKAGES, monitoredPackages)
                .putStringSet(KEY_ALWAYS_ALLOWED_PACKAGES, alwaysAllowedPackages)
                .putString(KEY_ALLOWED_UNTIL, encodeAllowedUntil(allowedUntilMillis))
                .commit()

            val serviceIntent = Intent(context, GentleInterceptService::class.java)
            if (shouldRun) {
                context.startForegroundService(serviceIntent)
            } else {
                context.stopService(serviceIntent)
            }
        }

        fun takePendingIntercept(context: Context): Map<String, Any>? {
            val preferences = context.getSharedPreferences(
                PREFERENCES,
                Context.MODE_PRIVATE,
            )
            val packageName = preferences.getString(KEY_PENDING_PACKAGE, null)
            val atMillis = preferences.getLong(KEY_PENDING_AT, 0L)
            preferences.edit()
                .remove(KEY_PENDING_PACKAGE)
                .remove(KEY_PENDING_AT)
                .commit()
            if (packageName.isNullOrBlank() ||
                atMillis <= 0L ||
                System.currentTimeMillis() - atMillis > PENDING_MAX_AGE_MILLIS
            ) {
                return null
            }
            return mapOf("package" to packageName, "atMillis" to atMillis)
        }

        private fun savePendingIntercept(
            context: Context,
            packageName: String,
            atMillis: Long,
        ) {
            context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
                .edit()
                .putString(KEY_PENDING_PACKAGE, packageName)
                .putLong(KEY_PENDING_AT, atMillis)
                .commit()
        }

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
