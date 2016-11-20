//
//  SelectionGesture.m
//  ReactNativeCameraKit
//
//  Created by Ran Greenberg on 05/07/2016.
//  Copyright © 2016 Wix. All rights reserved.
//

#import "SelectionGesture.h"

@implementation SelectionGesture


-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [super touchesBegan:touches withEvent:event];
    if (self.state == UIGestureRecognizerStatePossible) {
        self.state = UIGestureRecognizerStateBegan;
    }
}


-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    [super touchesEnded:touches withEvent:event];
    self.state = UIGestureRecognizerStateEnded;
}



@end
