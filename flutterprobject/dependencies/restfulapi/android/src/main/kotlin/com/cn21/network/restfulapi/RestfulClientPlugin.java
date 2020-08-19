package com.cn21.network.restfulapi;

import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import java.io.IOException;
import java.io.InputStream;
import java.nio.ByteBuffer;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;

import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.BinaryCodec;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;
import okhttp3.Headers;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.ResponseBody;

/**
 * 类说明:HttpClient通用插件
 * Created by Administrator on 2019/8/29.
 */
public class RestfulClientPlugin implements MethodChannel.MethodCallHandler {
    public static final String CHANNEL = "com.cn21.network.restfulapi/RestfulClientPlugin";
    private static final String TAG = "HttpClientFlutterPlugin";

    private PluginRegistry.Registrar mRegister;
    private int sClientId = 2000;
    private Map<Long, OkHttpClient> mHttpClients = new HashMap<>();
    // 保存正在执行的请求
    private Map<Long, okhttp3.Call> mHttpCalls = new HashMap<>();
    private Handler mMainHandler = null;

    public RestfulClientPlugin(PluginRegistry.Registrar registrar) {
        this.mRegister = registrar;
        mMainHandler = new Handler(Looper.getMainLooper());
    }

    public static void registerWith(PluginRegistry.Registrar registrar) {
        MethodChannel channel = new MethodChannel(registrar.messenger(), CHANNEL);
        RestfulClientPlugin instance = new RestfulClientPlugin(registrar);
        //setMethodCallHandler在此通道上接收方法调用的回调
        channel.setMethodCallHandler(instance);
    }

