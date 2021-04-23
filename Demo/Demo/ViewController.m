//
//  ViewController.m
//  Demo
//
//  Created by Mac on 2021/4/23.
//

#import "ViewController.h"
#import "QQPhotoBrowser.h"
#import "UIImageView+WebCache.h"

@interface ImageURLModel : NSObject
@property (nonatomic, copy) NSString *thumbImageURL;
@property (nonatomic, copy) NSString *largeImageURL;
@end

@implementation ImageURLModel
@end

@interface ViewController ()

@property (nonatomic, strong) UIView *container;
@property (nonatomic, strong) NSArray<UIImageView *> *imageViews;
@property (nonatomic, strong) NSArray<ImageURLModel *> *urlModels;

@end

@implementation ViewController

- (NSArray<ImageURLModel *> *)urlModels {
    if (!_urlModels) {
        NSArray *thumbURLs = @[
            @"http://ww2.sinaimg.cn/or180/613bfbfbgw1evpozdltf3j20ai0f8abf.jpg",
            @"http://ww4.sinaimg.cn/or180/dccb2f02gw1evo8ku5d1uj21kw7401ky.jpg",
            @"http://ww2.sinaimg.cn/or180/dccb2f02gw1evo8ke0t2pj21kw740u0x.jpg",
            @"http://ww4.sinaimg.cn/or180/dccb2f02gw1evo8mistttj21kw740npd.jpg",
            @"http://ww1.sinaimg.cn/or180/dccb2f02gw1evo8jw37ooj21kw23uk60.jpg",
            @"http://ww2.sinaimg.cn/or180/dccb2f02gw1evo8kdejrrj21kw23u12y.jpg",
            @"http://ww3.sinaimg.cn/or180/dccb2f02gw1evo8k0r4m8j21kw23u14p.jpg",
            @"http://ww2.sinaimg.cn/or180/dccb2f02gw1evo8k2ybi8j21kw23uahg.jpg",
            @"http://ww2.sinaimg.cn/or180/dccb2f02gw1evo8jxa5o2j21kw23uaob.jpg",
        ];
        NSArray *largeURLs = @[
            @"http://ww2.sinaimg.cn/wap720/613bfbfbgw1evpozdltf3j20ai0f8abf.jpg",
            @"http://ww4.sinaimg.cn/wap720/dccb2f02gw1evo8ku5d1uj21kw7401ky.jpg",
            @"http://ww2.sinaimg.cn/wap720/dccb2f02gw1evo8ke0t2pj21kw740u0x.jpg",
            @"http://ww4.sinaimg.cn/wap720/dccb2f02gw1evo8mistttj21kw740npd.jpg",
            @"http://ww1.sinaimg.cn/wap720/dccb2f02gw1evo8jw37ooj21kw23uk60.jpg",
            @"http://ww2.sinaimg.cn/wap720/dccb2f02gw1evo8kdejrrj21kw23u12y.jpg",
            @"http://ww3.sinaimg.cn/wap720/dccb2f02gw1evo8k0r4m8j21kw23u14p.jpg",
            @"http://ww2.sinaimg.cn/wap720/dccb2f02gw1evo8k2ybi8j21kw23uahg.jpg",
            @"http://ww2.sinaimg.cn/wap720/dccb2f02gw1evo8jxa5o2j21kw23uaob.jpg",
        ];
        NSMutableArray *array = [NSMutableArray array];
        for (NSInteger i = 0; i < thumbURLs.count; i++) {
            ImageURLModel *model = [[ImageURLModel alloc] init];
            model.thumbImageURL = thumbURLs[i];
            model.largeImageURL = largeURLs[i];
            [array addObject:model];
        }
        _urlModels = [array copy];
    }
    return _urlModels;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    _container = [[UIView alloc] init];
    _container.backgroundColor = [UIColor redColor];
    [self.view addSubview:_container];
    
    NSMutableArray *array = [NSMutableArray array];
    for (NSInteger i = 0; i < self.urlModels.count; i++) {
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        imageView.userInteractionEnabled = YES;
        [_container addSubview:imageView];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureHandler:)];
        [imageView addGestureRecognizer:tapGesture];
        
        [array addObject:imageView];
        
        [imageView sd_setImageWithURL:[NSURL URLWithString:self.urlModels[i].thumbImageURL]];
    }
    _imageViews = [array copy];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat width = MIN(CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame)) - 20;
    CGFloat y = (CGRectGetWidth(self.view.frame) > CGRectGetHeight(self.view.frame)) ? 20 : 80;
    _container.frame = CGRectMake((CGRectGetWidth(self.view.frame) - width) / 2, y, width, width);
    
    CGFloat margin = 5;
    CGFloat imageViewW = (width - 2 * margin) / 3;
    CGFloat imageViewH = imageViewW;
    for (NSInteger i = 0; i < self.imageViews.count; i++) {
        NSInteger row = i / 3;
        NSInteger col = i % 3;
        UIImageView *imageView = self.imageViews[i];
        imageView.frame = CGRectMake(col * (imageViewW + margin), row * (imageViewH + margin), imageViewW, imageViewH);
    }
}

- (void)tapGestureHandler:(UITapGestureRecognizer *)gesture {
    UIView *tapView = gesture.view;
    if ([tapView isKindOfClass:[UIImageView class]]) {
        UIImageView *imageView = (UIImageView *)tapView;
        NSMutableArray *photos = [NSMutableArray array];
        for (NSInteger i = 0; i < self.urlModels.count; i++) {
            UIImageView *sourceView = nil;
            if (i < self.imageViews.count) {
                sourceView = self.imageViews[i];
            }
            QQPhoto *photo = [[QQPhoto alloc] init];
            photo.sourceView = sourceView;
            photo.largeImageURL = [NSURL URLWithString:self.urlModels[i].largeImageURL];
            [photos addObject:photo];
        }
        NSInteger fromIndex = [self.imageViews indexOfObject:imageView];
        QQPhotoBrowser *browser = [[QQPhotoBrowser alloc] initWithPhotos:photos fromIndex:fromIndex];
        [browser show];
    }
}



@end
