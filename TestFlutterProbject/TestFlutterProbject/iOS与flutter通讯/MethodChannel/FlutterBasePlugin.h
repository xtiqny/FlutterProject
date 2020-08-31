//
//  FlutterBasePlugin.h
//  TestFlutterProbject
//
//  Created by 张耀 on 2020/8/21.
//  Copyright © 2020 张耀. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>
NS_ASSUME_NONNULL_BEGIN

@interface FlutterBasePlugin : NSObject<FlutterPlugin>
//当前通讯通道对象
@property (nonatomic, strong) FlutterMethodChannel * methodChannel;

///初始化
+ (instancetype)sharedPlugin;

/// 通道名称
+ (NSString *)pluginChannelName;

/// 注册通道
- (void)registerChannelWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar;

@end

NS_ASSUME_NONNULL_END
