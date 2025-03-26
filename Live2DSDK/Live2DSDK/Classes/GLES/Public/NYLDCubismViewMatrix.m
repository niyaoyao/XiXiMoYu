//
//  NYLDCubismViewMatrix.m
//  Live2DSDK
//
//  Created by niyao on 3/27/25.
//

#import "NYLDCubismViewMatrix.h"

@interface NYLDCubismViewMatrix () {
    float _screenLeft;
    float _screenRight;
    float _screenTop;
    float _screenBottom;
    float _maxLeft;
    float _maxRight;
    float _maxTop;
    float _maxBottom;
    float _maxScale;
    float _minScale;
}


@end

@implementation NYLDCubismViewMatrix

- (instancetype)init {
    self = [super init];
    if (self) {
        _screenLeft = 0.0f;
        _screenRight = 0.0f;
        _screenTop = 0.0f;
        _screenBottom = 0.0f;
        _maxLeft = 0.0f;
        _maxRight = 0.0f;
        _maxTop = 0.0f;
        _maxBottom = 0.0f;
        _maxScale = 0.0f;
        _minScale = 0.0f;
    }
    return self;
}

- (float)maxScale {
    return _maxScale;
}

- (float)minScale {
    return _minScale;
}

- (float)screenLeft {
    return _screenLeft;
}

- (float)screenRight {
    return _screenRight;
}

- (float)screenBottom {
    return _screenBottom;
}

- (float)screenTop {
    return _screenTop;
}

- (float)maxLeft {
    return _maxLeft;
}

- (float)maxRight {
    return _maxRight;
}

- (float)maxBottom {
    return _maxBottom;
}

- (float)maxTop {
    return _maxTop;
}

- (bool)isMaxScale {
    return [self maxScale] >= _maxScale;
}

- (bool)isMinScale {
    return [self minScale] <= _minScale;
}

- (void)adjustTranslateX:(float)x y:(float)y {
    float *tr = [self tr];
    
    if (tr[0] * _maxLeft + (tr[12] + x) > _screenLeft) {
        x = _screenLeft - tr[0] * _maxLeft - tr[12];
    }
    
    if (tr[0] * _maxRight + (tr[12] + x) < _screenRight) {
        x = _screenRight - tr[0] * _maxRight - tr[12];
    }
    
    if (tr[5] * _maxTop + (tr[13] + y) < _screenTop) {
        y = _screenTop - tr[5] * _maxTop - tr[13];
    }
    
    if (tr[5] * _maxBottom + (tr[13] + y) > _screenBottom) {
        y = _screenBottom - tr[5] * _maxBottom - tr[13];
    }
    
    float tr1[] = {
        1.0f, 0.0f, 0.0f, 0.0f,
        0.0f, 1.0f, 0.0f, 0.0f,
        0.0f, 0.0f, 1.0f, 0.0f,
        x,    y,    0.0f, 1.0f
    };
    [NYLDCubismMatrix44 multiplyMatrixA:tr1 matrixB:tr destination:tr];
    
}

- (void)adjustScaleWithCenterX:(float)cx centerY:(float)cy scale:(float)scale {
    float *tr = self.tr;
    float targetScale = scale * tr[0];
    
    if (targetScale < _minScale) {
        if (tr[0] > 0.0f) {
            scale = _minScale / tr[0];
        }
    } else if (targetScale > _maxScale) {
        if (tr[0] > 0.0f) {
            scale = _maxScale / tr[0];
        }
    }
    
    float tr1[] = {
        1.0f, 0.0f, 0.0f, 0.0f,
        0.0f, 1.0f, 0.0f, 0.0f,
        0.0f, 0.0f, 1.0f, 0.0f,
        cx,   cy,   0.0f, 1.0f
    };
    
    float tr2[] = {
        scale, 0.0f, 0.0f, 0.0f,
        0.0f, scale, 0.0f, 0.0f,
        0.0f, 0.0f,  1.0f, 0.0f,
        0.0f, 0.0f,  0.0f, 1.0f
    };
    
    float tr3[] = {
        1.0f, 0.0f, 0.0f, 0.0f,
        0.0f, 1.0f, 0.0f, 0.0f,
        0.0f, 0.0f, 1.0f, 0.0f,
        -cx,  -cy,  0.0f, 1.0f
    };
    [NYLDCubismMatrix44 multiplyMatrixA:tr3 matrixB:tr destination:tr];
    [NYLDCubismMatrix44 multiplyMatrixA:tr2 matrixB:tr destination:tr];
    [NYLDCubismMatrix44 multiplyMatrixA:tr1 matrixB:tr destination:tr];

}

- (void)setScreenRectWithLeft:(float)left right:(float)right bottom:(float)bottom top:(float)top {
    _screenLeft = left;
    _screenRight = right;
    _screenTop = top;
    _screenBottom = bottom;
}

- (void)setMaxScreenRectWithLeft:(float)left right:(float)right bottom:(float)bottom top:(float)top {
    _maxLeft = left;
    _maxRight = right;
    _maxTop = top;
    _maxBottom = bottom;
}

- (void)setMaxScale:(float)maxScale {
    _maxScale = maxScale;
}

- (void)setMinScale:(float)minScale {
    _minScale = minScale;
}
@end
