package com.cn21.app.navigation.flutter;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.view.View;
import android.arch.lifecycle.LifecycleOwner;
import com.idlefish.flutterboost.containers.NewBoostFlutterActivity;
import com.idlefish.flutterboost.interfaces.IContainerRecord;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.PluginRegistry;

/**
 * 配合UniRouter使用的Flutter容器(Activity)
 * */
public class UniFlutterContainerActivity extends NewBoostFlutterActivity implements InstanceKeyProvider {
    public  static final String ACTION_PUSH = "navigation.intent.action.PUSH";
    public static final String TAG = "FlutterContainerAct";
    private UniFlutterContainerDelegator delegator = new UniFlutterContainerDelegator();

    @Override
    public String getInstanceKey() {
        if(!delegator.ready()) {
            delegator.setup(getIntent());
        }
        return delegator.getInstanceKey();
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
//        Log.e(TAG, "=================> onCreate#" + this.hashCode() + ":" + getContainerName()+" and instanceKey=" + getInstanceKey());
        super.onCreate(savedInstanceState);
    }

    @Override
    protected void onResume() {
//        Log.e(TAG, "=================> onResume#" + this.hashCode() + ":" + getContainerName()+" and instanceKey=" + getInstanceKey());
        super.onResume();
    }

    @Override
    public void onPostResume() {
//        Log.e(TAG, "=================> onPostResume#" + this.hashCode() + ":" + getContainerName()+" and instanceKey=" + getInstanceKey());
        super.onPostResume();
    }

    @Override
    protected void onDestroy() {
//        Log.e(TAG, "=================> onDestroy#" + this.hashCode() + ":" + getContainerName()+" and instanceKey=" + getInstanceKey());
        super.onDestroy();
    }

    @Override
    protected void onPause() {
//        Log.e(TAG, "=================> onPause#" + this.hashCode() + ":" + getContainerName()+" and instanceKey=" + getInstanceKey());
        super.onPause();
    }

    @Override
    protected void onStart() {
//        Log.e(TAG, "=================> onStart#" + this.hashCode() + ":" + getContainerName()+" and instanceKey=" + getInstanceKey());
        super.onStart();
    }

    @Override
    protected void onStop() {
//        Log.e(TAG, "=================> onStop#" + this.hashCode() + ":" + getContainerName()+" and instanceKey=" + getInstanceKey());
        super.onStop();
    }

    @Override
    public String getContainerUrl() {
        if(!delegator.ready()) {
            delegator.setup(getIntent());
        }
        return delegator.getContainerUrl();
    }

    @Override
    public Map getContainerUrlParams() {
        if(!delegator.ready()) {
            delegator.setup(getIntent());
        }
        return delegator.getContainerUrlParams();
    }

//    @Override
//    public void onRegisterPlugins(PluginRegistry registry) {
//    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        delegator.clear();
    }
//
//    @Override
//    public BoostFlutterView getBoostFlutterView() {
//        if(UniFlutterContainerActivity.flutterView == null) {
//            UniFlutterContainerActivity.flutterView = super.getBoostFlutterView();
//            UniFlutterContainerActivity.flutterView.enableTransparentBackground();
//        }
//        return UniFlutterContainerActivity.flutterView;
//    }
//
//    @Override
//    protected View createSplashScreenView() {
//        View v = new View(this);
////        v.setBackgroundColor(Color.TRANSPARENT);
//        return v;
//    }
//
//    @Override
//    protected View createFlutterInitCoverView() {
//        View v = new View(this);
////        v.setBackgroundColor(Color.TRANSPARENT);
//        return v;
//    }
}
