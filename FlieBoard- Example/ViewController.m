//
//  ViewController.m
//  FlieBoard- Example
//
//  Created by develop5 on 2017/12/29.
//  Copyright © 2017年 yiqihi. All rights reserved.
//

#import "ViewController.h"
#import "ZYFlipViewController.h"
#import "ZYDetailViewController.h"
@interface ViewController ()<ZYFlipViewControllerDelegate>
@property(nonatomic, strong)ZYFlipViewController *flipViewController;
@property(nonatomic, strong)NSMutableArray *viewControllers;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.flipViewController.view];
    self.view.backgroundColor = [UIColor blackColor];
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (ZYFlipViewController *)flipViewController {
    if (_flipViewController == nil) {
        _flipViewController = [[ZYFlipViewController alloc]init];
        _flipViewController.viewControllers = self.viewControllers;
        _flipViewController.heardString = @"Hello FlieBoard";
        _flipViewController.delegate = self;
        
    }
    return _flipViewController;
}

- (NSMutableArray*)viewControllers{
    if (_viewControllers == nil) {
        ZYDetailViewController * vc1= [ZYDetailViewController new];
        vc1.numStr = @"1";
        ZYDetailViewController * vc2= [ZYDetailViewController new];
        vc2.numStr = @"2";
        ZYDetailViewController * vc3= [ZYDetailViewController new];
        vc3.numStr = @"3";
        ZYDetailViewController * vc4= [ZYDetailViewController new];
        vc4.numStr = @"4";
        ZYDetailViewController * vc5= [ZYDetailViewController new];
        vc5.numStr = @"5";
        ZYDetailViewController * vc6= [ZYDetailViewController new];
        vc6.numStr = @"6";
        _viewControllers = [NSMutableArray arrayWithObjects:vc1,vc2,vc3,vc4,vc5,vc6, nil];
    }
    return _viewControllers;
}
-(void)flipWillDoAction{
    NSLog(@"-----WillDoAction-----");
}
-(void)flipDidAction{
    NSLog(@"-----DidAction-----");
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
