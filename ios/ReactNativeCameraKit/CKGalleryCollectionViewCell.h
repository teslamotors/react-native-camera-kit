#import <UIKit/UIKit.h>

#define SUPPORTED_FILE_TYPES                            @"supportedFileTypes"
#define UNSUPPORTED_OVERLAY_COLOR                       @"unsupportedOverlayColor"
#define UNSUPPORTED_IMAGE                               @"unsupportedImage"
#define UNSUPPORTED_TEXT                                @"unsupportedText"
#define UNSUPPORTED_TEXT_COLOR                          @"unsupportedTextColor"

#define REMOTE_DOWNLOAD_INDICATOR_TYPE_SPINNER          @"spinner"
#define REMOTE_DOWNLOAD_INDICATOR_TYPE_PROGRESS_BAR     @"progress-bar"
#define REMOTE_DOWNLOAD_INDICATOR_TYPE_PROGRESS_PIE     @"progress-pie"

@class CKGalleryCollectionViewCell;

@protocol CKGalleryCollectionViewCellDelegate <NSObject>
- (BOOL)shouldShowPressIndicator:(CKGalleryCollectionViewCell*)cell;
@end

@interface CKGalleryCollectionViewCell : UICollectionViewCell

-(void)setPressed:(BOOL)pressed;

+(void)setSelectedImageIcon:(UIImage*)image;
+(void)setUnSlectedImageIcon:(UIImage*)image;
+(void)setSupported:(NSDictionary*)newSupported;
+(void)setImageStrokeColor:(UIColor*)strokeColor;
+(void)setImageStrokeColorWidth:(NSNumber*)width;
+(void)setSelection:(NSDictionary*)selectionDict;
+(void)setRemoteDownloadIndicatorColor:(UIColor*)color;
+(void)setRemoteDownloadIndicatorType:(NSString*)type;

+(void)cleanStaticsVariables;

@property (nonatomic, weak) id<CKGalleryCollectionViewCellDelegate> delegate;

@property (nonatomic, strong) UIImage *thumbnailImage;
@property (nonatomic, copy) NSString *representedAssetIdentifier;

@property (nonatomic) BOOL isSelected;
@property (nonatomic) BOOL isSupported;
@property (nonatomic) BOOL disableSelectionIcons;
@property (nonatomic) BOOL isDownloading;
@property (nonatomic) CGFloat downloadingProgress;
@end
