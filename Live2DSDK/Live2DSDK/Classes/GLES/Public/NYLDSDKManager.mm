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

#import <CubismMatrix44.hpp>
#import "LAppTextureManager.h"
#import "NYLDModelManager.h"
#import "NYLDRenderStageVC.h"
@interface NYLDSDKManager () {
    LAppAllocator _cubismAllocator; // Cubism SDK Allocator
    Csm::CubismFramework::Option _cubismOption;
}

@property (nonatomic, assign) NSInteger sceneIndex;


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
    self.stageVC = [[NYLDRenderStageVC alloc] initWithNibName:nil bundle:nil];
    [self.stageVC viewDidLoad];
    [self initializeCubism];
    [NYLDModelManager setup];
}

- (void)suspend {
    [NYLDModelManager shared].textureManager = [[LAppTextureManager alloc] init];

    [[NYLDModelManager shared] changeScene: self.sceneIndex];
}

- (void)resume {
    [NYLDModelManager shared].textureManager = nil;

    self.sceneIndex = [[NYLDModelManager shared] sceneIndex];
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
