package com.aldebaran.ks

import com.aldebaran.qi.Application
import com.aldebaran.qi.helper.EventCallback
import com.aldebaran.qi.helper.proxies.ALDialog
import com.aldebaran.qi.helper.proxies.ALMemory
import com.aldebaran.qi.CallError
import com.aldebaran.qi.helper.proxies.ALTextToSpeech



fun exitDialog(a:ALDialog,b:String,c:String){
    // exitDialog(dialog,topic,"myModule"
    a.deactivateTopic(b)
    a.unloadTopic(b)
    a.unsubscribe(c)
}

fun main(args: Array<String>) {
    println("AI")
    val robotUrl = "tcp://nao.local:9559"
    val application = Application(args, robotUrl)
    application.start()
    val session = application.session()
    val dialog = ALDialog(session)
    val memory = ALMemory(session)
    val tts = ALTextToSpeech(session)
    dialog.setLanguage("Chinese")
    val topic = dialog.loadTopic("/home/nao/java8/dialog_mnc.top")
    dialog.subscribe("myModule")
    dialog.activateTopic(topic)
    println("begin")

    // Subscribe to FrontTactilTouched event,
    // create an EventCallback expecting a Float.
/*    memory.subscribeToEvent(
        "FrontTactilTouched",
        object : EventCallback<Float> {
            override fun onEvent(arg0: Float): Unit = if (arg0 > 0) exitDialog(
                dialog,topic,"myModule"
            ) else
                tts.say("ouch!")
        })*/

    memory.subscribeToEvent(
        "FrontTactilTouched",
        EventCallback<Float> {
            if (it>0 )
                memory.raiseEvent("_touch", "初始事件测试")
            //else tts.say("ouch!")
        }
    )

    memory.subscribeToEvent(
        "_exit",
        EventCallback<String> {
            if (it == "end") exitDialog(dialog,topic,"myModule")
            //else tts.say("ouch!")
        }
    )


    application.run()
}
