//
//  CKMockPreview.h
//  ReactNativeCameraKit
//
//  Created by Aaron Grider on 10/20/20.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CKMockPreview : UIView

- (UIImage *)snapshotWithTimestamp:(BOOL)showTimestamp;
- (void)randomize;

@end

NS_ASSUME_NONNULL_END
