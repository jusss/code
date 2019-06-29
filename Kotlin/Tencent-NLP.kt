import com.google.gson.GsonBuilder
import java.io.BufferedReader
import java.io.DataOutputStream
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder
import java.security.MessageDigest

fun curlmd5(src:String):String{
    val md = MessageDigest.getInstance("MD5")
    val resultByte = md.digest(src.toByteArray(Charsets.UTF_8))
    return resultByte.joinToString("") {
        String.format("%02x", it).toUpperCase()
    }
}

fun get_params(question:String): String{
    val STRING_LENGTH = 10;
    val ALPHANUMERIC_REGEX = "[a-zA-Z0-9]+";
    val charPool: List<Char> = ('a'..'z') + ('A'..'Z') + ('0'..'9')
    val randomString = (1..STRING_LENGTH)
        .map { i -> kotlin.random.Random.nextInt(0, charPool.size) }
       .map(charPool::get)
        .joinToString("");
    val time_stamp = System.currentTimeMillis()/1000
    val app_key="URY2h67ATeRGJIRK"
    val paramsDict = mutableMapOf<String, String>()
    // in python we can use urllib.urlencode(dict) to do urlencode, but in java we have to do URLEncoder.encode(str,"UTF-8") for string value in key-value Map
    paramsDict["app_id"] = "2111117142"
    paramsDict["question"] = URLEncoder.encode(question, "UTF-8")
    paramsDict["time_stamp"] = time_stamp.toString()
    paramsDict["nonce_str"] = URLEncoder.encode(randomString, "UTF-8")
    paramsDict["session"] = "10000"
    var signBefore =""
    for (key in paramsDict.toSortedMap().keys){
        signBefore = signBefore + key + "=" + paramsDict[key] + "&"
    }
    var signB = signBefore
    signBefore = signBefore + "app_key=" + app_key
    println(signBefore)
    paramsDict["sign"] = curlmd5(signBefore)
    signB = signB + "sign=" + paramsDict["sign"]
    println("this is the signB $signB")
    return signB
    //return paramsDict
}

fun sendw(question: String):String{
    val gson = GsonBuilder().create()
    val result = get_params(question)
    println("this is the para $result")
    val res = khttp.post(
        url = "https://api.ai.qq.com/fcgi-bin/nlp/nlp_textchat",
        headers = mapOf("Content-Type" to "application/x-www-form-urlencoded;charset=utf-8"),
        data = result
    )
    return res.text
}

fun get_content(question: String){
    val gson = GsonBuilder().create()
    val url = URL("https://api.ai.qq.com/fcgi-bin/nlp/nlp_textchat")
    //val url = URL("http://openapi.tuling123.com/openapi/api/v2")
    //val sendDataStr  = gson.toJson(get_params(question))
    //val sendDataStr = """{"question": "hello", 'nonce_str': 'iyhGnB0AkL', 'app_id': '2111117142', 'sign': 'AA354827F740CC9A0546F54E3A9AB06A', 'session': '10000', 'time_stamp': '1561651456'}"""
    //val sendDataStr = """{"reqType": 0, "perception": {"inputText": {"text": "hi"}, "inputImage": {"url": "imageUrl"}, "selfInfo": {"location": {"city": "北京", "province": "北京", "street": "信息路"}}}, "userInfo": {"apiKey": "79229c49d0014c68ab90b9282ebf7156", "userId": "360371"}}"""
    val sendDataStr = get_params(question)
    //val sendData = URLEncoder.encode(sendDataStr, "UTF-8");
    println(sendDataStr)
    //println(sendData)
    val httpconn = url.openConnection()  as HttpURLConnection
    httpconn.requestMethod = "POST"
    httpconn.doOutput = true
    //httpconn.doInput=true
    httpconn.setRequestProperty("charset", "utf-8")
    //httpconn.setRequestProperty("Content-lenght", postData.size.toString())
    httpconn.setRequestProperty("Content-Type", "application/x-www-form-urlencoded")
    try {
        val outputStream: DataOutputStream = DataOutputStream(httpconn.outputStream)
        //outputStream.write(sendData.toByteArray())
        //outputStream.writeBytes("question=hello&nonce_str=J1I6KRUyTE&app_id=2111117142&sign=5958E8A48FDA6885644C0DC6A7AC97EC&session=10000&time_stamp=1561784968")
        outputStream.write(get_params(question).toByteArray(charset=Charsets.UTF_8))

        //outputStream.writeBytes("question=%B1%B1%BE%A9%B5%C4%CC%EC%C6%F8&nonce_str=Jwfh0F5nq3&app_id=2111117142&sign=67424E72EADA8E5B788F985E5408BE7C&session=10000&time_stamp=1561785707")
        outputStream.flush()
    } catch (exception: Exception) {

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
        } catch (exception: Exception) {
            throw Exception("Exception while push the notification  $exception.message")
        }

}

/*    with(url.openConnection() as HttpURLConnection) {
        // optional default is GET
        setDoInput(true)
        setRequestMethod("POST")
        setDoOutput(true)
        setRequestProperty("Charset", "UTF-8")
        *//*  val wr = OutputStreamWriter(getOutputStream(), "UTF-8");
          wr.write(sendDataStr)
          wr.flush()*//*;
        val wr = DataOutputStream(getOutputStream())
        //wr.writeBytes(sendDataStr.toByteArray(charset=Charsets.UTF_8))
        wr.write(sendDataStr.toByteArray(
            charset=Charsets.UTF_8
        ))
        wr.flush()

        val rcode = responseCode
        val reader = BufferedReader(InputStreamReader(inputStream,"UTF-8"))
        val sb = StringBuffer()
        val readLine = kotlin.String()
        val t1 = reader.readLine()
        val t2 = reader.readLine()
        sb.append(t1).append(t2)
        reader.close()
        println(sb.toString())
*//*            println(" URL : $url")
            println(" Response Code : $responseCode")

            BufferedReader(InputStreamReader(inputStream)).use {
                val response = StringBuffer()
                var inputLine = it.readLine()
                while (inputLine != null) {
                    response.append(inputLine)
                    inputLine = it.readLine()
                }
                it.close()
                println(" Response : $response")
            }
    }
}*/
fun main(){

    //get_content("%B1%B1%BE%A9%B5%C4%CC%EC%C6%F8")
    //get_content(URLEncoder.encode("你好", "UTF-8"))
    get_content("北京今天的天气")
    //println(sendw("你好"))
    //1. every value in key-value should do URLEncoder.encode
    //2. pass a key-value string like a=b&c=d, not a json {a=b;c=d}, declare this in header by "Content-Type", "application/x-www-form-urlencoded"
    //3. params is in body in post, in header in get
    //4. headers is look like accept: application/json content-type: application/json
    //5. params is in body, so they're same, when headers application/x-www-form-urlencoded, params and body like parameter=value&also=another
    //6. multipart/form-data is for files, application/json is for json like "{a=b;c=d}"
    //7. check post or get first, check json or urlencoded second,
    //8. if it's urlencoded, value should be urlencoded, if it's json, the dict or map should be to json
}
