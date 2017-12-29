//
//  ZYFlipViewController.h
//  翻页
//
//  Created by ios1 on 2017/10/10.
//  Copyright © 2017年 ios1. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ZYFlipViewControllerDelegate

-(void)flipDidAction;

-(void)flipWillDoAction;

@end


@interface ZYFlipViewController : UIViewController

/**翻页手势*/
@property(nonatomic, strong)UIPanGestureRecognizer *pan;
/**控制器集合*/
@property(nonatomic, copy)NSMutableArray *viewControllers;

@property(nonatomic, assign)BOOL action;
/**头部背景文字*/
@property(nonatomic,copy)NSString *heardString;

@property(nonatomic, strong)id<ZYFlipViewControllerDelegate>delegate;

@end
