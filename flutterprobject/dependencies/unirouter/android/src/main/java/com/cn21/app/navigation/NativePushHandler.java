package com.cn21.app.navigation;
import android.content.Context;

/**
 * Native 端导航跳转处理器
 * 该接口负责根据RouteAction 的信息执行Native端的跳转操作
 */
public interface NativePushHandler {
    /**
     * 根据RouteAction 构造跳转信息并执行跳转
     * 实现类需要根据RouteAction的url等信息判断跳转是否需要使用
     * Flutter容器（跳转后将加载Flutter侧的界面）。
     * @param context Application Context
     * @param action 路由信息对象
     * @return 是否成功跳转
     */
    boolean handleNativePush(Context context, RouteAction action);
}
