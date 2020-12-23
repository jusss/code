

HttpURLConnection and OkHttp suck on android,
there're ktor, fuel, retrofit

// build
    implementation 'org.jetbrains.kotlinx:kotlinx-coroutines-core:1.0.1'
    implementation "org.jetbrains.kotlinx:kotlinx-coroutines-android:1.0.1"
    implementation 'com.google.code.gson:gson:2.8.5'
    implementation "io.ktor:ktor-client-android:1.4.0"
    implementation "io.ktor:ktor-client-cio:1.4.0"
    implementation "io.ktor:ktor-client-serialization-jvm:1.4.0"
    implementation "io.ktor:ktor-client-gson:1.4.0"

// call
  val rl = RemoteList("http://49.5.6.84:9870/webhdfs/v1/?op=LISTSTATUS")
  var timeoutJob = Job()
  val timeoutScope = CoroutineScope(Dispatchers.IO + timeoutJob)
  timeoutScope.launch {
       withContext(Dispatchers.IO){
              rl.getContent()
            }
  }

// define
class RemoteList (val addr: String) {
    suspend fun getContent() {
        val httpClient = HttpClient(CIO){
            install(JsonFeature){
                serializer = GsonSerializer()
            }
        }
        val result = httpClient.get<String>(addr)
        println(result)
    }
}













http://ktor.kotlincn.net/clients/index.html
https://medium.com/better-programming/how-to-use-ktor-in-your-android-app-a99f50cc9444