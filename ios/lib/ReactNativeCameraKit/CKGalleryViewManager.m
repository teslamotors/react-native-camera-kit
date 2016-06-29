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

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) PHFetchResult<PHAsset *> *galleryFetchResults;
@property (nonatomic, strong) PHFetchResult *assetsCollection;

@property (nonatomic, strong) PHCachingImageManager *imageManager;

@property (nonatomic) CGSize cellSize;
@property (nonatomic, strong) NSMutableArray *selectedAssets;


@end

static NSString * const CellReuseIdentifier = @"Cell";

@implementation CKGalleryView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    
    self.selectedAssets = [[NSMutableArray alloc] init];
    self.imageManager = [[PHCachingImageManager alloc] init];
    
    PHFetchOptions *allPhotosOptions = [[PHFetchOptions alloc] init];
    allPhotosOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    
    PHFetchOptions *albumsOptions = [[PHFetchOptions alloc] init];
    albumsOptions.predicate = [NSPredicate predicateWithFormat:@"estimatedAssetCount > 0"];
    
    
    return self;
}


-(CGSize)cellSize {
    if (CGSizeEqualToSize(_cellSize, CGSizeZero)) {
        CGFloat minSize = (MAX(self.bounds.size.width - (2*self.minimumInteritemSpacing.floatValue),0))/3;
        _cellSize = CGSizeMake(minSize, minSize);
    }
    return _cellSize;
}


-(void)reactSetFrame:(CGRect)frame {
    [super reactSetFrame:frame];
    
    if (!self.collectionView) {
        
        UICollectionViewFlowLayout* flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.itemSize = self.cellSize; //TODO remve this, get it from the JS
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
    
    PHFetchOptions *allPhotosOptions = [[PHFetchOptions alloc] init];
    allPhotosOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    
    if ([albumName caseInsensitiveCompare:@"all photos"] == NSOrderedSame || !albumName || [albumName isEqualToString:@""]) {
        self.assetsCollection = [PHAsset fetchAssetsWithOptions:allPhotosOptions];
        [self.collectionView reloadData];
        return;
    }
    
    
    PHFetchResult *collections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
    
    [collections enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ([collection.localizedTitle isEqualToString:albumName]) {
            
            self.assetsCollection = [PHAsset fetchAssetsInAssetCollection:collection options:nil];;
            [self.collectionView reloadData];
        }
    }];
    
    [self.collectionView reloadData];
}


#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.assetsCollection.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PHAsset *asset = self.assetsCollection[indexPath.row];
    
    CKGalleryCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellReuseIdentifier forIndexPath:indexPath];
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
    PHAsset *asset = self.assetsCollection[indexPath.row];
    
    if ([selectedCell isKindOfClass:[CKGalleryCollectionViewCell class]]) {
        CKGalleryCollectionViewCell *ckCell = (CKGalleryCollectionViewCell*)selectedCell;
        ckCell.isSelected = !ckCell.isSelected;
        
        [self.selectedAssets removeObject:asset];
        
        
        if (ckCell.isSelected) {
            if (asset) {
                [self.selectedAssets addObject:asset];
            }
        }
    }
}


- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    
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
    //
    
}

@end
