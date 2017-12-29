//
//  ZYFlipViewController.m
//  翻页
//
//  Created by ios1 on 2017/10/10.
//  Copyright © 2017年 ios1. All rights reserved.
//



#import "ZYFlipViewController.h"
#import "ZYFlipHeardView.h"
#import <AudioToolbox/AudioToolbox.h>
#include <math.h>
typedef NS_ENUM(NSInteger, ZYViewAnimationDirection) {
   ZYViewAnimationDirectionBackward = -1,
   ZYViewAnimationDirectionNone = 0,
   ZYViewAnimationDirectionForward = 1
};


static NSMutableArray *pendingFlips;
static dispatch_queue_t pageFlipDelayQueue;

@interface ZYFlipViewController ()
{
    BOOL _isCancel;
    CGPoint oldLocation;
    BOOL _isUp;
    BOOL _isAnimation;
    BOOL _isEnd;
    BOOL _isChange;
    BOOL _isPlayed;
}
/**翻页方向*/
@property(nonatomic, assign) ZYViewAnimationDirection direction;
/**当前控制器下标*/
@property(nonatomic, assign) NSInteger currentIndex;
/**当前控制器*/
@property(nonatomic, strong) UIViewController *currentVC;

/**下一个控制器*/
@property(nonatomic, strong) UIViewController *nextVC;


/**容器*/
@property(nonatomic, strong) UIView *containerView;
/**当控制器view*/
@property(nonatomic,strong) UIView *currentView;
/**下一个控制器view*/
@property(nonatomic, strong) UIView *nextView;
/**当控制器上半view*/
@property(nonatomic, strong) UIView *currentUpperView;

/**当控制器下半view*/
@property(nonatomic, strong) UIView *currentBottomView;
/**下一个控制器上半view*/
@property(nonatomic, strong)  UIView *nextUpperView ;

/**下一个控制器下半view*/
@property(nonatomic, strong) UIView *nextBottomView;

/**当控制器上半view阴影*/

@property(nonatomic,strong)UIView *currentUpperShadow;
/**当控制器下半view阴影*/
@property(nonatomic,strong)UIView *currentBottomShadow;
/**下一个控制器上半view*阴影*/
@property(nonatomic,strong)UIView *nextUpperShadow;
/**下一个控制器下半view*阴影*/
@property(nonatomic,strong)UIView *nextBottomShadow;

/**头部*/

@property(nonatomic,strong)ZYFlipHeardView *flipHeardView;
@end

@implementation ZYFlipViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    //添加手势
    [self.view addGestureRecognizer:self.pan];
    [self.view addSubview:self.flipHeardView];
    
    // Do any additional setup after loading the view.
}
#pragma mark 懒加载

/**手势*/
-(UIPanGestureRecognizer *)pan{
    if (_pan == nil) {
        _pan = [[UIPanGestureRecognizer alloc]init];
        [_pan addTarget:self action:@selector(panFlipWithGesture:)];
        _pan.minimumNumberOfTouches = 1;
        _pan.maximumNumberOfTouches = 2;
    }
    return _pan;
}
#pragma getter && setter方法
/**控制器集合*/
-(void)setViewControllers:(NSMutableArray *)viewControllers{

    if (self.currentVC) {
        [self.currentVC removeFromParentViewController];
        [self.currentVC.view removeFromSuperview];
        self.nextVC = nil;
        self.nextView = nil;
        self.currentVC = nil;
        self.containerView = nil;
        self.currentView = nil;
    }
    for ( UIViewController *viewContoller  in viewControllers) {
        [self addChildViewController:viewContoller];
    }
    _viewControllers = viewControllers;
    self.currentVC = _viewControllers[0];
    [self.view addSubview:self.currentVC.view];
    self.currentIndex = 0;
}

-(ZYFlipHeardView *)flipHeardView{
    if (_flipHeardView == nil) {
        _flipHeardView = [[ZYFlipHeardView alloc]init];
    }
    return _flipHeardView;
}
-(void)setHeardString:(NSString *)heardString{
    _heardString = heardString;
    self.flipHeardView.textLabel.text =_heardString;
}
#pragma mark 手势处理

