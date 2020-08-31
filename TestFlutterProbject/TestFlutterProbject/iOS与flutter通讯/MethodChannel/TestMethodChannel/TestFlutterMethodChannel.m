//
//  TestFlutterMethodChannel.m
//  TestFlutterProbject
//
//  Created by 张耀 on 2020/8/24.
//  Copyright © 2020 张耀. All rights reserved.
//

#import "TestFlutterMethodChannel.h"

@implementation TestFlutterMethodChannel

+ (NSString *)pluginChannelName
{
    return @"com.Test.zhangyao/user_info";
}

#pragma mark - FlutterPlugin
- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result
{
    if([call.method isEqualToString:@"getUserInfo"]) {
        result([self getUserInfo]);
    }
}

- (NSString *)getUserInfo
{
    return @"cctv";
//    NSMutableDictionary * info = [NSMutableDictionary dictionary];
//    [info setObject:@"张耀" forKey:@"name"];
//    [info setValue:@"3" forKey:@"cctv"];
//    return info;
}

- (void)onUserInfoChangedEvent:(NSInteger)type
{
    if(type <= 0)
    {
        return;
    }
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic setValue:[NSNumber numberWithInteger:type] forKey:@"type"];
    [self.methodChannel invokeMethod:@"notifyUserInfoChanged" arguments:dic];
}


@end
