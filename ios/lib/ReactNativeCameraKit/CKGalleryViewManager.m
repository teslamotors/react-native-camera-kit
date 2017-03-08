//
//  CKGalleryViewManager.m
//  ReactNativeCameraKit
//
//  Created by Ran Greenberg on 20/06/2016.
//  Copyright © 2016 Wix. All rights reserved.
//

@import Photos;
#import "CKGalleryViewManager.h"
#import "CKGalleryCollectionViewCell.h"
#import "CKGalleryCustomCollectionViewCell.h"
#import "GalleryData.h"
#import "UIView+React.h"
#import "CKGalleryManager.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "CKCamera.h"

#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)

#define DEFAULT_MINIMUM_INTERITEM_SPACING       10.0
#define DEFAULT_MINIMUM_LINE_SPACING            10.0
#define IMAGE_SIZE_MULTIPLIER                   2






@interface CKGalleryView : UIView <UICollectionViewDelegateFlowLayout, UICollectionViewDataSource>

//props
@property (nonatomic, strong) NSString *albumName;
@property (nonatomic, strong) NSNumber *minimumLineSpacing;
@property (nonatomic, strong) NSNumber *minimumInteritemSpacing;
@property (nonatomic, strong) NSNumber *columnCount;
@property (nonatomic, strong) NSNumber *getUrlOnTapImage;
@property (nonatomic, strong) NSNumber *autoSyncSelection;
@property (nonatomic, copy) RCTDirectEventBlock onTapImage;


@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) GalleryData *galleryData;
@property (nonatomic, strong) PHCachingImageManager *imageManager;
@property (nonatomic) CGSize cellSize;
@property (nonatomic, strong) NSMutableArray *selectedImages;

@property (nonatomic, strong) PHImageRequestOptions *imageRequestOptions;

@property (nonatomic, strong) PHFetchOptions *fetchOptions;
@property (nonatomic, strong) NSString *selectedBase64Image;
@property (nonatomic, strong) UIImage *selectedImageIcon;
@property (nonatomic, strong) UIImage *unSelectedImageIcon;
@property (nonatomic, strong) UIColor *imageStrokeColor;
@property (nonatomic, strong) NSNumber *disableSelectionIcons;
@property (nonatomic, strong) NSDictionary *selection;

//custom button props
@property (nonatomic, strong) NSDictionary *customButtonStyle;
@property (nonatomic, copy) RCTDirectEventBlock onCustomButtonPress;

//supported props
@property (nonatomic, strong) NSDictionary *fileTypeSupport;
@property (nonatomic, strong) NSArray *supportedFileTypesArray;


@end

static NSString * const CellReuseIdentifier = @"Cell";
static NSString * const CustomCellReuseIdentifier = @"CustomCell";

@implementation CKGalleryView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        
        self.selectedImages = [[NSMutableArray alloc] init];
        self.imageManager = [[PHCachingImageManager alloc] init];
        
        self.imageRequestOptions = [[PHImageRequestOptions alloc] init];
        self.imageRequestOptions.synchronous = YES;
    }
    
    return self;
}


-(CGSize)cellSize {
    if (CGSizeEqualToSize(_cellSize, CGSizeZero)) {
        CGFloat minSize = (MAX(self.bounds.size.width - ((self.columnCount.floatValue-1.0f)*self.minimumInteritemSpacing.floatValue),0))/self.columnCount.floatValue;
        _cellSize = CGSizeMake(minSize, minSize);
    }
    return _cellSize;
}

-(PHFetchOptions *)fetchOptions {
    if (!_fetchOptions) {
        PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
        fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
        fetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType = %d",PHAssetMediaTypeImage];
        
        _fetchOptions = fetchOptions;
    }
    
    return _fetchOptions;
}


-(void)removeFromSuperview {
    [CKGalleryCollectionViewCell cleanStaticsVariables];
    [super removeFromSuperview];
}


-(void)reactSetFrame:(CGRect)frame {
    [super reactSetFrame:frame];
    //NSLog(@"### reactSetFrame #####");
    
    if (CGRectIsEmpty(frame)) return;
    
    if (!self.collectionView) {
        //NSLog(@"### collection view create new#####");
        UICollectionViewFlowLayout* flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.itemSize = self.cellSize;
        [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
        
        self.collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:flowLayout];
        self.collectionView.delegate = self;
        self.collectionView.dataSource = self;
        
        [self.collectionView registerClass:[CKGalleryCollectionViewCell class] forCellWithReuseIdentifier:CellReuseIdentifier];
        [self.collectionView registerClass:[CKGalleryCustomCollectionViewCell class] forCellWithReuseIdentifier:CustomCellReuseIdentifier];
        [self addSubview:self.collectionView];
        self.collectionView.backgroundColor = [UIColor whiteColor];
        
    }
    else {
        //NSLog(@"### collection view using exists #####");
        self.collectionView.frame = self.bounds;
    }
}


