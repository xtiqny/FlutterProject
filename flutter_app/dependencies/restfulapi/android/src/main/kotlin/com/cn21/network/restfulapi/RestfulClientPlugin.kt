package com.cn21.network.restfulapi

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import okhttp3.*

const val SMALL_BODY_SIZE = 256 * 1024L
const val CONTENT_STREAM_CHANNEL_PREFIX = "restful_content_stream:"

class RestfulClientPlugin2 : MethodCallHandler {
    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            if (messenger == null)
                messenger = registrar.messenger()
            val channel = MethodChannel(registrar.messenger(), "restfulapi")
            channel.setMethodCallHandler(RestfulClientPlugin2())
        }

        val okHttpClient = OkHttpClient()
        var nextClientId = 1L
        var nextRequestId = 1L
        var messenger: BinaryMessenger? = null
        val mainHandler = Handler(Looper.getMainLooper())
    }

    data class ClientRef(val clientId: Long, val client: OkHttpClient,
                         val requestRefs: MutableList<RequestRef> = mutableListOf())

    data class RequestRef(val requestId: Long, val clientRef: ClientRef,
                          val request: Request, var response: Response? = null,
                          var error: Throwable? = null, var resResult: Result? = null)

    val clientList = mutableMapOf<Long, ClientRef>()
    val requestList = mutableMapOf<Long, RequestRef>()



    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "createClient") {
            val client = okHttpClient.newBuilder().build()
            val clientId = nextClientId++
            clientList[clientId] = ClientRef(clientId, client)
            result.success(clientId)
        } else {
            result.notImplemented()
        }
    }
}
