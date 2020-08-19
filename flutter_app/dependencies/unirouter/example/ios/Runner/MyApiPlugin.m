//
//  MyApiPlugin.m
//  Runner
//
//  Created by luogh on 2019/1/18.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

#import "UniDemoController.h"
#import "MyApiPlugin.h"

@interface MyApiPlugin()
@property (nonatomic,strong) NSObject<FlutterPluginRegistrar>* registrar;
@end

@implementation MyApiPlugin
+ (instancetype)sharedInstance{
    static MyApiPlugin * sharedInst;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInst = [[MyApiPlugin alloc] init];
    });
    return sharedInst;
}

- (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar{
    self.methodChannel = [FlutterMethodChannel
                          methodChannelWithName:@"my_api_plugin"
                          binaryMessenger:[registrar messenger]];
    [registrar addMethodCallDelegate:self channel:self.methodChannel];
    self.registrar = registrar;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"getText" isEqualToString:call.method]) {
        NSLog(@"===========> %@", @"getText");
        result(@"Hello world");
    } else {
        result(@"");
    }
}

- (void)getText {
    if(self.methodChannel) {
        [self.methodChannel invokeMethod:@"getText" arguments:nil result:^(id  _Nullable result) {
            NSLog(@"<==================%@", result);
        }];
    }
}
@end
