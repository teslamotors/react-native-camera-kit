#import <Foundation/Foundation.h>
@import Photos;

@interface GalleryData : NSObject

-(instancetype)initWithFetchResults:(PHFetchResult*)fetchResults selectedImagesIds:(NSArray*)selectedImagesIds;

@property (nonatomic, strong, readonly) NSArray *data;



@end