    @Override
    public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
//        Log.d(TAG, "onMethodCall " + methodCall.method + ", args: " + methodCall.arguments);
        if ("create".equals(methodCall.method)) {
            if (methodCall.arguments instanceof Map) {
                Map<String, Object> map = (Map<String, Object>) methodCall.arguments;
                String message = (String) map.get("message");
                int connectTimeout = (Integer) map.get("http.connTimeout");
                int readTimeout = (Integer) map.get("http.readTimeout");
                int writeTimeout = (Integer) map.get("http.writeTimeout");
                OkHttpClient client = new OkHttpClient.Builder()
                        .connectTimeout(connectTimeout, TimeUnit.MILLISECONDS)
                        .readTimeout(readTimeout, TimeUnit.MILLISECONDS)
                        .writeTimeout(writeTimeout, TimeUnit.MILLISECONDS)
                        .build();
                int clientId = sClientId++;
                mHttpClients.put(Long.valueOf(clientId), client);
                result.success(clientId);
            } else {
                Log.e(TAG, "参数错误！");
                result.error(TAG, "create invalid param", null);
            }
        } else if ("close".equals(methodCall.method)) {
            if (methodCall.arguments instanceof Integer) {
                int clientId = (Integer) methodCall.arguments;
                OkHttpClient client = mHttpClients.get(Long.valueOf(clientId));
                if (client != null) {
                    mHttpClients.remove(Long.valueOf(clientId));
                }
            }
            result.success(Boolean.TRUE);
        } else if ("execute".equals(methodCall.method)) {
            if (methodCall.arguments instanceof Map) {
                Map<String, Object> map = (Map<String, Object>) methodCall.arguments;
                int clientId = (Integer) map.get("clientId");
                int requestId = (Integer) map.get("requestId");
                String method = (String) map.get("method");
                String url = (String) map.get("url");
                Map headers = (Map) map.get("headers");
                byte[] body = (byte[]) map.get("body");
                OkHttpClient client = mHttpClients.get(Long.valueOf(clientId));
                if (client != null) {
                    executeRequest(client, clientId, requestId, method, url, headers, body, result);
                } else {
                    result.error(TAG, "execute can not find client", null);
                }
            } else {
                result.error(TAG, "execute invalid argument", null);
            }

        } else if ("cancelRequest".equals(methodCall.method)) {
            if (methodCall.arguments instanceof Map) {
                Map<String, Object> map = (Map<String, Object>) methodCall.arguments;
                int clientId = (Integer) map.get("clientId");
                int requestId = (Integer) map.get("requestId");
                okhttp3.Call call = getCallById(clientId, requestId);
                if (call != null) {
                    call.cancel();
                    removeRequestCall(clientId, requestId);
                }
            }
            result.success(Boolean.TRUE);
        } else {
            result.notImplemented();
        }
    }

    private void executeRequest(OkHttpClient client, final int clientId,
                                final int requestId, String method, String url, Map<String, String> headers, byte[] body,
                                final MethodChannel.Result result) {
        Headers header = Headers.of(headers != null ? headers : new HashMap<String, String>());
        RequestBody requestBody = null;
        if (!"GET".equals(method)) {
            requestBody = (body != null)
                    ? RequestBody.create(null, body)
                    : RequestBody.create(null, "");
        }

        Request request = new Request.Builder()
                .method(method, requestBody)
                .url(url)
                .headers(header)
                .build();
        okhttp3.Call call = client.newCall(request);
        // 保存请求对象
        addRequestCall(clientId, requestId, call);

        call.enqueue(new okhttp3.Callback() {
            @Override
            public void onFailure(okhttp3.Call call, IOException e) {
                removeRequestCall(clientId, requestId);
                Log.i(TAG, "e: " + e.getMessage());
                Map<String, Object> res = new HashMap<String, Object>();
                res.put("excpetion", e.getClass().getName());
                res.put("exceptionMsg", e.getMessage());
                mMainHandler.post(()->{result.success(res);});
            }

            @Override
            public void onResponse(okhttp3.Call call, okhttp3.Response response) throws IOException {
                removeRequestCall(clientId, requestId);
//                Log.d(TAG, "onResponse: " + response.code() + ", message: " + response.message());
                Headers headers = response.headers();
                Map<String, String> headerMap = new HashMap<>();
                int size = (headers != null) ? headers.size() : 0;
                for (int i = 0; i < size; i++) {
                    String name = headers.name(i);
                    String value = headers.value(i);
                    headerMap.put(name, value);
                }
                Map<String, Object> res = new HashMap<String, Object>();
                res.put("statusCode", response.code());
                res.put("statusMsg", response.message());
                res.put("headers", headerMap);

                if (response.body() != null) {
                    // 直接返回body
//                    res.put("body", response.body().bytes());

                    // 通过流的形式返回body
                    res.put("bodyBinaryLength", response.body().contentLength());
                    mMainHandler.post(()->{result.success(res);});
                    sendBodyByBasicChannel(clientId, requestId, response.body());
                } else {
                    // 无body
                    mMainHandler.post(()->{result.success(res);});
                }
            }
        });
    }

    // 使用BasicMessageChannel发送二进制数据
    private void sendBodyByBasicChannel(int clientId, int requestId, ResponseBody responseBody) {
        String name = "com.cn21.ecloud/HttpClient_" + clientId + "_Response_" + requestId;
        BasicMessageChannel<ByteBuffer> messageChannel = new BasicMessageChannel<>(mRegister.messenger(), name,
                BinaryCodec.INSTANCE);
//        Log.d(TAG, "sendBodyByBasicChannel: channelName: " + name);

        InputStream stream = responseBody.byteStream();
        byte[] byteBuffer = new byte[1024];
        try {
            int len;
            while ((len = stream.read(byteBuffer)) > 0) {
//                Log.i(TAG, "sendBodyByBasicChannel: byteBuffer: " + len);
                ByteBuffer buffer = ByteBuffer.allocateDirect(len);
                buffer.put(byteBuffer, 0, len);
                mMainHandler.post(()-> messageChannel.send(buffer));
            }
        } catch (IOException e) {
            e.printStackTrace();
        } finally {
            try {
                stream.close();
            } catch (IOException e) {}
            // 发送一个null表示结束
            mMainHandler.post(()-> messageChannel.send(null));
//            Log.i(TAG, "sendBodyByBasicChannel: null");
        }
    }

    private void addRequestCall(int clientId, int requestId, okhttp3.Call call) {
        long key = Integer.valueOf(clientId).hashCode() + Integer.valueOf(requestId).hashCode();
        mHttpCalls.put(key, call);
    }

    private void removeRequestCall(int clientId, int requestId) {
        long key = Integer.valueOf(clientId).hashCode() + Integer.valueOf(requestId).hashCode();
        mHttpCalls.remove(key);
    }

    private okhttp3.Call getCallById(int clientId, int requestId) {
        long key = Integer.valueOf(clientId).hashCode() + Integer.valueOf(requestId).hashCode();
        return mHttpCalls.get(key);
    }

    /** 请求的body接收器 */
//    private class RequestBodyReceiver {
//        public void startReceive(int clientId, int requestId, ReceiveBodyCallback callback) {
//            String name = "com.cn21.ecloud/HttpClient_" + clientId + "_Request_" + requestId;
//            okio.Buffer buffer = new okio.Buffer();
//            BasicMessageChannel<ByteBuffer> receiveChannel = new BasicMessageChannel<>(mRegister.messenger(), name,
//                    BinaryCodec.INSTANCE);
//            receiveChannel.setMessageHandler((ByteBuffer data, BasicMessageChannel.Reply<ByteBuffer> var2)->{
//                if (data != null) {
//                    Log.i(TAG, "receive " + data.array().length + " bytes");
//                    try {
//                        buffer.write(data);
//                    } catch (IOException e) {
//                        e.printStackTrace();
//                    }
//                } else {
//                    Log.i(TAG, "receive completed");
//                    callback.onReceiveBody(buffer.readByteArray());
//                    receiveChannel.setMessageHandler(null);
//                }
//            });
//        }
//    }
//
//    private interface ReceiveBodyCallback {
//        void onReceiveBody(byte[] bytes);
//    }

}
