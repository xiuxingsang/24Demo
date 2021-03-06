//
//  ZCImagePreviewViewController.m
//  24EditorDemo
//
//  Created by zhuchen on 2017/11/23.
//  Copyright © 2017年 personal. All rights reserved.
//

#import "ZCImagePreviewViewController.h"

#define ZCViewAnimationOptionsCurveOut (7<<16)
#define ZCViewAnimationOptionsCurveIn (8<<16)

@interface ZCImagePreviewViewController ()

@property(nonatomic, strong) UIWindow *previewWindow;
@property(nonatomic, assign) BOOL shouldStartWithFading;
@property(nonatomic, assign) CGRect previewFromRect;
@property(nonatomic, assign) CGFloat transitionCornerRadius;
@property(nonatomic, strong) UIImageView *transitionImageView;
@property(nonatomic, strong) UIColor *backgroundColorTemporarily;
@end

@implementation ZCImagePreviewViewController

@synthesize imagePreviewView = _imagePreviewView;

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    return self;
}


- (ZCImagePreviewView *)imagePreviewView {
    [self loadViewIfNeeded];
    return _imagePreviewView;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    _backgroundColor = backgroundColor;
    if ([self isViewLoaded]) {
        self.view.backgroundColor = backgroundColor;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
    _imagePreviewView = [[ZCImagePreviewView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.imagePreviewView];
}


- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.imagePreviewView.frame = self.view.bounds;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.imagePreviewView.collectionView reloadData];
    
    if (self.previewWindow && !self.shouldStartWithFading) {
        // 为在 viewDidAppear 做动画做准备
        self.imagePreviewView.collectionView.hidden = YES;
    } else {
        self.imagePreviewView.collectionView.hidden = NO;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // 配合 ZCImagePreviewViewController (UIWindow) 使用的
    if (self.previewWindow) {
        
        if (self.shouldStartWithFading) {
            [UIView animateWithDuration:.2 delay:0.0 options:ZCViewAnimationOptionsCurveOut animations:^{
                self.view.alpha = 1;
            } completion:^(BOOL finished) {
                self.imagePreviewView.collectionView.hidden = NO;
                self.shouldStartWithFading = NO;
            }];
            return;
        }
        
        ZCZoomImageView *zoomImageView = [self.imagePreviewView zoomImageViewAtIndex:self.imagePreviewView.currentImageIndex];
        if (!zoomImageView) {
            NSAssert(NO, @"第 %@ 个 zoomImageView 不存在，可能当前还处于非可视区域", @(self.imagePreviewView.currentImageIndex));
        }
        CGRect transitionFromRect = self.previewFromRect;
        CGRect transitionToRect = [self.view convertRect:[zoomImageView imageViewRectInZoomImageView] fromView:zoomImageView.superview];
        
        self.transitionImageView.contentMode = zoomImageView.imageView.contentMode;
        self.transitionImageView.image = zoomImageView.imageView.image;
        self.transitionImageView.frame = transitionFromRect;
        self.transitionImageView.clipsToBounds = YES;
        self.transitionImageView.layer.cornerRadius = self.transitionCornerRadius;
        [self.view addSubview:self.transitionImageView];
        
        [UIView animateWithDuration:.2 delay:0.0 options:ZCViewAnimationOptionsCurveOut animations:^{
            self.transitionImageView.frame = transitionToRect;
            self.transitionImageView.layer.cornerRadius = 0;
            self.view.backgroundColor = self.backgroundColorTemporarily;
        } completion:^(BOOL finished) {
            [self.transitionImageView removeFromSuperview];
            self.imagePreviewView.collectionView.hidden = NO;
            self.backgroundColorTemporarily = nil;
        }];
    }
}

@end

@implementation ZCImagePreviewViewController (UIWindow)

- (void)startPreviewFromRectInScreen:(CGRect)rect cornerRadius:(CGFloat)cornerRadius {
    self.transitionCornerRadius = cornerRadius;
    [self startPreviewWithFadingAnimation:NO orFromRect:rect];
}

- (void)startPreviewFromRectInScreen:(CGRect)rect {
    [self startPreviewFromRectInScreen:rect cornerRadius:0];
}

- (void)endPreviewToRectInScreen:(CGRect)rect {
    [self endPreviewWithFadingAnimation:NO orToRect:rect];
    self.transitionCornerRadius = 0;
}

- (void)startPreviewFading {
    self.transitionCornerRadius = 0;
    [self startPreviewWithFadingAnimation:YES orFromRect:CGRectZero];
}

- (void)endPreviewFading {
    [self endPreviewWithFadingAnimation:YES orToRect:CGRectZero];
    self.transitionCornerRadius = 0;
}

#pragma mark - 动画

- (void)initPreviewWindowIfNeeded {
    if (!self.previewWindow) {
        self.previewWindow = [[UIWindow alloc] init];
        self.previewWindow.windowLevel = UIWindowLevelStatusBar + 1;
        self.previewWindow.backgroundColor = [UIColor clearColor];
    }
}

- (void)removePreviewWindow {
    self.previewWindow.hidden = YES;
    self.previewWindow.rootViewController = nil;
    self.previewWindow = nil;
}

- (void)startPreviewWithFadingAnimation:(BOOL)isFading orFromRect:(CGRect)rect {
    self.shouldStartWithFading = isFading;
    
    if (isFading) {
        
        // 为动画做准备，先置为透明
        self.view.alpha = 0;
        
    } else {
        self.previewFromRect = rect;
        
        if (!self.transitionImageView) {
            self.transitionImageView = [[UIImageView alloc] init];
        }
        
        // 为动画做准备，先置为透明
        self.backgroundColorTemporarily = self.view.backgroundColor;
        self.view.backgroundColor = [UIColor clearColor];
    }
    
    [self initPreviewWindowIfNeeded];
    
    self.previewWindow.rootViewController = self;
    self.previewWindow.hidden = NO;
}

- (void)endPreviewWithFadingAnimation:(BOOL)isFading orToRect:(CGRect)rect {
    
    if (isFading) {
        [UIView animateWithDuration:.2 delay:0.0 options:ZCViewAnimationOptionsCurveOut animations:^{
            self.view.alpha = 0;
        } completion:^(BOOL finished) {
            [self removePreviewWindow];
            self.view.alpha = 1;
        }];
        return;
    }
    
    ZCZoomImageView *zoomImageView = [self.imagePreviewView zoomImageViewAtIndex:self.imagePreviewView.currentImageIndex];
    CGRect transitionFromRect = [zoomImageView imageViewRectInZoomImageView];
    CGRect transitionToRect = rect;
    
    self.transitionImageView.image = zoomImageView.image;
    self.transitionImageView.frame = transitionFromRect;
    [self.view addSubview:self.transitionImageView];
    self.imagePreviewView.collectionView.hidden = YES;
    
    self.backgroundColorTemporarily = self.view.backgroundColor;
    
    [UIView animateWithDuration:.2 delay:0.0 options:ZCViewAnimationOptionsCurveOut animations:^{
        self.transitionImageView.frame = transitionToRect;
        self.transitionImageView.layer.cornerRadius = self.transitionCornerRadius;
        self.view.backgroundColor = [UIColor clearColor];
    } completion:^(BOOL finished) {
        [self removePreviewWindow];
        [self.transitionImageView removeFromSuperview];
        self.imagePreviewView.collectionView.hidden = NO;
        self.view.backgroundColor = self.backgroundColorTemporarily;
        self.backgroundColorTemporarily = nil;
    }];
}

@end
