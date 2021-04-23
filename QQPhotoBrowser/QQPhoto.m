//
//  QQPhoto.m
//  QQPhotoBrowser
//
//  Created by Mac on 2021/4/23.
//

#import "QQPhoto.h"

@implementation QQPhoto

- (NSURL *)largeImageURL {
    if ([_largeImageURL isKindOfClass:[NSString class]]) {
        _largeImageURL = [NSURL URLWithString:(NSString *)_largeImageURL];
    }
    return _largeImageURL;
}

- (UIImage *)thumbImage {
    UIImage *image = nil;
    if ([_sourceView isKindOfClass:[UIButton class]]) {
        image = [(UIButton *)_sourceView currentImage];
        if (!image) {
            image = [(UIButton *)_sourceView currentBackgroundImage];
        }
    } else if ([_sourceView isKindOfClass:[UIImageView class]]) {
        image = ((UIImageView *)_sourceView).image;
    }
    if (!image) {
        image = [self getImageFromView:_sourceView];
    }
    return image;
}

- (UIImage *)getImageFromView:(UIView *)view {
    if (!view) return nil;
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, YES, [UIScreen mainScreen].scale);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
