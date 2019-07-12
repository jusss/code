package com.aldebaran.ks
import com.aldebaran.qi.Application
import com.aldebaran.qi.helper.proxies.ALTextToSpeech
import java.net.ServerSocket
fun main(args: Array<String>){
    val server = ServerSocket(50027)
    val msg = "hello from server"
    var aob = ByteArray(1024)

    val robotUrl = "tcp://nao.local:9559"
    // Create a new application
    val application = Application(args, robotUrl)
    // Start your application
    application.start()
    // Create an ALTextToSpeech object and link it to your current session
    val tts = ALTextToSpeech(application.session())
    tts.language = "Chinese"

    val client = server.accept()
    println("connected!")
    tts.say("已连接")
    client.outputStream.write(msg.toByteArray(Charsets.UTF_8))
    client.outputStream.flush()
    val size = client.inputStream.read(aob)
    //val recvMsg:String = aob.toString(Charsets.UTF_8)
    // don't use toString, it can not reverse toByteArray
    val recvMsg:String = String(aob.sliceArray(0 until size), Charsets.UTF_8)
    println(aob)
    //println(aob.toString(Charsets.UTF_8))

    // Make your robot say something
    //tts.say(recvMsg)  it's very strange, this won't work, but recvMsg.substring(0,2) work
    tts.say(recvMsg)
    println(recvMsg)
    client.close()
    server.close()
}