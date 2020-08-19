#import "RestfulClientPlugin.h"
#import <restfulapi/restfulapi-Swift.h>
#import "RestfulHttpClientPlugin.h"

@implementation RestfulClientPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
 // [SwiftRestfulClientPlugin registerWithRegistrar:registrar];
   [RestfulHttpClientPlugin registerWithRegistrar:registrar];
}
@end
