//
//  QQPhotoView.h
//  QQPhotoBrowser
//
//  Created by Mac on 2021/4/23.
//

#import <UIKit/UIKit.h>
#import "QQPhotoProgressView.h"
#import "QQPhoto.h"

NS_ASSUME_NONNULL_BEGIN

@interface QQPhotoScrollView : UIScrollView

@end

@interface QQPhotoView : UIView

@property (nonatomic, strong) QQPhotoScrollView *scrollView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) QQPhotoProgressView *progressView;

@property (nonatomic, assign) NSInteger page;
@property (nonatomic, strong, nullable) QQPhoto *photo;

- (void)resizeSubviewsSize;
- (void)cancelCurrentImageLoad;
- (void)showProgressView;
- (void)hideProgressView;

@end

NS_ASSUME_NONNULL_END