-(void)panFlipWithGesture:(UIPanGestureRecognizer *)gestureRecognizer{

    /**手势状态*/
   UIGestureRecognizerState state = [gestureRecognizer state];
     CGPoint translation = [gestureRecognizer translationInView:self.view];
   // NSLog(@"%lf",ABS(translation.y) - ABS(translation.x));

        switch (state) {
            case UIGestureRecognizerStateBegan:
            {
                /**设置翻页开始状态*/
                if (ABS(translation.y) - ABS(translation.x)>= 0) {
                    CGPoint velocity = [gestureRecognizer velocityInView:self.view];
                    BOOL isDownwards = (velocity.y > 0);
                    NSLog(@"开始");
                    //[[Context get]playFlieBoard];
                    if (isDownwards) {
                        if (_isAnimation) {
                            return;
                        }
                        [self.delegate flipWillDoAction];
                        self.direction = ZYViewAnimationDirectionBackward;
                        [self setNextOfViewOfIndex:self.currentIndex - 1];
                    } else {
                        if (_isAnimation) {
                            return;
                        }
                            [self.delegate flipWillDoAction];
                        self.direction = ZYViewAnimationDirectionForward;
                        [self setNextOfViewOfIndex:self.currentIndex +1];
                    }
                    _isAnimation = YES;
                    _isEnd = NO;
                    CGPoint nowPoint = [gestureRecognizer locationInView:self.view];
                    oldLocation  = nowPoint;
                }
            }
                break;
            case  UIGestureRecognizerStateChanged:
               
                {
                if (_isChange) {
                    return;
                }
                if (ABS(translation.y) - ABS(translation.x)<= 0) {
                    return;
                }
                NSLog(@"变化");
                CGRect viewRect = self.view.bounds;
                CGPoint translation = [gestureRecognizer translationInView:self.view];
                CGFloat percent = (double)translation.y / (double)viewRect.size.height;
                if (self.direction == ZYViewAnimationDirectionForward && percent > 0) {
                    [self updateInteractiveTransition:0];
                    return;
                }
                if (self.direction == ZYViewAnimationDirectionBackward && percent < 0) {
                      [self updateInteractiveTransition:0];
                    return;
                }
                    percent = fabs(percent);
                percent = MIN(1.0, MAX(0.0, percent));
                [self updateInteractiveTransition:percent];
                CGPoint location = [gestureRecognizer locationInView:self.view];
                CGFloat absY = fabs(location.y);
                CGFloat oldAbsY = fabs(oldLocation.y);
                if (absY -oldAbsY < 0) {
                    _isUp = YES;
                    //向上滑动
                } else if (absY - oldAbsY > 0){
                   _isUp = NO;
                    //向下滑动
                }else{
                }
                oldLocation  = location;
            }
                break;
            case  UIGestureRecognizerStateEnded:
            case  UIGestureRecognizerStateCancelled:
            case  UIGestureRecognizerStateFailed:
            case  UIGestureRecognizerStatePossible:
            {
                if (_isEnd || !_isAnimation) {
                    return;
                }
                 NSLog(@"结束");
                if (!_isChange) {
                    [self.delegate flipDidAction];
                    // NotificationCenterPost(NOTIFICATION_FlipAction, @"no", nil);
                }
                _isEnd = YES;
                _isChange =YES;
               if (self.direction == ZYViewAnimationDirectionForward){
                   if ( self.currentIndex == self.viewControllers.count - 1) {
                       _isCancel = YES;
                       [self cancelInteractiveTransition];
                   }else{
                       if (_isUp) {
                           _isCancel = NO;
                           [self finishInteractiveTransition];
                       }else{
                           _isCancel = YES;
                           [self cancelInteractiveTransition];
                       }
                   }
               }else{
                    if (self.currentIndex == 0) {
                        _isCancel = YES;
                        [self cancelInteractiveTransition];
                    }else{
                        if (!_isUp) {
                            _isCancel = NO;
                            [self finishInteractiveTransition];
                        }else{
                            _isCancel = YES;
                            [self cancelInteractiveTransition];
                        }
                    }
                  
               }
            }
                break;
            default:
                break;
        }
}

#pragma mark 设置控制器view 和 截图

