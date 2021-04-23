//
//  QQPhotoProgressView.h
//  QQPhotoBrowser
//
//  Created by Mac on 2021/4/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface QQPhotoProgressView : UIView

@property (nonatomic, assign) CGFloat progress;
- (void)startSpinAnimation;
- (void)stopSpinAnimation;

@end

NS_ASSUME_NONNULL_END
