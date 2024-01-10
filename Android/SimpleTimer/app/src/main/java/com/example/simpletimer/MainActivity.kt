package com.example.simpletimer

import android.Manifest
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Build.VERSION.SDK_INT
import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import android.os.Environment
import android.provider.ContactsContract.Intents.Insert.ACTION
import android.provider.Settings
import android.provider.SyncStateContract
import android.util.Log.d
import android.widget.Button
import android.widget.TextView
import androidx.core.app.ActivityCompat
import com.example.simplerecorder.OnlyAudioRecorder
import kotlinx.coroutines.*
import java.util.logging.Logger

class MainActivity : AppCompatActivity() {

    fun askPermissions(){
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val strings = arrayOfNulls<String>(12)
            strings[0] = Manifest.permission.WRITE_EXTERNAL_STORAGE
            strings[1] = Manifest.permission.READ_EXTERNAL_STORAGE
//            strings[2] = Manifest.permission.ACCESS_NETWORK_STATE
//            strings[3] = Manifest.permission.ACCESS_WIFI_STATE
//            strings[4] = Manifest.permission.READ_PHONE_STATE
//            strings[5] = Manifest.permission.INTERNET
//            strings[6] = Manifest.permission.CAMERA
//            strings[7] = Manifest.permission.WRITE_APN_SETTINGS
//            strings[8] = Manifest.permission.ACCESS_COARSE_LOCATION
//            strings[9] = Manifest.permission.ACCESS_FINE_LOCATION
            strings[2] = Manifest.permission.RECORD_AUDIO
//            strings[11] = Manifest.permission.SYSTEM_ALERT_WINDOW
            ActivityCompat.requestPermissions(this, strings, 100)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            if (!Environment.isExternalStorageManager()) {
                val uri = Uri.parse("package:${BuildConfig.APPLICATION_ID}")
                startActivity(
                        Intent(
                                Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
                                uri
                        )
                )
            }
        }
    }

    fun onRequestPermissionResult(requestCode: Int, permissions: List<String>, grantResults: List<Int>) {
        if (requestCode == 100) {
            if (grantResults.map { it == 0 }.contains(false)) this.finish()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        askPermissions()

//        val audioRecord = OnlyAudioRecorder.instance
//        findViewById<Button>(R.id.startRec).setOnClickListener {  audioRecord.startRecord()}
//        findViewById<Button>(R.id.stopRec).setOnClickListener {  audioRecord.stopRecord()}

        val updateUI = Job()
        val uiScope = CoroutineScope(Dispatchers.Main + updateUI)


        findViewById<Button>(R.id.startRec).setOnClickListener{
            uiScope.launch {
                withContext(Dispatchers.Main) {
                    val showTextView = findViewById<TextView>(R.id.text1)

//                    audioRecord.startRecord()
                    showTextView.text = "recording..."

//                    https://www.geeksforgeeks.org/foreground-service-in-android/
//                    https://dhexx.cn/news/show-4555137.html?action=onClick

                    val intent=Intent(applicationContext,RecordingService::class.java)
                    intent.putExtra("name","Geek for Geeks")
                    startForegroundService(intent)
//                    startService(intent)


                }
            }
        }

        findViewById<Button>(R.id.stopRec).setOnClickListener{
            uiScope.launch {
                withContext(Dispatchers.Main) {
                    val showTextView = findViewById<TextView>(R.id.text1)
//                    audioRecord.stopRecord()
                    showTextView.text="stopped"

                    val intent=Intent(applicationContext,RecordingService::class.java)
                    intent.putExtra("name","Geek for Geeks")
                    stopService(intent)
                }
            }

        }


    }




}