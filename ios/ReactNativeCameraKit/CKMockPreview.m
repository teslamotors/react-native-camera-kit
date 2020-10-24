//
//  CKMockPreview.m
//  ReactNativeCameraKit
//
//  Created by Aaron Grider on 10/20/20.
//

#import "CKMockPreview.h"

@implementation CKMockPreview

- (id)initWithFrame:(CGRect) frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    self.layer.cornerRadius  = 10.0f;
    self.layer.masksToBounds = YES;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self randomize];
}

- (void)randomize {
    self.layer.backgroundColor = [UIColor colorWithHue:drand48() saturation:1.0 brightness:1.0 alpha:1.0].CGColor;
    self.layer.sublayers = nil;
    
    for (int i = 0; i < 5; i++) {
        [self drawBalloon];
    }
}

- (void)drawBalloon {
    int stringLength = 200;
    CGFloat radius = [CKMockPreview randomNumberBetween:50 maxNumber:150];
    int x = arc4random_uniform(self.frame.size.width);
    int y = arc4random_uniform(self.frame.size.height + radius + stringLength);
    int stretch = radius / 3;
    
    CALayer *balloon = [CALayer layer];
    balloon.frame = CGRectMake(x - radius, y - radius, radius * 2, radius * 2 + stringLength);
    
    // Ballon main circle
    CAShapeLayer *circle = [CAShapeLayer layer];
    double colorHue = drand48();
    
    [circle setPath:[[UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, radius * 2, radius * 2 + stretch)] CGPath]];
    [circle setFillColor:[[UIColor colorWithHue:colorHue saturation:1.0 brightness:0.95 alpha:1.0] CGColor]];
    
    // Ballon reflection
    CAShapeLayer *reflection = [CAShapeLayer layer];
    [reflection setPath:[[UIBezierPath bezierPathWithOvalInRect:CGRectMake(radius / 2, radius / 2, radius * 0.7, radius * 0.7)] CGPath]];
    [reflection setFillColor:[[UIColor colorWithHue:colorHue saturation:1.0 brightness:1.0 alpha:1.0] CGColor]];
    
    // Ballon string
    CAShapeLayer *line = [CAShapeLayer layer];
    UIBezierPath *linePath= [UIBezierPath bezierPath];
    CGPoint startPoint = CGPointMake(balloon.frame.size.width / 2, radius * 2);
    CGPoint endPoint = CGPointMake(balloon.frame.size.width, (radius * 2) + stringLength);
    [linePath moveToPoint: startPoint];
    [linePath addQuadCurveToPoint:endPoint controlPoint:CGPointMake(balloon.frame.size.width / 2, radius * 2 + stringLength / 2)];
    line.path = linePath.CGPath;
    line.fillColor = nil;
    line.strokeColor = [UIColor darkGrayColor].CGColor;
    line.opacity = 1.0;
    line.lineWidth = radius * 0.05;
    
    // Add layers
    [balloon addSublayer:line];
    [circle addSublayer:reflection];
    [balloon addSublayer:circle];
    
    [self.layer addSublayer:balloon];
    
    // Apply animation
    CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    [scale setFromValue:[NSNumber numberWithFloat:0.7f]];
    [scale setToValue:[NSNumber numberWithFloat:1.0f]];
    [scale setDuration:10.0f];
    [scale setFillMode:kCAFillModeForwards];
    
    scale.removedOnCompletion = NO;
    scale.autoreverses= YES;
    scale.repeatCount = HUGE_VALF;
    
    CABasicAnimation *move = [CABasicAnimation animationWithKeyPath:@"position.y"];
    [move setFromValue:[NSNumber numberWithFloat:balloon.frame.origin.y]];
    [move setToValue:[NSNumber numberWithFloat: 0 - balloon.frame.size.height]];
    [move setDuration:[CKMockPreview randomNumberBetween:30 maxNumber:100]];
    
    move.removedOnCompletion = NO;
    move.repeatCount = HUGE_VALF;

    [balloon addAnimation:scale forKey:@"scale"];
    [balloon addAnimation:move forKey:@"move"];
}


- (UIImage *)snapshotWithTimestamp:(BOOL)showTimestamp {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0);
    [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:NO];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    if (showTimestamp) {
        NSDate *date = [NSDate date];
        NSDateFormatter *dateformatter = [[NSDateFormatter alloc] init];
        [dateformatter setDateFormat:@"HH:mm:ss"];
        NSString *stringFromDate = [dateformatter stringFromDate:date];
        UIFont *font = [UIFont boldSystemFontOfSize:20];
        
        [image drawInRect:CGRectMake(0,0,image.size.width,image.size.height)];
        CGRect rect = CGRectMake(25, 25, image.size.width, image.size.height);
        [[UIColor whiteColor] set];
        [stringFromDate drawInRect:CGRectIntegral(rect) withAttributes:[NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName]];
        
        image = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
    }
    
    return image;
}

+ (NSInteger)randomNumberBetween:(NSInteger)min maxNumber:(NSInteger)max
{
    return min + arc4random_uniform((uint32_t)(max - min + 1));
}

@end
