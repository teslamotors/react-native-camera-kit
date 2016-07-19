//
//  CKOverlayObject.m
//  ReactNativeCameraKit
//
//  Created by Ran Greenberg on 17/07/2016.
//  Copyright © 2016 Wix. All rights reserved.
//

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
        float first = [array[0] floatValue];
        float second = [array[1] floatValue];
        
        if (first != 0 && second != 0) {
            self.width = first;
            self.height = second;
            self.ratio = self.width/self.height;
        }
    }
}

-(NSString *)description {
    return [NSString stringWithFormat:@"width:%f height:%f ratio:%f", self.width, self.height, self.ratio];
}


@end
