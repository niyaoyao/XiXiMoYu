//
//  NYGLTextureLoader.h
//  Live2DSDK
//
//  Created by niyao on 4/5/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NYGLTextureLoader : NSObject

- (instancetype)initWithImagePath:(NSString *)imagePath;

- (void)renderGLTexture;
@end

NS_ASSUME_NONNULL_END