-(void)setNextOfViewOfIndex:(NSInteger) index{
    if (_isAnimation) {
        return;
    }
   
    UIWindow * window = [UIApplication sharedApplication].keyWindow;
    [window makeKeyAndVisible];
    
    self.currentView = self.currentVC.view;
    self.containerView = self.view;
    self.currentUpperView = [self createUpperHalf: self.currentView];
    self.currentBottomView = [self createBottomHalf: self.currentView];
    [self.containerView addSubview:self.currentUpperView];
    [self.containerView addSubview:self.currentBottomView];
    
    self.currentUpperShadow = [[UIView alloc] initWithFrame:self.currentUpperView.frame];
    self.currentUpperShadow.backgroundColor = [UIColor blackColor];
    
    self.currentBottomShadow = [[UIView alloc] initWithFrame:self.currentBottomView.frame];
    self.currentBottomShadow.backgroundColor = [UIColor blackColor];
    
    CGFloat w = [UIScreen mainScreen].bounds.size.width;
    CGFloat h = [UIScreen mainScreen].bounds.size.height/2;
    
    CGFloat minShadow = 0.0f;
    CGFloat maxShadow = 0.5f;
    
    if (index < 0 || index > self.viewControllers.count - 1) {
         //是最后一页和第一页
        self.currentUpperShadow = [[UIView alloc] initWithFrame:self.currentUpperView.frame];
        self.currentUpperShadow.backgroundColor = [UIColor blackColor];
        
        self.currentBottomShadow = [[UIView alloc] initWithFrame:self.currentBottomView.frame];
        self.currentBottomShadow.backgroundColor = [UIColor blackColor];
        [self.containerView insertSubview:self.currentUpperShadow aboveSubview:self.currentUpperView];
        [self.containerView insertSubview:self.currentBottomShadow aboveSubview:self.currentBottomView];
        self.currentUpperShadow.alpha = minShadow;
        self.currentBottomShadow.alpha = minShadow;
        [self.containerView insertSubview:self.currentUpperShadow aboveSubview:self.currentUpperView];
        [self.containerView insertSubview:self.currentBottomShadow aboveSubview:self.currentBottomView];
       
    }else{
        
        //不是最后一页和第一页
        self.nextVC = self.viewControllers[index];
        [self.nextVC removeFromParentViewController];
        self.nextView  = self.nextVC.view;
        self.nextUpperView = [self createUpperHalf: self.nextView];
        self.nextBottomView = [self createBottomHalf: self.nextView];

  
        
        self.nextUpperShadow  = [[UIView alloc] initWithFrame:self.nextUpperView.frame];
        self.nextUpperShadow.backgroundColor = [UIColor blackColor];
        
        self.nextBottomShadow = [[UIView alloc] initWithFrame:self.nextBottomView.frame];
        self.nextBottomShadow.backgroundColor = [UIColor blackColor];
        
        
        if (self.direction == ZYViewAnimationDirectionForward) {
              [self.nextUpperView setFrame:CGRectMake(0, h, w, 0)];
          
            [self.containerView insertSubview:self.nextView belowSubview:self.currentUpperView];
            [self.containerView addSubview:self.nextUpperView];
            
            self.nextUpperShadow.frame = self.nextUpperView.frame;
            
            self.currentUpperShadow.alpha = minShadow;
            self.currentBottomShadow.alpha = minShadow;
            self.nextUpperShadow.alpha = minShadow;
            self.nextBottomShadow.alpha = maxShadow;
            
            [self.containerView insertSubview:self.currentUpperShadow aboveSubview:self.currentUpperView];
            [self.containerView insertSubview:self.currentBottomShadow aboveSubview:self.currentBottomView];
            [self.containerView insertSubview:self.nextUpperShadow aboveSubview:self.nextUpperView];
            [self.containerView insertSubview:self.nextBottomShadow belowSubview:self.currentBottomView];
            
            
        }else{
             [self.nextBottomView  setFrame:CGRectMake(0, h, w, 0)];
            [self.containerView insertSubview:self.nextView belowSubview:self.currentUpperView];
            
            [self.containerView addSubview:self.nextBottomView];
            
            self.nextBottomShadow.frame = self.nextBottomView.frame;
            
            self.currentUpperShadow.alpha = minShadow;
            self.nextBottomShadow.alpha = minShadow;
            self.nextUpperShadow.alpha = maxShadow;
            self.nextBottomShadow.alpha = minShadow;
            
            [self.containerView insertSubview:self.currentUpperShadow aboveSubview:self.currentUpperView];
            [self.containerView insertSubview:self.nextBottomShadow aboveSubview:self.currentBottomView];
            [self.containerView insertSubview:self.nextUpperShadow belowSubview:self.currentUpperView];
            [self.containerView insertSubview: self.nextBottomShadow aboveSubview:self.nextBottomShadow];
            
            
        }
        
     
        
    }
       [self.currentVC.view removeFromSuperview];
 
   
}


