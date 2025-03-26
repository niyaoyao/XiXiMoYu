//
//  NYLDCubismMatrix44.h
//  Live2DSDK
//
//  Created by niyao on 3/26/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NYLDCubismMatrix44 : NSObject
/// Instance variable to store the transformation matrix (4x4)
@property (nonatomic, readonly) float *tr;

- (instancetype)init;
- (void)dealloc;

/// Class method to multiply two matrices and store the result in dst
+ (void)multiplyMatrixA:(float *)a matrixB:(float *)b destination:(float *)dst;

/// Sets the identity matrix
- (void)loadIdentity;

/// Returns the matrix as an array of floating-point numbers
- (float *)getArray;

/// Sets the matrix with the provided 4x4 matrix (16 floats)
- (void)setMatrix:(float *)tr;

/// Get scaling factors
- (float)getScaleX;
- (float)getScaleY;

/// Get translation values
- (float)getTranslateX;
- (float)getTranslateY;

/// Transform coordinates
- (float)transformX:(float)src;
- (float)transformY:(float)src;

/// Inverse transform coordinates
- (float)invertTransformX:(float)src;
- (float)invertTransformY:(float)src;

/// Translation methods
- (void)translateRelativeX:(float)x y:(float)y;
- (void)translateX:(float)x y:(float)y;
- (void)translateX:(float)x;
- (void)translateY:(float)y;

/// Scaling methods
- (void)scaleRelativeX:(float)x y:(float)y;
- (void)scaleX:(float)x y:(float)y;

/// Multiply current matrix by another matrix
- (void)multiplyByMatrix:(NYLDCubismMatrix44 *)m;
@end

NS_ASSUME_NONNULL_END