#pragma mark - Collection view layout things


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    return self.cellSize;
}


- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return self.minimumInteritemSpacing ? self.minimumInteritemSpacing.floatValue : DEFAULT_MINIMUM_INTERITEM_SPACING;
}


- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return self.minimumLineSpacing ? self.minimumLineSpacing.floatValue : DEFAULT_MINIMUM_INTERITEM_SPACING;
}

-(void)upadateCollectionView:(PHFetchResult*)fetchResults animated:(BOOL)animated {
    
    self.galleryData = [[GalleryData alloc] initWithFetchResults:fetchResults selectedImagesIds:self.selectedImages];
    
    if (animated) {
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^ {
            [self.collectionView performBatchUpdates:^{
                [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
            } completion:nil];
        });
    }
    else {
        dispatch_async(dispatch_get_main_queue(), ^ {
            [self.collectionView reloadData];
        });
    }
}


-(void)setSelectedImageIcon:(UIImage *)selectedImage {
    [CKGalleryCollectionViewCell setSelectedImageIcon:selectedImage];
}


-(void)setUnSelectedImageIcon:(UIImage *)unSelectedImage {
    [CKGalleryCollectionViewCell setUnSlectedImageIcon:unSelectedImage];
}

-(void)setImageStrokeColor:(UIColor *)imageStrokeColor {
    [CKGalleryCollectionViewCell setImageStrokeColor:imageStrokeColor];
}

-(void)setSelection:(NSDictionary *)selection {
    [CKGalleryCollectionViewCell setSelection:selection];
}


-(void)setFileTypeSupport:(NSDictionary *)supported {
    _fileTypeSupport = supported;
    
    NSMutableDictionary *supportedDict = [[NSMutableDictionary alloc] init];
    
    // SUPPORTED_FILE_TYPES
    id supportedFileTypesId = self.fileTypeSupport[SUPPORTED_FILE_TYPES];
    if (supportedFileTypesId) {
        NSArray *supportedFileTypesArray = [RCTConvert NSArray:supportedFileTypesId];
        supportedDict[SUPPORTED_FILE_TYPES] = supportedFileTypesArray;
        
        self.supportedFileTypesArray = [NSArray arrayWithArray:supportedFileTypesArray];
    }
    
    // UNSUPPORTED_OVERLAY_COLOR
    id unsupportedOverlayColorId = self.fileTypeSupport[UNSUPPORTED_OVERLAY_COLOR];
    if (unsupportedOverlayColorId) {
        UIColor *unsupportedOverlayColor = [RCTConvert UIColor:unsupportedOverlayColorId];
        supportedDict[UNSUPPORTED_OVERLAY_COLOR] = unsupportedOverlayColor;
    }
    
    // UNSUPPORTED_OVERLAY_COLOR
    id unsupportedImageId = self.fileTypeSupport[UNSUPPORTED_IMAGE];
    if (unsupportedImageId) {
        UIImage *unsupportedImage = [RCTConvert UIImage:unsupportedImageId];
        supportedDict[UNSUPPORTED_IMAGE] = unsupportedImage;
    }
    
    // UNSUPPORTED_TEXT
    id unsupportedTextId = self.fileTypeSupport[UNSUPPORTED_TEXT];
    if (unsupportedTextId) {
        NSString *unsupportedText = [RCTConvert NSString:unsupportedTextId];
        supportedDict[UNSUPPORTED_TEXT] = unsupportedText;
    }
    
    // UNSUPPORTED_TEXT_COLOR
    id unsupportedTextColorId = self.fileTypeSupport[UNSUPPORTED_TEXT_COLOR];
    if (unsupportedTextColorId) {
        UIColor *unsupportedTextColor = [RCTConvert UIColor:unsupportedTextColorId];
        supportedDict[UNSUPPORTED_TEXT_COLOR] = unsupportedTextColor;
    }
    
    [CKGalleryCollectionViewCell setSupported:supportedDict];
}


