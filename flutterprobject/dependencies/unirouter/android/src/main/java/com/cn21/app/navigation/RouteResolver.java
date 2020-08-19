package com.cn21.app.navigation;

import java.util.Map;

/**
 * 导航路由目标解析器对象
 * 负责最终决定跳转目标（重定向）及其参数，实现路由的动态变更管理等
 */
public interface RouteResolver {
    /**
     * 根据原始目标信息解析最终的路由信息
     * @param url 目标url
     * @param instanceKey 目标实例的key
     * @param params 跳转参数
     * @param ext 扩展参数，例如用于控制整体动画等非功能相关因素
     * @return 最终跳转的RouteAction对象。如果无法跳转则返回null
     */
    RouteAction resolveFor(String url, String instanceKey, Map params/*, Map ext*/);
}
