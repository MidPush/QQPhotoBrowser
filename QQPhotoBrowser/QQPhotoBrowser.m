//
//  QQPhotoBrowser.m
//  QQPhotoBrowser
//
//  Created by Mac on 2021/4/23.
//

#import "QQPhotoBrowser.h"
#import "QQPhotoView.h"
#import "SDWebImageManager.h"

const CGFloat kPadding = 20;
@interface QQPhotoBrowser ()<UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *pagingScrollView;

@property (nonatomic, strong) NSMutableSet<QQPhotoView *> *reusableCells;
@property (nonatomic, strong) NSArray<QQPhoto *> *photos;

@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, assign) BOOL isPresented;
@property (nonatomic, assign) BOOL isDraggingPhoto;
@property (nonatomic, assign) BOOL performingLayout;
@property (nonatomic, assign) CGAffineTransform imageViewBeginTransform;

@property (nonatomic, assign) BOOL isTap;
@property (nonatomic, strong) UIView *firstFromView;

@end

@implementation QQPhotoBrowser

#pragma mark - Init

- (UIScrollView *)pagingScrollView {
    if (!_pagingScrollView) {
        _pagingScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(-kPadding, 0, self.view.frame.size.width + 2 * kPadding, self.view.frame.size.height)];
        _pagingScrollView.backgroundColor = [UIColor clearColor];
        _pagingScrollView.showsHorizontalScrollIndicator = NO;
        _pagingScrollView.showsVerticalScrollIndicator = NO;
        _pagingScrollView.pagingEnabled = YES;
        _pagingScrollView.delegate = self;
    }
    return _pagingScrollView;
}

- (instancetype)initWithPhotos:(NSArray *)photos fromIndex:(NSInteger)index {
    if (self = [super init]) {
        _currentPage = index;
        _photos = [photos copy];
        self.automaticallyAdjustsScrollViewInsets = NO;
        self.modalPresentationStyle = UIModalPresentationCustom;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        self.modalPresentationCapturesStatusBarAppearance = YES;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self performPresentAnimation];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
    if (@available(iOS 11.0, *)) {
        self.pagingScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    } else {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    [self.view addSubview:self.pagingScrollView];
    
    //
    self.isPresented = NO;
    self.performingLayout = NO;
    self.isDraggingPhoto = NO;
    self.reusableCells = [NSMutableSet set];
    
    // Gestures
    UITapGestureRecognizer *singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapGestureHandle:)];
    singleTapGesture.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:singleTapGesture];
    
    UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapGestureHandle:)];
    doubleTapGesture.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:doubleTapGesture];
    [singleTapGesture requireGestureRecognizerToFail:doubleTapGesture];

    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureHandle:)];
    panGesture.maximumNumberOfTouches = 1;
    [self.view addGestureRecognizer:panGesture];
    
    //
    [self.view addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)show {
    UIViewController *visibleViewController = [self findVisibleViewController];
    [visibleViewController presentViewController:self animated:NO completion:nil];
}

#pragma mark - Observer

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"frame"]) {
        if (_isDraggingPhoto) return;
        _performingLayout = YES;
        
        CGRect bounds = self.view.frame;
        _pagingScrollView.frame = CGRectMake(-kPadding, 0, bounds.size.width + 2 * kPadding, bounds.size.height);
        _pagingScrollView.contentSize = CGSizeMake(CGRectGetWidth(_pagingScrollView.frame) * _photos.count, bounds.size.height);
        [_pagingScrollView setContentOffset:CGPointMake(CGRectGetWidth(_pagingScrollView.frame) * _currentPage, 0) animated:NO];
        for (QQPhotoView *photoView in _reusableCells) {
            photoView.scrollView.zoomScale = 1.0;
            photoView.frame = [self cellFrameForPage:photoView.page];
            [photoView resizeSubviewsSize];
        }
        
        _performingLayout = NO;
    }
}

#pragma mark - Screen Rotate

- (BOOL)shouldAutorotate {
    if (_isDraggingPhoto) {
        return NO;
    }
    return self.canAutorotate;
}
    
#pragma mark - Status Bar