-(void)setAlbumName:(NSString *)albumName {
    
    
    if ([albumName caseInsensitiveCompare:@"all photos"] == NSOrderedSame || !albumName || [albumName isEqualToString:@""]) {
        
        PHFetchResult *allPhotosFetchResults = [PHAsset fetchAssetsWithOptions:self.fetchOptions];
        [self upadateCollectionView:allPhotosFetchResults animated:(self.galleryData != nil)];
        return;
    }
    
    PHFetchResult *collections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
    
    [collections enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ([collection.localizedTitle isEqualToString:albumName]) {
            
            PHFetchResult *collectionFetchResults = [PHAsset fetchAssetsInAssetCollection:collection options:nil];
            [self upadateCollectionView:collectionFetchResults animated:(self.galleryData != nil)];
            *stop = YES;
            return;
        }
    }];
    
}


#pragma mark - UICollectionViewDataSource


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSUInteger itemsAmount = self.galleryData.data.count;
    if (self.customButtonStyle) {
        itemsAmount++;
    }
    return itemsAmount;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger cellIndex = indexPath.row;
    if (self.customButtonStyle ) {
        cellIndex--;
        
        if (indexPath.row == 0) {
            CKGalleryCustomCollectionViewCell *customCell = [collectionView dequeueReusableCellWithReuseIdentifier:CustomCellReuseIdentifier forIndexPath:indexPath];
            [customCell applyStyle:self.customButtonStyle];
            return customCell;
        }
        
    }
    
    NSDictionary *assetDictionary = (NSDictionary*)self.galleryData.data[cellIndex];
    PHAsset *asset = assetDictionary[@"asset"];
    
    NSString *fileType = [self extractFileTypeForAsset:asset];
    
    CFStringRef fileExtension = (__bridge CFStringRef)[fileType pathExtension];
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, NULL);
    CFStringRef MIMEType = UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType);
    CFRelease(UTI);
    NSString *MIMETypeString = (__bridge_transfer NSString *)MIMEType;
    
    __block CKGalleryCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellReuseIdentifier forIndexPath:indexPath];
    cell.disableSelectionIcons = self.disableSelectionIcons ? self.disableSelectionIcons.boolValue : false;
    
    if (self.supportedFileTypesArray) {
        cell.isSupported = [self.supportedFileTypesArray containsObject:[MIMETypeString lowercaseString]];
    }
    
    cell.representedAssetIdentifier = asset.localIdentifier;
    
    [self.imageManager requestImageForAsset:asset
                                 targetSize:CGSizeMake(self.cellSize.width*IMAGE_SIZE_MULTIPLIER, self.cellSize.height*IMAGE_SIZE_MULTIPLIER)
                                contentMode:PHImageContentModeDefault
                                    options:nil
                              resultHandler:^(UIImage *result, NSDictionary *info) {
                                  
                                  if ([cell.representedAssetIdentifier isEqualToString:asset.localIdentifier]) {
                                      cell.thumbnailImage = result;
                                  }
                              }];
    
    return cell;
}

-(NSString*)extractFileTypeForAsset:(PHAsset*)asset {
    return [asset valueForKey:@"uniformTypeIdentifier"];
}


#pragma mark - UICollectionViewDelegate


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger galleryDataIndex = indexPath.row;
    if (self.customButtonStyle) {
        galleryDataIndex--;
    }
    
    if (indexPath.row == 0 && self.onCustomButtonPress) {
        self.onCustomButtonPress(@{@"selected":@"customButtonPressed"});
        return;
    }
    
    id selectedCell =[collectionView cellForItemAtIndexPath:indexPath];
    NSMutableDictionary *assetDictionary = (NSMutableDictionary*)self.galleryData.data[galleryDataIndex];
    PHAsset *asset = assetDictionary[@"asset"];
    NSNumber *isSelectedNumber = assetDictionary[@"isSelected"];
    assetDictionary[@"isSelected"] = [NSNumber numberWithBool:!(isSelectedNumber.boolValue)];
    
    if ([selectedCell isKindOfClass:[CKGalleryCollectionViewCell class]]) {
        CKGalleryCollectionViewCell *ckCell = (CKGalleryCollectionViewCell*)selectedCell;
        
        if (!ckCell.isSupported) {
            return;
        }
        
        ckCell.isSelected = !ckCell.isSelected;
        
        [self onSelectChanged:asset];
    }
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if([cell isKindOfClass:[CKGalleryCollectionViewCell class]]) {
        CKGalleryCollectionViewCell *ckCell = (CKGalleryCollectionViewCell*)cell;
        
        NSInteger galleryDataIndex = indexPath.row;
        if (self.customButtonStyle) {
            galleryDataIndex--;
        }
        NSDictionary *assetDictionary = (NSDictionary*)self.galleryData.data[galleryDataIndex];
        ((CKGalleryCollectionViewCell*)cell).isSelected = ((NSNumber*)assetDictionary[@"isSelected"]).boolValue;
    }
}

