package com.example.del

import android.net.Uri
import android.os.Bundle
import android.os.Environment
import android.os.Looper
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import io.ktor.client.HttpClient
import io.ktor.client.call.receive
import io.ktor.client.engine.HttpClientEngine
import io.ktor.client.engine.cio.CIO
import io.ktor.client.engine.okhttp.OkHttp
import io.ktor.client.features.HttpRedirect
import io.ktor.client.features.RedirectResponseException
import io.ktor.client.features.json.GsonSerializer
import io.ktor.client.features.json.JsonFeature
import io.ktor.client.request.delete
import io.ktor.client.request.get
import io.ktor.client.request.headers
import io.ktor.client.request.put
import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.request
import io.ktor.http.ContentType
import io.ktor.http.HttpHeaders
import io.ktor.http.content.MultiPartData
import io.ktor.util.cio.write
import io.ktor.utils.io.ByteReadChannel
import io.ktor.utils.io.ByteWriteChannel
import io.ktor.utils.io.write
import io.ktor.utils.io.writer
import kotlinx.coroutines.*
import okhttp3.internal.connection.ConnectInterceptor.intercept
import java.io.*
import java.nio.ByteBuffer

interface UpdateUi {
    fun readFromUri(uri: Uri): ByteArray?
}
class MainActivity : UpdateUi, AppCompatActivity() {

    override fun readFromUri(uri: Uri): ByteArray? =
        this.contentResolver.openInputStream(uri)?.buffered().use { it?.readBytes() }
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        val rl = RemoteList()

        val updateUI = Job()
        val updateUIScope = CoroutineScope(Dispatchers.Main + updateUI)
        updateUIScope.launch {
            withContext(Dispatchers.IO) {
                rl.getFile("VID_20210106_110213.mp4","http://ip/webhdfs/v1/VID_20210106_110213.mp4?op=OPEN")
//                rl.uploadFile("http://ip/webhdfs/v1/alternativeMydevice2.txt?op=CREATE",Uri.EMPTY,this@MainActivity)
            }
        }
    }
}

class RemoteList {
    //    val httpClient = HttpClient(OkHttp) {
//        install(JsonFeature) {
//            serializer = GsonSerializer()
//            acceptContentTypes += ContentType("application", "json+hal")
//
//        }
//    }
    val httpClient = HttpClient(CIO)

    suspend fun delete(addr: String) {
        println("delete files: $addr")
        val result = httpClient.delete<String>(addr)
        println(result)
    }

    suspend fun rename(addr: String) {
        println("rename file: $addr")
        val result = httpClient.put<String>(addr)
        println("rename result: $result")
    }

    suspend fun createDirecotry(addr: String) {
        val result = httpClient.put<String>(addr)
        println("create dir $result")
    }


    suspend fun getFile(name: String, addr: String) {
        val filePath = Environment.getExternalStorageDirectory().path + "/wnyphone/" + name
        val checkDir = Environment.getExternalStorageDirectory().path + "/wnyphone/"
        if (!File(checkDir).exists()) {
            File(checkDir).mkdir()
        }
        if (File(filePath).exists()) {
            File(filePath).delete()
        }
        val file = File(filePath)
        val fos = FileOutputStream(file)


       //PROBLEM

    val client = HttpClient(CIO) {
        followRedirects = false
    }
        val _result = client.get<HttpResponse>(addr)
        val readInputStream = client.get<InputStream>(_result.headers["LOCATION"]?:"")









//        println("the result is $result")
//        print("this is length: ")
//        println(result.headers["Content-Length"])
//
////        val readChannel = result.receive<ByteReadChannel>()
//        val readInputStream = result.receive<InputStream>()
        val buffer = ByteArray(1024)
        var len: Int
        var total = 0
        while (((readInputStream.read(buffer)).also { len = it }) != -1) {
            fos.write(buffer, 0, len)
            total += len
            println("it's total $total")
//            pd.progress = total / 1024
        }
        fos.close()
        println("it's done")
    }

//    val client = HttpClient(CIO) {
//        followRedirects = false
//    }
    suspend fun uploadFile(addr: String, uri: Uri, updateUi: UpdateUi) {
        val output = httpClient.put<HttpResponse>(addr)
        println("this is upload test ${output.headers["Location"]}")
        val realUrl = output.headers["Location"]?:""
//        val re = client.put<HttpResponse>(realUrl){
//            body = "aha"
//        }
        httpClient.put<ByteArray>(realUrl){
            body = "aha".toByteArray()
        }



    }
}
//        val outputStream = output.receive<OutputStream>()
//        val filePath = Environment.getExternalStorageDirectory().path + "/wnyphone/" + "mydevice.txt"
//
//        outputStream.write(
//            "abc"
////        updateUi.readFromUri(uri)
//        )
//        outputStream.autoFlush
//        println("this is headers ${output.content}")




