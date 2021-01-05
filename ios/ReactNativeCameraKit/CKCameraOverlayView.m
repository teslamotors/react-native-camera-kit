#import "CKCameraOverlayView.h"


@interface CKCameraOverlayView ()

@property (nonatomic, strong, readwrite) CKOverlayObject *overlayObject;
@property (nonatomic, strong) UIView *topView;
@property (nonatomic, strong, readwrite) UIView *centerView;
@property (nonatomic, strong) UIView *bottomView;


@end

@implementation CKCameraOverlayView



-(instancetype)initWithFrame:(CGRect)frame ratioString:(NSString*)ratioString overlayColor:(UIColor*)overlayColor {

    self = [super initWithFrame:frame];

    if (self) {

        self.overlayObject = [[CKOverlayObject alloc] initWithString:ratioString];
        self.topView = [[UIView alloc] initWithFrame:CGRectZero];
        self.centerView = [[UIView alloc] initWithFrame:CGRectZero];
        self.bottomView = [[UIView alloc] initWithFrame:CGRectZero];

        overlayColor = overlayColor ? overlayColor : [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3];

        self.topView.backgroundColor = overlayColor;
        self.bottomView.backgroundColor = overlayColor;

        [self addSubview:self.topView];
        [self addSubview:self.centerView];
        [self addSubview:self.bottomView];

        [self setOverlayParts];
    }

    return self;
}


-(void)setOverlayParts {

    if (self.overlayObject.ratio == 0) return;

    CGSize centerSize = CGSizeZero;
    CGSize sideSize = CGSizeZero;

    if (self.overlayObject.width < self.overlayObject.height) {

        centerSize.width = self.frame.size.width;
        centerSize.height = self.frame.size.height * self.overlayObject.ratio;

        sideSize.width = centerSize.width;
        sideSize.height = (self.frame.size.height - centerSize.height)/2.0;

        self.topView.frame = CGRectMake(0, 0, sideSize.width, sideSize.height);
        self.centerView.frame = CGRectMake(0, self.topView.frame.size.height + self.topView.frame.origin.y, centerSize.width, centerSize.height);
        self.bottomView.frame = CGRectMake(0, self.centerView.frame.size.height + self.centerView.frame.origin.y, sideSize.width, sideSize.height);
    }
    else if (self.overlayObject.width > self.overlayObject.height){
        centerSize.width = self.frame.size.width / self.overlayObject.ratio;
        centerSize.height = self.frame.size.height;

        sideSize.width = (self.frame.size.width - centerSize.width)/2.0;
        sideSize.height = centerSize.height;

        self.topView.frame = CGRectMake(0, 0, sideSize.width, sideSize.height);
        self.centerView.frame = CGRectMake(self.topView.frame.size.width + self.topView.frame.origin.x, 0, centerSize.width, centerSize.height);
        self.bottomView.frame = CGRectMake(self.centerView.frame.size.width + self.centerView.frame.origin.x, 0, sideSize.width, sideSize.height);
    }
    else { // ratio is 1:1
        centerSize.width = self.frame.size.width;
        centerSize.height = self.frame.size.width;

        sideSize.width = centerSize.width;
        sideSize.height = (self.frame.size.height - centerSize.height)/2.0;

        self.topView.frame = CGRectMake(0, 0, sideSize.width, sideSize.height);
        self.centerView.frame = CGRectMake(0, self.topView.frame.size.height + self.topView.frame.origin.y, centerSize.width, centerSize.height);
        self.bottomView.frame = CGRectMake(0, self.centerView.frame.size.height + self.centerView.frame.origin.y, sideSize.width, sideSize.height);
    }
}


-(void)setRatio:(NSString*)ratio {
    self.overlayObject = [[CKOverlayObject alloc] initWithString:ratio];

//    self.alpha =0;
    [UIView animateWithDuration:0.2 animations:^{
        [self setOverlayParts];
    } completion:nil];

}


@end
