//
//  TYMainViewController.m
//  Minesweeper
//
//  Created by Leo on 14-7-23.
//  Copyright (c) 2014年 Leo. All rights reserved.
//

#import "TYMainViewController.h"
#import "TYGameViewController.h"

@interface TYMainViewController ()

- (void)initializeAppearance;
- (void)animation;

@end

@implementation TYMainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initializeAppearance];
    // Do any additional setup after loading the view.
}

- (void)initializeAppearance {
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    NSString *imagePath = [[NSBundle mainBundle] pathForAuxiliaryExecutable:@"app_begin.png"];
    UIImageView *beginImage = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:imagePath]];
    beginImage.frame = self.view.bounds;
    [self.view addSubview:beginImage];
    
    [self performSelector:@selector(animation) withObject:nil afterDelay:2];
}

- (void)animation {
    
    // 首先截取当前视图状态的图片，以及视图最终状态的图片备用
    UIImage *currentImage = [self createScreenShootForView:self.view];
    [[[self.view subviews] lastObject] removeFromSuperview];
    
    // 新页面的容器
    TYGameViewController *vc = [[TYGameViewController alloc] initWithLines:10 numberOfMines:10];
    vc.view.frame = self.view.bounds;
    [self.view addSubview:vc.view];
    [self addChildViewController:vc];
    
    UIView *backView = vc.view;
    
    // 开门左
    UIImageView *leftImageView = [[UIImageView alloc] initWithImage:currentImage];
    [leftImageView setBounds:CGRectMake(0, 0, CGRectGetMidX(backView.bounds), CGRectGetHeight(backView.bounds))];
    [leftImageView setCenter:CGPointMake(CGRectGetMinX(backView.bounds) + CGRectGetMidX(leftImageView.bounds),
                                         CGRectGetMidY(backView.bounds))];
    [leftImageView setContentMode:UIViewContentModeLeft]; // 将图片左对齐放置
    [leftImageView setClipsToBounds:YES]; // 防止图片内容超出UIImageView
    [self.view addSubview:leftImageView];
    
    // 开门右
    UIImageView *rightImageView = [[UIImageView alloc] initWithImage:currentImage];
    [rightImageView setBounds:CGRectMake(0, 0, CGRectGetMidX(backView.bounds), CGRectGetHeight(backView.bounds))];
    [rightImageView setCenter:CGPointMake(CGRectGetMaxX(leftImageView.frame) + CGRectGetMidX(rightImageView.bounds),
                                          CGRectGetMidY(backView.bounds))];
    [rightImageView setContentMode:UIViewContentModeRight]; // 将图片右对齐放置
    [rightImageView setClipsToBounds:YES]; // 防止图片内容超出UIImageView
    [self.view addSubview:rightImageView];
    
    // 将新页面容器缩小并隐藏
    [backView setAlpha:0.0];
    [backView setTransform:CGAffineTransformMakeScale(0.5, 0.5)];
    
    // 开门
    [UIView animateWithDuration:1.0 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [leftImageView  setTransform:CGAffineTransformMakeTranslation(-CGRectGetWidth(leftImageView.bounds), 0)];
        [rightImageView setTransform:CGAffineTransformMakeTranslation(CGRectGetWidth(rightImageView.bounds), 0)];
    } completion:^(BOOL finished) {
        
    }];
    
    // 新页面放大显示
    [UIView animateWithDuration:0.5 delay:0.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [leftImageView  setAlpha:0.5];
        [rightImageView setAlpha:0.5];
        [backView  setAlpha:1.0];
        [backView  setTransform:CGAffineTransformIdentity];
    } completion:^(BOOL finished) {
        
    }];
}

#pragma mark - 截屏操作

- (UIImage *)createScreenShootForView:(UIView *)view {
    
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [view.layer renderInContext:context];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
