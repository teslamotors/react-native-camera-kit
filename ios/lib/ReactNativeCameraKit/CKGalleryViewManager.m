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
#import "GalleryData.h"
#import "UIView+React.h"
#import "CKGalleryManager.h"

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


//supported
@property (nonatomic, strong) NSDictionary *supported;
@property (nonatomic, strong) NSArray *supportedFileTypesArray;


@end

static NSString * const CellReuseIdentifier = @"Cell";

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


-(void)setSupported:(NSDictionary *)supported {
    _supported = supported;
    
    
    NSArray *supportedFileTypesArray;
    UIColor *unsupportedOverlayColor;
    UIImage *unsupportedImage;
    NSString *unsupportedText;
    UIColor *unsupportedTextColor;
    
    NSMutableDictionary *supportedDict = [[NSMutableDictionary alloc] init];
    
    
    // SUPPORTED_FILE_TYPES
    id supportedFileTypesId = self.supported[SUPPORTED_FILE_TYPES];
    if (supportedFileTypesId) {
        supportedFileTypesArray = [RCTConvert NSArray:supportedFileTypesId];
        [supportedDict setValue:supportedFileTypesArray forKey:SUPPORTED_FILE_TYPES];
        
        self.supportedFileTypesArray = [NSArray arrayWithArray:supportedFileTypesArray];
    }
    
    // UNSUPPORTED_OVERLAY_COLOR
    id unsupportedOverlayColorId = self.supported[UNSUPPORTED_OVERLAY_COLOR];
    if (unsupportedOverlayColorId) {
        unsupportedOverlayColor = [RCTConvert UIColor:unsupportedOverlayColorId];
        [supportedDict setValue:unsupportedOverlayColor forKey:UNSUPPORTED_OVERLAY_COLOR];
    }
    
    // UNSUPPORTED_OVERLAY_COLOR
    id unsupportedImageId = self.supported[UNSUPPORTED_IMAGE];
    if (unsupportedImageId) {
        unsupportedImage = [RCTConvert UIImage:unsupportedImageId];
        [supportedDict setValue:unsupportedImage forKey:UNSUPPORTED_IMAGE];
    }
    
    // UNSUPPORTED_TEXT
    id unsupportedTextId = self.supported[UNSUPPORTED_TEXT];
    if (unsupportedTextId) {
        unsupportedText = [RCTConvert NSString:unsupportedTextId];
        [supportedDict setValue:unsupportedText forKey:UNSUPPORTED_TEXT];
    }
    
    // UNSUPPORTED_TEXT_COLOR
    id unsupportedTextColorId = self.supported[UNSUPPORTED_TEXT_COLOR];
    if (unsupportedTextColorId) {
        unsupportedTextColor = [RCTConvert UIColor:unsupportedTextColorId];
        [supportedDict setValue:unsupportedTextColor forKey:UNSUPPORTED_TEXT_COLOR];
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
    return self.galleryData.data.count;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *assetDictionary = (NSDictionary*)self.galleryData.data[indexPath.row];
    PHAsset *asset = assetDictionary[@"asset"];
    
    NSString *fileType = [self extractFileTypeForAsset:asset];
    
    
    
    
    __block CKGalleryCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellReuseIdentifier forIndexPath:indexPath];
    cell.isSelected = ((NSNumber*)assetDictionary[@"isSelected"]).boolValue;
    cell.isSupported = YES;
    
    cell.representedAssetIdentifier = asset.localIdentifier;
    
    [self.imageManager requestImageForAsset:asset
                                 targetSize:CGSizeMake(self.cellSize.width*IMAGE_SIZE_MULTIPLIER, self.cellSize.height*IMAGE_SIZE_MULTIPLIER)
                                contentMode:PHImageContentModeDefault
                                    options:self.imageRequestOptions
                              resultHandler:^(UIImage *result, NSDictionary *info) {
                                  if ([cell.representedAssetIdentifier isEqualToString:asset.localIdentifier]) {
                                      cell.thumbnailImage = result;
                                      
                                      if (self.supportedFileTypesArray) {
                                          
                                          if ([self.supportedFileTypesArray containsObject:[fileType lowercaseString]]) {
                                              cell.isSupported = YES;
                                          }
                                          
                                          else {
                                              cell.isSupported = NO;
                                          }
                                      }
                                  }
                              }];
    
    
    return cell;
}

-(NSString*)extractFileTypeForAsset:(PHAsset*)asset {
    NSString *fileName = [asset valueForKey:@"filename"];
    NSArray *splitFileName = [fileName componentsSeparatedByString:@"."];
    if (splitFileName.count > 1) {
        return splitFileName[1];
    }
    
    return nil;
}


#pragma mark - UICollectionViewDelegate


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    id selectedCell =[collectionView cellForItemAtIndexPath:indexPath];
    NSMutableDictionary *assetDictionary = (NSMutableDictionary*)self.galleryData.data[indexPath.row];
    PHAsset *asset = assetDictionary[@"asset"];
    NSNumber *isSelectedNumber = assetDictionary[@"isSelected"];
    assetDictionary[@"isSelected"] = [NSNumber numberWithBool:!(isSelectedNumber.boolValue)];
    
    if ([selectedCell isKindOfClass:[CKGalleryCollectionViewCell class]]) {
        CKGalleryCollectionViewCell *ckCell = (CKGalleryCollectionViewCell*)selectedCell;
        
        if (!ckCell.isSupported) {
            return;
        }
        
        ckCell.isSelected = !ckCell.isSelected;
        NSString *assetLocalIdentifier = asset.localIdentifier;
        
        [self onSelectChanged:assetLocalIdentifier];
    }
}

-(void)setSelectedImages:(NSMutableArray *)selectedImages {
    if (selectedImages) {
        _selectedImages = selectedImages;
    }
}


-(void)refreshGalleryView:(NSArray*)selectedImages {
    self.selectedImages = selectedImages;
    [self setAlbumName:self.albumName];
}


#pragma mark - misc


-(void)onSelectChanged:(NSString*)tappedImageId {
    if (self.onTapImage) {
        self.onTapImage(@{@"selected":tappedImageId});
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
RCT_EXPORT_VIEW_PROPERTY(supported, NSDictionary);



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