#pragma mark  翻页动画
-(void)cancelInteractiveTransition{
    CGFloat minShadow = 0.0f;
    CGFloat maxShadow = 0.5f;
    CGFloat w = [UIScreen mainScreen].bounds.size.width;
    CGFloat h = [UIScreen mainScreen].bounds.size.height/2;
    if (self.direction == ZYViewAnimationDirectionForward) {
        if (_isCancel) {
            [UIView animateKeyframesWithDuration:0.3 delay:0 options:0 animations:^{
                [UIView addKeyframeWithRelativeStartTime:0.0
                                        relativeDuration:0.5
                                              animations:
                 ^{
                     self.nextUpperView.frame = CGRectMake(0, h, w,  0);
                      self.currentBottomShadow.frame = self.currentBottomView.frame;
                     self.currentUpperShadow.alpha = minShadow;
                     self.currentBottomShadow.alpha = minShadow;
                     self.nextUpperShadow.alpha = minShadow;
                     self.nextBottomShadow.alpha = maxShadow;
                 }];
                
                [UIView addKeyframeWithRelativeStartTime:0.5
                                        relativeDuration:0.5
                                              animations:
                 ^{
                     self.currentBottomView.frame = CGRectMake(0, h,w, h);
                      self.nextUpperShadow.frame = self.nextUpperView.frame;
                     self.currentUpperShadow.alpha = minShadow;
                     self.currentBottomShadow.alpha = minShadow;
                     self.nextUpperShadow.alpha = minShadow;
                     self.nextBottomShadow.alpha = maxShadow;
                 }];
            } completion:^(BOOL finished) {
                
                for (UIView *view in self.view.subviews) {
                    [view removeFromSuperview];
                }
                self.currentUpperView = nil;
                self.currentBottomView = nil;
                self.currentUpperShadow = nil;
                self.currentBottomShadow = nil;
                self.nextUpperView = nil;
                self.nextBottomShadow = nil;
                self.nextUpperShadow = nil;
                self.nextBottomView = nil;
                [self.view addSubview:self.flipHeardView];
                [self.view addSubview:self.currentVC.view];
              
                _isAnimation = NO;
                _isEnd = NO;
                _isChange = NO;
               
            }];
        }
  
    }
    if (self.direction == ZYViewAnimationDirectionBackward) {
        if (_isCancel) {
            [UIView animateKeyframesWithDuration:0.3 delay:0 options:0 animations:^{
                [UIView addKeyframeWithRelativeStartTime:0.0
                                        relativeDuration:0.5
                                              animations:
                 ^{
                       self.nextBottomView.frame = CGRectMake(0, h, w, 0);
                      self.currentUpperShadow.frame = self.currentUpperView.frame;
                     self.currentUpperShadow.alpha = minShadow;
                     self.currentBottomShadow.alpha = minShadow;
                     self.nextUpperShadow.alpha = minShadow;
                     self.nextBottomShadow.alpha = maxShadow;
                 }];
                
                [UIView addKeyframeWithRelativeStartTime:0.5
                                        relativeDuration:0.5
                                              animations:
                 ^{
                     self.currentUpperView.frame = CGRectMake(0, 0, w, h);
                     self.nextBottomShadow.frame = self.nextBottomView.frame;
                     self.currentUpperShadow.alpha = minShadow;
                     self.currentBottomShadow.alpha = minShadow;
                     self.nextUpperShadow.alpha = minShadow;
                     self.nextBottomShadow.alpha = maxShadow;
                     
                 }];
                
            } completion:^(BOOL finished) {
                for (UIView *view in self.view.subviews) {
                    [view removeFromSuperview];
                }
                self.currentUpperView = nil;
                self.currentBottomView = nil;
                self.currentUpperShadow = nil;
                self.currentBottomShadow = nil;
                self.nextUpperView = nil;
                self.nextBottomShadow = nil;
                self.nextUpperShadow = nil;
                self.nextBottomView = nil;
                [self.view addSubview:self.flipHeardView];
                [self.view addSubview:self.currentVC.view];
                _isAnimation = NO;
                _isEnd = NO;
                _isChange = NO;
           
            }];
        }
      
    }
    
}

