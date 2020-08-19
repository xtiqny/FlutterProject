#import <Foundation/Foundation.h>

/**
 * 导航路由跳转信息类
 */
@interface RouteAction : NSObject
// 目标url
@property (nonatomic,copy) NSString * url;
// 目标实例的key（用于标识该实例）
@property (nonatomic,copy) NSString * instanceKey;
// 跳转附带的参数对象
@property (nonatomic,strong) NSDictionary * params;
@end
