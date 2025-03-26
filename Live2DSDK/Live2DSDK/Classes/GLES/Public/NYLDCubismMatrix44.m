//
//  NYLDCubismMatrix44.m
//  Live2DSDK
//
//  Created by niyao on 3/26/25.
//

#import "NYLDCubismMatrix44.h"

@implementation NYLDCubismMatrix44

- (instancetype)init {
    self = [super init];
    if (self) {
        _tr  = (float *)malloc(16 * sizeof(float));
        [self loadIdentity];
    }
    return self;
}

- (void)dealloc {
    // No explicit cleanup needed in Objective-C with ARC
}

+ (void)multiplyMatrixA:(float *)a matrixB:(float *)b destination:(float *)dst {
    float c[16] = {0.0f, 0.0f, 0.0f, 0.0f,
                   0.0f, 0.0f, 0.0f, 0.0f,
                   0.0f, 0.0f, 0.0f, 0.0f,
                   0.0f, 0.0f, 0.0f, 0.0f};
    int n = 4;

    for (int i = 0; i < n; ++i) {
        for (int j = 0; j < n; ++j) {
            for (int k = 0; k < n; ++k) {
                c[j + i * 4] += a[k + i * 4] * b[j + k * 4];
            }
        }
    }

    for (int i = 0; i < 16; ++i) {
        dst[i] = c[i];
    }
}

- (void)loadIdentity {
    float c[16] = {1.0f, 0.0f, 0.0f, 0.0f,
                   0.0f, 1.0f, 0.0f, 0.0f,
                   0.0f, 0.0f, 1.0f, 0.0f,
                   0.0f, 0.0f, 0.0f, 1.0f};
    [self setMatrix:c];
}

- (float *)getArray {
    return _tr;
}

- (void)setMatrix:(float *)tr {
    for (int i = 0; i < 16; ++i) {
        _tr[i] = tr[i];
    }
}

- (float)getScaleX {
    return _tr[0];
}

- (float)getScaleY {
    return _tr[5];
}

- (float)getTranslateX {
    return _tr[12];
}

- (float)getTranslateY {
    return _tr[13];
}

- (float)transformX:(float)src {
    return _tr[0] * src + _tr[12];
}

- (float)transformY:(float)src {
    return _tr[5] * src + _tr[13];
}

- (float)invertTransformX:(float)src {
    return (src - _tr[12]) / _tr[0];
}

- (float)invertTransformY:(float)src {
    return (src - _tr[13]) / _tr[5];
}

- (void)translateRelativeX:(float)x y:(float)y {
    float tr1[16] = {
        1.0f, 0.0f, 0.0f, 0.0f,
        0.0f, 1.0f, 0.0f, 0.0f,
        0.0f, 0.0f, 1.0f, 0.0f,
        x,    y,    0.0f, 1.0f
        };

    [NYLDCubismMatrix44 multiplyMatrixA:tr1 matrixB:_tr destination:_tr];
}

- (void)translateX:(float)x y:(float)y {
    _tr[12] = x;
    _tr[13] = y;
}

- (void)translateX:(float)x {
    _tr[12] = x;
}

- (void)translateY:(float)y {
    _tr[13] = y;
}

- (void)scaleRelativeX:(float)x y:(float)y {
    float tr1[16] = {x,    0.0f, 0.0f, 0.0f,
                     0.0f, y,    0.0f, 0.0f,
                     0.0f, 0.0f, 1.0f, 0.0f,
                     0.0f, 0.0f, 0.0f, 1.0f};
    
    [NYLDCubismMatrix44 multiplyMatrixA:tr1 matrixB:_tr destination:_tr];
}

- (void)scaleX:(float)x y:(float)y {
    _tr[0] = x;
    _tr[5] = y;
}

- (void)multiplyByMatrix:(NYLDCubismMatrix44 *)m {
    [NYLDCubismMatrix44 multiplyMatrixA:[m getArray] matrixB:_tr destination:_tr];
}
    
@end