- (BOOL)prefersStatusBarHidden {
    if (_isDraggingPhoto) {
        return NO;
    }
    return YES;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationFade;
}

#pragma mark - <UIScrollViewDelegate>

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    NSInteger page = self.currentPage;
    if (_currentPage == page || !_isPresented || _performingLayout) {
        return;
    }
    _currentPage = page;
    [self updateCellsForReuse];
    [self loadCellsForPage:page];
}

#pragma mark - Private Methods

- (void)loadCellsForPage:(NSInteger)page {
    for (NSInteger i = page - 1; i <= page + 1; i++) {
        if (i < 0 || i >= self.photos.count) continue;
        QQPhotoView *cell = [self cellForPage:i];
        if (!cell) {
            cell = [self dequeueReusableCell];
            cell.frame = [self cellFrameForPage:i];
            [cell layoutIfNeeded];
            cell.page = i;
            cell.photo = self.photos[i];
            [self.pagingScrollView addSubview:cell];
        } else {
            cell.photo = self.photos[i];
        }
        cell.photo.sourceView.hidden = (i == page);
    }
}

- (void)updateCellsForReuse {
    for (QQPhotoView *cell in _reusableCells) {
        if (cell.superview) {
            if (CGRectGetMinX(cell.frame) > _pagingScrollView.contentOffset.x + _pagingScrollView.frame.size.width * 2 ||
            CGRectGetMaxX(cell.frame) < _pagingScrollView.contentOffset.x - _pagingScrollView.frame.size.width) {
                cell.page = -1;
                cell.photo = nil;
                [cell removeFromSuperview];
            }
        }
    }
}

- (QQPhotoView *)dequeueReusableCell {
    QQPhotoView *cell = nil;
    for (cell in _reusableCells) {
        if (!cell.superview) {
            return cell;
        }
    }
    cell = [[QQPhotoView alloc] init];
    cell.frame = self.view.bounds;
    cell.page = -1;
    cell.photo = nil;
    [_reusableCells addObject:cell];
    return cell;
}

- (QQPhotoView *)cellForPage:(NSInteger)page {
    for (QQPhotoView *cell in _reusableCells) {
        if (cell.page == page) {
            return cell;
        }
    }
    return nil;
}

- (CGRect)cellFrameForPage:(NSInteger)page {
    CGRect bounds = _pagingScrollView.bounds;
    CGRect frame = bounds;
    frame.size.width -= (2 * kPadding);
    frame.origin.x = (bounds.size.width * page) + kPadding;
    return frame;
}

- (NSInteger)currentPage {
    NSInteger page = _pagingScrollView.contentOffset.x / _pagingScrollView.frame.size.width + 0.5;
    if (page >= _photos.count) page = (NSInteger)_photos.count - 1;
    if (page < 0) page = 0;
    return page;
}

- (void)setAnchorPoint:(CGPoint)anchorPoint forView:(UIView *)view scale:(CGFloat)scale {
    anchorPoint = CGPointMake(anchorPoint.x * scale, anchorPoint.y * scale);
    CGPoint oldOrigin = view.frame.origin;
    view.layer.anchorPoint = anchorPoint;
    CGPoint newOrigin = view.frame.origin;
    CGPoint transition = CGPointMake(newOrigin.x - oldOrigin.x, newOrigin.y - oldOrigin.y);
    view.center = CGPointMake(view.center.x - transition.x, view.center.y - transition.y);
}

- (UIViewController *)findVisibleViewController {
    UIViewController *visibleViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    while (1) {
        if (visibleViewController.presentedViewController) {
            visibleViewController = visibleViewController.presentedViewController;
        } else {
            if ([visibleViewController isKindOfClass:[UITabBarController class]]) {
                visibleViewController = ((UITabBarController *)visibleViewController).selectedViewController;
            } else if ([visibleViewController isKindOfClass:[UINavigationController class]]) {
                visibleViewController = ((UINavigationController *)visibleViewController).visibleViewController;
            } else {
                break;
            }
        }
    }
    return visibleViewController;
}

#pragma mark - Gestures

- (void)singleTapGestureHandle:(UITapGestureRecognizer *)gesture {
    _isTap = YES;
    [self performDismissAnimation];
}

