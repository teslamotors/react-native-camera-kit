#import <Foundation/Foundation.h>

@interface CKOverlayObject : NSObject


@property (nonatomic, readonly) float width;
@property (nonatomic, readonly) float height;
@property (nonatomic, readonly) float ratio;

-(instancetype)initWithString:(NSString*)str;


@end
