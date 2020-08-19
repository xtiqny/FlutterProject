#import "RouteAction.h"
#import <flutter_boost/FLBFlutterViewContainer.h>
#import <flutter_boost/FlutterBoostPlugin.h>
#import "UniRouter.h"
#import "UniRouterPlugin.h"

#define kInstanceKey @"instanceKey"
#define kSendResultOnly @"_sendResultOnly_"

@interface UniRouter() {
    NSMutableArray<id<RouteListener>> * _routeListeners;

}
- (void)setFlutterEngine:(FlutterEngine *)engine;
@end

@implementation UniRouter
@synthesize flutterEngine;
- (void)setFlutterEngine:(FlutterEngine *)engine {
    flutterEngine = engine;
}

+ (instancetype)sharedInstance{
    static UniRouter *sInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sInstance = [UniRouter new];
        [FlutterBoostPlugin.sharedInstance startFlutterWithPlatform:sInstance onStart:^(FlutterEngine *engine){
            sInstance.flutterEngine = engine;
        }];
    });
    return sInstance;
}

- (instancetype)init {
    if(self = [super init]){
        _routeListeners = [NSMutableArray<id<RouteListener>> new];
    }
    return self;
}

- (BOOL)startRoute:(ReadyHandler)handler startArgs:(NSString *)startArgs {
    [[UniRouterPlugin sharedInstance] signalReady:startArgs];
    if(handler) {
        [[UniRouterPlugin sharedInstance] requestStartRoute:handler];
    }
    return YES;
}

- (void)push:(NSString *)url instanceKey:(NSString *)instanceKey params:(NSDictionary *)params {
    [self push:url instanceKey:instanceKey params:params resultCallback:nil completion:nil];
}

- (void)push:(NSString *)url instanceKey:(NSString *)instanceKey params:(NSDictionary *)params resultCallback:(void (^)(NSDictionary * result))resultCallback completion:(void (^)(BOOL))completion {
    NSMutableDictionary * newParams = [NSMutableDictionary dictionaryWithDictionary:params];
    newParams[kInstanceKey] = instanceKey;
    [FlutterBoostPlugin open:url urlParams:newParams exts:@{} onPageFinished:resultCallback completion:completion];
}

- (BOOL)pushInternal:(NSString *)url instanceKey:(NSString *)instanceKey params:(NSDictionary *)params
          completion:(void (^)(BOOL))completion {
    RouteAction * action = nil;
    if(self.routeResolver != nil) {
        action = self.routeResolver(url, instanceKey, params);
        for(id<RouteListener> listener in _routeListeners) {
            if([listener respondsToSelector:@selector(onRouteResolved:instanceKey:params:action:)]) {
                [listener onRouteResolved:url instanceKey:instanceKey params:params action:action];
            }
        }
    } else {
        action = [RouteAction new];
        action.url = url;
        action.instanceKey = instanceKey;
        action.params = params;
    }
    if(action != nil) {
        BOOL handled = [self pushResolved:action];
        if(handled) {
            for(id<RouteListener> listener in _routeListeners) {
                if([listener respondsToSelector:@selector(onRouteHandled:)]) {
                    [listener onRouteHandled:action];
                }
            }
            if(completion) {
                completion(YES);
            }
        }
        return handled;
    }
    return false;
}

/**
 * 界面跳转入栈，适用于已经有最终路由信息的跳转
 * 应用程序通常应该使用 push 方法以真正达到解析
 * 和跳转分离的效果
 * @param action 跳转目标的路由信息对象
 * @return 是否成功入栈
 */
- (BOOL)pushResolved:(RouteAction *)action {
    if (self.nativePushHandler != nil) {
        BOOL done = self.nativePushHandler(action);
        return done;
    }
    return NO;
}

- (void) close:(NSString *)instanceKey result:(NSDictionary *)result
sendResultOnly:(BOOL)sendResultOnly completion:(void (^)(BOOL))completion {
    NSDictionary * ext = @{kSendResultOnly : @(sendResultOnly)};
    [FlutterBoostPlugin close:instanceKey result:result exts:ext completion:completion];
}

- (void) addListener:(id<RouteListener>)listener {
    [_routeListeners addObject:listener];
}

- (void) removeListener:(id<RouteListener>)listener {
    [_routeListeners removeObject:listener];
}

/**
 * 实现Flutter Boost的打开Flutter页面方法
 */
- (void)open:(NSString *)name
   urlParams:(NSDictionary *)params
        exts:(NSDictionary *)exts
  completion:(void (^)(BOOL))completion
{
    NSString * instanceKey = nil;
//    instanceKey = [params objectForKey:kInstanceKey];
    NSMutableDictionary * newParams = nil;
    if(params != nil) {
        instanceKey = [params objectForKey:kInstanceKey];
        newParams = [[NSMutableDictionary alloc] initWithDictionary:params];
        if(instanceKey != nil) {
            [newParams removeObjectForKey:kInstanceKey];
        }
    } else {
        newParams =[NSMutableDictionary new];
    }
    
    [self pushInternal:name instanceKey:instanceKey params:newParams completion:^(BOOL done) {}];
}

- (void)present:(NSString *)name
      urlParams:(NSDictionary *)params
           exts:(NSDictionary *)exts
     completion:(void (^)(BOOL))completion
{
    NSLog(@"=============== Not support present now!!!!!!!!!! ===============");
}

/**
 * 实现Flutter Boost的关闭Flutter页面方法
 */
- (void)close:(NSString *)uid result:(NSDictionary *)result
         exts:(NSDictionary *)exts completion:(void (^)(BOOL))completion
{
    BOOL animated = YES;
    FLBFlutterViewContainer *vc = (id)self.navigationController.presentedViewController;
    BOOL sendResultOnly = NO;
    if(exts && exts[kSendResultOnly] != nil) {
        sendResultOnly = exts[kSendResultOnly];
    }
    if(!sendResultOnly) {
        // FIXME: 当前我们只支持关闭最上层的界面（且必须是通过UniRouter push进来的）
        if([vc isKindOfClass:FLBFlutterViewContainer.class] && [vc.uniqueIDString isEqual: uid]){
            [vc dismissViewControllerAnimated:animated completion:^{}];
        }else{
            [self.navigationController popViewControllerAnimated:animated];
        }
    }
}

@end





