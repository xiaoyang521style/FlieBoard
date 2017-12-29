//
//  ZYFlipHeardView.m
//  FlieBoard
//
//  Created by ios1 on 2017/10/24.
//  Copyright © 2017年 ios1. All rights reserved.
//

#define HeardW [UIScreen mainScreen].bounds.size.width
#define HeardH [UIScreen mainScreen].bounds.size.height/2
#define Device_Is_iPhoneX ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO)
#import "ZYFlipHeardView.h"

@implementation ZYFlipHeardView

-(instancetype)init{
    if ([super init]) {
        self.frame = CGRectMake(0, 0, HeardW, HeardH);
        [self addSubviews];
    }
    return self;
}

-(void)addSubviews{
    [self addSubview:self.textLabel];
}

-(UILabel *)textLabel {
    if (_textLabel == nil) {
        _textLabel = [UILabel new];
        if (Device_Is_iPhoneX) {
            _textLabel.frame = CGRectMake(0, 60, HeardW, 50);
        }else{
            _textLabel.frame = CGRectMake(0, 20, HeardW, 50);
        }
        _textLabel.font = [UIFont systemFontOfSize:20];
        _textLabel.textAlignment = NSTextAlignmentCenter;
        
        _textLabel.textColor = [UIColor whiteColor];
        
    }
    return _textLabel;
}



@end
