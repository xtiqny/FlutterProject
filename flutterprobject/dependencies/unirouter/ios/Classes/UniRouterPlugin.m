#import <sys/utsname.h>
#import "RouteAction.h"
#import "UniRouterPlugin.h"

@interface UniRouterPlugin() {
    BOOL _isReady;
    BOOL _flutterSideRunning;
    id _startArgs;
    FlutterResult _methodResult;
    ReadyHandler _readyHandler;
}
@property (nonatomic,strong) NSObject<FlutterPluginRegistrar>* registrar;
@property (nonatomic,strong) FlutterMethodChannel* methodChannel;
@end

@implementation UniRouterPlugin
+ (instancetype)sharedInstance{
    static UniRouterPlugin * sharedInst;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInst = [[UniRouterPlugin alloc] init];
    });
    return sharedInst;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar{
    UniRouterPlugin* instance = [UniRouterPlugin sharedInstance];
    instance.methodChannel = [FlutterMethodChannel
                              methodChannelWithName:@"unirouter_manager"
                              binaryMessenger:[registrar messenger]];
    [registrar addMethodCallDelegate:instance channel:instance.methodChannel];
    instance.registrar = registrar;
}

- (void)signalReady:(id)startArgs {
    if(_isReady == YES) {
        return;
    }
    _isReady = YES;
    if(_methodResult) {
        _methodResult(startArgs);
        _methodResult = nil;
    } else {
        _startArgs = startArgs;
    }
    [self safeRequestStartRoute];
}

-(void)requestStartRoute:(ReadyHandler)hanlder {
    _readyHandler = hanlder;
    if(_isReady) {
        [self safeRequestStartRoute];
    }
}

- (void)safeRequestStartRoute {
    if(_readyHandler && _flutterSideRunning) {
        ReadyHandler handler = _readyHandler;
        _readyHandler = nil;
        [_methodChannel invokeMethod:@"startRoute" arguments:nil result:^(id _Nullable result){
            if(result == FlutterMethodNotImplemented) {
                NSError * error = [NSError errorWithDomain:@"FlutterError" code:-1 userInfo:nil];
                handler(NO, error);
            }
            else if(result != nil && [result isKindOfClass:NSError.class]) {
                handler(NO, result);
            }
            else {
                handler(YES, nil);
            }
        }];
    }
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if([call.method isEqualToString:@"waitForReady"]) {
        _flutterSideRunning = true;
        if(_isReady) {
            result(_startArgs);
            _startArgs = nil;
            [self safeRequestStartRoute];
        } else {
            _methodResult = result;
        }
    } else {
        result(FlutterMethodNotImplemented);
    }
}
@end
