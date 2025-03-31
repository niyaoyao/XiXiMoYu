//
//  NYCubismManager.h
//  Live2DSDK
//
//  Created by niyao on 3/18/25.
//

#import <Foundation/Foundation.h>
@class UIViewController;
@class LAppTextureManager;

NS_ASSUME_NONNULL_BEGIN
/// Manage Live2D SDK
@interface NYLDSDKManager : NSObject

@property (nonatomic, strong) UIViewController *stageVC;

+ (instancetype)shared;
/// init
+ (void)setup;

/// Suspend when background
+ (void)suspend;

/// resume when foreground
+ (void)resume;

@end

NS_ASSUME_NONNULL_END
