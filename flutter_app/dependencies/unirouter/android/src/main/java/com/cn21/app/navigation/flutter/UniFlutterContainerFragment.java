package com.cn21.app.navigation.flutter;

import android.app.Activity;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Bundle;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import com.idlefish.flutterboost.containers.NewFlutterFragment;
import com.idlefish.flutterboost.interfaces.IContainerRecord;

import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.android.FlutterView;
import io.flutter.plugin.common.PluginRegistry;

/**
 * 配合UniRouter使用的Flutter容器(Fragment)
 */
public class UniFlutterContainerFragment extends NewFlutterFragment implements InstanceKeyProvider {

    private static final String TAG = "FlutterContainerFrag";

    private UniFlutterContainerDelegator delegator = new UniFlutterContainerDelegator();

    @Override
    public void setArguments(@Nullable Bundle args) {
        if(args == null) {
            args = new Bundle();
            args.putString("tag","");
        }
        super.setArguments(args);
    }

    public void setTabTag(String tag) {
        Bundle args = new Bundle();
        args.putString("tag",tag);
        super.setArguments(args);
    }

    @Override
    public String getContainerUrl() {
        if(!delegator.ready()) {
            delegator.setup(getArguments());
        }
        return delegator.getContainerUrl();
    }

    @Override
    public Map getContainerUrlParams() {
        if(!delegator.ready()) {
            delegator.setup(getArguments());
        }
        return delegator.getContainerUrlParams();
    }

//    @Override
//    public void onRegisterPlugins(PluginRegistry registry) {
//    }

//    @Override
//    public void finishContainer(Map<String, Object> result) {
//        super.finishContainer(result);
//        delegator.clear();
//    }

    @NonNull
    @Override
    public FlutterView.TransparencyMode getTransparencyMode() {
        return FlutterView.TransparencyMode.transparent;
    }
    //    @Override
//    protected View createSplashScreenView() {
//        View v = new View(getContext());
////        v.setBackgroundColor(Color.TRANSPARENT);
//        return v;
//    }
//
//    @Override
//    protected View createFlutterInitCoverView() {
//        View v = new View(getContext());
////        v.setBackgroundColor(Color.TRANSPARENT);
//        return v;
//    }

    @Override
    public String getInstanceKey() {
        if(!delegator.ready()) {
            delegator.setup(getArguments());
        }
        return delegator.getInstanceKey();
    }

    @Override
    public void onResume() {
//        Log.e(TAG, "+++++++++++++++++> onResume:" + getContainerUrl()+" and instanceKey=" + getInstanceKey());
        super.onResume();
    }

    @Override
    public void onDestroy() {
//        Log.e(TAG, "+++++++++++++++++> onDestroy:" + getContainerUrl()+" and instanceKey=" + getInstanceKey());
        super.onDestroy();
    }

    @Override
    public void onPause() {
//        Log.e(TAG, "+++++++++++++++++> onPause:" + getContainerUrl()+" and instanceKey=" + getInstanceKey());
        super.onPause();
    }

    @Override
    public void onStart() {
//        Log.e(TAG, "+++++++++++++++++> onStart:" + getContainerUrl()+" and instanceKey=" + getInstanceKey());
        super.onStart();
    }

    @Override
    public void onStop() {
//        Log.e(TAG, "+++++++++++++++++> onStop:" + getContainerUrl()+" and instanceKey=" + getInstanceKey());
        super.onStop();
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
//        Log.e(TAG, "+++++++++++++++++> onCreate:" + getContainerName()+" and instanceKey=" + getInstanceKey());
        super.onCreate(savedInstanceState);
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
//        Log.e(TAG, "+++++++++++++++++> onCreateView:" + getContainerName()+" and instanceKey=" + getInstanceKey());
        return super.onCreateView(inflater, container, savedInstanceState);
    }

    @Override
    public void onDestroyView() {
//        Log.e(TAG, "+++++++++++++++++> onDestroyView:" + getContainerName()+" and instanceKey=" + getInstanceKey());
        super.onDestroyView();
    }

//    public Bitmap getSnapshot() {
//        BoostFlutterView flutterView = this.getBoostFlutterView();
//        if(flutterView != null) {
//            return flutterView.getBitmap();
//        }
//        return null;
//    }

//    @Override
//    public BoostFlutterView getBoostFlutterView() {
//        if(UniFlutterContainerFragment.flutterView == null) {
//            UniFlutterContainerFragment.flutterView = super.getBoostFlutterView();
//            UniFlutterContainerFragment.flutterView.enableTransparentBackground();
//            //code
//            try{
//                Activity act =  (Activity)UniFlutterContainerFragment.flutterView.getContext();
//                Log.d(TAG, "+++++++++++++++++> act:" + act.getClass().getName());
//            }catch (Throwable e){
//            }
//        }
//        return UniFlutterContainerFragment.flutterView;
//    }

    public static UniFlutterContainerFragment instance(String tag){
        UniFlutterContainerFragment fragment = new UniFlutterContainerFragment();
        fragment.setTabTag(tag);
        return fragment;
    }
}
