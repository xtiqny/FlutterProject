//
//  RestfulHttpClientPlugin.h
//  Cloud189
//
//  Created by cocoDevil on 2019/9/9.
//  Copyright © 2019 21cn. All rights reserved.
//

#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@interface RestfulHttpClientPlugin : NSObject<FlutterPlugin>

/// 通道名称
+ (NSString *)pluginChannelName;

/// 注册通道
- (void)registerChannelWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar;

/// 持有通道
@property (nonatomic,strong) FlutterMethodChannel* methodChannel;

@end

NS_ASSUME_NONNULL_END
