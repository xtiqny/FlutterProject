package com.cn21.app.navigation.flutter;

import android.content.Context;

import com.idlefish.flutterboost.NewFlutterBoost;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.view.FlutterMain;
import io.flutter.view.FlutterNativeView;
import io.flutter.view.FlutterRunArguments;

public class FlutterAgent {
    private static final String TAG = "FlutterAgent";
    private static FlutterAgent sAgent;
    private static Context mContext;
//    private static BoostFlutterNativeView mNativeView;
    private FlutterAgent(){}
    public static FlutterAgent instance() {
        if(sAgent == null) {
            synchronized (FlutterAgent.class) {
                if(sAgent == null) {
                    sAgent = new FlutterAgent();
                }
            }
        }
        return sAgent;
    }

    public void init(Context appContext) {
        mContext = appContext;
    }

    public FlutterEngine getEngine() {
        return NewFlutterBoost.instance().engineProvider();
    }

    public PluginRegistry getPluginRegistry() {
        return NewFlutterBoost.instance().getPluginRegistry();
    }

//    public FlutterNativeView getNativeView() {
//        if(mNativeView == null && mContext != null) {
//            mNativeView = new BoostFlutterNativeView(mContext);
//        }
//        return mNativeView;
//    }

    public boolean runBundle(FlutterRunArguments runArguments) {
        NewFlutterBoost.instance().doInitialFlutter();
        return true;
//        FlutterNativeView nativeView = getNativeView();
//
//        if(nativeView == null || nativeView.isApplicationRunning()) {
//            return false;
//        }
//        if(runArguments != null) {
//            nativeView.runFromBundle(runArguments);
//            return true;
//        } else {
//            String appBundlePath = FlutterMain.findAppBundlePath(mContext);
//            if (appBundlePath != null) {
//                FlutterRunArguments arguments = new FlutterRunArguments();
//                arguments.bundlePath = appBundlePath;
//                arguments.entrypoint = "main";
//                nativeView.runFromBundle(arguments);
//                return true;
//            } else {
//                return false;
//            }
//        }
    }
}
