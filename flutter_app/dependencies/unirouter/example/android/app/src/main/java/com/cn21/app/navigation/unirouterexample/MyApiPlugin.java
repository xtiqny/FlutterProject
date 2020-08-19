package com.cn21.app.navigation.unirouterexample;

import android.util.Log;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;

public final class MyApiPlugin implements MethodChannel.MethodCallHandler {
    private MethodChannel methodChannel;
    private static MyApiPlugin plugin;
    public static MyApiPlugin instance() {
        if(plugin == null) {
            plugin = new MyApiPlugin();
        }
        return plugin;
    }

    private MyApiPlugin() {
    }
    @Override
    public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
        if(methodCall.method.equals("show")) {
            Log.i("", "==================> Show somthing in native .");
        }
        result.success("DONE");
    }

    public void registerWith(PluginRegistry.Registrar registrar) {
        methodChannel = new MethodChannel(registrar.messenger(), "my_api_plugin");
        methodChannel.setMethodCallHandler(this);
    }

    public void getText() {
        if(methodChannel == null) {
            return;
        }
        MethodChannel.Result callback = new MethodChannel.Result() {
            @Override
            public void success(Object o) {
                Log.i("", "Call back result:" + o.toString());
            }

            @Override
            public void error(String s, String s1, Object o) {
                Log.i("", "Error:" + s);
            }

            @Override
            public void notImplemented() {

            }
        };
        methodChannel.invokeMethod("getText", null, callback);
    }
}
