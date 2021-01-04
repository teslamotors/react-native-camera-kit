#import <UIKit/UIKit.h>
#import "CKOverlayObject.h"

@interface CKCameraOverlayView : UIView


@property (nonatomic, strong, readonly) UIView *centerView;
@property (nonatomic, strong, readonly) CKOverlayObject *overlayObject;



-(instancetype)initWithFrame:(CGRect)frame ratioString:(NSString*)ratioString overlayColor:(UIColor*)overlayColor;

-(void)setRatio:(NSString*)ratio;

@end
