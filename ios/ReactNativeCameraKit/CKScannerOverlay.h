#import <UIKit/UIKit.h>

@interface CKScannerOverlay: UIView
@property (nonatomic, strong) UIView *topView, *leftSideView,*rightSideView,*bottomView;
@property (nonatomic, strong) NSArray *cornerViews;
@property (nonatomic, strong) UIView *dataReadingFrame;
@property (nonatomic) CGFloat frameOffset;
@property (nonatomic) CGFloat frameHeight;
@property (nonatomic) UIView *scannerView;
@property (nonatomic, strong) UIColor *laserColor;
@property (nonatomic, strong) UIColor *frameColor;
@property (nonatomic, assign) BOOL shouldAnimating;
@end
