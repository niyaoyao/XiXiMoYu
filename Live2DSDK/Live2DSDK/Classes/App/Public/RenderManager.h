//
//  RenderManager.h
//  Live2DSDK
//
//  Created by NY on 2025/3/7.
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

@interface RenderManager : NSObject


- (BOOL)applicationDidFinishLaunching;

- (void)applicationDidEnterBackground;

- (void)applicationWillEnterForeground;

- (void)initializeCubism;

- (void)finishApplication;
@end

NS_ASSUME_NONNULL_END
