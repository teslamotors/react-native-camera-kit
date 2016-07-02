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

#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)

#define DEFAULT_MINIMUM_INTERITEM_SPACING       10.0
#define DEFAULT_MINIMUM_LINE_SPACING            10.0


@interface CKGalleryView : UIView <UICollectionViewDelegateFlowLayout, UICollectionViewDataSource>

//props
@property (nonatomic, strong) NSString *albumName;
@property (nonatomic, strong) NSNumber *minimumLineSpacing;
@property (nonatomic, strong) NSNumber *minimumInteritemSpacing;
@property (nonatomic, strong) NSNumber *columnCount;
@property (nonatomic, copy) RCTDirectEventBlock onSelected;

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) PHFetchResult<PHAsset *> *galleryFetchResults;
@property (nonatomic, strong) GalleryData *galleryData;
@property (nonatomic, strong) PHCachingImageManager *imageManager;
@property (nonatomic) CGSize cellSize;
@property (nonatomic, strong) NSMutableArray *selectedAssets;

@property (nonatomic, strong) NSMutableArray *selectedImagesUrls;
@property (nonatomic, strong) PHImageRequestOptions *imageRequestOptions;

@property (nonatomic, strong) PHFetchOptions *fetchOptions;


@end

static NSString * const CellReuseIdentifier = @"Cell";

@implementation CKGalleryView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    self.selectedAssets = [[NSMutableArray alloc] init];
    self.imageManager = [[PHCachingImageManager alloc] init];
    
    self.imageRequestOptions = [[PHImageRequestOptions alloc] init];
    self.imageRequestOptions.synchronous = YES;
    
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
        _fetchOptions = fetchOptions;
    }
    
    return _fetchOptions;
}


-(void)reactSetFrame:(CGRect)frame {
    [super reactSetFrame:frame];
    
    if (!self.collectionView) {
        
        UICollectionViewFlowLayout* flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.itemSize = self.cellSize; //TODO remove this, get it from the JS
        [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
        
        self.collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:flowLayout];
        self.collectionView.delegate = self;
        self.collectionView.dataSource = self;
        
        [self.collectionView registerClass:[CKGalleryCollectionViewCell class] forCellWithReuseIdentifier:CellReuseIdentifier];
        [self addSubview:self.collectionView];
        self.collectionView.backgroundColor = [UIColor whiteColor];
        
    }
}



#pragma mark Collection view layout things



- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    return self.cellSize;
}


- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return self.minimumInteritemSpacing ? self.minimumInteritemSpacing.floatValue : DEFAULT_MINIMUM_INTERITEM_SPACING;
}


- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return self.minimumLineSpacing ? self.minimumLineSpacing.floatValue : DEFAULT_MINIMUM_INTERITEM_SPACING;
}


-(void)setAlbumName:(NSString *)albumName {
    
    
    if ([albumName caseInsensitiveCompare:@"all photos"] == NSOrderedSame || !albumName || [albumName isEqualToString:@""]) {
        PHFetchResult *allPhotosFetchResults = [PHAsset fetchAssetsWithOptions:self.fetchOptions];
        self.galleryData = [[GalleryData alloc] initWithFetchResults:allPhotosFetchResults];
        
        [self.collectionView reloadData];
        return;
    }
    
    
    PHFetchResult *collections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
    
    [collections enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ([collection.localizedTitle isEqualToString:albumName]) {
            
            PHFetchResult *collectionFetchResults = [PHAsset fetchAssetsInAssetCollection:collection options:nil];
            self.galleryData = [[GalleryData alloc] initWithFetchResults:collectionFetchResults];
            [self.collectionView reloadData];
        }
    }];
    
    [self.collectionView reloadData];
}


