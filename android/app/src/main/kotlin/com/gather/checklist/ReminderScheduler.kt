package com.gather.checklist

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri

data class ChecklistReminder(
    val id: String,
    val title: String,
    val timeMillis: Long,
)

object ReminderScheduler {
    private const val PREFS_NAME = "checklist.nativeReminders.v1"
    private const val TIME_PREFIX = "time:"
    private const val TITLE_PREFIX = "title:"

    fun sync(context: Context, reminders: List<ChecklistReminder>) {
        val preferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val incomingIds = reminders.mapTo(mutableSetOf()) { it.id }
        val storedIds = preferences.all.keys
            .filter { it.startsWith(TIME_PREFIX) }
            .map { it.removePrefix(TIME_PREFIX) }

        for (id in storedIds) {
            if (id !in incomingIds) cancel(context, id)
        }
        for (reminder in reminders) {
            if (reminder.timeMillis > System.currentTimeMillis()) {
                schedule(context, reminder)
            } else {
                cancel(context, reminder.id)
            }
        }
    }

    fun restore(context: Context) {
        val preferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val reminders = preferences.all.entries.mapNotNull { (key, value) ->
            if (!key.startsWith(TIME_PREFIX) || value !is Long) return@mapNotNull null
            val id = key.removePrefix(TIME_PREFIX)
            val title = preferences.getString("$TITLE_PREFIX$id", null) ?: return@mapNotNull null
            ChecklistReminder(id = id, title = title, timeMillis = value)
        }
        sync(context, reminders)
    }

    private fun schedule(context: Context, reminder: ChecklistReminder) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val alarmIntent = alarmPendingIntent(context, reminder)
        val showIntent = PendingIntent.getActivity(
            context,
            reminder.id.hashCode(),
            Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        alarmManager.setAlarmClock(
            AlarmManager.AlarmClockInfo(reminder.timeMillis, showIntent),
            alarmIntent,
        )
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putLong("$TIME_PREFIX${reminder.id}", reminder.timeMillis)
            .putString("$TITLE_PREFIX${reminder.id}", reminder.title)
            .apply()
    }

    private fun cancel(context: Context, id: String) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            data = reminderUri(id)
        }
        PendingIntent.getBroadcast(
            context,
            id.hashCode(),
            intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
        )?.let {
            alarmManager.cancel(it)
            it.cancel()
        }
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .remove("$TIME_PREFIX$id")
            .remove("$TITLE_PREFIX$id")
            .apply()
    }

    private fun alarmPendingIntent(
        context: Context,
        reminder: ChecklistReminder,
    ): PendingIntent {
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            data = reminderUri(reminder.id)
            putExtra(AlarmSoundService.EXTRA_REMINDER_ID, reminder.id)
            putExtra(AlarmSoundService.EXTRA_REMINDER_TITLE, reminder.title)
        }
        return PendingIntent.getBroadcast(
            context,
            reminder.id.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun reminderUri(id: String): Uri =
        Uri.parse("checklist://reminder/${Uri.encode(id)}")
}
