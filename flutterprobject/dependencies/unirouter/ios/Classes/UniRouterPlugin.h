#import <Flutter/Flutter.h>
#import "UniRouter.h"

/**
 * 统一导航路由的Flutter UI栈处理插件
 * 实现了Flutter的插件处理接口，与 UniRouter 配合，
 * 支持Native与Flutter的混合栈管理
 * 注意：应用不要直接使用该类
 */
@interface UniRouterPlugin : NSObject<FlutterPlugin>
+ (instancetype)sharedInstance;
- (void)signalReady:(id)startArgs;
- (void)requestStartRoute:(ReadyHandler)hanlder;
@end

