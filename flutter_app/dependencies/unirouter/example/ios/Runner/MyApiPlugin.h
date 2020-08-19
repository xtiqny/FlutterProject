//
//  MyApiPlugin.h
//  Runner
//
//  Created by luogh on 2019/1/18.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

#import <Flutter/Flutter.h>

@interface MyApiPlugin : NSObject<FlutterPlugin>
+ (instancetype)sharedInstance;
- (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar;
- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result;
- (void)getText;
@property (nonatomic,strong) FlutterMethodChannel* methodChannel;
@end

