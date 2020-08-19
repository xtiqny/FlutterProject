package com.cn21.app.navigation.flutter;

import android.support.annotation.Nullable;
import android.util.Log;

import com.cn21.app.navigation.UniRouter;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * 统一导航路由的Flutter UI栈处理插件
 * 实现了Flutter的插件处理接口，与 UniRouter 配合，
 * 支持Native与Flutter的混合栈管理
 * 注意：应用不要直接使用该类
 */
public class UniRouterPlugin implements MethodCallHandler {
    private static final String TAG = "UniRouterPlugin";
    /**
     * Plugin registration.
     */
    private static UniRouterPlugin uniRouterPlugin = null;
    MethodChannel methodChannel;
    EventChannel signalChannel;
    private EventChannel.EventSink signalSink;
    private boolean isReady = false;
    private Object startArgs;

    private Result methodResult;
    private boolean flutterSideRunning;
    private UniRouter.ReadyHandler readyHandler;

    /**
     * 获取单例
     * @return UniRouterPlugin 对象单例
     */
    public static UniRouterPlugin instance() {
        if (uniRouterPlugin != null) { return uniRouterPlugin; }
        uniRouterPlugin = new UniRouterPlugin();
        return uniRouterPlugin;
    }

    /**
     * Method channel注册
     * @param registrar
     */
    public static void registerWith(Registrar registrar) {
        uniRouterPlugin = UniRouterPlugin.instance();
        uniRouterPlugin.methodChannel = new MethodChannel(registrar.messenger(), "unirouter_manager");
        uniRouterPlugin.methodChannel.setMethodCallHandler(uniRouterPlugin);
        uniRouterPlugin.signalChannel = new EventChannel(registrar.messenger(), "unirouter_signal_channel");
        uniRouterPlugin.signalChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object o, EventChannel.EventSink eventSink) {
                Log.e(TAG, "-----------> onListen");
                uniRouterPlugin.signalSink = eventSink;
                if(uniRouterPlugin.isReady) {
                    Log.e(TAG, "--------> I am ready now.");
                    uniRouterPlugin.signalSink.success(true);
                }
            }

            @Override
            public void onCancel(Object o) {
                Log.e(TAG, "-----------> onCancel");
                uniRouterPlugin.signalSink = null;
            }
        });
    }

    public void signalReady(Object startArgs) {
        if(!isReady) {
            isReady = true;
            if(methodResult != null) {
                methodResult.success(startArgs);
                methodResult = null;
            } else {
                this.startArgs = startArgs;
            }
            safeRequestStartRoute();
        }
    }


    public void requestStartRoute(UniRouter.ReadyHandler handler) {
        readyHandler = handler;
        if(isReady) {
            safeRequestStartRoute();
        }
    }

    private void safeRequestStartRoute() {
        if(readyHandler != null && flutterSideRunning) {
            final UniRouter.ReadyHandler handler = readyHandler;
            readyHandler = null;
            Log.e(TAG, "======> requestStartRoute");
            methodChannel.invokeMethod("startRoute", null, new Result() {
                @Override
                public void success(@Nullable Object o) {
                    handler.onReady();
                }

                @Override
                public void error(String s, @Nullable String s1, @Nullable Object o) {
                    handler.onError(new IllegalStateException(s));
                }

                @Override
                public void notImplemented() {
                    handler.onError(new IllegalStateException("Not implemented"));
                }
            });
        }
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        if(call.method.equals("waitForReady")) {
            flutterSideRunning = true;
            if(isReady) {
                result.success(startArgs);
                startArgs = null;
                safeRequestStartRoute();
            } else {
                methodResult = result;
            }
        } else {
            result.notImplemented();
        }
    }
}
