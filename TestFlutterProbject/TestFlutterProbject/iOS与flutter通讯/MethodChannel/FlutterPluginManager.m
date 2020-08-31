//
//  FlutterPluginManager.m
//  Cloud189
//
//  Created by ouzy on 2019/4/3.
//  Copyright © 2019 21cn. All rights reserved.
//

#import "FlutterPluginManager.h"

#import "FlutterBasePlugin.h"
#import "TestFlutterMethodChannel.h"
//#import "MusicFlutterPlugin.h"
//#import "MyPageFlutterPlugin.h"
//#import "ContactsBackupPlugin.h"
//#import "FlutterUserInfoPlugin.h"
//#import "FlutterAlbumBackupPlugin.h"
//#import "FlutterTransferPlugin.h"
//#import "FlutterFamilyPlugin.h"
//#import "FlutterCorpPlugin.h"
//#import "CreateAlbumPlugin.h"
//#import "RecycleBinPlugin.h"
//#import "FlutterFileListPlugin.h"

@interface FlutterPluginManager ()

@property (nonatomic, strong) NSMutableDictionary <NSString *, FlutterBasePlugin *> * pluginDict;

@end

@implementation FlutterPluginManager

+ (instancetype)instance
{
    static dispatch_once_t onceToken;
    static FlutterPluginManager * pluginManager  = nil;
    dispatch_once(&onceToken, ^{
        pluginManager = [[FlutterPluginManager alloc] init];
    });
    return pluginManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (NSMutableDictionary<NSString *, FlutterBasePlugin *> *)pluginDict
{
    [self loadPluginDictionary];
    return _pluginDict;
}

- (void)loadPluginDictionary
{
    if (_pluginDict == nil)
    {
        _pluginDict = [NSMutableDictionary dictionary];
        [self addPlugin:[[TestFlutterMethodChannel alloc] init]];     // 公共插件
//        [self addPlugin:[[FlutterUserInfoPlugin alloc] init]];   //个人信息
//        [self addPlugin:[[MusicFlutterPlugin alloc] init]];      // 音乐播放插件
//        [self addPlugin:[[MyPageFlutterPlugin alloc] init]];     //我的页面
//        [self addPlugin:[[ContactsBackupPlugin alloc] init]];    //联系人备份
//        [self addPlugin:[[FlutterAlbumBackupPlugin alloc] init]];  //相册备份
//        [self addPlugin:[[FlutterTransferPlugin alloc] init]];     //传输管理
//        [self addPlugin:[[FlutterFamilyPlugin alloc] init]];       //家庭云列表
//        [self addPlugin:[[FlutterCorpPlugin alloc] init]];         //企业云列表
//        [self addPlugin:[[CreateAlbumPlugin alloc] init]];         //新建相册页面
//        [self addPlugin:[[RecycleBinPlugin alloc] init]];          //回收站
//        [self addPlugin:[[FlutterFileListPlugin alloc]init]];      //文件列表
    }
}

- (void)addPlugin:(FlutterBasePlugin *)plugin
{
    NSString * channelName = [[plugin class] pluginChannelName];
    if (channelName.length == 0)
    {
        return;
    }
    [_pluginDict setObject:plugin forKey:channelName];
}

+ (void)registerPlugin:(NSObject<FlutterPluginRegistry> *)registry
{
    
    [[FlutterPluginManager instance] registerPlugin:registry];
}

+ (FlutterBasePlugin *)pluginForChannel:(NSString *)channelName
{
    return [[FlutterPluginManager instance] pluginForChannel:channelName];
}

- (void)registerPlugin:(NSObject<FlutterPluginRegistry> *)registry
{
    [self.pluginDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, FlutterBasePlugin * _Nonnull obj, BOOL * _Nonnull stop) {
        [obj registerChannelWithRegistrar:[registry registrarForPlugin:key]];
    }];
}

- (FlutterBasePlugin *)pluginForChannel:(NSString *)channelName
{
    if (channelName.length == 0)
    {
        return nil;
    }
    return [self.pluginDict objectForKey:channelName];
}

- (void)registerHttpClientPlugin {
}

@end
