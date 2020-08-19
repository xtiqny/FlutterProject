package com.cn21.app.navigation.unirouterexample;

import android.annotation.TargetApi;
import android.graphics.Bitmap;
import android.os.Build;
import android.os.Bundle;
import android.support.annotation.Nullable;
import android.support.design.widget.TabLayout;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentActivity;
import android.support.v4.app.FragmentTransaction;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.ImageView;

import com.cn21.app.navigation.flutter.UniFlutterContainerFragment;
import com.idlefish.flutterboost.NewFlutterBoost;

import java.util.ArrayList;
import java.util.HashMap;

public class TabFragmentDemoActivity extends FragmentActivity {
    public  static final String ACTION_PUSH = "navigation.intent.action.PUSH";
    private static final String TAG = "TabFragmentDemoActivity";
    private UniFlutterContainerFragment[] fragments;
    private TabLayout tabHost;
    private static int fragInstIncreament = 0;
    private ImageView imgBackground;
    private Bitmap bmSnapshot;
    private long lastSwitchTime = 0;
    private int lastFragmentIndex = -1;
    private FrameLayout frameLayout;

    private String getUrl() {
        return getIntent().getData().toString();
    }

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        Log.e(TAG, "=================> onCreate:" + getUrl());
        super.onCreate(savedInstanceState);
        setContentView(R.layout.tab_fragment_activity);
        frameLayout = findViewById(R.id.fragment_stub);
        imgBackground = findViewById(R.id.imgBackground);
        createFragments();
        initTabHost();

    }

    @Override
    protected void onResume() {
        Log.e(TAG, "=================> onResume:" + getUrl());
        super.onResume();
    }

    @Override
    protected void onPostResume() {
        Log.e(TAG, "=================> onPostResume:" + getUrl());
        super.onPostResume();
    }

    @Override
    protected void onStart() {
        Log.e(TAG, "=================> onStart:" + getUrl());
        super.onStart();
    }


    @Override
    protected void onPause() {
        Log.e(TAG, "=================> onPause:" + getUrl());
        if(isFinishing()) {
            ArrayList<View> removeViews = new ArrayList<>(frameLayout.getChildCount());
            for(int i = 0; i < frameLayout.getChildCount(); i++) {
                View view = frameLayout.getChildAt(i);
                if(view != imgBackground) {
                    removeViews.add(view);
                }
            }
            for(View view : removeViews) {
                frameLayout.removeView(view);
            }
            removeViews.clear();
        }
        super.onPause();
    }

    @Override
    protected void onStop() {
        Log.e(TAG, "=================> onStop:" + getUrl());
        super.onStop();
    }

    @Override
    protected void onDestroy() {
        Log.e(TAG, "=================> onDestroy:" + getUrl());
//        imgBackground.setImageBitmap(null);
//        if (bmSnapshot != null && !bmSnapshot.isRecycled()) {
//            bmSnapshot.recycle();
//        }
        bmSnapshot = null;
//        List<Fragment> fragments = getSupportFragmentManager().getFragments();
//        FragmentTransaction transaction = getSupportFragmentManager().beginTransaction();
//        for(Fragment fragment : fragments) {
//            transaction.remove(fragment);
//        }
//        transaction.commitAllowingStateLoss();
        super.onDestroy();
    }

    @Override
    public void finish() {
        if(lastFragmentIndex >= 0) {
//            takeSnapshot(lastFragmentIndex);
        }
        super.finish();
    }

    private void createFragments() {
        if(fragments != null) {
            return;
        }
        fragments = new UniFlutterContainerFragment[3];
        fragments[0] = buildFragment("Left", "fltfrag://fragdemo?p=left", null);
        fragments[1] = buildFragment("Center", "fltfrag://fragdemo?p=center", null);
        fragments[2] = buildFragment("Right", "fltfrag://fragdemo?p=right", null);
    }

    private UniFlutterContainerFragment buildFragment(String tab, String url, HashMap<String, Object> params) {
        UniFlutterContainerFragment fragment = UniFlutterContainerFragment.instance(tab);
        Bundle args = fragment.getArguments();
        args.putString("url", url);
        args.putString("instanceKey", "frag:" + String.valueOf(++fragInstIncreament));
        if(params != null) {
            args.putSerializable("params", params);
        }
        return fragment;
    }

    private void initTabHost() {
        tabHost = findViewById(R.id.tabHost);
        tabHost.addOnTabSelectedListener(new TabLayout.OnTabSelectedListener() {
            @Override
            public void onTabSelected(TabLayout.Tab tab) {
                int pos = tab.getPosition();
                switchToFragment(pos);
            }

            @Override
            public void onTabUnselected(TabLayout.Tab tab) {

            }

            @Override
            public void onTabReselected(TabLayout.Tab tab) {

            }
        });
        tabHost.getTabAt(0).select();
        Log.e(TAG, "==== switchToFragment ====");
        switchToFragment(0);
    }

    @TargetApi(Build.VERSION_CODES.JELLY_BEAN_MR1)
    private void switchToFragment(int pos) {
        lastSwitchTime = System.currentTimeMillis();
        enableTabHost(false);
        tabHost.postDelayed(()->{
            if(isDestroyed() || isFinishing()) {
                return;
            }
            enableTabHost(true);
        }, 300);
        if(pos >= 0 && pos < fragments.length) {
            UniFlutterContainerFragment fragment = fragments[pos];
            if(lastFragmentIndex >= 0 && lastFragmentIndex != pos) {
//                takeSnapshot(lastFragmentIndex);
            }
            lastFragmentIndex = pos;
            getSupportFragmentManager().beginTransaction()
                    .replace(R.id.fragment_stub, fragment)
                    .commitAllowingStateLoss();
        }
    }

//    private void takeSnapshot(int index) {
//        Bitmap bm = fragments[index].getSnapshot();
//        if (bm != null && !bm.isRecycled()) {
//            imgBackground.setImageBitmap(null);
//            if (bmSnapshot != null && !bmSnapshot.isRecycled()) {
//                bmSnapshot.recycle();
//            }
//            bmSnapshot = bm;
//            imgBackground.setImageBitmap(bmSnapshot);
//        }
//    }

    private void enableTabHost(boolean enable) {
        for(int i = 0; i < tabHost.getTabCount(); i++) {
            View viewGroup = tabHost.getChildAt(i);
            if(viewGroup instanceof ViewGroup) {
                for(int c = 0; c < ((ViewGroup) viewGroup).getChildCount(); c++) {
                    View tabView = ((ViewGroup) viewGroup).getChildAt(c);
                    if(tabView != null) {
                        tabView.setEnabled(enable);
                    }
                }
            }
        }
    }
}
