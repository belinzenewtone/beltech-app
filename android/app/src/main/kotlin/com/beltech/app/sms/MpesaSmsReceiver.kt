package com.beltech.app.sms

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import androidx.work.*
import dev.fluttercommunity.workmanager.BackgroundWorker
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.TimeUnit

class MpesaSmsReceiver : BroadcastReceiver() {
    companion object {
        var channel: MethodChannel? = null

        // WorkManager plugin internals — must match SharedPreferenceHelper constants.
        private const val WM_PREFS = "flutter_workmanager_plugin"
        private const val WM_HANDLE_KEY =
            "dev.fluttercommunity.workmanager.CALLBACK_DISPATCHER_HANDLE_KEY"
        private const val WM_DART_TASK_KEY =
            "dev.fluttercommunity.workmanager.DART_TASK"
        private const val SYNC_TASK_NAME = "beltech.background.sync"
        private const val SMS_ONEOFF_UNIQUE = "beltech.background.sms-receive"

        fun setMethodChannel(ch: MethodChannel?) {
            channel = ch
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return

        val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
        if (messages.isNullOrEmpty()) return

        // goAsync() extends the broadcast window from 10 s to 30 s, giving
        // WorkManager.enqueue() and MethodChannel.invokeMethod() enough room.
        val pendingResult = goAsync()

        try {
            // Concatenate multi-part SMS from the same sender (preserves order).
            val grouped = LinkedHashMap<String, StringBuilder>()
            for (msg in messages) {
                val sender = msg.originatingAddress ?: continue
                grouped.getOrPut(sender) { StringBuilder() }.append(msg.messageBody ?: "")
            }

            var needsBackgroundSync = false

            for ((sender, bodyBuilder) in grouped) {
                val body = bodyBuilder.toString()
                if (body.isBlank()) continue
                val senderLower = sender.lowercase()
                val bodyLower = body.lowercase()
                val isMpesa = senderLower.contains("mpesa") ||
                    bodyLower.contains("m-pesa") ||
                    bodyLower.contains("mpesa") ||
                    (bodyLower.contains("confirmed") &&
                        (bodyLower.contains("ksh") || bodyLower.contains("kes")))
                if (!isMpesa) continue

                val ch = channel
                if (ch != null) {
                    // App is alive — forward to Flutter via MethodChannel.
                    ch.invokeMethod(
                        "onMpesaSmsReceived",
                        mapOf(
                            "sender" to sender,
                            "body" to body,
                            "timestamp" to System.currentTimeMillis(),
                        ),
                    )
                } else {
                    // App is killed — flag that we need a background sync so the SMS
                    // gets imported from the device inbox as soon as WorkManager fires.
                    needsBackgroundSync = true
                }
            }

            if (needsBackgroundSync) {
                triggerImmediateSync(context)
            }
        } finally {
            pendingResult.finish()
        }
    }

    /**
     * Enqueues an immediate one-off WorkManager task that calls [backgroundSyncDispatcher],
     * which reads the device SMS inbox and imports the new message.
     *
     * Guards against the cold-start case where the Dart side has never run (callback
     * handle not yet stored) — in that scenario WorkManager cannot invoke Flutter and
     * the periodic 15-minute sync will catch up on the next app open instead.
     */
    private fun triggerImmediateSync(context: Context) {
        val prefs = context.getSharedPreferences(WM_PREFS, Context.MODE_PRIVATE)
        val handle = prefs.getLong(WM_HANDLE_KEY, -1L)
        if (handle == -1L) return // WorkManager not yet initialized by Flutter

        val data = workDataOf(WM_DART_TASK_KEY to SYNC_TASK_NAME)

        val request = OneTimeWorkRequestBuilder<BackgroundWorker>()
            .setInputData(data)
            // Expedited = OS tries to run this within seconds; falls back to normal
            // work (no forced ForegroundService) if the expedited quota is exhausted.
            .setExpedited(OutOfQuotaPolicy.RUN_AS_NON_EXPEDITED_WORK_REQUEST)
            // If the task fails, WorkManager retries with exponential backoff
            // (10 s → 20 s → 40 s … capped by WorkManager's 5-hour limit).
            .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 10, TimeUnit.SECONDS)
            .build()

        WorkManager.getInstance(context)
            .enqueueUniqueWork(SMS_ONEOFF_UNIQUE, ExistingWorkPolicy.REPLACE, request)
    }
}
