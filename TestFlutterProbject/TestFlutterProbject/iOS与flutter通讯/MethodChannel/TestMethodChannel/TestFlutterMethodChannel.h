//
//  TestFlutterMethodChannel.h
//  TestFlutterProbject
//
//  Created by 张耀 on 2020/8/24.
//  Copyright © 2020 张耀. All rights reserved.
//

#import "FlutterBasePlugin.h"

NS_ASSUME_NONNULL_BEGIN

@interface TestFlutterMethodChannel : FlutterBasePlugin

- (void)onUserInfoChangedEvent:(NSInteger)type;

@end

NS_ASSUME_NONNULL_END