-(BOOL)isSelectionDirty:(NSMutableArray *)newSelectedImages {
    if(![self.autoSyncSelection boolValue]) {
        return NO;
    }
    NSArray *mergedArray = [newSelectedImages arrayByAddingObjectsFromArray:self.selectedImages];
    NSArray *arrayWithoutDuplicates = [[NSOrderedSet orderedSetWithArray:mergedArray] array];
    return (arrayWithoutDuplicates.count > 0);
}

-(void)setSelectedImages:(NSMutableArray *)selectedImages {
    BOOL selectionDirty = [self isSelectionDirty:selectedImages];
    if (selectedImages) {
        _selectedImages = selectedImages;
    }
    
    if(selectionDirty && [self.autoSyncSelection boolValue]) {
        //sync visible cells
        for (CKGalleryCollectionViewCell *cell in [self.collectionView visibleCells]) {
            if([cell respondsToSelector:@selector(representedAssetIdentifier)]) {
                cell.isSelected = ([selectedImages indexOfObject:cell.representedAssetIdentifier] != NSNotFound);
            }
        }
        //sync data
        for (NSMutableDictionary *dataDic in self.galleryData.data) {
            PHAsset *asset = dataDic[@"asset"];
            dataDic[@"isSelected"] = @([selectedImages indexOfObject:asset.localIdentifier] != NSNotFound);
        }
    }
}


-(void)refreshGalleryView:(NSArray*)selectedImages {
    self.selectedImages = selectedImages;
    [self setAlbumName:self.albumName];
}


#pragma mark - misc


-(void)onSelectChanged:(PHAsset*)asset {
    if (self.onTapImage) {
        
        BOOL shouldReturnUrl = self.getUrlOnTapImage ? [self.getUrlOnTapImage boolValue] : NO;
        if (shouldReturnUrl) {
            PHImageRequestOptions *imageRequestOptions = [[PHImageRequestOptions alloc] init];
            imageRequestOptions.synchronous = YES;
            NSDictionary *info = [CKGalleryViewManager infoForAsset:asset imageRequestOptions:imageRequestOptions];
            NSString *uriString = info[@"uri"];
            if (uriString) {
                self.onTapImage(@{@"selected": uriString, @"selectedId": asset.localIdentifier});
            }
            else {
                self.onTapImage(@{@"Error": @"Could not get image uri"});
            }
            
        }
        else {
            self.onTapImage(@{@"selected":asset.localIdentifier});
        }
    }
}


+(PHFetchResult*)filterFetchResults:(PHFetchResult*)fetchResults typesArray:(NSArray*)typesArray {
    
    [fetchResults enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSLog(@"obj");
    }];
    
    return nil;
    
}


@end

@interface CKGalleryViewManager ()

@property (nonatomic, strong) CKGalleryView *galleryView;

@end


@implementation CKGalleryViewManager


RCT_EXPORT_MODULE()


- (UIView *)view
{
    self.galleryView = [[CKGalleryView alloc] init];
    return self.galleryView;
}


RCT_EXPORT_VIEW_PROPERTY(albumName, NSString);
RCT_EXPORT_VIEW_PROPERTY(minimumLineSpacing, NSNumber);
RCT_EXPORT_VIEW_PROPERTY(minimumInteritemSpacing, NSNumber);
RCT_EXPORT_VIEW_PROPERTY(columnCount, NSNumber);
RCT_EXPORT_VIEW_PROPERTY(onTapImage, RCTDirectEventBlock);
RCT_EXPORT_VIEW_PROPERTY(selectedImageIcon, UIImage);
RCT_EXPORT_VIEW_PROPERTY(unSelectedImageIcon, UIImage);
RCT_EXPORT_VIEW_PROPERTY(selectedImages, NSArray);
RCT_EXPORT_VIEW_PROPERTY(fileTypeSupport, NSDictionary);
RCT_EXPORT_VIEW_PROPERTY(imageStrokeColor, UIColor);
RCT_EXPORT_VIEW_PROPERTY(disableSelectionIcons, NSNumber);
RCT_EXPORT_VIEW_PROPERTY(customButtonStyle, NSDictionary);
RCT_EXPORT_VIEW_PROPERTY(onCustomButtonPress, RCTDirectEventBlock);
RCT_EXPORT_VIEW_PROPERTY(getUrlOnTapImage, NSNumber);
RCT_EXPORT_VIEW_PROPERTY(autoSyncSelection, NSNumber);
RCT_EXPORT_VIEW_PROPERTY(selection, NSDictionary);


