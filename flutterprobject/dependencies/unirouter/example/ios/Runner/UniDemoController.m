#import "UniDemoController.h"
#import <unirouter/UniRouter.h>

static NSInteger sNativeVCIdx = 1;

@interface UniDemoController ()
@end

@implementation UniDemoController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *title = [NSString stringWithFormat:@"Native demo page(%ld)",(long)sNativeVCIdx];
    self.title = title;
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}

- (void)loadView{
    UIView *view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [view setBackgroundColor:[UIColor whiteColor]];
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 200, 40)];
    [btn setTitle:@"Click to jump Native" forState:UIControlStateNormal];
    [view addSubview:btn];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn setCenter:CGPointMake(view.center.x, view.center.y-50)];
    [btn addTarget:self action:@selector(onJumpNativePressed) forControlEvents:UIControlEventTouchUpInside];
    
    btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 200, 40)];
    [btn setTitle:@"Click to jump Flutter" forState:UIControlStateNormal];
    [view addSubview:btn];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn setCenter:CGPointMake(view.center.x, view.center.y+50)];
    [btn addTarget:self action:@selector(onJumpFlutterPressed) forControlEvents:UIControlEventTouchUpInside];
    
    self.view = view;
}

- (void)onJumpNativePressed{
    NSString *instanceKey = [NSString stringWithFormat:@"n%ld",(long)++sNativeVCIdx];
    [[UniRouter sharedInstance] push:@"/nativedemo" instanceKey:instanceKey params:@{} resultCallback:^(NSDictionary * result) {
        NSLog(@"-------------> /nativedemo Returns result:%@", (result)? @"OK" : @"Nil");
    } completion:^(BOOL done){
        NSLog(@"-----------> Pushed /nativedemo");
    }];
}

- (void)onJumpFlutterPressed{
    NSString *instanceKey = [NSString stringWithFormat:@"n%ld",(long)++sNativeVCIdx];
    [[UniRouter sharedInstance] push:@"/flutterdemo" instanceKey:instanceKey params:@{} resultCallback:^(NSDictionary * result) {
        NSLog(@"-------------> /flutterdemo Returns result:%@", (result)? @"OK" : @"Nil");
    } completion:^(BOOL done){
        NSLog(@"-----------> Pushed /flutterdemo");
    }];
}
@end
