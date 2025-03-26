//
//  NYLDCubismViewMatrix.h
//  Live2DSDK
//
//  Created by niyao on 3/27/25.
//

#import <Foundation/Foundation.h>
#import "NYLDCubismMatrix44.h"

NS_ASSUME_NONNULL_BEGIN

@interface NYLDCubismViewMatrix : NYLDCubismMatrix44
- (void)adjustTranslateX:(float)x y:(float)y;
- (void)adjustScaleWithCenterX:(float)cx centerY:(float)cy scale:(float)scale;
- (void)setScreenRectWithLeft:(float)left right:(float)right bottom:(float)bottom top:(float)top;
- (void)setMaxScreenRectWithLeft:(float)left right:(float)right bottom:(float)bottom top:(float)top;
- (void)setMaxScale:(float)maxScale;
- (void)setMinScale:(float)minScale;

- (float)maxScale;
- (float)minScale;
- (bool)isMaxScale;
- (bool)isMinScale;
- (float)screenLeft;
- (float)screenRight;
- (float)screenBottom;
- (float)screenTop;
- (float)maxLeft;
- (float)maxRight;
- (float)maxBottom;
- (float)maxTop;
@end

NS_ASSUME_NONNULL_END
