package com.cn21.app.navigation.unirouterexample;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.util.Log;

import com.cn21.app.navigation.RouteAction;
import com.cn21.app.navigation.UniRouter;
import com.cn21.app.navigation.flutter.UniFlutterContainerActivity;

import java.util.HashMap;

import io.flutter.app.FlutterApplication;

public final class MyApp extends FlutterApplication {
    private static int autoKey = 0;
    @Override
    public void onCreate() {
        super.onCreate();
        UniRouter.instance().init(this);
        UniRouter.instance().setRouteResolver((url, instanceKey, params) -> {
            if(url != null) {
                if(instanceKey == null) {
                    instanceKey = "auto:" + (autoKey++);
                }
                if(url.startsWith("/flutterdemo")) {
                    return new RouteAction(url, instanceKey, params);
                }
                else if(url.startsWith("/nativedemo")) {
                    return new RouteAction(url, instanceKey, params);
                }
                else if(url.startsWith("/fragdemo")) {
                    return new RouteAction(url, instanceKey, params);
                }
            }
            return null;
        });
        UniRouter.instance().setNativePushHandler((context, action) ->{
            Intent intent;
            if(!action.url.startsWith("/nativedemo")) {
                if(action.url.startsWith("/flutterdemo")) {
                    intent = new Intent(context, UniFlutterContainerActivity.class);
                    intent.setAction(UniFlutterContainerActivity.ACTION_PUSH);
                } else {
                    intent = new Intent(context, TabFragmentDemoActivity.class);
                    intent.setAction(TabFragmentDemoActivity.ACTION_PUSH);
//                    intent = new Intent(context, PageFragmentDemoActivity.class);
//                    intent.setAction(PageFragmentDemoActivity.ACTION_PUSH);
                }

            }
            else {
                intent = new Intent(context, UniDemoActivity.class);
                intent.setAction(Intent.ACTION_VIEW);
            }
            intent.setData(Uri.parse(action.url + "?instanceKey=" + action.instanceKey));
            intent.putExtra("instanceKey", action.instanceKey);
            if(action.params != null) {
                intent.putExtra("params", (action.params instanceof HashMap)? (HashMap)action.params : new HashMap(action.params));
            }
            if(!(context instanceof Activity)) {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            }
            context.startActivity(intent);
            return true;
        });
        UniRouter.instance().startRoute(new UniRouter.ReadyHandler() {
            @Override
            public void onReady() {
                Log.e("", "============> Start route ready.");
            }

            @Override
            public void onError(Throwable e) {
                Log.e("", e.getMessage());
            }
        }, "debug");
//        String [] args = {"--start-paused"};
//        FlutterMain.ensureInitializationComplete(this.getApplicationContext(), args);
    }
}
