#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"
#import "UniRootController.h"
#import <unirouter/UniRouter.h>
#import "UniDemoController.h"
#import <unirouter/UniFlutterViewContainer.h>

@interface MyListener : NSObject<RouteListener>
- (void)onRouteResolved:(NSString *)url instanceKey:(NSString *)instanceKey params:(NSDictionary *)params action:(RouteAction *)action;
- (void)onRouteHandled:(RouteAction *)action;
@end

@implementation MyListener

- (void)onRouteResolved:(NSString *)url instanceKey:(NSString *)instanceKey params:(NSDictionary *)params action:(RouteAction *)action {
    NSLog(@"onRouteResolved %@ -> %@", url, action.url);
}
- (void)onRouteHandled:(RouteAction *)action; {
    NSLog(@"onRouteHandled %@", action.url);
}

@end

@interface AppDelegate(UIGestureRecognizerDelegate)
@end

@implementation AppDelegate
- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    UINavigationController *rootNav = [[UINavigationController alloc] initWithRootViewController:[UniRootController new]];
    rootNav.interactivePopGestureRecognizer.delegate = self;
    UIWindow *window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    window.rootViewController = rootNav;
    [window makeKeyAndVisible];
    self.window = window;
    [self setupNativeOpenUrlHandler];
    [UniRouter sharedInstance].navigationController = rootNav;
    [[UniRouter sharedInstance] startRoute: ^(BOOL ready, NSError * error) {
        if(ready) {
            NSLog(@"========> Start route ready.");
        } else {
            NSLog(@"========> Start route not ready.");
        }
    } startArgs:nil];
    return YES;
}

- (void)setupNativeOpenUrlHandler{
    static NSInteger gSeq = 10000;
    static RouteResolver routeResolver = ^RouteAction *(NSString *url, NSString *instanceKey, NSDictionary *params) {
        RouteAction * routeAction = [RouteAction new];
        routeAction.url = url;
        routeAction.instanceKey = instanceKey;
        routeAction.params = params;
        if(routeAction.instanceKey == nil) {
            routeAction.instanceKey = [NSString stringWithFormat:@"x%d", (int)(gSeq++)];
        }
        return routeAction;
    };
    
    [UniRouter sharedInstance].routeResolver = routeResolver;
    
    static NativePushHandler nativePushHandler = ^BOOL (RouteAction *action) {
        if(![action.url hasPrefix:@"/nativedemo"]) {
            // Flutter
            UniFlutterViewContainer *vc = [[UniFlutterViewContainer alloc] initWithRoute:action.url instanceKey:action.instanceKey params:action.params];
            [[UniRouter sharedInstance].navigationController pushViewController:vc animated:YES];
            return YES;
        }
        else {
            UIViewController *vc = [UniDemoController new];
            if(vc!=nil) {
                UINavigationController *rootNav = (UINavigationController*)[UIApplication sharedApplication].delegate.window.rootViewController;
                [rootNav pushViewController:vc animated:YES];
                return YES;
            }
        }
        return NO;
    };
    [UniRouter sharedInstance].nativePushHandler = nativePushHandler;
    
    static MyListener * listener = nil;
    listener = [MyListener new];
    [[UniRouter sharedInstance] addListener:listener];
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    return TRUE;
}
@end