- (void)doubleTapGestureHandle:(UITapGestureRecognizer *)gesture {
    QQPhotoView *photoView = [self cellForPage:_currentPage];
    if (photoView.scrollView.zoomScale > 1.0) {
        [photoView.scrollView setZoomScale:1.0 animated:YES];
    } else {
        CGPoint touchPoint = [gesture locationInView:photoView.imageView];
        CGFloat newZoomScale = photoView.scrollView.maximumZoomScale;
        CGFloat xsize = floorf(photoView.frame.size.width / newZoomScale);
        CGFloat ysize = floorf(photoView.frame.size.height / newZoomScale);
        [photoView.scrollView zoomToRect:CGRectMake(touchPoint.x - xsize / 2, touchPoint.y - ysize / 2, xsize, ysize) animated:YES];
    }
}

- (void)panGestureHandle:(UIPanGestureRecognizer *)gesture {
    if (!_isPresented) return;
    QQPhotoView *photoView = [self cellForPage:self.currentPage];
    if (CGSizeEqualToSize(photoView.imageView.frame.size, CGSizeZero)) return;
    
    CGPoint locationPoint = [gesture locationInView:self.view];
    CGPoint translationPoint = [gesture translationInView:self.view];
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan: {
            self.isDraggingPhoto = YES;
            [self setNeedsStatusBarAppearanceUpdate];
            [photoView hideProgressView];
            _imageViewBeginTransform = photoView.imageView.transform;
            locationPoint = [self.view convertPoint:locationPoint toView:photoView.imageView];
            CGPoint anchorPoint = CGPointMake(locationPoint.x / photoView.imageView.frame.size.width, locationPoint.y / photoView.imageView.frame.size.height);
            [self setAnchorPoint:anchorPoint forView:photoView.imageView scale:_imageViewBeginTransform.a];
        } break;
        case UIGestureRecognizerStateChanged: {
            CGFloat deltaX = translationPoint.x;
            CGFloat deltaY = translationPoint.y;
            
            CGFloat percent = 1 - fabs(deltaY / photoView.frame.size.height / 2);
            if (deltaY < 0) {
                percent = 1.0;
            };
            
            CGFloat scale = MAX(percent * _imageViewBeginTransform.a, 0.3);
    
            CGAffineTransform translationTransform = CGAffineTransformMakeTranslation(deltaX / scale, deltaY / scale);
            CGAffineTransform scaleTransform = CGAffineTransformMakeScale(scale, scale);
            photoView.imageView.transform = CGAffineTransformConcat(translationTransform, scaleTransform);
            
            CGFloat alpha = 1 - fabs(deltaY / photoView.frame.size.height * 2);
            if (deltaY < 0) {
                alpha = 1.0;
            }
            self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:alpha];
            
        } break;
        case UIGestureRecognizerStateEnded: {
            CGPoint v = [gesture velocityInView:self.view];
            CGFloat deltaY = translationPoint.y;
            if (v.y > 1000 || deltaY > 50) {
                [self performDismissAnimation];
            } else {
                if (photoView.photo.largeImageURL && photoView.photo.largeImageURL.absoluteString.length > 0 && !photoView.photo.originalImage) {
                    [photoView showProgressView];
                } else {
                    [photoView hideProgressView];
                }
                [UIView animateWithDuration:0.25 animations:^{
                    photoView.imageView.transform = self.imageViewBeginTransform;
                    self.view.backgroundColor = [UIColor blackColor];
                } completion:^(BOOL finished) {
                    self.isDraggingPhoto = NO;
                    [self setNeedsStatusBarAppearanceUpdate];
                    [self setAnchorPoint:CGPointMake(0.5, 0.5) forView:photoView.imageView scale:1.0];
                }];
            }
        } break;
        default:
            break;
    }
}

#pragma mark - Animations

