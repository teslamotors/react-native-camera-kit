//
//  GalleryData.m
//  ReactNativeCameraKit
//
//  Created by Ran Greenberg on 30/06/2016.
//  Copyright © 2016 Wix. All rights reserved.
//

#import "GalleryData.h"

@interface GalleryData ()

@property (nonatomic, strong) PHFetchResult *fetchResults;
@property (nonatomic, strong, readwrite) NSArray *data;

@end


@implementation GalleryData

-(instancetype)initWithFetchResults:(PHFetchResult*)fetchResults selectedImagesIds:(NSArray*)selectedImagesIds{
    
    self = [super init];
    if (self) {
        self.fetchResults = fetchResults;
        self.data = [self arrayWithFetchResults:self.fetchResults selectedImagesIds:selectedImagesIds];
    }
    return self;
}



-(NSArray*)arrayWithFetchResults:(PHFetchResult*)fetchResults selectedImagesIds:(NSArray*)selectedImagesIds{
    
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    for (PHAsset *asset in fetchResults) {
        BOOL isSelected = ([selectedImagesIds containsObject:asset.localIdentifier]) ? YES : NO;
        
        NSMutableDictionary *assetDictionary = [@{@"asset": asset, @"isSelected": @(isSelected)} mutableCopy];
        
        [array addObject:assetDictionary];
    }
    
    return array;
}


@end
