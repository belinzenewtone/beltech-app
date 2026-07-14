package com.beltech.app.sms

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import androidx.work.Data
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequest
import androidx.work.WorkManager
import io.flutter.plugin.common.MethodChannel

/**
 * BroadcastReceiver for SMS_RECEIVED_ACTION.
 *
 * Two independent delivery paths are triggered on every matching SMS so that
 * transactions are processed regardless of whether the app is open or closed:
 *
 *   1. MethodChannel (foreground path) — calls onMpesaSmsReceived on the Dart
 *      side when the Flutter engine is running.  Enables immediate real-time
 *      UI updates.
 *
 *   2. WorkManager (background path) — always schedules a one-shot ingest task
 *      keyed by WORKER_UNIQUE_NAME with ExistingWorkPolicy.KEEP.  This path
 *      works even when the app is fully closed.
 *
 * The 4-tier dedup layer (Phases 3–4) prevents double-insertion when both paths
 * deliver the same SMS.
 */
class MpesaSmsReceiver : BroadcastReceiver() {

    companion object {
        /** Dart-side MethodChannel (set by MainActivity while engine is alive). */
        @Volatile
        var channel: MethodChannel? = null

        fun setMethodChannel(ch: MethodChannel?) {
            channel = ch
        }

        // Must match SmsIngestionWorker.dart constants.
        private const val WORKER_UNIQUE_NAME = "com.beltech.sms.ingest.oneshot"
        private const val WORKER_TASK_NAME   = "beltech.sms.ingest"

        // Input data key consumed by the workmanager Flutter plugin's BackgroundWorker.
        private const val WM_TASK_NAME_KEY  = "be.tramckrijte.workmanager.BackgroundWorkerName"
        private const val WM_DEBUG_MODE_KEY = "be.tramckrijte.workmanager.IsInDebugMode"

        // Cheap Kotlin-side pre-filter — avoids cross-thread overhead for
        // non-M-Pesa SMS.  The Dart-side parser applies the full filter.
        private fun isMpesaLike(sender: String, body: String): Boolean {
            val s = sender.lowercase()
            val b = body.lowercase()
            return s.contains("mpesa") ||
                b.contains("m-pesa") ||
                (b.contains("ksh") && b.contains("confirmed")) ||
                b.contains("safaricom m-pesa")
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return

        val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            ?.takeIf { it.isNotEmpty() }
            ?: return

        // Multi-part SMS: getMessagesFromIntent returns one SmsMessage per PDU
        // fragment.  Concatenate all bodies in order to reconstruct the full
        // message before filtering or dispatching.
        val sender    = messages.first().originatingAddress ?: ""
        val body      = messages.joinToString("") { it.messageBody ?: "" }.trim()
        val timestamp = messages.first().timestampMillis

        if (body.isEmpty() || !isMpesaLike(sender, body)) return

        // Foreground path — no-op when channel is null (app closed).
        channel?.invokeMethod(
            "onMpesaSmsReceived",
            mapOf("sender" to sender, "body" to body, "timestamp" to timestamp),
        )

        // Background path — always schedule so closed-app SMS are not lost.
        // Show a transient notification so the user knows work is happening.
        SmsIngestNotificationHelper.show(context)
        scheduleIngestWorker(context)
    }

    /**
     * Schedules a one-shot WorkManager task that runs the Dart SMS ingest
     * pipeline via the Flutter workmanager plugin's BackgroundWorker.
     *
     * Class.forName avoids a compile-time dependency on the plugin's internal
     * class hierarchy; the try/catch is a safety net for cases where the
     * plugin has not been initialized yet (app not yet run once after install).
     */
    @Suppress("UNCHECKED_CAST")
    private fun scheduleIngestWorker(context: Context) {
        try {
            val workerClass = Class.forName("be.tramckrijte.workmanager.BackgroundWorker")
                as Class<out androidx.work.ListenableWorker>

            val inputData = Data.Builder()
                .putString(WM_TASK_NAME_KEY, WORKER_TASK_NAME)
                .putBoolean(WM_DEBUG_MODE_KEY, false)
                .build()

            val request = OneTimeWorkRequest.Builder(workerClass)
                .setInputData(inputData)
                .build()

            WorkManager.getInstance(context).enqueueUniqueWork(
                WORKER_UNIQUE_NAME,
                ExistingWorkPolicy.KEEP,
                request,
            )
        } catch (_: Exception) {
            // WorkManager plugin not yet bootstrapped (app not yet run once).
            // The next app open will process the SMS via importFromDevice().
        }
    }
}
