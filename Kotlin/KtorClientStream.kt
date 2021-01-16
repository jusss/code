package com.example.ktor


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
import io.ktor.client.features.HttpRedirect
import io.ktor.client.features.RedirectResponseException
import io.ktor.client.features.json.GsonSerializer
import io.ktor.client.features.json.JsonFeature
import io.ktor.client.request.delete
import io.ktor.client.request.get
import io.ktor.client.request.headers
import io.ktor.client.request.put
import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.HttpStatement
import io.ktor.client.statement.request
import io.ktor.http.ContentType
import io.ktor.http.HttpHeaders
import io.ktor.http.cio.Response
import io.ktor.http.content.MultiPartData
import io.ktor.http.content.OutgoingContent
import io.ktor.util.cio.write
import io.ktor.utils.io.*
import io.ktor.utils.io.jvm.javaio.toInputStream
import io.ktor.utils.io.jvm.javaio.toOutputStream
import io.ktor.utils.io.jvm.nio.copyTo
import kotlinx.coroutines.*
import java.io.*
import java.net.HttpURLConnection
import java.net.URL
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
//                rl.getFile("VID_20210106_110213.mp4","http://ip:9870/webhdfs/v1/VID_20210106_110213.mp4?op=OPEN")
                rl.uploadFile("http://ip:9870/webhdfs/v1/" + System.currentTimeMillis().toString()  + ".txt?op=CREATE",Uri.EMPTY,this@MainActivity)
            }
        }
    }
}

class RemoteList {
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

        val client = HttpClient(CIO) {
            followRedirects = false
        }
        val _result = client.get<HttpResponse>(addr)

        client.get<HttpStatement>(_result.headers["LOCATION"]
                ?: "").execute { response: HttpResponse ->
            val channel = response.receive<ByteReadChannel>()
            val count = response.headers["Content-Length"]
            println("this is the length $count")
            val readInputStream = channel.toInputStream()
            val buffer = ByteArray(1024)
            var len: Int
            var total = 0
            while (((readInputStream.read(buffer)).also { len = it }) != -1) {
                fos.write(buffer, 0, len)
                total += len
                println("it's total $total")
            }
            fos.close()
            println("it's done")
        }
    }

    suspend fun uploadFile(addr: String, uri: Uri, updateUi: UpdateUi) {
        val client = HttpClient(CIO) {
            followRedirects = false
        }
        val output = client.put<HttpResponse>(addr)
        println("this is upload test ${output.headers["Location"]}")
        val realUrl = output.headers["Location"] ?: ""
        val filePath = Environment.getExternalStorageDirectory().path + "/wnyphone/" + "sd.jpg"
        println(File(filePath).inputStream().read().toString())
        val result = client.put<ByteWriteChannel>(realUrl) {
            body = StreamContent(File(filePath))
        }
    }
}


class StreamContent(private val pdfFile:File): OutgoingContent.WriteChannelContent() {
    override suspend fun writeTo(channel: ByteWriteChannel) {
        val readChannel = pdfFile.inputStream().channel
        var copiedBytes: Long
        var count : Long = 0
        do {

            copiedBytes = readChannel.copyTo(channel, 1024)
            count =  count + copiedBytes
            println("reading files now! count is $count")
        } while (copiedBytes > 0)
    }
    override val contentType = ContentType.Application.Pdf
    override val contentLength: Long = pdfFile.length()
}


