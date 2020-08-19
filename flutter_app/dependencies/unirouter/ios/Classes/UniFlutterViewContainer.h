#import <Flutter/Flutter.h>
#import <flutter_boost/FLBFlutterViewContainer.h>

@interface UniFlutterViewContainer : FLBFlutterViewContainer
@property (nonatomic,copy,readonly) NSString *instanceKey;
- (instancetype)init;
- (instancetype)initWithRoute:(NSString *)url instanceKey:(NSString *)instanceKey params:(NSDictionary *)params;
-(void)setRoute:(NSString *)url instanceKey:(NSString *)instanceKey params:(NSDictionary *)params;
@end
