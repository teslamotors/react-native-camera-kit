#import "CKScannerOverlay.h"

@implementation CKScannerOverlay
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.frameOffset = 30;
        self.frameHeight = 200;

        self.dataReadingFrame = [UIView new];
        [self addSubview:self.dataReadingFrame];

        self.cornerViews = @[[UIView new],[UIView new],[UIView new],[UIView new],[UIView new],[UIView new],[UIView new],[UIView new]];
        for (UIView *view in self.cornerViews) {
            [self.dataReadingFrame addSubview:view];
        }

        self.topView = [UIView new];
        self.leftSideView = [UIView new];
        self.rightSideView = [UIView new];
        self.bottomView = [UIView new];
        [self addSubview:self.topView];
        [self addSubview:self.leftSideView];
        [self addSubview:self.rightSideView];
        [self addSubview:self.bottomView];

    }
    return self;
}

- (void)layoutSubviews{
    [self layoutDataReadingFrame];
    [self layoutCornerViews];
    [self layoutDimmedViews];
    if (self.shouldAnimating) {
        [self createScannerViewAndAnimate];
    } else {
        [self.scannerView removeFromSuperview];
        self.scannerView = nil;
    }
}

- (void)layoutDataReadingFrame {
    CGFloat frameWidth = self.bounds.size.width - 2 * self.frameOffset;
    self.dataReadingFrame.frame = CGRectMake(0, 0, frameWidth, self.frameHeight);
    self.dataReadingFrame.center = self.center;
    self.dataReadingFrame.backgroundColor = [UIColor clearColor];
}

- (void)createScannerViewAndAnimate {
    if (self.scannerView) {
        [self.scannerView removeFromSuperview];
    }
    self.scannerView = [[UIView alloc] initWithFrame:CGRectMake(2, 0, self.dataReadingFrame.frame.size.width - 4, 2)];
    self.scannerView.backgroundColor = self.laserColor;

    if (self.scannerView.frame.origin.y != 0) {
        [self.scannerView setFrame:CGRectMake(2, 0, self.dataReadingFrame.frame.size.width - 4, 2)];
    }
    [self.dataReadingFrame addSubview:self.scannerView];
    [UIView animateWithDuration:3 delay:0 options:(UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat) animations:^{
        CGFloat middleX = self.dataReadingFrame.frame.size.width / 2;
        self.scannerView.center = CGPointMake(middleX, self.dataReadingFrame.frame.size.height - 1);
    } completion:^(BOOL finished) {}];
}


// dimmed views are rectangles placed on the top left right bottom
- (void)layoutDimmedViews {
    UIColor *bgColor = [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:0.4];
    self.topView.backgroundColor = self.leftSideView.backgroundColor = self.rightSideView.backgroundColor = self.bottomView.backgroundColor = bgColor;

    CGRect inputRect = self.dataReadingFrame.frame;
    self.topView.frame = CGRectMake(0, 0, self.frame.size.width, inputRect.origin.y);
    self.leftSideView.frame = CGRectMake(0, inputRect.origin.y, self.frameOffset, self.frameHeight);
    self.rightSideView.frame = CGRectMake(inputRect.size.width + self.frameOffset, inputRect.origin.y, self.frameOffset, self.frameHeight);
    self.bottomView.frame = CGRectMake(0, inputRect.origin.y + self.frameHeight, self.frame.size.width, self.frame.size.height - inputRect.origin.y - self.frameHeight);
}


- (void)layoutCornerViews {
    UIView *frameView = self.dataReadingFrame;
    CGFloat cornerSize = 20.f;
    CGFloat cornerWidth = 2.f;
    for (int i = 0; i < 8; i++) {
        CGFloat x = 0.0;
        CGFloat y = 0.0;
        CGFloat width = 0.0;
        CGFloat height = 0.0;
        switch (i) {
            case 0:
                x = 0; y = 0; width = cornerWidth; height = cornerSize;
                break;
            case 1:
                x = 0; y = 0; width = cornerSize; height = cornerWidth;
                break;
            case 2:
                x = CGRectGetWidth(frameView.bounds) - cornerSize; y = 0; width = cornerSize; height = cornerWidth;
                break;
            case 3:
                x = CGRectGetWidth(frameView.bounds) - cornerWidth; y = 0; width = cornerWidth; height = cornerSize;
                break;
            case 4:
                x = CGRectGetWidth(frameView.bounds) - cornerWidth;
                y = CGRectGetHeight(frameView.bounds) - cornerSize; width = cornerWidth; height = cornerSize;
                break;
            case 5:
                x = CGRectGetWidth(frameView.bounds) - cornerSize;
                y = CGRectGetHeight(frameView.bounds) - cornerWidth; width = cornerSize; height = cornerWidth;
                break;
            case 6:
                x = 0; y = CGRectGetHeight(frameView.bounds) - cornerWidth; width = cornerSize; height = cornerWidth;
                break;
            case 7:
                x = 0; y = CGRectGetHeight(frameView.bounds) - cornerSize; width = cornerWidth; height = cornerSize;
                break;
        }
        UIView *cornerView = self.cornerViews[i];
        cornerView.frame = CGRectMake(x, y, width, height);
        cornerView.backgroundColor = self.frameColor;
    }
}


@end
