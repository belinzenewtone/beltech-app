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
        for (msg in messages) {
            val sender = msg.originatingAddress ?: ""
            val body = msg.messageBody ?: ""

            if (sender.lowercase().contains("mpesa")) {
                channel?.invokeMethod("onMpesaSmsReceived", mapOf(
                    "sender" to sender,
                    "body" to body,
                    "timestamp" to System.currentTimeMillis()
                ))
            }
        }
    }
}
