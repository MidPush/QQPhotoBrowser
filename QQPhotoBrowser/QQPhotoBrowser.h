//
//  QQPhotoBrowser.h
//  QQPhotoBrowser
//
//  Created by Mac on 2021/4/23.
//

#import <UIKit/UIKit.h>
#import "QQPhoto.h"

NS_ASSUME_NONNULL_BEGIN

@interface QQPhotoBrowser : UIViewController

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new NS_UNAVAILABLE;

// Init
- (instancetype)initWithPhotos:(NSArray<QQPhoto *> *)photos fromIndex:(NSInteger)index;

@property (nonatomic, assign) BOOL canAutorotate;

// Show
- (void)show;

@end

NS_ASSUME_NONNULL_END
