package com.cn21.app.navigation;

import java.util.HashMap;
import java.util.Map;

/**
 * 导航路由跳转信息类
 */
public class RouteAction {
    // 目标url
    public String url;
    // 目标实例的key（用于标识该实例）
    public String instanceKey;
    // 跳转附带的参数对象
    public Map params;
    // 扩展参数，例如用于控制整体动画等非功能相关因素
    public Map ext;
    public RouteAction(String url, String instanceKey, Map params) {
        this(url, instanceKey, params, null);
    }
    public RouteAction(String url, String instanceKey, Map params, Map ext) {
        this.url = url;
        this.instanceKey = instanceKey;
        this.params = params;
        this.ext = ext;
    }
}
