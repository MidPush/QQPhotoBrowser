//
//  QQPhoto.h
//  QQPhotoBrowser
//
//  Created by Mac on 2021/4/23.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class QQPhoto;
typedef void(^QQProgressUpdateBlock)(QQPhoto *photo, CGFloat progress);

@interface QQPhoto : NSObject

@property (nonatomic, strong, nullable) UIView *sourceView;
@property (nonatomic, strong, nullable) NSURL *largeImageURL;
@property (nonatomic, strong) UIImage *originalImage;
@property (nonatomic, strong, readonly) UIImage *thumbImage;
@property (nonatomic, copy) QQProgressUpdateBlock progressUpdateBlock;

@end

NS_ASSUME_NONNULL_END
