#import "UniRootController.h"
#import <unirouter/UniRouter.h>

@interface UniRootController ()

@end

@implementation UniRootController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Native root page";
    // Do any additional setup after loading the view.
}

- (void)loadView{
    UIView *view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [view setBackgroundColor:[UIColor whiteColor]];
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 200, 40)];
    [btn setTitle:@"Click to jump Flutter" forState:UIControlStateNormal];
    [view addSubview:btn];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn setCenter:view.center];
    [btn addTarget:self action:@selector(onJumpFlutterPressed) forControlEvents:UIControlEventTouchUpInside];
    self.view = view;
}

- (void)onJumpFlutterPressed{
    [[UniRouter sharedInstance] push:@"/flutterdemo" instanceKey:@"n0" params:@{} resultCallback:^(NSDictionary * result) {
        NSLog(@"-------------> /flutterdemo Returns result:%@", (result)? @"OK" : @"Nil");
    } completion:^(BOOL done){
        NSLog(@"-----------> Pushed /flutterdemo");
    }];
}
@end
