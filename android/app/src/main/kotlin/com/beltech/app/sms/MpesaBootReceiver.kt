package com.beltech.app.sms

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.work.*
import dev.fluttercommunity.workmanager.BackgroundWorker
import java.util.concurrent.TimeUnit

/**
 * Re-registers the periodic WorkManager sync after a device reboot or app update.
 *
 * WorkManager persists scheduled work in its own database, but on some devices
 * (especially those running custom Android skins) the OS clears pending work on
 * reboot. Listening to these events and re-enqueueing with KEEP policy is safe:
 * if the task is already running it won't be replaced, and if it was wiped it
 * will be re-added with the correct 15-minute cadence.
 */
class MpesaBootReceiver : BroadcastReceiver() {
    companion object {
        private const val WM_PREFS = "flutter_workmanager_plugin"
        private const val WM_HANDLE_KEY =
            "dev.fluttercommunity.workmanager.CALLBACK_DISPATCHER_HANDLE_KEY"
        private const val WM_DART_TASK_KEY =
            "dev.fluttercommunity.workmanager.DART_TASK"
        private const val SYNC_TASK_NAME = "beltech.background.sync"
        private const val PERIODIC_UNIQUE_NAME = "com.beltech.app.sync"
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            -> Unit // proceed
            else -> return
        }

        // Guard: the Flutter dispatcher handle is only stored after the app has
        // been opened at least once. If it's absent we can't call Flutter headlessly,
        // so skip — the 15-minute periodic will register itself when the user next
        // opens the app and OsBackgroundSyncScheduler.initializeAndSchedule() runs.
        val prefs = context.getSharedPreferences(WM_PREFS, Context.MODE_PRIVATE)
        val handle = prefs.getLong(WM_HANDLE_KEY, -1L)
        if (handle == -1L) return

        val data = workDataOf(WM_DART_TASK_KEY to SYNC_TASK_NAME)

        val periodicRequest =
            PeriodicWorkRequestBuilder<BackgroundWorker>(15, TimeUnit.MINUTES)
                .setInputData(data)
                // Give the device 1 minute to fully boot before the first run.
                .setInitialDelay(1, TimeUnit.MINUTES)
                .setConstraints(
                    Constraints.Builder()
                        .setRequiresBatteryNotLow(true)
                        .build(),
                )
                .build()

        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            PERIODIC_UNIQUE_NAME,
            ExistingPeriodicWorkPolicy.KEEP,
            periodicRequest,
        )
    }
}
