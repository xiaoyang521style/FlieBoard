//
//  ZYDetailViewController.m
//  翻页
//
//  Created by ios1 on 2017/10/10.
//  Copyright © 2017年 ios1. All rights reserved.
//
#define random(r, g, b, a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1]

#define randomColor random(arc4random_uniform(256), arc4random_uniform(256), arc4random_uniform(256), arc4random_uniform(256))

#import "ZYDetailViewController.h"

@interface ZYDetailViewController ()

@end

@implementation ZYDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor yellowColor];
    [self.view addSubview:self.numLa];
    
}

-(UILabel *)numLa {
    if (_numLa == nil) {
        _numLa = [[UILabel alloc]init];
        _numLa.frame = self.view.frame;
        _numLa.font = [UIFont systemFontOfSize:250];
        _numLa.textAlignment = NSTextAlignmentCenter;
        _numLa.text = self.numStr;
    }
    return _numLa;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