RCT_EXPORT_METHOD(getSelectedImages:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    
    NSError *error = nil;
    NSURL *directoryURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]] isDirectory:YES];
    [[NSFileManager defaultManager] createDirectoryAtURL:directoryURL withIntermediateDirectories:YES attributes:nil error:&error];
    
    NSMutableArray *assetsUrls = [[NSMutableArray alloc] init];
    
    for (PHAsset *asset in self.galleryView.selectedImages) {
        
        [self.galleryView.imageManager requestImageDataForAsset:asset options:nil resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
            
            NSURL *fileURLKey = info[@"PHImageFileURLKey"];
            if (!fileURLKey) {
                if (resolve) {
                    resolve(nil);
                }
            }
            
            NSMutableDictionary *assetInfoDict = [[NSMutableDictionary alloc] init];
            
            NSString *fileName = ((NSURL*)info[@"PHImageFileURLKey"]).lastPathComponent;
            if (fileName) {
                assetInfoDict[@"name"] = fileName;
            }
            
            float imageSize = imageData.length;
            assetInfoDict[@"size"] = [NSNumber numberWithFloat:imageSize];
            
            NSURL *fileURL = [directoryURL URLByAppendingPathComponent:fileName];
            NSError *error = nil;
            [imageData writeToURL:fileURL options:NSDataWritingAtomic error:&error];
            
            if (!error && fileURL) {
                assetInfoDict[@"uri"] = fileURL.absoluteString;
            }
            
            [assetsUrls addObject:assetInfoDict];
            
            if (asset == self.galleryView.selectedImages.lastObject) {
                if (resolve) {
                    resolve(@{@"selectedImages":assetsUrls});
                }
            }
        }];
    }
}


RCT_EXPORT_METHOD(refreshGalleryView:(NSArray*)selectedImages
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    NSMutableArray *newArray = [[NSMutableArray alloc] initWithArray:selectedImages];
    [self.galleryView refreshGalleryView:newArray];
    
    if (resolve)
        resolve(@YES);
}


#pragma mark - Static functions


+(NSMutableDictionary*)infoForAsset:(PHAsset*)asset imageRequestOptions:(PHImageRequestOptions*)imageRequestOptions {
    
    NSError *error = nil;
    NSURL *directoryURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]] isDirectory:YES];
    
    [[NSFileManager defaultManager] createDirectoryAtURL:directoryURL withIntermediateDirectories:YES attributes:nil error:&error];
    
    if (error) {
        //NSLog(@"ERROR while creating directory:%@",error);
    }
    
    
    __block NSMutableDictionary *assetInfoDict = nil;
    
    [[PHCachingImageManager defaultManager] requestImageDataForAsset:asset options:imageRequestOptions resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        
        
        NSURL *fileURLKey = info[@"PHImageFileURLKey"];
        
        if (fileURLKey) {
            
            assetInfoDict = [[NSMutableDictionary alloc] init];
            
            NSString *fileName = ((NSURL*)info[@"PHImageFileURLKey"]).lastPathComponent;
            if (fileName) {
                assetInfoDict[@"name"] = fileName;
            } else {
                fileName = @"";
            }
            
            float imageSize = 0;
            if (imageData) {
                imageSize= imageData.length;
            }
            assetInfoDict[@"size"] = [NSNumber numberWithFloat:imageSize];
            
            NSURL *fileURL = [directoryURL URLByAppendingPathComponent:fileName];
            NSError *error = nil;
            
            [imageData writeToURL:fileURL options:NSDataWritingAtomic error:&error];
            
            if (!error && fileURL) {
                assetInfoDict[@"uri"] = fileURL.absoluteString;
            }
            else if (error){
                //NSLog(@"%@", error);
            }
        }
    }];
    
    if (assetInfoDict && asset) {
        assetInfoDict[@"asset"] = asset;
    }
    
    return assetInfoDict;
}


@end
