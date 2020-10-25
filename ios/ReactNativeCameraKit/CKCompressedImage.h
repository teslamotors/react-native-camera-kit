#import <UIKit/UIKit.h>

@interface CKCompressedImage : NSObject

- (instancetype)initWithImage:(UIImage *)image imageQuality:(NSString*)imageQuality;

@property (nonatomic, readonly) UIImage *image;
@property (nonatomic, readonly) NSData *data;

@end
