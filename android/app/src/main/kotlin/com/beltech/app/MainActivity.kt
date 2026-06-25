package com.beltech.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.SystemClock
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.plugin.common.MethodChannel
import com.beltech.app.sms.MpesaSmsReceiver
import kotlin.system.exitProcess

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val smsChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "beltech.app/sms"
        )
        MpesaSmsReceiver.setMethodChannel(smsChannel)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "beltech/app_control"
        ).setMethodCallHandler { call, result ->
            if (call.method != "restartApp") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
                ?.apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
                }

            if (launchIntent == null) {
                result.error("launch_intent_missing", "Unable to relaunch app.", null)
                return@setMethodCallHandler
            }

            val pendingIntent = PendingIntent.getActivity(
                this,
                1001,
                launchIntent,
                PendingIntent.FLAG_CANCEL_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            alarmManager.setExact(
                AlarmManager.ELAPSED_REALTIME,
                SystemClock.elapsedRealtime() + 200,
                pendingIntent
            )

            result.success(true)
            window.decorView.post {
                finishAffinity()
                exitProcess(0)
            }
        }
    }
}
