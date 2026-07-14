package com.beltech.app.sms

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

/**
 * Manages the "Processing M-Pesa SMS…" transient foreground notification.
 *
 * Lifecycle:
 *   1. [show] — called by [MpesaSmsReceiver] when an M-Pesa SMS arrives and a
 *      WorkManager task is scheduled.  Signals to the user that background work
 *      is in progress.
 *   2. [dismiss] — called by the MethodChannel from Dart when the ingest task
 *      completes (via [SmsAutoImportService] or [BackgroundWorkerRuntime]).
 *
 * Required on Android 12+ (API 31+) where BroadcastReceivers cannot start
 * foreground services directly.  WorkManager handles the actual background work
 * scheduling; this notification is informational only.
 */
object SmsIngestNotificationHelper {

    private const val CHANNEL_ID   = "beltech_sms_ingest"
    private const val CHANNEL_NAME = "M-Pesa SMS Processing"
    const val NOTIFICATION_ID      = 8471  // arbitrary unique ID

    fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val mgr = context.getSystemService(Context.NOTIFICATION_SERVICE)
            as NotificationManager
        if (mgr.getNotificationChannel(CHANNEL_ID) != null) return
        mgr.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "Shown briefly while M-Pesa SMS are being imported"
                setShowBadge(false)
            }
        )
    }

    fun show(context: Context) {
        ensureChannel(context)
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_popup_sync)
            .setContentTitle("BELTECH")
            .setContentText("Processing M-Pesa SMS…")
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setAutoCancel(false)
            .build()
        try {
            NotificationManagerCompat.from(context).notify(NOTIFICATION_ID, notification)
        } catch (_: SecurityException) {
            // POST_NOTIFICATIONS not granted — silently skip.
        }
    }

    fun dismiss(context: Context) {
        NotificationManagerCompat.from(context).cancel(NOTIFICATION_ID)
    }
}
