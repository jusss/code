import com.google.gson.GsonBuilder
import java.io.*
import java.net.HttpURLConnection
import java.net.URL
val gson = GsonBuilder().create()
val name = System.currentTimeMillis().toString()
val destUrl = "http://ip:8082/consumers/" + name
fun main() {
   step1()
   step2()
    step3()
}
fun step1(){

    val gson = GsonBuilder().create()
    var base_uri = ""

        val addr = destUrl
        val url = URL(addr)

            val httpconn = url.openConnection() as HttpURLConnection
            httpconn.requestMethod = "POST"
            httpconn.doOutput = true
            httpconn.setRequestProperty("Content-Type","application/vnd.kafka.v2+json")
            val value = mutableMapOf<String, String>()
            value["name"] = "my_consumer_instance"
            value["format"] = "json"
            value["auto.offset.reset"] = "earliest"
            try {
                val outputStream: DataOutputStream = DataOutputStream(httpconn.outputStream)
                outputStream.write(gson.toJson(value).toByteArray(charset=Charsets.UTF_8))
                outputStream.flush()
            } catch (exception: Exception) {
                throw Exception("Exception while push the notification  $exception.message")
            }
            try {
                val reader: BufferedReader = BufferedReader(InputStreamReader(httpconn.inputStream))
                val response = reader.readLine()
                println(response)
                //val map1 = gson.fromJson(response, Result::class.java)
                //base_uri = map1.base_uri
                //println(  "base uri is " + base_uri)

//                val addr2 = base_uri + "/subscription"
//
//                //val url2 = URL(addr2)
//                val url2 = URL("http://ip:8082/consumers/abc/instances/ff/subscription")
//                //println("this is subscription addr: " + addr2)
//                val httpconn2 = url2.openConnection() as HttpURLConnection
//                httpconn2.requestMethod = "POST"
//                httpconn2.doOutput = true    // mark one
//                httpconn2.setRequestProperty("Content-Type","application/vnd.kafka.v2+json")
//                try {
//                    val map2 = mutableMapOf<String, List<String>>()
//                    val vn = "jsontest"
//                    val v2 = mutableListOf<String>(vn)
//                    map2["topics"] = v2
//                    val outputStream2: DataOutputStream = DataOutputStream(httpconn2.outputStream)
//                    outputStream2.write(gson.toJson(map2).toByteArray(charset=Charsets.UTF_8))
//                    outputStream2.flush()
//                    println("this is post data: " + gson.toJson(map2))
//                    println("subscription success")
//                } catch (exception: Exception) {
//                    throw Exception("Exception while push the notification  $exception.message")
//                }
//                val url3 = URL("http://ip:8082/consumers/abc/instances/ff/records")
//                //val url3 = URL(base_uri + "/records")
//                //val url3 = URL("http://ip:8082/consumers/1604899966532/instances/kanye/records")
//                //println("this is get addr: " + base_uri + "/records")
//                val httpconn3 = url3.openConnection() as HttpURLConnection
//                httpconn3.requestMethod = "GET"
//                //httpconn3.doOutput = true
//                //httpconn3.doInput = true
//                httpconn3.setRequestProperty("Accept","application/vnd.kafka.json.v2+json")
//                println("start get...")
//                //println(base_uri+"/records")
//                //error
//
//                try {
//
//                    val reader3: BufferedReader = BufferedReader(InputStreamReader(httpconn3.inputStream))
//                    val msg = reader3.readLine()
//                    print(msg)
//                } catch (exception: Exception) {
//                    throw Exception("Exception while push the notification  $exception.message")
//                }

            } catch (exception: Exception) {
                throw Exception("Exception while push the notification  $exception.message")
            }
        }



fun step2(){
                   // val addr2 = base_uri + "/subscription"

                //val url2 = URL(addr2)
                val url2 = URL(destUrl + "/instances/my_consumer_instance/subscription")
                //println("this is subscription addr: " + addr2)
                val httpconn2 = url2.openConnection() as HttpURLConnection
                httpconn2.requestMethod = "POST"
                httpconn2.doOutput = true    // mark one
                httpconn2.setRequestProperty("Content-Type","application/vnd.kafka.v2+json")
                try {
                    val map2 = mutableMapOf<String, List<String>>()

                    map2["topics"] = listOf("hezi")

                    val outputStream2: DataOutputStream = DataOutputStream(httpconn2.outputStream)
                    val a = "{\"topics\":[\"jsontest\"]}"
                    outputStream2.write(gson.toJson(map2).toString().toByteArray())
                    outputStream2.flush()
                    println("this is post data: " + gson.toJson(map2))
                    println("subscription success")

                } catch (exception: Exception) {
                    throw Exception("Exception while push the notification  $exception.message")
                }


    try {
        val reader: BufferedReader = BufferedReader(InputStreamReader(httpconn2.inputStream))
        val response = reader.readLine()
        println(response)

    } catch (exception: Exception) {
        throw Exception("Exception while push the notification  $exception.message")
    }
}




data class Result(val base_uri: String)
data class KafkaMsg(val value: Map<String, String>)

fun step3(){
    val url3 = URL(destUrl + "/instances/my_consumer_instance/records")
    //val url3 = URL(base_uri + "/records")
    //val url3 = URL("http://ip:82/consumers/1604899966532/instances/kanye/records")
    //println("this is get addr: " + base_uri + "/records")
    val httpconn3 = url3.openConnection() as HttpURLConnection
    httpconn3.requestMethod = "GET"
    //httpconn3.doOutput = true
    //httpconn3.doInput = true
    httpconn3.setRequestProperty("Accept","application/vnd.kafka.json.v2+json")
    println("start get...")
    //println(base_uri+"/records")
 

    try {

        val reader3: BufferedReader = BufferedReader(InputStreamReader(httpconn3.inputStream))
        val msg = reader3.readLine()
        println(msg)
        val objectList = gson.fromJson(msg, Array<KafkaMsg>::class.java).asList()
        val result = objectList.first().value
        println(result.get("foo"))


    } catch (exception: Exception) {
        throw Exception("Exception while push the notification  $exception.message")
    }

}
