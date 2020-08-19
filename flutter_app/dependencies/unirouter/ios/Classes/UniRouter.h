#import <Foundation/Foundation.h>
#import <Flutter/FlutterEngine.h>
#import <flutter_boost/FLBPlatform.h>
#import "RouteAction.h"

/**
 * 导航路由目标解析器对象
 * 负责最终决定跳转目标（重定向）及其参数，实现路由的动态变更管理等
 * @param url 目标url
 * @param instanceKey 目标实例的key
 * @param params 跳转参数
 * @return 最终跳转的RouteAction对象。如果无法跳转则返回null
 */
typedef RouteAction * (^RouteResolver)(NSString * url, NSString * instanceKey, NSDictionary * params);

/**
 * Native 端导航跳转处理器
 * 该接口负责根据RouteAction 的信息创建跳转信息并执行跳转。
 * 实现时需要根据RouteAction 的url等信息判断跳转是否需要
 * 使用Flutter容器（跳转后将加载Flutter侧的界面）。
 * 当成功跳转（返回YES时），实现者需要负责调整后界面的返回值调用，
 * 即页面关闭需要返回值时调用
 * resultCallback（如果非nil的话）。如果页面不支持返回值，同样
 * 需要回调resultCallback并传入nil作为参数，这种情况下可以在
 * 页面关闭前调用（建议都应该支持返回值）。
 * @param action 路由信息对象
 * @return 返回是否成功跳转
 */
typedef BOOL (^NativePushHandler)(RouteAction * action);

typedef void (^ReadyHandler)(BOOL ready, NSError * error);

/*
 * 路由UI处理提供者接口
 * 需要返回结果的UIViewController需要实现该接口，当界面关闭时
 * 回调resultCallback传递结果
 */
@protocol RouteResultProvider <NSObject>
// 设置结果回调Block对象
- (void)setRouteResultCallback:(void (^)(NSDictionary *))resultCallback;
@end

/**
 * 路由监听接口
 */
@protocol RouteListener <NSObject>
@optional
/**
 * 通知路由解析完成
 * @param url 原跳转请求的url
 * @param instanceKey 原跳转请求的instanceKey
 * @param params 原跳转请求的params
 * @param action 解析的路由结果
 */
- (void) onRouteResolved:(NSString *)url instanceKey:(NSString *)instanceKey params:(NSDictionary *)params action:(RouteAction *)action;
/**
 * 通知路由跳转处理完成
 * @param action 已经处理的路由信息
 */
- (void) onRouteHandled:(RouteAction *)action;
@end

/**
 * 统一导航路由对象
 * 用于作为应用级别的统一接口，解耦并处理应用各功能界面的
 * 路由跳转。应用程序可以利用setRouteResolver和setNativePushHandler
 * 方法动态配置实际执行跳转的逻辑，达到配置和使用分离的效果。
 * 该类中所有方法及字段都必须保证在UI线程中访问。
 */
@interface UniRouter : NSObject<FLBPlatform>

@property (nonatomic, strong) UINavigationController *navigationController;
@property (readonly, strong) FlutterEngine *flutterEngine;

/**
 * 设置导航路由解析器对象。
 * 应用程序通过该接口实现定制化路由
 */
@property (nonatomic,weak) RouteResolver routeResolver;

/**
 * 设置Native的跳转 Intent 解析器。
 * 应用程序可以通过该接口定制化
 */
@property (nonatomic,weak) NativePushHandler nativePushHandler;

+ (instancetype)sharedInstance;

/**
 * 启动路由管理
 * 当路由器启动并初始化后，将会通过handler通知应用程序，应用程序
 * 可以选择在收到回调后完成整个应用的初始化工作并启动起始界面。
 * @param handler (Nullable)路由启动并初始化好后的回调处理器
 * @param startArgs (Nullable)路由启动时的初始化参数，可以在Flutter端的PrepareApp的回调中获取到
 */
- (BOOL)startRoute:(ReadyHandler)handler startArgs:(NSString *)startArgs;

/**
 * 界面跳转入栈
 * @param url 目标url
 * @param instanceKey 目标实例key，用于标识实例，同一key的实例不能同时存在于栈中。intanceKey可以为null，这样等同于以url作为唯一性的判断
 * @param params 跳转参数
 */
- (void)push:(NSString *)url instanceKey:(NSString *)instanceKey params:(NSDictionary *)params;

/**
 * 界面跳转入栈
 * @param url 目标url
 * @param instanceKey 目标实例key，用于标识实例，同一key的实例不能同时存在于栈中。intanceKey可以为null，这样等同于以url作为唯一性的判断
 * @param params 跳转参数
 * @param resultCallback 结果回调Block，回调时result为nil表示不支持返回结果
 * @param completion 跳转新界面后回调Block
 */
- (void)push:(NSString *)url instanceKey:(NSString *)instanceKey params:(NSDictionary *)params resultCallback:(void (^)(NSDictionary * result))resultCallback completion:(void (^)(BOOL))completion;

/**
 * 关闭界面及返回结果
 * @param instanceKey 目标实例key(不可为nil)
 * @param result 需要返回的结果，nil表示不支持结果返回
 * @param sendResultOnly 是否仅需要返回结果，不需要关闭以instanceKey标识的界面
 * @param completion 完成时回调Block，可为nil
 */
- (void)close:(NSString *)instanceKey result:(NSDictionary *)result
    sendResultOnly:(BOOL)sendResultOnly completion:(void (^)(BOOL))completion;

/**
 * 添加路由监听对象
 * @param listener RouteListener对象
 */
- (void) addListener:(id<RouteListener>)listener;

/**
 * 移除路由监听对象
 * @param listener RouteListener对象
 */
- (void) removeListener:(id<RouteListener>)listener;

@end
