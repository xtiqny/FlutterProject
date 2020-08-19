package com.cn21.app.navigation;

import android.app.Activity;
import android.app.Application;
import android.content.Context;
import android.net.Uri;
import android.util.Log;


import com.cn21.app.navigation.flutter.FlutterAgent;
import com.cn21.app.navigation.flutter.UniRouterPlugin;
import com.idlefish.flutterboost.NewFlutterBoost;
import com.idlefish.flutterboost.Platform;
import com.idlefish.flutterboost.interfaces.INativeRouter;

import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

import io.flutter.BuildConfig;
import io.flutter.embedding.android.FlutterView;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.view.FlutterMain;

/**
 * 统一导航路由对象
 * 用于作为应用级别的统一接口，解耦并处理应用各功能界面的
 * 路由跳转。应用程序可以利用setRouteResolver和setNativePushHandler
 * 方法动态配置实际执行跳转的逻辑，达到配置和使用分离的效果。
 * 该类中所有方法及字段都必须保证在UI线程中访问。
 */
public class UniRouter {
    private static final String TAG = "UniRouter";
    private static UniRouter sRouterInst;
    private RouteResolver routeResolver;
    private NativePushHandler nativeHandler;
    private Activity mainActivity = null;
    private static int sInstanceKeyId = 0;

    public interface ResultCallback {
        void onResult(int requestCode, Map<String, Object> result);
    }

    /**
     * 路由监听接口
     */
    public interface RouteListener {
        /**
         * 通知路由解析完成
         *
         * @param context     Activity或Application的Context
         * @param url         原跳转请求的url
         * @param instanceKey 原跳转请求的instanceKey
         * @param params      原跳转请求的params
         * @param ext         扩展参数，例如用于控制整体动画等非功能相关因素
         * @param action      解析的路由结果
         */
        void onRouteResolved(Context context, String url, String instanceKey, Map params/*, Map ext*/, RouteAction action);

        /**
         * 通知路由跳转处理完成
         *
         * @param context Activity或Application的Context
         * @param action  已经处理的路由信息
         */
        void onRouteHandled(Context context, RouteAction action);
    }

    private ArrayList<RouteListener> routeListeners = new ArrayList<>();

    /**
     * 添加路由监听对象
     *
     * @param listener RouteListener对象
     */
    public void addListener(RouteListener listener) {
        if (!routeListeners.contains(listener)) {
            routeListeners.add(listener);
        }
    }

    /**
     * 移除路由监听对象
     *
     * @param listener RouteListener对象
     * @return 是否成功移除
     */
    public boolean removeListener(RouteListener listener) {
        return routeListeners.remove(listener);
    }

    /**
     * 获取单例
     *
     * @return UniRouter 单例
     */
    public static UniRouter instance() {
        if (sRouterInst == null) {
            sRouterInst = new UniRouter();
        }
        return sRouterInst;
    }

