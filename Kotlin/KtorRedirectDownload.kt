package com.example.del

import android.os.Bundle
import android.os.Environment
import androidx.appcompat.app.AppCompatActivity
import io.ktor.client.HttpClient
import io.ktor.client.call.receive
import io.ktor.client.engine.cio.CIO
import io.ktor.client.engine.okhttp.OkHttp
import io.ktor.client.features.json.GsonSerializer
import io.ktor.client.features.json.JsonFeature
import io.ktor.client.request.delete
import io.ktor.client.request.get
import io.ktor.client.request.put
import io.ktor.client.statement.HttpResponse
import io.ktor.http.ContentType
import io.ktor.utils.io.ByteReadChannel
import kotlinx.coroutines.*
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream

// https://ktor.io/docs/response.html#receive

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        val rl = RemoteList()

        val updateUI = Job()
        val updateUIScope = CoroutineScope(Dispatchers.Main + updateUI)
        updateUIScope.launch {
            withContext(Dispatchers.IO) {
                rl.getFile("IMG_20210102_172006.jpg","http://x/webhdfs/v1/IMG_20210102_172006.jpg?op=OPEN")
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
        val filePath = Environment.getExternalStorageDirectory().path + "/" + name
        if (File(filePath).exists()) {
            File(filePath).delete()
        }
        val file = File(filePath)
        val fos = FileOutputStream(file)
        val result = httpClient.get<HttpResponse>(addr)

//        val readChannel = result.receive<ByteReadChannel>()
        val readInputStream = result.receive<InputStream>()
        val buffer = ByteArray(1024)
        var len : Int
        var total = 0
        while (((readInputStream.read(buffer)).also { len = it }) != -1) {
            fos.write(buffer, 0, len)
            total += len
            //获取当前下载量
//            pd.progress = total / 1024
        }
        fos.close()


    }
}
