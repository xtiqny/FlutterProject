package com.cn21.app.navigation.unirouterexample;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.widget.Button;

import com.cn21.app.navigation.UniRouter;

import java.util.HashMap;

public class MainActivity extends Activity {
  private static int id = 0;
  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
//    UniRouter.instance().push(this, "/flutterdemo", null, new HashMap());
    setContentView(R.layout.placeholder);
    setTitle("Native Root Page");
    setupOperationBtns();
  }

  void setupOperationBtns(){
//    LinearLayout layout = findViewById(R.id.native_root);
//    final Button btn=new Button(this);
//    btn.setLayoutParams(new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT));
//    btn.setText("Click to jump Flutter");
    Button btn = findViewById(R.id.btnJumpFlutter);
    btn.setOnClickListener(v -> {
      HashMap<String,Object> m = new HashMap<>();
      m.put("flutter",true);
      UniRouter.instance().push(MainActivity.this, "/flutterdemo", "m" + (id++), m);

    });
//    layout.addView(btn);
//    TextView tvContent = findViewById(R.id.tvContent);
//    tvContent.setText("Open Flutter");
  }
}
