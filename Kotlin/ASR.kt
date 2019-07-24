//package com.aldebaran.ks

import java.io.BufferedReader
import java.io.DataOutputStream
import java.io.File
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest
import java.util.*

fun _curlmd5(src:String):String{
    val md = MessageDigest.getInstance("MD5")
    val resultByte = md.digest(src.toByteArray(Charsets.UTF_8))
    return resultByte.joinToString("") {
        String.format("%02x", it)
    }
}

fun getHeader(aue:String,engineType:String):Map<String,String>{
    val APPID = "x"  // change your appid here
    val API_KEY = "x"  // change your api key here
    val time_stamp = System.currentTimeMillis()/1000
    val curTime = time_stamp.toString()
    //val curTime = "1563961545"
    val paramBase64 = "eyJhdWUiOiJyYXciLCJlbmdpbmVfdHlwZSI6InNtczE2ayJ9"
    val checkSum = _curlmd5(API_KEY + curTime + paramBase64)
    val header = mutableMapOf<String,String>()
    header["X-CurTime"] = curTime
    header["X-Param"] = paramBase64
    header["X-Appid"] = APPID
    header["X-CheckSum"] = checkSum
    header["Content-Type"] = "application/x-www-form-urlencoded; charset=utf-8"
    println(header)

    return header
}

fun getBody(filePath:String):String{
    val binFile =  File(filePath).inputStream().readBytes()
    val data =  Base64.getEncoder().encodeToString(binFile)
    //val a = mutableMapOf<String,String>("audio" to data)
    //println(a)
    return data
}
fun main() {
    val addr = "http://api.xfyun.cn/v1/service/v1/iat"
    val url = URL(addr)
    val httpconn = url.openConnection()  as HttpURLConnection
    httpconn.requestMethod = "POST"
    httpconn.doOutput = true
    val header = getHeader("raw","sms16k")
    header.forEach {
        k,v ->
        httpconn.setRequestProperty(k,v)
    }

    try {
        val outputStream: DataOutputStream = DataOutputStream(httpconn.outputStream)
        outputStream.write( ("audio=" + getBody("/tmp/7.ogg")).toByteArray(Charsets.UTF_8))
        outputStream.flush()
    } catch (exception: Exception) {
        throw Exception("Exception while push the notification  $exception.message")
    }


    try {
        val reader: BufferedReader = BufferedReader(InputStreamReader(httpconn.inputStream))
        var output = reader.readLine()
        var result = ""
        while (output != null){
            result += output
            output = reader.readLine()
        }
        println(result)
        //return result
    } catch (exception: Exception) {
        throw Exception("Exception while push the notification  $exception.message")
    }
}
















