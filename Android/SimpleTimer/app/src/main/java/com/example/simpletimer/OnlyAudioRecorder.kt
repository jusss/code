package com.example.simplerecorder


import android.media.AudioFormat;
import android.media.AudioRecord;
import android.media.MediaRecorder;
import android.os.Bundle;
import android.os.Environment;
import android.view.MotionEvent;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import kotlinx.coroutines.*;
import java.io.BufferedOutputStream;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.time.LocalDateTime;
import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.File;
import java.io.InputStreamReader;
import java.lang.StringBuilder;
import java.net.HttpURLConnection;
import java.net.URL;
import java.security.MessageDigest;
import java.util.*;

class OnlyAudioRecorder private constructor(){
    //1.设置录音相关参数,音频采集源、采样率、声道、数据格式
    //2.计算最小录音缓存区大小
    //3.创建audioRecord对象
    //4.开始录音
    //5.创建文件用于保存PCM文件
    //6.录音完毕，关闭录音及释放相关资源
    //7.将pcm文件转换为WAV文件

    companion object{
        private const val TAG:String = "OnlyAudioRecorder"
        private const val AudioSource = MediaRecorder.AudioSource.MIC//生源
        private const val SampleRate = 16000//采样率
        private const val Channel = AudioFormat.CHANNEL_IN_MONO//单声道
        private const val EncodingType = AudioFormat.ENCODING_PCM_16BIT//数据格式


        //double check单例
        val instance:OnlyAudioRecorder by lazy (mode = LazyThreadSafetyMode.SYNCHRONIZED){
            OnlyAudioRecorder()
        }
    }

    private var bufferSizeInByte:Int = 0//最小录音缓存区
    private var audioRecorder:AudioRecord? = null//录音对象
    private var isRecord = false

    private fun initRecorder() {//初始化audioRecord对象

        bufferSizeInByte = AudioRecord.getMinBufferSize(SampleRate, Channel, EncodingType)
        audioRecorder = AudioRecord(AudioSource, SampleRate, Channel,
                EncodingType, bufferSizeInByte)
    }

    fun startRecord():Int {

        if (isRecord) {
            return -1
        } else{

            audioRecorder?: initRecorder()
            audioRecorder?.startRecording()
            isRecord = true

            AudioRecordToFile().start()
            return 0
        }
    }

    fun stopRecord() {

        audioRecorder?.stop()
        audioRecorder?.release()
        isRecord = false
        audioRecorder = null
    }

    private fun writeDateTOFile(PCMPath: String) {

        var audioData = ByteArray(bufferSizeInByte)

        val file = File(PCMPath)
        if (!file.parentFile.exists()) {

            file.parentFile.mkdirs()
        }
        if (file.exists()) {
            file.delete()
        }
        file.createNewFile()
        val out = BufferedOutputStream(FileOutputStream(file))
        var length = 0
        while (isRecord && audioRecorder!=null) {
            length = audioRecorder!!.read(audioData, 0, bufferSizeInByte)//获取音频数据
            if (AudioRecord.ERROR_INVALID_OPERATION != length) {
                out.write(audioData, 0, length)//写入文件
                out.flush()
            }
        }
        out.close()
    }

    //将pcm格式的文件转换为WAV格式的
    private fun copyWaveFile(pcmPath: String, wavPath: String) {

        var fileIn = FileInputStream(pcmPath)
        var fileOut = FileOutputStream(wavPath)
        val data = ByteArray(bufferSizeInByte)
        val totalAudioLen = fileIn.channel.size()
        val totalDataLen = totalAudioLen + 36
        writeWaveFileHeader(fileOut, totalAudioLen, totalDataLen)
        var count = fileIn.read(data, 0, bufferSizeInByte)
        while (count != -1) {
            fileOut.write(data, 0, count)
            fileOut.flush()
            count = fileIn.read(data, 0, bufferSizeInByte)
        }
        fileIn.close()
        fileOut.close()
    }

    //添加WAV格式的文件头
    private fun writeWaveFileHeader(out:FileOutputStream , totalAudioLen:Long,
            totalDataLen:Long){

        val channels = 1
        val byteRate = 16 * SampleRate * channels / 8
        val header = ByteArray(44)
        header[0] = 'R'.toByte()
        header[1] = 'I'.toByte()
        header[2] = 'F'.toByte()
        header[3] = 'F'.toByte()
        header[4] = (totalDataLen and 0xff).toByte()
        header[5] = (totalDataLen shr 8 and 0xff).toByte()
        header[6] = (totalDataLen shr 16 and 0xff).toByte()
        header[7] = (totalDataLen shr 24 and 0xff).toByte()
        header[8] = 'W'.toByte()
        header[9] = 'A'.toByte()
        header[10] = 'V'.toByte()
        header[11] = 'E'.toByte()
        header[12] = 'f'.toByte() // 'fmt ' chunk
        header[13] = 'm'.toByte()
        header[14] = 't'.toByte()
        header[15] = ' '.toByte()
        header[16] = 16 // 4 bytes: size of 'fmt ' chunk
        header[17] = 0
        header[18] = 0
        header[19] = 0
        header[20] = 1 // format = 1
        header[21] = 0
        header[22] = channels.toByte()
        header[23] = 0
        header[24] = (SampleRate and 0xff).toByte()
        header[25] = (SampleRate shr 8 and 0xff).toByte()
        header[26] = (SampleRate shr 16 and 0xff).toByte()
        header[27] = (SampleRate shr 24 and 0xff).toByte()
        header[28] = (byteRate and 0xff).toByte()
        header[29] = (byteRate shr 8 and 0xff).toByte()
        header[30] = (byteRate shr 16 and 0xff).toByte()
        header[31] = (byteRate shr 24 and 0xff).toByte()
        header[32] = (2 * 16 / 8).toByte() // block align
        header[33] = 0
        header[34] = 16 // bits per sample
        header[35] = 0
        header[36] = 'd'.toByte()
        header[37] = 'a'.toByte()
        header[38] = 't'.toByte()
        header[39] = 'a'.toByte()
        header[40] = (totalAudioLen and 0xff).toByte()
        header[41] = (totalAudioLen shr 8 and 0xff).toByte()
        header[42] = (totalAudioLen shr 16 and 0xff).toByte()
        header[43] = (totalAudioLen shr 24 and 0xff).toByte()
        out.write(header, 0, 44)
    }



    private inner class AudioRecordToFile : Thread() {

        override fun run() {
            super.run()
            val fileName = System.currentTimeMillis().toString() + ".pcm"
            val PCMPath = Environment.getExternalStorageDirectory().path.toString()+"/Recordings/" + fileName
            val WAVPath = PCMPath + ".wav"
            val dir = File (Environment.getExternalStorageDirectory().path.toString(), "/Recordings/")
            println(PCMPath)
            if (!dir.exists()){
                dir.mkdirs()

            }
            writeDateTOFile(PCMPath)
            copyWaveFile(PCMPath, WAVPath)
        }
    }
}
