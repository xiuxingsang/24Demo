//
//  ZCImagePreviewView.h
//  24EditorDemo
//
//  Created by zhuchen on 2017/11/23.
//  Copyright © 2017年 personal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZCZoomImageView.h"

@class ZCImagePreviewView;
@class ZCCollectionViewPagingLayout;

typedef NS_ENUM (NSUInteger, ZCImagePreviewMediaType) {
    ZCImagePreviewMediaTypeImage,
    ZCImagePreviewMediaTypeLivePhoto,
    ZCImagePreviewMediaTypeVideo,
    ZCImagePreviewMediaTypeOthers
};

@protocol ZCImagePreviewViewDelegate <ZCZoomImageViewDelegate>

@required
- (NSUInteger)numberOfImagesInImagePreviewView:(ZCImagePreviewView *)imagePreviewView;
- (void)imagePreviewView:(ZCImagePreviewView *)imagePreviewView renderZoomImageView:(ZCZoomImageView *)zoomImageView atIndex:(NSUInteger)index;

@optional
// 返回要展示的媒体资源的类型（图片、live photo、视频），如果不实现此方法，则 ZCImagePreviewView 将无法选择最合适的 cell 来复用从而略微增大系统开销
- (ZCImagePreviewMediaType)imagePreviewView:(ZCImagePreviewView *)imagePreviewView assetTypeAtIndex:(NSUInteger)index;

@optional

/**
 *  当左右的滚动停止时会触发这个方法
 *  @param  imagePreviewView 当前预览的 ZCImagePreviewView
 *  @param  index 当前滚动到的图片所在的索引
 */
- (void)imagePreviewView:(ZCImagePreviewView *)imagePreviewView didScrollToIndex:(NSUInteger)index;

/**
 *  在滚动过程中，如果某一张图片的边缘（左/右）经过预览控件的中心点时，就会触发这个方法
 *  @param  imagePreviewView 当前预览的 ZCImagePreviewView
 *  @param  index 当前滚动到的图片所在的索引
 */
- (void)imagePreviewView:(ZCImagePreviewView *)imagePreviewView willScrollHalfToIndex:(NSUInteger)index;

@optional

@end

/**
 *  查看图片的控件，支持横向滚动、放大缩小、loading 及错误语展示，内部使用 UICollectionView 实现横向滚动及 cell 复用，因此与其他普通的 UICollectionView 一样，也可使用 reloadData、collectionViewLayout 等常用方法。
 *
 *  使用方式：
 *
 *  1. 使用 initWithFrame: 或 init 方法初始化。
 *  2. 设置 delegate。
 *  3. 在 delegate 的 numberOfImagesInImagePreviewView: 方法里返回图片总数。
 *  4. 在 delegate 的 imagePreviewView:renderZoomImageView:atIndex: 方法里为 zoomImageView.image 设置图片，如果需要，也可调用 [zoomImageView showLoading] 等方法来显示 loading。
 *  5. 由于 ZCImagePreviewViewDelegate 继承自 ZCZoomImageViewDelegate，所以若需要响应单击、双击、长按事件，请实现 ZCZoomImageViewDelegate 里的对应方法。
 *  6. 若需要从指定的某一张图片开始查看，可使用 currentImageIndex 属性。
 *
 *  @see ZCImagePreviewViewController
 */
@interface ZCImagePreviewView : UIView<UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, ZCZoomImageViewDelegate>

@property(nonatomic, weak) id<ZCImagePreviewViewDelegate> delegate;
@property(nonatomic, strong, readonly) UICollectionView *collectionView;
@property(nonatomic, strong, readonly) ZCCollectionViewPagingLayout *collectionViewLayout;

/// 获取当前正在查看的图片 index，也可强制将图片滚动到指定的 index
@property(nonatomic, assign) NSUInteger currentImageIndex;
- (void)setCurrentImageIndex:(NSUInteger)currentImageIndex animated:(BOOL)animated;

/// 每一页里的 loading 的颜色，默认为 UIColorWhite
@property(nonatomic, strong) UIColor *loadingColor;

@end

@interface ZCImagePreviewView (ZCZoomImageView)<ZCZoomImageViewDelegate>

/**
 *  获取某个 ZCZoomImageView 所对应的 index
 *  @return zoomImageView 对应的 index，若当前的 zoomImageView 不可见，会返回 0
 */
- (NSUInteger)indexForZoomImageView:(ZCZoomImageView *)zoomImageView;

/**
 *  获取某个 index 对应的 zoomImageView
 *  @return 指定的 index 所在的 zoomImageView，若该 index 对应的图片当前不可见（不处于可视区域），则返回 nil
 */
- (ZCZoomImageView *)zoomImageViewAtIndex:(NSUInteger)index;
@end
