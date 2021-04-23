//
//  QQPhotoProgressView.m
//  QQPhotoBrowser
//
//  Created by Mac on 2021/4/23.
//

#import "QQPhotoProgressView.h"

static NSString *kQQSipnAnimationKey = @"kQQSipnAnimationKey";

@interface QQPhotoProgressView ()

@property (nonatomic, strong) CAShapeLayer *rotateLayer;
@property (nonatomic, strong) UILabel *progressLabel;

@end

@implementation QQPhotoProgressView

- (CAShapeLayer *)rotateLayer {
    if (!_rotateLayer) {
        _rotateLayer = [CAShapeLayer layer];
        _rotateLayer.lineWidth = 4.0;
        _rotateLayer.lineCap = kCALineCapRound;
        _rotateLayer.fillColor = [UIColor clearColor].CGColor;
        _rotateLayer.strokeColor = [UIColor whiteColor].CGColor;
    }
    return _rotateLayer;
}

- (UILabel *)progressLabel {
    if (!_progressLabel) {
        _progressLabel = [[UILabel alloc] initWithFrame:self.bounds];
        _progressLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _progressLabel.backgroundColor = [UIColor clearColor];
        _progressLabel.textAlignment = NSTextAlignmentCenter;
        _progressLabel.textColor = [UIColor whiteColor];
        _progressLabel.font = [UIFont systemFontOfSize:12];
    }
    return _progressLabel;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        [self addSubview:self.progressLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.progressLabel.frame = self.bounds;
}

- (void)drawRect:(CGRect)rect {
    CGFloat lineWidth = 4.0;
    CGFloat radius = self.frame.size.width / 2 - lineWidth / 2;
    CGPoint center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextAddArc(context, center.x, center.y, radius, 0, 2 * M_PI, YES);
    CGContextSetStrokeColorWithColor(context, [[UIColor blackColor] colorWithAlphaComponent:0.7].CGColor);
    CGContextSetLineWidth(context, lineWidth);
    CGContextStrokePath(context);
    
    UIBezierPath *rotatePath = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:-M_PI_2 endAngle:M_PI_2 - M_PI / 3.0 clockwise:YES];
    self.rotateLayer.path = rotatePath.CGPath;
    self.rotateLayer.frame = self.bounds;
    [self.layer addSublayer:self.rotateLayer];
}

- (void)setProgress:(CGFloat)progress {
    if (progress <= 0.0) progress = 0.0;
    if (progress > 1.0) progress = 1.0;
    _progress = progress;
    self.progressLabel.text = [NSString stringWithFormat:@"%.f%%", progress * 100.0];
}

- (void)startSpinAnimation {
    CABasicAnimation *spinAnimation = [self.layer animationForKey:kQQSipnAnimationKey];
    if (!spinAnimation) {
        spinAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        spinAnimation.toValue = @(M_PI * 2);
        spinAnimation.duration = 0.8;
        spinAnimation.repeatCount = HUGE_VALF;
        spinAnimation.removedOnCompletion = NO;
        [self.rotateLayer addAnimation:spinAnimation forKey:kQQSipnAnimationKey];
    }
}

- (void)stopSpinAnimation {
    [_rotateLayer removeAnimationForKey:kQQSipnAnimationKey];
}

- (void)dealloc {
    [self stopSpinAnimation];
}

@end
