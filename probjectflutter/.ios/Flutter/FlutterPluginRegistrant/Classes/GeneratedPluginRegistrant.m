//
//  Generated file. Do not edit.
//

#import "GeneratedPluginRegistrant.h"

#if __has_include(<cn21base/Cn21basePlugin.h>)
#import <cn21base/Cn21basePlugin.h>
#else
@import cn21base;
#endif

#if __has_include(<connectivity/ConnectivityPlugin.h>)
#import <connectivity/ConnectivityPlugin.h>
#else
@import connectivity;
#endif

#if __has_include(<flutter_boost/FlutterBoostPlugin.h>)
#import <flutter_boost/FlutterBoostPlugin.h>
#else
@import flutter_boost;
#endif

#if __has_include(<path_provider/PathProviderPlugin.h>)
#import <path_provider/PathProviderPlugin.h>
#else
@import path_provider;
#endif

#if __has_include(<restfulapi/RestfulClientPlugin.h>)
#import <restfulapi/RestfulClientPlugin.h>
#else
@import restfulapi;
#endif

#if __has_include(<unirouter/UniRouterPlugin.h>)
#import <unirouter/UniRouterPlugin.h>
#else
@import unirouter;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [Cn21basePlugin registerWithRegistrar:[registry registrarForPlugin:@"Cn21basePlugin"]];
  [FLTConnectivityPlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTConnectivityPlugin"]];
  [FlutterBoostPlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterBoostPlugin"]];
  [FLTPathProviderPlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTPathProviderPlugin"]];
  [RestfulClientPlugin registerWithRegistrar:[registry registrarForPlugin:@"RestfulClientPlugin"]];
  [UniRouterPlugin registerWithRegistrar:[registry registrarForPlugin:@"UniRouterPlugin"]];
}

@end
