package com.cn21.app.navigation.flutter;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.util.Log;

import com.idlefish.flutterboost.interfaces.IContainerRecord;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.atomic.AtomicLong;

public class UniFlutterContainerDelegator {
    private HashMap<String, Object> containerParams = new HashMap<>(2);
    private Uri uri;
    private String instanceKey;

    private static AtomicLong sCounter = new AtomicLong(0);

    public void clear() {
        uri = null;
        instanceKey = null;
        containerParams.clear();
    }

    public boolean ready() {
        return (instanceKey != null);
    }

    public void setup(Intent intent) {
        if(ready()) {
            return;
        }
        if(intent != null) {
            uri = intent.getData();
            instanceKey = intent.getStringExtra("instanceKey");
            if(instanceKey == null || instanceKey.isEmpty()) {
                instanceKey = generateInstanceKey((uri != null)? uri.toString() : "instance");
            }
            HashMap<String, Object> params = (HashMap) intent.getSerializableExtra("params");
            if(params != null) {
                containerParams = params;
            }
            // 将instanceKey植入params中，flutter boost会自动读取作为unique id
            addUniqueKeyToParams();
        }
    }

    public void setup(Bundle args) {
        if(ready()) {
            return;
        }
        if(args != null) {
            String strUrl = args.getString("url");
            if(strUrl != null && !strUrl.isEmpty()) {
                uri = Uri.parse(strUrl);
            }
            instanceKey = args.getString("instanceKey");
            if(instanceKey == null || instanceKey.isEmpty()) {
                instanceKey = generateInstanceKey((uri != null)? uri.toString() : "instance");
            }
            HashMap<String, Object> params = (HashMap) args.getSerializable("params");
            if(params != null) {
                containerParams = params;
            }
            // 将instanceKey植入params中，flutter boost会自动读取作为unique id
            addUniqueKeyToParams();
        } else {
            Log.w("", "getContainerName but current getArguments() returns null!");
        }

    }

    private String generateInstanceKey(String url) {
        return url + ":auto_" + sCounter.incrementAndGet();
    }

    private void addUniqueKeyToParams() {
        if(!containerParams.containsKey(IContainerRecord.UNIQ_KEY)) {
            if(instanceKey != null && !instanceKey.isEmpty()) {
                containerParams.put(IContainerRecord.UNIQ_KEY, instanceKey);
            }
        }
    }

    public Map getContainerUrlParams() {
        return containerParams;
    }



    public String getInstanceKey() {
        return instanceKey != null? instanceKey : "";
    }

    public String getContainerUrl() {
        if(uri == null) {
            return "";
        }
        return uri.toString();
    }
}
