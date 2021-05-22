import kotlin.math.min

fun main() {

    println(t2h(90001))

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
