package com.gather.checklist

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val serviceIntent = Intent(context, AlarmSoundService::class.java).apply {
            action = AlarmSoundService.ACTION_START
            putExtra(
                AlarmSoundService.EXTRA_REMINDER_ID,
                intent.getStringExtra(AlarmSoundService.EXTRA_REMINDER_ID),
            )
            putExtra(
                AlarmSoundService.EXTRA_REMINDER_TITLE,
                intent.getStringExtra(AlarmSoundService.EXTRA_REMINDER_TITLE),
            )
        }
        ContextCompat.startForegroundService(context, serviceIntent)
    }
}

class ReminderBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            ReminderScheduler.restore(context)
        }
    }
}
