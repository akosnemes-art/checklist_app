package com.gather.checklist

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import java.util.Locale

class AlarmSoundService : Service() {
    companion object {
        const val ACTION_START = "com.gather.checklist.START_ALARM"
        const val ACTION_STOP = "com.gather.checklist.STOP_ALARM"
        const val EXTRA_REMINDER_ID = "reminderId"
        const val EXTRA_REMINDER_TITLE = "reminderTitle"

        private const val CHANNEL_ID = "checklist_reminders"
        private const val NOTIFICATION_ID = 4202
    }

    private var player: MediaPlayer? = null
    private var audioFocusRequest: AudioFocusRequest? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopAlarm()
            return START_NOT_STICKY
        }

        val strings = alarmLanguageContext()
        createNotificationChannel(strings)
        val title = intent?.getStringExtra(EXTRA_REMINDER_TITLE)
            ?.takeIf { it.isNotBlank() }
            ?: strings.getString(R.string.checklist_reminder)
        startForeground(NOTIFICATION_ID, buildNotification(title, strings))
        startAlarmSound()
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        releasePlayer()
        super.onDestroy()
    }

    private fun alarmLanguageContext(): Context {
        // Legacy Flutter SharedPreferences stores this setting for offline alarms.
        val preference = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
            .getString("flutter.checklist.language.v1", null)
        val language = when (preference) {
            "hungarian" -> "hu"
            "french" -> "fr"
            "czech" -> "cs"
            "german" -> "de"
            "chinese" -> "zh-CN"
            else -> "en"
        }
        return createConfigurationContext(Configuration(resources.configuration).apply {
            setLocale(Locale.forLanguageTag(language))
        })
    }

    private fun createNotificationChannel(strings: Context) {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channel = NotificationChannel(
            CHANNEL_ID,
            strings.getString(R.string.alarm_channel_name),
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = strings.getString(R.string.alarm_channel_description)
            setSound(null, null)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        }
        manager.createNotificationChannel(channel)
    }

    private fun buildNotification(title: String, strings: Context): Notification {
        val openIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val stopIntent = PendingIntent.getService(
            this,
            1,
            Intent(this, AlarmSoundService::class.java).apply { action = ACTION_STOP },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(resources.getIdentifier("checklist_logo", "mipmap", packageName))
            .setContentTitle(title)
            .setContentText(strings.getString(R.string.checklist_reminder))
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setAutoCancel(false)
            .setContentIntent(openIntent)
            .addAction(0, strings.getString(R.string.stop_alarm), stopIntent)
            .build()
    }

    private fun startAlarmSound() {
        if (player?.isPlaying == true) return
        releasePlayer()
        val alarmUri = RingtoneManager.getActualDefaultRingtoneUri(
            this,
            RingtoneManager.TYPE_ALARM,
        ) ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
        val attributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        audioFocusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE)
            .setAudioAttributes(attributes)
            .build()
            .also(audioManager::requestAudioFocus)
        player = MediaPlayer().apply {
            setAudioAttributes(attributes)
            setWakeMode(applicationContext, PowerManager.PARTIAL_WAKE_LOCK)
            setDataSource(applicationContext, alarmUri)
            isLooping = true
            prepare()
            start()
        }
    }

    private fun stopAlarm() {
        releasePlayer()
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun releasePlayer() {
        player?.run {
            if (isPlaying) stop()
            release()
        }
        player = null
        audioFocusRequest?.let {
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            audioManager.abandonAudioFocusRequest(it)
        }
        audioFocusRequest = null
    }
}
