#import "UniFlutterViewContainer.h"
#import <Flutter/Flutter.h>

@interface UniFlutterViewContainer() {
    BOOL _navigationBarHidden;
}
//@property (nonatomic,assign) BOOL enableViewWillAppear;
@property (nonatomic,copy,readwrite) NSString *instanceKey;
-(BOOL) shouldHideNavigationBar;
@end

@implementation UniFlutterViewContainer
#pragma mark - LifeCycle
- (instancetype)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (instancetype)initWithRoute:(NSString *)url instanceKey:(NSString *)instanceKey params:(NSDictionary *)params {
    self = [super init];
    if (self) {
        [self setRoute:url instanceKey:instanceKey params:params];
    }
    return self;
}

-(void)setInstanceKey:(NSString *)instanceKey {
    self.instanceKey = instanceKey;
}

// Override if you want to show the navigation bar.
-(BOOL) shouldHideNavigationBar {
    return YES;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    _navigationBarHidden = self.navigationController.navigationBarHidden;
    BOOL shouldHide = [self shouldHideNavigationBar];
    if(_navigationBarHidden != shouldHide) {
        self.navigationController.navigationBarHidden = shouldHide;
    }
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    if(_navigationBarHidden != self.navigationController.navigationBarHidden) {
        self.navigationController.navigationBarHidden = _navigationBarHidden;
    }
}

-(void)setRoute:(NSString *)url instanceKey:(NSString *)instanceKey params:(NSDictionary *)params {
    _instanceKey = instanceKey;
    [self setName:url params:params];
}

- (NSString *)uniqueIDString
{
    return _instanceKey;
}

@end

