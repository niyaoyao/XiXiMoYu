//
//  NYCubismManager.h
//  Live2DSDK
//
//  Created by niyao on 3/18/25.
//

#import <Foundation/Foundation.h>

@class LAppView;
@class LAppTextureManager;

NS_ASSUME_NONNULL_BEGIN

@interface NYLDSDKManager : NSObject

@property (nonatomic, readonly, getter=getTextureManager) LAppTextureManager *textureManager;

+ (instancetype)shared;
/// init
+ (void)initializeCubism;

/// Suspend when background
+ (void)suspend;

/// resume when foreground
+ (void)resume;

@end

NS_ASSUME_NONNULL_END
