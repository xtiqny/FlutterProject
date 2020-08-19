package com.cn21.app.navigation.unirouterexample;

import android.app.Activity;
import android.os.Bundle;
import android.widget.Button;
import android.widget.LinearLayout;

import com.cn21.app.navigation.UniRouter;

import java.util.HashMap;

public class UniDemoActivity extends Activity{
    static int sNativeActivityIdx = 0;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.unidemo_activity);
        setupOperationBtns();
        setTitle(String.format("Native Demo Page(%d)",sNativeActivityIdx));
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

    void setupOperationBtns(){
        LinearLayout layout = findViewById(R.id.native_root);
        Button btn=new Button(this);
        btn.setLayoutParams(new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT));
        btn.setText("Click to jump Flutter");
        btn.setOnClickListener(v -> {
            HashMap<String,Object> m = new HashMap<>();
            m.put("flutter",true);
            UniRouter.instance().push(UniDemoActivity.this, "/flutterdemo", "n" + (sNativeActivityIdx++), m);

        });
        layout.addView(btn);

        btn=new Button(this);
        btn.setLayoutParams(new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT));
        btn.setText("Click to jump native");
        HashMap<String, Object> params = new HashMap<>();
        params.put("name", "/nativedemo");
        params.put("interval", 3000);
        HashMap<String, Object> ext = new HashMap<>();
        ext.put("show", false);
        btn.setOnClickListener(v -> UniRouter.instance().push(UniDemoActivity.this, "/nativedemo","n" + (sNativeActivityIdx++), params, ext));
        layout.addView(btn);
    }
}
