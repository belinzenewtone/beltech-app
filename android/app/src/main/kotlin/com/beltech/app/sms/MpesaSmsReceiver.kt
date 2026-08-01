package com.beltech.app.sms

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import io.flutter.plugin.common.MethodChannel

class MpesaSmsReceiver : BroadcastReceiver() {
    companion object {
        var channel: MethodChannel? = null

        fun setMethodChannel(ch: MethodChannel?) {
            channel = ch
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return

        val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
        if (messages.isNullOrEmpty()) return

        // Concatenate multi-part SMS from the same sender (preserves order).
        val grouped = LinkedHashMap<String, StringBuilder>()
        for (msg in messages) {
            val sender = msg.originatingAddress ?: continue
            grouped.getOrPut(sender) { StringBuilder() }.append(msg.messageBody ?: "")
        }

        for ((sender, bodyBuilder) in grouped) {
            val body = bodyBuilder.toString()
            if (body.isBlank()) continue
            val senderLower = sender.lowercase()
            val bodyLower = body.lowercase()
            // Forward if official M-PESA sender OR body contains M-Pesa keywords.
            val isMpesa = senderLower.contains("mpesa") ||
                bodyLower.contains("m-pesa") ||
                bodyLower.contains("mpesa") ||
                (bodyLower.contains("confirmed") &&
                    (bodyLower.contains("ksh") || bodyLower.contains("kes")))
            if (isMpesa) {
                channel?.invokeMethod("onMpesaSmsReceived", mapOf(
                    "sender" to sender,
                    "body" to body,
                    "timestamp" to System.currentTimeMillis()
                ))
            }
        }
    }
}
