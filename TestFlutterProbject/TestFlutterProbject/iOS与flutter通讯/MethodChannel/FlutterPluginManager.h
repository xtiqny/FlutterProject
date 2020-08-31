//
//  FlutterPluginManager.h
//  Cloud189
//
//  Created by ouzy on 2019/4/3.
//  Copyright © 2019 21cn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@class FlutterBasePlugin;

@interface FlutterPluginManager : NSObject

/// 注册Flutter插件
+ (void)registerPlugin:(NSObject<FlutterPluginRegistry> *)registry;

/// 获取对应Channel插件
+ (FlutterBasePlugin *)pluginForChannel:(NSString *)channelName;

@end

NS_ASSUME_NONNULL_END