-(void)finishInteractiveTransition{
    CGFloat w = [UIScreen mainScreen].bounds.size.width;
    CGFloat h = [UIScreen mainScreen].bounds.size.height/2;
    
    CGFloat minShadow = 0.0f;
    CGFloat maxShadow = 0.5f;
    if (self.direction == ZYViewAnimationDirectionForward) {
        [UIView animateKeyframesWithDuration:0.3 delay:0 options:0 animations:^{
            
            [UIView addKeyframeWithRelativeStartTime:0.0  relativeDuration:0.5 animations: ^{
                self.currentBottomView.frame = CGRectMake(0, h,w, 0);
                self.currentBottomShadow.frame = self.currentBottomView.frame;
                self.currentBottomShadow.alpha = maxShadow;
                self.nextBottomShadow.alpha = minShadow;
            
             }];
            [UIView addKeyframeWithRelativeStartTime:0.5 relativeDuration:0.5 animations: ^{
                self.nextUpperView.frame = CGRectMake(0, 0, w,  h);
                self.nextUpperShadow.frame = self.nextUpperView.frame;
                self.nextUpperShadow.alpha = minShadow;
                self.currentUpperShadow.alpha = maxShadow;
             
             }];
        } completion:^(BOOL finished) {
            for (UIView *view in self.view.subviews) {
                [view removeFromSuperview];
            }
            self.currentUpperView = nil;
            self.currentBottomView = nil;
            self.currentUpperShadow = nil;
            self.currentBottomShadow = nil;
            self.nextUpperView = nil;
            self.nextBottomShadow = nil;
            self.nextUpperShadow = nil;
            self.nextBottomView = nil;

            self.currentVC = self.nextVC;
            [self.view addSubview:self.flipHeardView];
            [self.view addSubview:self.currentVC.view];
            self.currentIndex ++;
            _isEnd = NO;
            _isAnimation = NO;
            _isChange = NO;
     
        }];
    }
     if (self.direction == ZYViewAnimationDirectionBackward) {

         [UIView animateKeyframesWithDuration:0.3 delay:0 options:0 animations:^{
             [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.5 animations: ^{
                 
                 self.currentUpperView.frame = CGRectMake(0, h, w, 0);
                 self.currentUpperShadow.frame = self.currentUpperView.frame;
                 self.currentUpperShadow.alpha = maxShadow;
                 self.nextUpperShadow.alpha = minShadow;
            
              }];
             [UIView addKeyframeWithRelativeStartTime:0.5 relativeDuration:0.5 animations:
              ^{
                  self.nextBottomView.frame = CGRectMake(0, h, w, h);
                  self.nextBottomShadow.frame = self.nextBottomView.frame;
                  self.nextBottomShadow.alpha = minShadow;
                  self.currentUpperShadow.alpha = maxShadow ;
                  self.currentBottomShadow.alpha = maxShadow;
              }];
         } completion:^(BOOL finished) {
             for (UIView *view in self.view.subviews) {
                 [view removeFromSuperview];
             }
             self.currentUpperView = nil;
             self.currentBottomView = nil;
             self.currentUpperShadow = nil;
             self.currentBottomShadow = nil;
             self.nextUpperView = nil;
             self.nextBottomShadow = nil;
             self.nextUpperShadow = nil;
             self.nextBottomView = nil;

             self.currentVC = self.nextVC;
             [self.view addSubview:self.flipHeardView];
             [self.view addSubview:self.currentVC.view];
             self.currentIndex --;
             _isEnd = NO;
             _isAnimation = NO;
             _isChange = NO;
         }];
     }
    
}
-(void)updateInteractiveTransition:(float)percent{
    CGFloat minShadow = 0.0f;
    CGFloat maxShadow = 0.5f;
    
    CGFloat w = [UIScreen mainScreen].bounds.size.width;
    CGFloat h = [UIScreen mainScreen].bounds.size.height/2;
    if (self.direction == ZYViewAnimationDirectionForward) {
        if (self.currentIndex == self.viewControllers.count- 1 ) {
            if (percent > 0.2) {
                percent = 0.2;
                if (!_isPlayed) {
                    [self playSound];
                }
                _isPlayed = YES;
            }else{
                _isPlayed = NO;
            }
        }
        if (percent <= 0.5f) {
            self.currentBottomView.frame = CGRectMake(0, self.currentBottomView.frame.origin.y, w, h * (1-percent/0.5));
            self.nextUpperView.frame = CGRectMake(0,  self.currentBottomView.frame.origin.y,  w, 0);
            self.currentBottomShadow.frame = self.currentBottomView.frame;
            self.currentBottomShadow.alpha = maxShadow * ( percent/0.5);
            self.nextBottomShadow.alpha = maxShadow * (1 - percent/0.5);
            self.nextUpperShadow.alpha = maxShadow;
            self.nextUpperShadow.frame = self.nextUpperView.frame;
          
        }else{
            
            self.currentBottomShadow.frame = self.currentBottomView.frame;
            
            self.currentBottomShadow.alpha = maxShadow ;
            self.nextUpperShadow.alpha = maxShadow ;
            self.nextBottomShadow.alpha = minShadow ;
            self.currentBottomView.frame = CGRectMake(0, self.currentBottomView.frame.origin.y, w,0);
            self.nextUpperView.frame = CGRectMake(0,  h -( h*  ((percent - 0.5)/0.5)  ) ,  w,  h * ((percent - 0.5)/0.5) );
            
            self.nextUpperShadow.frame = self.nextUpperView.frame;
            self.nextUpperShadow.alpha = maxShadow * (1-(percent - 0.5)/0.5);
            self.currentUpperShadow.alpha = maxShadow * (percent - 0.5)/0.5;
            
         
            
        }
        
    
    }
    
    if (self.direction == ZYViewAnimationDirectionBackward) {
        
        
        if (self.currentIndex == 0 ) {
            if (percent > 0.2) {
                percent = 0.2;
                if (!_isPlayed) {
                    [self playSound];
                }
                _isPlayed = YES;
            }else{
                 _isPlayed = NO;
            }
        }
        if (percent <= 0.5f) {
            self.currentUpperView.frame = CGRectMake(0, h - h * (1-percent/0.5), w, h * (1 - percent/0.5));
            self.nextBottomView.frame = CGRectMake(0, h, w, 0);
            self.currentUpperShadow.frame = self.currentUpperView.frame;
            self.currentUpperShadow.alpha = maxShadow * (percent/0.5);
            self.nextBottomShadow.alpha = maxShadow * (1 - percent/0.5);
            self.nextUpperShadow.alpha = maxShadow * (1 - percent/0.5);
            self.nextBottomShadow.alpha = maxShadow;
            self.nextBottomShadow.frame = self.nextBottomView.frame;
        }else if( percent <= 1.0f){
            self.nextBottomView.frame = CGRectMake(0, h, w, h * ((percent - 0.5)/0.5));
            self.currentUpperView.frame = CGRectMake(0, h, w, 0);
            
            self.currentUpperShadow.frame = self.currentUpperView.frame;
            self.nextBottomShadow.frame = self.nextBottomView.frame;
            self.nextBottomShadow.alpha = maxShadow * (1-(percent - 0.5)/0.5);;
            self.currentUpperShadow.alpha = maxShadow * ((percent - 0.5)/0.5);
            self.currentBottomShadow.alpha = maxShadow * ((percent - 0.5)/0.5);
         
        }
        
    }
}
#pragma mark 截屏

