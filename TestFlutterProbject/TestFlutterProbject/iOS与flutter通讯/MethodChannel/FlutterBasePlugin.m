//
//  FlutterBasePlugin.m
//  TestFlutterProbject
//
//  Created by 张耀 on 2020/8/21.
//  Copyright © 2020 张耀. All rights reserved.
//

#import "FlutterBasePlugin.h"
#import "FlutterPluginManager.h"

@interface FlutterBasePlugin()
@property (nonatomic,strong) NSObject<FlutterPluginRegistrar>* registrar;
@end

@implementation FlutterBasePlugin

///初始化
+ (instancetype)sharedPlugin
{
    return [FlutterPluginManager pluginForChannel:[self pluginChannelName]];
}

/// 通道名称
+ (NSString *)pluginChannelName
{
    return @"";
}

/// 注册通道
- (void)registerChannelWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar
{
    self.methodChannel = [FlutterMethodChannel
                          methodChannelWithName:[[self class] pluginChannelName]
                          binaryMessenger:[registrar messenger]];
    [registrar addMethodCallDelegate:self channel:self.methodChannel];
    self.registrar = registrar;
}


#pragma mark FlutterPlugin
+ (void)registerWithRegistrar:(nonnull NSObject<FlutterPluginRegistrar> *)registrar {
    FlutterBasePlugin * instance = [self sharedPlugin];
    [instance registerChannelWithRegistrar:registrar];
}

@end
