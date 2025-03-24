//
//  NYLDModelManager.h
//  Live2DSDK
//
//  Created by niyao on 3/18/25.
//

#import <Foundation/Foundation.h>
#import "NYCommon.h"
NS_ASSUME_NONNULL_BEGIN

/**
 * Live2D Model Manager
 */
@interface NYLDModelManager : NSObject

@property (nonatomic, strong, readonly) NSBundle *modelBundle;
@property (nonatomic, assign, readonly) NSInteger sceneIndex;

+ (instancetype)shared;

+ (void)setup;

- (void)changeScene:(NSInteger)sceneIndex;


@end

NS_ASSUME_NONNULL_END