- (void)performPresentAnimation {
    if (_isPresented) return;
    if (_currentPage >= _photos.count) _currentPage = _photos.count - 1;
    if (_currentPage < 0) _currentPage = 0;
    
    UIWindow *window = [UIApplication sharedApplication].delegate.window;
    QQPhoto *photo = self.photos[_currentPage];
    
    UIView *fromView = photo.sourceView;
    _firstFromView = fromView;
    CGRect fromFrame = [fromView convertRect:fromView.bounds toView:self.view];
    UIImageView *animatedImageView = [[UIImageView alloc] initWithImage:photo.thumbImage];
    animatedImageView.clipsToBounds = YES;
    animatedImageView.contentMode = photo.sourceView.contentMode;
    animatedImageView.layer.cornerRadius = photo.sourceView.layer.cornerRadius;
    animatedImageView.frame = fromFrame;
    [window addSubview:animatedImageView];
    
    CGRect finalFrame = [self finalFrameForAnimatedImageView:animatedImageView];
    [UIView animateWithDuration:0.25 animations:^{
        animatedImageView.frame = finalFrame;
        animatedImageView.layer.cornerRadius = 0.0;
    } completion:^(BOOL finished) {
        [animatedImageView removeFromSuperview];
        self.isPresented = YES;
        [self loadCellsForPage:self.currentPage];
    }];
}

- (void)performDismissAnimation {
    self.isDraggingPhoto = YES;
    [self setNeedsStatusBarAppearanceUpdate];
    self.view.hidden = YES;
    
    UIWindow *window = [UIApplication sharedApplication].delegate.window;
    QQPhotoView *photoView = [self cellForPage:self.currentPage];
    QQPhoto *photo = photoView.photo;
    
    UIView *fadeView = [[UIView alloc] initWithFrame:window.bounds];
    fadeView.backgroundColor = self.view.backgroundColor;
    [window addSubview:fadeView];
    
    UIImageView *animatedImageView = [[UIImageView alloc] initWithImage:photoView.imageView.image];
    animatedImageView.clipsToBounds = YES;
    animatedImageView.contentMode = photo.sourceView.contentMode;
    
    CGRect frame = [photoView.imageView convertRect:photoView.imageView.bounds toView:self.view];
    animatedImageView.frame = frame;
    [window addSubview:animatedImageView];

    CGRect fromFrame = [photo.sourceView convertRect:photo.sourceView.bounds toView:self.view];
    if (_isTap) {
//        fromFrame.origin.y += [UIApplication sharedApplication].statusBarFrame.size.height;
    }
    if (!photo.sourceView) {
        fromFrame = [_firstFromView convertRect:_firstFromView.bounds toView:self.view];
    }

    [UIView animateWithDuration:0.25 animations:^{
        fadeView.alpha = 0.0;
        animatedImageView.frame = fromFrame;
        animatedImageView.layer.cornerRadius = photo.sourceView.layer.cornerRadius;
    } completion:^(BOOL finished) {
        for (QQPhotoView *photoView in self.reusableCells) {
            photoView.photo.sourceView.hidden = NO;
            [photoView cancelCurrentImageLoad];
        }
        [animatedImageView removeFromSuperview];
        [fadeView removeFromSuperview];
        [self dismissViewControllerAnimated:NO completion:nil];
    }];
}

- (CGRect)finalFrameForAnimatedImageView:(UIImageView *)animatedImageView {
    UIImage *image = animatedImageView.image;
    if (!image) return CGRectZero;
    
    CGSize imageSize = image.size;
    CGSize boundsSize = self.view.frame.size;
    
    CGFloat imageViewX = 0;
    CGFloat imageViewY = 0;
    
    CGFloat imageViewWidth = floorf(self.view.frame.size.width);
    if (imageSize.width == 0) {
        return CGRectZero;
    }
    CGFloat imageViewHeight = floorf((imageViewWidth * imageSize.height) / imageSize.width);
    
    // Horizontally
    if (imageViewWidth < boundsSize.width) {
        imageViewX = floorf((boundsSize.width - imageViewWidth) / 2);
    } else {
        imageViewX = 0;
    }
    
    // Vertically
    if (imageViewHeight < boundsSize.height) {
        imageViewY = floorf((boundsSize.height - imageViewHeight) / 2);
    } else {
        imageViewY = 0;
    }
    
    // Center
    return CGRectMake(imageViewX, imageViewY, imageViewWidth, imageViewHeight);
}

#pragma mark - Dealloc

- (void)dealloc {
    [self.view removeObserver:self forKeyPath:@"frame"];
}

@end
