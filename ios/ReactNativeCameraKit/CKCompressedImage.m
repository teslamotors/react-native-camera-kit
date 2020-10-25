#import "CKCompressedImage.h"

@implementation CKCompressedImage

- (instancetype)initWithImage:(UIImage *)image imageQuality:(NSString*)imageQuality
{
    if(self = [super init]) {
        CGFloat max = 1200.0f;
        if ([imageQuality isEqualToString:@"high"]) {
            max = 1200.0f;
        }
        else if ([imageQuality isEqualToString:@"medium"]) {
            max = 800.0f;
        }
        else {
            _image = image;
            _data = UIImageJPEGRepresentation(image, 1.0f);
        }
        float actualHeight = image.size.height;
        float actualWidth = image.size.width;

        float imgRatio = actualWidth/actualHeight;

        float newHeight = (actualHeight > actualWidth) ? max : max/imgRatio;
        float newWidth = (actualHeight > actualWidth) ? max*imgRatio : max;


        CGRect rect = CGRectMake(0.0, 0.0, newWidth, newHeight);
        UIGraphicsBeginImageContext(rect.size);
        [image drawInRect:rect];
        _image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        _data = UIImageJPEGRepresentation(_image, 0.85f);
    }

    return self;
}


@end