    /**
     * 初始化方法
     *
     * @param app 应用的Application对象
     */
    public void init(final Application app) {
        FlutterAgent.instance().init(app.getApplicationContext());
        INativeRouter router = new INativeRouter() {
            @Override
            public void openContainer(Context context, String url, Map<String, Object> urlParams, int requestCode, Map<String, Object> exts) {
                String instanceKey = null;
                if(urlParams != null) {
                    instanceKey = (String)urlParams.get("instanceKey");
                    if(instanceKey != null) {
                        urlParams.remove("instanceKey");
                    }
                }
                RouteAction action = new RouteAction(url, instanceKey, urlParams, exts);
                if(action != null) {
                    push(context, action.url, action.instanceKey, action.params, action.ext);
                }
            }

        };

        NewFlutterBoost.BoostLifecycleListener lifecycleListener= new NewFlutterBoost.BoostLifecycleListener() {
            @Override
            public void onEngineCreated() {

            }

            @Override
            public void onPluginsRegistered() {
//                MethodChannel mMethodChannel = new MethodChannel( NewFlutterBoost.instance().engineProvider().getDartExecutor(), "methodChannel");
//                Log.e("MyApplication","MethodChannel create");

            }

            @Override
            public void onEngineDestroy() {

            }
        };
        Platform platform= new NewFlutterBoost
                .ConfigBuilder(app,router)
                .isDebug(BuildConfig.DEBUG)
                .whenEngineStart(NewFlutterBoost.ConfigBuilder.IMMEDIATELY)
                .lifecycleListener(lifecycleListener)
                .renderMode(FlutterView.RenderMode.texture)
                .whenEngineDestory(NewFlutterBoost.ConfigBuilder.APP_EXit)
                .build();

        NewFlutterBoost.instance().init(platform);

        try {
//            // FIXME:
//            // 由于FlutterBoost没有提供直接方法自定义id，为了不过多侵入FlutterBoost，导致
//            // 版本更新的维护困难，此处使用反射的方式处理。如果后期FlutterBoost提供了相应的
//            // 设置id方法，则去除此处的代码
//            FlutterViewContainerManager containerManager = (FlutterViewContainerManager) NewFlutterBoost.instance().containerManager();
//            Field recordField = FlutterViewContainerManager.class.getDeclaredField("mRecordMap");
//            recordField.setAccessible(true);
//            UniLinkedHashMap<IFlutterViewContainer, IContainerRecord> records = new UniLinkedHashMap<>();
//            recordField.set(containerManager, records);
//            FlutterViewProvider provider = (FlutterViewProvider)FlutterBoostPlugin.viewProvider();
//            Field flutterNativeViewField = FlutterViewProvider.class.getDeclaredField("mFlutterNativeView");
//            flutterNativeViewField.setAccessible(true);
            FlutterMain.ensureInitializationComplete(app.getApplicationContext(), null);
//            BoostFlutterNativeView nativeView = (BoostFlutterNativeView)FlutterAgent.instance().getNativeView();
//            flutterNativeViewField.set(provider, nativeView);

            // 注册必要的plugin
            Class c = Class.forName("io.flutter.plugins.GeneratedPluginRegistrant");
            Method method = c.getMethod("registerWith", PluginRegistry.class);
            method.invoke(null, NewFlutterBoost.instance().getPluginRegistry());

            // 启动Flutter端的运行代码
            FlutterAgent.instance().runBundle(null);
        } catch (Throwable e) {
            Log.e(TAG, e.getMessage(), e);
            throw new IllegalStateException("Failed to init UniRouter", e);
        }
    }

    public interface ReadyHandler {
        void onReady();

        void onError(Throwable e);
    }

    /**
     * 启动路由管理
     * 当路由器启动并初始化后，将会通过handler通知应用程序，应用程序
     * 可以选择在收到回调后完成整个应用的初始化工作并启动起始界面。
     *
     * @param handler   (Nullable)路由启动并初始化好后的回调处理器
     * @param startArgs (Nullable)路由启动时的初始化参数，可以在Flutter端的PrepareApp的回调中获取到
     */
    public void startRoute(ReadyHandler handler, String startArgs) {
        UniRouterPlugin.instance().signalReady(startArgs);
        if (handler != null) {
            UniRouterPlugin.instance().requestStartRoute(handler);
        }
    }

    /**
     * 设置导航路由解析器对象。
     * 应用程序通过该接口实现定制化路由
     *
     * @param routeResolver RouteResolver 对象
     */
    public void setRouteResolver(RouteResolver routeResolver) {
        this.routeResolver = routeResolver;
    }

    /**
     * 设置Native的跳转处理对象。
     * 应用程序可以通过该接口定制化
     *
     * @param handler NativePushHandler 对象
     */
    public void setNativePushHandler(NativePushHandler handler) {
        nativeHandler = handler;
    }

    /**
     * 界面跳转入栈
     *
     * @param context     Activity context
     * @param url         目标url
     * @param instanceKey 目标实例key，用于标识实例，同一key的实例不能同时存在于栈中。如果intanceKey为null，RouteResolver或PushHandler必须负责生成唯一的intanceKey
     * @param params      跳转参数
     * @return 是否成功入栈
     */
    public boolean push(Context context, String url, String instanceKey, Map params) {
        return push(context, url, instanceKey, params, null);
    }

