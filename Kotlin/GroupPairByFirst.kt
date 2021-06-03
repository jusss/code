import arrow.mtl.extensions.eithert.monadState.get
import java.text.SimpleDateFormat
import java.util.*
import kotlin.collections.ArrayList
import kotlin.math.min

fun main() {

//    println(t2h(90001))
    val timestamp = System.currentTimeMillis()
    println(timestamp)

    val t1 = 1622597450L * 1000
    val t2 = 1622496450L * 1000
    val t3 = 1622395450L * 1000
    val t4 = 1622597950L * 1000
    val t5 = 1622498450L * 1000
    val t6 = 1622397750L * 1000

    val getLink = {alst: List<Pair<String, String>> -> alst.map { it.second }}
    val ab = arrayListOf<NaP>()
    val test1 = arrayListOf( "2020" to "abc", "2020" to "bce", "2021" to "wth")

    //  https://kotlinlang.org/api/latest/jvm/stdlib/kotlin.collections/group-by.html
    val test2 = test1.groupBy { it.first }
    test2.map {
        ab.add(NaP(it.key,(getLink(it.value))))
    }

    ab.map {
        println(it)
    }

    println(epoch2Date(t1,"year"))
    println(epoch2Date(t1,"month"))
    println(epoch2Date(t1,"day"))
}

data class NaP(val name: String, val value: List<String>)

fun epoch2Date(timestamp: Long, format: String) =
    when (format) {
        "year" -> SimpleDateFormat("yyyy").format(Date(timestamp))
        "month" -> SimpleDateFormat("yyyyMM").format(Date(timestamp))
        "day" -> SimpleDateFormat("yyyyMMdd").format(Date(timestamp))
        else -> "invalid format style"
}




//fun t2h(second: Long, minute: Long = 0, hour: Long = 0): String =
//    when {
//        (second > 60 ) -> t2h(second - 60, minute + 1, hour)
//        (minute > 60 ) -> t2h(second, minute - 60, hour + 1)
//        else -> hour.toString() + ":" + minute.toString() + ":" + second.toString()
//    }


fun humanTime(hour: Long, minute: Long, second: Long): String {
    val ss = if (second < 10) "0" + second.toString() else second.toString()
    val sm = if (minute < 10) "0" + minute.toString() + ":" else minute.toString() + ":"
    val sh = if (hour == 0L) "" else if (hour < 10) "0" + hour.toString() + ":" else hour.toString() + ":"
    return sh + sm + ss
}

fun t2h(second: Long, minute: Long = 0, hour: Long = 0): String =
    when {
        (second > 59 ) -> t2h(second - 60, minute + 1, hour)
        (minute > 59 ) -> t2h(second, minute - 60, hour + 1)
        else -> humanTime(hour,minute,second)
//                hour.toString() + ":" + minute.toString() + ":" + second.toString()
    }
