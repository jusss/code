package com.example.simpletimer

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import android.widget.Toast
import androidx.core.app.NotificationCompat
import com.example.simplerecorder.OnlyAudioRecorder


class RecordingService: Service() {

    lateinit var audioRecord: OnlyAudioRecorder

    override fun onBind(p0: Intent?): IBinder? {
        return null
    }

    override fun onCreate() {
        super.onCreate()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = "newChannelId"
            val channelName = "channelName"
            val channel =
                NotificationChannel(channelId, channelName, NotificationManager.IMPORTANCE_LOW)
            val manager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
            val notification: Notification =
                NotificationCompat.Builder(this, channelId).setAutoCancel(true)
                    .setCategory(Notification.CATEGORY_SERVICE).setOngoing(true)
                    .setPriority(NotificationManager.IMPORTANCE_LOW).build()
            startForeground(1, notification)
        }

        audioRecord = OnlyAudioRecorder.instance
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {

        audioRecord.startRecord()

        val name=intent?.getStringExtra("name")
        Toast.makeText(
            applicationContext, "Service has started running in the background",
            Toast.LENGTH_SHORT
        ).show()
        if (name != null) {
            Log.d("Service Name",name)
        }
        Log.d("Service Status","Starting Service")
        for (i in 1..10)
        {
            Thread.sleep(100)
            Log.d("Status", "Service $i")
        }
//        stopSelf()
        return START_STICKY
    }

    override fun stopService(name: Intent?): Boolean {
        Log.d("Stopping","Stopping Service")

        return super.stopService(name)
    }

    override fun onDestroy() {

        audioRecord.stopRecord()

        Toast.makeText(
            applicationContext, "Service execution completed",
            Toast.LENGTH_SHORT
        ).show()
        Log.d("Stopped","Service Stopped")
        super.onDestroy()
    }

}

