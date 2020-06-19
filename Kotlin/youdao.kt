import com.google.gson.GsonBuilder
import java.io.BufferedReader
import java.io.DataOutputStream
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest

object HashUtils {
    fun sha512(input: String) = hashString("SHA-512", input)
    fun sha256(input: String) = hashString("SHA-256", input)
    fun sha1(input: String) = hashString("SHA-1", input)
    private fun hashString(type: String, input: String): String {
        val HEX_CHARS = "0123456789abcdef"
        val bytes = MessageDigest
            .getInstance(type)
            .digest(input.toByteArray())
        val result = StringBuilder(bytes.size * 2)

        bytes.forEach {
            val i = it.toInt()
            result.append(HEX_CHARS[i shr 4 and 0x0f])
            result.append(HEX_CHARS[i and 0x0f])
        }
        return result.toString()
    }
}

fun truncate(q: String):String {
    if (q.length <= 20) return q
    else return q.take(10) + q.length.toString() + q.drop(q.length - 10)
}

fun connect(q: String): Unit {
    val endpoint = "https://openapi.youdao.com/api"
    val key = ""
    val token = ""

    val data = mutableMapOf<String,String>()
    data["from"] = "en"
    data["to"] = "zh-CHS"
    data["signType"] = "v3"
    val curtime = (System.currentTimeMillis()/1000).toString()
    data["curtime"] = curtime
    val salt = System.currentTimeMillis().toString()
    val signStr = key + truncate(q) + salt + curtime + token
    val sign = HashUtils.sha256(signStr)
    data["appKey"] = key
    data["q"] = q
    data["salt"] = salt
    data["sign"] = sign

    val gson = GsonBuilder().create()
    val url = URL(endpoint)

    val httpconn = url.openConnection()  as HttpURLConnection
    httpconn.requestMethod = "POST"
    httpconn.doOutput = true
    httpconn.doInput=true
    httpconn.setRequestProperty("charset", "utf-8")
    httpconn.setRequestProperty("Content-Type", "application/x-www-form-urlencoded")
    try {
        val outputStream: DataOutputStream = DataOutputStream(httpconn.outputStream)
        //print(data)
        // turn Map to URLRequests, {"a":"1","b":"2"} to "a=1&b=2"
        val postData = data.map { (k,v) -> "$k=$v"}.reduce{acc, str -> acc + "&" + str}
        println(postData)
        outputStream.write(postData.toByteArray(charset=Charsets.UTF_8))
        outputStream.flush()
    } catch (exception: Exception) {
        throw Exception("Exception while post  $exception.message")
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
        val map1 = gson.fromJson(result, Result::class.java)
        println(map1)
        println(map1.translation.first())

    } catch (exception: Exception) {
        throw Exception("Exception while get  $exception.message")
    }
}

data class Result(val translation: List<String>)

fun main(){
    connect("this is a test")
}

