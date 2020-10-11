#import "CKOverlayObject.h"

@interface CKOverlayObject ()

@property (nonatomic, readwrite) float width;
@property (nonatomic, readwrite) float height;
@property (nonatomic, readwrite) float ratio;

@end

@implementation CKOverlayObject

-(instancetype)initWithString:(NSString*)str {

    self = [super init];

    if (self) {
        [self commonInit:str];
    }

    return self;
}

-(void)commonInit:(NSString*)str {

    NSArray<NSString*> *array = [str componentsSeparatedByString:@":"];
    if (array.count == 2) {
        float height = [array[0] floatValue];
        float width = [array[1] floatValue];

        if (width != 0 && height != 0) {
            self.width = width;
            self.height = height;
            self.ratio = self.width/self.height;
        }
    }
}

-(NSString *)description {
    return [NSString stringWithFormat:@"width:%f height:%f ratio:%f", self.width, self.height, self.ratio];
}


@end