    /**
     * 界面跳转入栈
     *
     * @param context     Activity context
     * @param url         目标url
     * @param instanceKey 目标实例key，用于标识实例，同一key的实例不能同时存在于栈中。如果intanceKey为null，RouteResolver或PushHandler必须负责生成唯一的intanceKey
     * @param params      跳转参数
     * @param ext         扩展参数，例如用于控制整体动画等非功能相关因素
     * @return 是否成功入栈
     */
    public boolean push(Context context, String url, String instanceKey, Map params, Map ext) {
        RouteAction action;
        if (routeResolver != null) {
            action = routeResolver.resolveFor(url, instanceKey, params);
            if(action != null) {
                action.ext = ext;
            }
        } else {
            action = new RouteAction(url, instanceKey, params, ext);
        }
        if (action != null) {
            for (RouteListener listener : routeListeners) {
                listener.onRouteResolved(context, url, instanceKey, params, action);
            }
            return pushResolved(context, action);
        } else {
            return false;
        }
    }

    /**
     * 界面跳转入栈，适用于已经有最终路由信息的跳转
     * 应用程序通常应该使用 push 方法以真正达到解析
     * 和跳转分离的效果
     *
     * @param context Activity context
     * @param action  跳转目标的路由信息对象
     * @return 是否成功入栈
     */
    private boolean pushResolved(Context context, RouteAction action) {
        boolean handled = false;
        try {
            if (action.instanceKey == null) {
                // 自动生成唯一的instanceKey
                action.instanceKey = action.url + "_" + String.valueOf(++sInstanceKeyId);
            }
            if (nativeHandler != null) {
                handled = nativeHandler.handleNativePush(context, action);
            }
        } catch (Throwable e) {
            Log.e(TAG, e.getMessage());
        }
        if (handled) {
            for (RouteListener listener : routeListeners) {
                listener.onRouteHandled(context, action);
            }
        }
        return handled;
    }

    private RouteAction buildRouteActionFromUrl(String url) {
        RouteAction action;
        try {
            Uri uri = Uri.parse(url);
            Uri targetUrl = new Uri.Builder()
                    .scheme(uri.getScheme())
                    .encodedAuthority(uri.getEncodedAuthority())
                    .encodedPath(uri.getEncodedPath()).build();
            HashMap<String, String> params = new HashMap<>();
            HashMap<String, Object> ext = new HashMap<>();
            String val;
            String instanceKey = null;
            for (String key : uri.getQueryParameterNames()) {
                val = uri.getQueryParameter(key);
                if (key.startsWith("_ext_")) {
                    // remove '_ext_' prefix and store it to ext.
                    String k = key.substring(5);
                    if(k.equals("animated")) {
                        ext.put(k, Boolean.valueOf(val));
                    } else {
                        ext.put(k, val);
                    }
                } else if (key.equals("instanceKey")) {
                    instanceKey = val;
                } else {
                    params.put(key, val);
                }
            }

            action = new RouteAction(targetUrl.toString(), instanceKey, params, ext);
            return action;
        } catch (Throwable e) {
            Log.e(TAG, e.getMessage(), e);
        }
        return null;
    }

//    private static class UniLinkedHashMap<K, V> extends LinkedHashMap<K, V> {
//        @Override
//        public V put(K key, V value) {
//            if(key instanceof InstanceKeyProvider && value instanceof ContainerRecord) {
//                try {
//                    Field field = ContainerRecord.class.getDeclaredField("mUniqueId");
//                    field.setAccessible(true);
//                    field.set(value, ((InstanceKeyProvider) key).getInstanceKey());
//                } catch (Throwable e) {
//                    e.printStackTrace();
//                }
//            }
//            return super.put(key, value);
//        }
//
//        @Override
//        public void putAll(Map<? extends K, ? extends V> m) {
//            throw new IllegalStateException("Not implemented");
//        }
//
//        @TargetApi(Build.VERSION_CODES.N)
//        @Override
//        public V putIfAbsent(K key, V value) {
//            throw new IllegalStateException("Not implemented");
//        }
//
//        @Override
//        public void replaceAll(BiFunction<? super K, ? super V, ? extends V> function) {
//            throw new IllegalStateException("Not implemented");
//        }
//
//        @Override
//        public boolean replace(K key, V oldValue, V newValue) {
//            throw new IllegalStateException("Not implemented");
//        }
//
//        @Override
//        public V replace(K key, V value) {
//            throw new IllegalStateException("Not implemented");
//        }
//
//        @Override
//        public V merge(K key, V value, BiFunction<? super V, ? super V, ? extends V> remappingFunction) {
//            throw new IllegalStateException("Not implemented");
//        }
//    }
}
