//
//  QQPhotoView.m
//  QQPhotoBrowser
//
//  Created by Mac on 2021/4/23.
//

#import "QQPhotoView.h"
#import "UIImageView+WebCache.h"
#import "UIView+WebCache.h"

@interface QQPhotoView ()<UIScrollViewDelegate>

@end

@implementation QQPhotoView

#pragma mark - Init

- (QQPhotoProgressView *)progressView {
    if (!_progressView) {
        _progressView = [[QQPhotoProgressView alloc] init];
    }
    return _progressView;
}

- (QQPhotoScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[QQPhotoScrollView alloc] init];
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.scrollsToTop = NO;
        _scrollView.delegate = self;
        _scrollView.bouncesZoom = YES;
        _scrollView.maximumZoomScale = 3;
        _scrollView.minimumZoomScale = 1;
        if (@available(iOS 11.0, *)) {
            _scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    return _scrollView;
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _imageView;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        [self.scrollView addSubview:self.imageView];
        [self addSubview:self.scrollView];
        [self addSubview:self.progressView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat progressWidth = 40;
    self.scrollView.frame = self.bounds;
    self.progressView.frame = CGRectMake((self.frame.size.width - progressWidth) / 2, (self.frame.size.height - progressWidth) / 2, progressWidth, progressWidth);
}

#pragma mark - Setter Photo

- (void)setPhoto:(QQPhoto *)photo {
    if (_photo != photo) {
        _photo = photo;
        if (!photo) {
            [self hideProgressView];
            _imageView.image = nil;
            [self cancelCurrentImageLoad];
            return;
        }
        
        __weak typeof(self) weakSelf = self;
        photo.progressUpdateBlock = ^(QQPhoto *photo, CGFloat progress) {
            if ([weakSelf.photo.largeImageURL.absoluteString isEqualToString:photo.largeImageURL.absoluteString]) {
                [weakSelf.progressView setProgress:progress];
            }
        };
        
        if (photo.originalImage) {
            [self hideProgressView];
            _imageView.image = photo.originalImage;
            [self resizeSubviewsSize];
        } else {
            _imageView.image = photo.thumbImage;
            [self resizeSubviewsSize];

            if (photo.largeImageURL && photo.largeImageURL.absoluteString.length > 0) {
                [self showProgressView];
                [_imageView sd_setImageWithURL:photo.largeImageURL placeholderImage:photo.thumbImage options:SDWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        CGFloat progress = (CGFloat)receivedSize / (CGFloat)expectedSize;
                        if (photo.progressUpdateBlock) {
                            photo.progressUpdateBlock(photo, progress);
                        }
                    });
                } completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (image) {
                            // Successful load
                            if ([self.photo.largeImageURL.absoluteString isEqualToString:imageURL.absoluteString]) {
                                [self hideProgressView];
                                self.photo.originalImage = image;
                                [self resizeSubviewsSize];
                            }
                        } else {
                            // Failed to load
                            [self hideProgressView];
                        }
                    });
                }];
            } else {
                [self hideProgressView];
            }
        }
    }
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    return _imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    UIView *subView = _imageView;
    
    CGFloat offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width)?
    (scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5 : 0.0;
    
    CGFloat offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height)?
    (scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5 : 0.0;
    
    subView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX,
                                 scrollView.contentSize.height * 0.5 + offsetY);
}

#pragma mark - Public

- (void)resizeSubviewsSize {
    UIImage *image = _imageView.image;
    if (!image) return;
    
    // Screen Landscape Layout
//    if (self.frame.size.width > self.frame.size.height) {
//        _imageView.frame = self.bounds;
//        self.contentSize = CGSizeMake(self.frame.size.width, self.frame.size.height);
//        return;
//    }
    
    // Screen Portrait Layout
    CGSize imageSize = image.size;
    CGSize scrollViewSize = self.frame.size;
    
    CGFloat imageViewX = 0.0f;
    CGFloat imageViewY = 0.0f;
    
    CGFloat imageViewWidth = floorf(self.frame.size.width);
    CGFloat imageViewHeight = floorf((imageViewWidth * imageSize.height) / imageSize.width);
    
    // Horizontally
    if (imageViewWidth < scrollViewSize.width) {
        imageViewX = floorf((scrollViewSize.width - imageViewWidth) / 2);
    } else {
        imageViewX = 0;
    }
    
    // Vertically
    if (imageViewHeight < scrollViewSize.height) {
        imageViewY = floorf((scrollViewSize.height - imageViewHeight) / 2);
    } else {
        imageViewY = 0;
    }
    
    // Center
    _imageView.frame = CGRectMake(imageViewX, imageViewY, imageViewWidth, imageViewHeight);
    
    // ContentSize
    self.scrollView.contentSize = CGSizeMake(self.frame.size.width, MAX(_imageView.frame.size.height, self.frame.size.height));
}

- (void)cancelCurrentImageLoad {
    [self.imageView sd_cancelCurrentImageLoad];
}

- (void)showProgressView {
    self.progressView.hidden = NO;
    [self.progressView startSpinAnimation];
}

- (void)hideProgressView {
    self.progressView.hidden = YES;
    [self.progressView stopSpinAnimation];
}

@end


@implementation QQPhotoScrollView

- (BOOL)isOnTop {
    CGPoint translation = [self.panGestureRecognizer translationInView:self];
    if (translation.y > 0 && self.contentOffset.y <= 0) {
        return YES;
    }
    return NO;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer == self.panGestureRecognizer) {
        if (gestureRecognizer.state == UIGestureRecognizerStatePossible) {
            if ([self isOnTop]) {
                return NO;
            }
        }
    }
    return YES;
}

@end