#pragma mark - UICollectionViewDataSource


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.galleryData.data.count;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *assetDictionary = (NSDictionary*)self.galleryData.data[indexPath.row];
    PHAsset *asset = assetDictionary[@"asset"];
    
    CKGalleryCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellReuseIdentifier forIndexPath:indexPath];
    cell.isSelected = ((NSNumber*)assetDictionary[@"isSelected"]).boolValue;
    
    cell.representedAssetIdentifier = asset.localIdentifier;
    
    [self.imageManager requestImageForAsset:asset
                                 targetSize:CGSizeMake(self.cellSize.width*0.95, self.cellSize.height*0.95)
                                contentMode:PHImageContentModeDefault
                                    options:nil
                              resultHandler:^(UIImage *result, NSDictionary *info) {
                                  // Set the cell's thumbnail image if it's still showing the same asset.
                                  if ([cell.representedAssetIdentifier isEqualToString:asset.localIdentifier]) {
                                      cell.thumbnailImage = result;
                                  }
                              }];
    
    
    return cell;
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
        ckCell.isSelected = !ckCell.isSelected;
        NSString *assetLocalIdentifier = asset.localIdentifier;
        
        if (ckCell.isSelected) {
            
            
            if (assetLocalIdentifier) {
                [self.selectedAssets addObject:assetLocalIdentifier];
            }
            else {
                NSLog(@"ERROR: assetInfo is nil!");
            }
        }
        else {
            [self.selectedAssets removeObject:assetLocalIdentifier];
        }
        
        [self onSelectChanged];
    }
}


-(NSMutableArray*)removeAssetInfoFromSelectedAssets:(PHAsset*)asset {
    
    NSMutableArray *newSelectedAssets = [[NSMutableArray alloc] init];
    
    for (NSDictionary *dictionary in self.selectedAssets) {
        if (dictionary[@"asset"] != asset) {
            [newSelectedAssets addObject:dictionary];
        }
    }
    return newSelectedAssets;
}


- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

-(void)refreshGalleryView {
    [self setAlbumName:self.albumName];
}


#pragma mark - misc


-(void)onSelectChanged {
    if (self.onSelected) {
        self.onSelected(@{@"selected":self.selectedAssets});
    }
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
RCT_EXPORT_VIEW_PROPERTY(onSelected, RCTDirectEventBlock);

RCT_EXPORT_METHOD(getSelectedImages:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    
    NSError *error = nil;
    NSURL *directoryURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]] isDirectory:YES];
    [[NSFileManager defaultManager] createDirectoryAtURL:directoryURL withIntermediateDirectories:YES attributes:nil error:&error];
    
    NSMutableArray *assetsUrls = [[NSMutableArray alloc] init];
    
    for (PHAsset *asset in self.galleryView.selectedAssets) {
        
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
            
            if (asset == self.galleryView.selectedAssets.lastObject) {
                if (resolve) {
                    resolve(@{@"selectedImages":assetsUrls});
                }
            }
        }];
    }
}


RCT_EXPORT_METHOD(refreshGalleryView:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    [self.galleryView refreshGalleryView];
    
    if (resolve)
        resolve(@YES);
}


#pragma mark - Static functions


+(NSMutableDictionary*)infoForAsset:(PHAsset*)asset imageRequestOptions:(PHImageRequestOptions*)imageRequestOptions {
    
    NSError *error = nil;
    NSURL *directoryURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]] isDirectory:YES];
    
    [[NSFileManager defaultManager] createDirectoryAtURL:directoryURL withIntermediateDirectories:YES attributes:nil error:&error];
    
    if (error) {
        NSLog(@"ERROR while creating directory:%@",error);
    }
    
    
    __block NSMutableDictionary *assetInfoDict = nil;
    
    [[PHCachingImageManager defaultManager] requestImageDataForAsset:asset options:imageRequestOptions resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        
        
        NSURL *fileURLKey = info[@"PHImageFileURLKey"];
        
        if (fileURLKey) {
            
            assetInfoDict = [[NSMutableDictionary alloc] init];
            
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
            else if (error){
                NSLog(@"%@", error);
            }
        }
    }];
    
    if (assetInfoDict && asset) {
        assetInfoDict[@"asset"] = asset;
    }
    
    return assetInfoDict;
}


@end
