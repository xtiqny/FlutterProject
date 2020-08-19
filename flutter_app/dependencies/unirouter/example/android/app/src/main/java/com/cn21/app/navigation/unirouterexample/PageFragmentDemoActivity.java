package com.cn21.app.navigation.unirouterexample;

import android.os.Bundle;
import android.support.annotation.Nullable;
import android.support.design.widget.TabLayout;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentActivity;
import android.support.v4.app.FragmentManager;
import android.support.v4.app.FragmentPagerAdapter;
import android.support.v4.view.ViewPager;
import android.util.Log;

import com.cn21.app.navigation.flutter.UniFlutterContainerFragment;

import java.util.HashMap;

public class PageFragmentDemoActivity extends FragmentActivity {
    public  static final String ACTION_PUSH = "navigation.intent.action.PUSH";
    private TabLayout tabHost;
    private static int fragInstIncreament = 0;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.page_fragment_activity);
        initTabHost();

    }

    @Override
    protected void onResume() {
        super.onResume();
    }

    @Override
    protected void onPostResume() {
        super.onPostResume();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
    }

    @Override
    protected void onPause() {
        super.onPause();
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
        ViewPager viewPager = findViewById(R.id.viewpager);
        //自定义的Adapter继承自FragmentPagerAdapter
        final MyPagerAdapter adapter = new MyPagerAdapter(
                getSupportFragmentManager(), tabHost.getTabCount());
        viewPager.setOffscreenPageLimit(0);

        //ViewPager设置Adapter
        viewPager.setAdapter(adapter);
        viewPager.setOffscreenPageLimit(0);

        //为ViewPager添加页面改变监听
        viewPager.addOnPageChangeListener(new TabLayout.TabLayoutOnPageChangeListener(tabHost));
        viewPager.setOffscreenPageLimit(0);

        tabHost.addOnTabSelectedListener(new TabLayout.OnTabSelectedListener() {
            @Override
            public void onTabSelected(TabLayout.Tab tab) {
                viewPager.setCurrentItem(tab.getPosition());
            }

            @Override
            public void onTabUnselected(TabLayout.Tab tab) {

            }

            @Override
            public void onTabReselected(TabLayout.Tab tab) {

            }
        });
        tabHost.getTabAt(0).select();
//        getSupportFragmentManager().beginTransaction().replace(R.id.fragment_stub, fragments[0]).commit();
    }

    public class MyPagerAdapter extends FragmentPagerAdapter {
        //fragment的数量
        int nNumOfTabs;
        public MyPagerAdapter(FragmentManager fm, int nNumOfTabs)
        {
            super(fm);
            this.nNumOfTabs=nNumOfTabs;
        }

        /**
         * 重写getItem方法
         *
         * @param position 指定的位置
         * @return 特定的Fragment
         */
        @Override
        public Fragment getItem(int position) {
            Log.w("ViewPager", "------> getItem for pos:" + position);
            switch(position)
            {
                case 0:
                    return buildFragment("Left", "fltfrag://fragdemo?p=left", null);
                case 1:
                    return buildFragment("Center", "fltfrag://fragdemo?p=center", null);
                case 2:
                    return buildFragment("Right", "fltfrag://fragdemo?p=right", null);
            }
            return null;
        }

        /**
         * 重写getCount方法
         *
         * @return fragment的数量
         */
        @Override
        public int getCount() {
            return nNumOfTabs;
        }
    }
}
