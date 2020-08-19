#import "Cn21basePlugin.h"
#import <cn21base/cn21base-Swift.h>

@implementation Cn21basePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftCn21basePlugin registerWithRegistrar:registrar];
}
@end
