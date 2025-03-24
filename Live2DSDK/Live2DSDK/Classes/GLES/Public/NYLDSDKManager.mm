//
//  NYCubismManager.m
//  Live2DSDK
//
//  Created by niyao on 3/18/25.
//

#import "NYLDSDKManager.h"

#import "LAppAllocator.h"
#import <iostream>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "LAppPal.h"
#import "LAppDefine.h"
#import "LAppLive2DManager.h"
#import "LAppTextureManager.h"
#import "NYLDModelManager.h"
@interface NYLDSDKManager () {
    LAppAllocator _cubismAllocator; // Cubism SDK Allocator
    Csm::CubismFramework::Option _cubismOption;
    Csm::csmInt32 sceneIndex;
}

@property (nonatomic, readwrite) LAppTextureManager *textureManager;

@end

@implementation NYLDSDKManager

+ (instancetype)shared {
    static NYLDSDKManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[NYLDSDKManager alloc] init];
        // Additional initialization code here, if needed
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}



- (void)initializeCubism {
    _cubismOption.LogFunction = LAppPal::PrintMessageLn;
    _cubismOption.LoggingLevel = LAppDefine::CubismLoggingLevel;
    Csm::CubismFramework::StartUp(&_cubismAllocator,&_cubismOption);
    Csm::CubismFramework::Initialize();
    Csm::CubismMatrix44 projection;
    LAppPal::UpdateTime();

}

- (void)setup {
    [self initializeCubism];
    [NYLDModelManager setup];
}

- (void)suspend {
    _textureManager = [[LAppTextureManager alloc] init];

    [[LAppLive2DManager getInstance] changeScene:sceneIndex];
}

- (void)resume {
    _textureManager = nil;

    sceneIndex = [[LAppLive2DManager getInstance] sceneIndex];
}


+ (void)setup {
    [[NYLDSDKManager shared] setup];
}


+ (void)suspend {
    [[NYLDSDKManager shared] suspend];
}

+ (void)resume {
    [[NYLDSDKManager shared] resume];
}

@end
