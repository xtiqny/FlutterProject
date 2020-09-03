#import "SceneDelegate.h"
#import "TestFlutterMethodChannel.h"

@interface SceneDelegate ()

@property (nonatomic, strong) FlutterEventChannel *eventChannel;
@property (nonatomic, copy) FlutterEventSink sink;

@end

@implementation SceneDelegate


- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
    // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
    // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        [TestFlutterMethodChannel sharedPlugin];
    FlutterViewController *mainView = [[FlutterViewController alloc]init];
      UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:mainView];
    
    
    //flutter -> OC
    FlutterMethodChannel * methodChannel = [FlutterMethodChannel methodChannelWithName:@"com.cc.flutter.fileselect" binaryMessenger:mainView.binaryMessenger];
    [methodChannel setMethodCallHandler:^(FlutterMethodCall * _Nonnull call, FlutterResult  _Nonnull result) {
        if ([call.method isEqualToString:@"cityId"])
        {
              result([NSNumber numberWithInt:1]);
          }
            if([call.method isEqualToString:@"envType"])
          {
              [self updateWifi];
              result(@"1");
          }
            else
            {
            result(FlutterMethodNotImplemented);
        }
    }];
    
    
    self.eventChannel = [FlutterEventChannel eventChannelWithName:@"ios_event_channel" binaryMessenger:(NSObject<FlutterBinaryMessenger> *)mainView];
     [self.eventChannel setStreamHandler:self];

    [self listeningWIFIChange];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateWifi) name:@"updateWifi" object:nil];

    //[GeneratedPluginRegistrant registerWithRegistry:self];
    
    
      UIWindowScene *windowScene = (UIWindowScene *)scene;
      self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
      self.window.frame = windowScene.coordinateSpace.bounds;
      [self.window addSubview:mainView.view];
      self.window.rootViewController = nav;
      [self.window makeKeyAndVisible];
    

}


- (void)sceneDidDisconnect:(UIScene *)scene {
    // Called as the scene is being released by the system.
    // This occurs shortly after the scene enters the background, or when its session is discarded.
    // Release any resources associated with this scene that can be re-created the next time the scene connects.
    // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
}


- (void)sceneDidBecomeActive:(UIScene *)scene {
    // Called when the scene has moved from an inactive state to an active state.
    // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
}


- (void)sceneWillResignActive:(UIScene *)scene {
    // Called when the scene will move from an active state to an inactive state.
    // This may occur due to temporary interruptions (ex. an incoming phone call).
}


- (void)sceneWillEnterForeground:(UIScene *)scene {
    // Called as the scene transitions from the background to the foreground.
    // Use this method to undo the changes made on entering the background.
}


- (void)sceneDidEnterBackground:(UIScene *)scene {
    // Called as the scene transitions from the foreground to the background.
    // Use this method to save data, release shared resources, and store enough scene-specific state information
    // to restore the scene back to its current state.
}

- (NSString *)getWifi{
    
    return @"wifi";
}


- (void)updateWifi{
    NSString *wifiName = [self getWifi];
    NSLog(@"ios ---- 网络变化-----wifiName:%@",wifiName);
    NSLog(@"%@",self.sink);
//通过该方法传值给flutter
    if (self.sink != nil){
   //当有多个值返回给flutter的时候，比如获取wifi、获取手机版本号等等，可以给dic添加个参数key区分参数，方便flutter接收的时候区分
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        [dic setValue:@"key" forKey:@"wifi"];
        [dic setValue:@"name" forKey:wifiName];
        self.sink(dic);
    }
}

//监听网络变化
- (void)listeningWIFIChange{

    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL,onNotifyCallback, CFSTR("com.apple.system.config.network_change"), NULL,CFNotificationSuspensionBehaviorDeliverImmediately);
}

static void onNotifyCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo){
    NSString* notifyName = (__bridge NSString *) name;
    if ([notifyName isEqualToString:@"com.apple.system.config.network_change"]) {
        NSLog(@"======网络变化");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"updateWifi" object:nil];
    } else {
        NSLog(@"intercepted %@", notifyName);
    }
}

#pragma mark - <FlutterStreamHandler>

// 这个onListen是Flutter端开始监听这个channel时的回调，第二个参数 EventSink是用来传数据的载体
- (FlutterError* _Nullable)onListenWithArguments:(id _Nullable)arguments
                                       eventSink:(FlutterEventSink)events {
    NSLog(@"onListenWithArguments");
    self.sink = events;
    return nil;
}

- (FlutterError* _Nullable)onCancelWithArguments:(id _Nullable)arguments {
    NSLog(@"onCancelWithArguments");
    return  nil;
}


@end
