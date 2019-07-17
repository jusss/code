package com.aldebaran.ks
import com.aldebaran.qi.Application
import com.aldebaran.qi.helper.proxies.ALTextToSpeech
import com.aldebaran.qi.helper.proxies.ALAnimatedSpeech
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import java.lang.Exception
import java.net.ServerSocket
import java.net.Socket

sealed class Either<A,B>
data class Left<A,B>(val v:A): Either<A,B>()
data class Right<A,B>(val v:B): Either<A,B>()

fun netInit(a:Either<ALTextToSpeech,ALAnimatedSpeech>, server:ServerSocket): Socket{
    var client = server.accept()
    println("connected!")
    when (a){
        is Left -> a.v.say("已连接")
        is Right -> a.v.say("已连接")
    }
    //val msg = "hello from server"
    //client.outputStream.write(msg.toByteArray(Charsets.UTF_8))
    //client.outputStream.flush()
    return client
}

fun main(args: Array<String>){
    val intro = Intro()
    val robotUrl = "tcp://nao.local:9559"
    val application = Application(args, robotUrl)
    application.start()
    val ttsl = Left<ALTextToSpeech,ALAnimatedSpeech>(ALTextToSpeech(application.session()))
    val ttsr = Right<ALTextToSpeech,ALAnimatedSpeech>(ALAnimatedSpeech(application.session()))
    ttsl.v.language = "Chinese"
    val server = ServerSocket(50009)
    var size:Int = 0
    var recvMsg:String
    var outputMsg:List<String>
    var aob = ByteArray(1024)
    var client = netInit(ttsl, server)
    var sayMsg:String?
    while (true) {
        // shutdown without exit signal
        try {
            size = client.inputStream.read(aob)
        }
        catch(e: Exception) {
            ttsl.v.say("网络异常已断开")
            client.close()
            client = netInit(ttsl,server)
        }
        //shutdown with exit signal
        if (size == -1) {
            ttsl.v.say("客户中断连接")
            client.close()
            client = netInit(ttsl,server)
        }
        recvMsg = String(aob.sliceArray(0 until size), Charsets.UTF_8)
        println(recvMsg)
        if (recvMsg.contains("end")) {
                ttsl.v.say("程序结束")
                break
        }
        outputMsg = recvMsg.split("\r\n")
        if (outputMsg.size >= 2) {
                ttsl.v.stopAll()
                sayMsg = intro.duce[
                    outputMsg[outputMsg.size - 2]
                    ]
                if (sayMsg != null) {
                    GlobalScope.launch {
                        ttsr.v.say( sayMsg
                        )
                    }
                }
/*                else{
                    ttsr.v.say("你滑动的太快了")
                }*/
                //println(outputMsg[outputMsg.size - 2])
        }
    }
    client.close()
    server.close()
}