- (UIView *)createUpperHalf:(UIView *)view{
    

    CGRect snapRect = CGRectMake(0, 0, view.frame.size.width, view.frame.size.height / 2);
    UIView *topHalf = [view resizableSnapshotViewFromRect:snapRect afterScreenUpdates:YES withCapInsets:UIEdgeInsetsZero];
    topHalf.userInteractionEnabled = NO;
    return topHalf;
    
    
}

-(void)dealloc{
    NSLog(@"ZYFlipViewController");
    [self.viewControllers removeAllObjects];
    self.viewControllers = nil;
    self.currentUpperView = nil;
    self.currentBottomView = nil;
    self.currentUpperShadow = nil;
    self.currentBottomShadow = nil;
    self.nextUpperView = nil;
    self.nextBottomShadow = nil;
    self.nextUpperShadow = nil;
    self.nextBottomView = nil;
}
- (UIView *)createBottomHalf:(UIView *)view
{

    CGRect snapRect = CGRectMake(0, CGRectGetMidY(view.frame), view.frame.size.width, view.frame.size.height / 2);
    UIView *bottomHalf = [view resizableSnapshotViewFromRect:snapRect afterScreenUpdates:YES withCapInsets:UIEdgeInsetsZero];
    CGRect newFrame = CGRectOffset(bottomHalf.frame, 0, bottomHalf.bounds.size.height);
    bottomHalf.frame = newFrame;
    bottomHalf.userInteractionEnabled = NO;
    return bottomHalf;
}

-(void)playSound{
    AudioServicesPlaySystemSound(1519);
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
