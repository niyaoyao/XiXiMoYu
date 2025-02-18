//
//  DREmotionModelController.m
//  DREmotionKit
//
//  Created by niyao on 11/1/17.
//  Copyright © 2017 dourui. All rights reserved.
//

#import "DREmotionModelRender.h"
#include "Live2D.h"
#include "Live2DModelOpenGL.h"
#include "UtSystem.h"
#include "DrawProfileCocos2D.h"
#include "Live2DMotion.h"
#include "MotionQueueManager.h"
#import "DREmotionKit-Bridging-Header.h"

#include <OpenGLES/ES2/gl.h>

#if DEBUG
#define DRLog(...)  NSLog(@"%s \n%@", __PRETTY_FUNCTION__, [NSString stringWithFormat:__VA_ARGS__]);
#else
#define DRLog(...)
#endif

using namespace live2d;

static DREmotionModelRender *manager = nil;
@interface DREmotionModelRender () <GLKViewDelegate>

@property (nonatomic, strong) EAGLContext *context;
@property (nonatomic, strong) GLKView *view;
@property (nonatomic, strong) DREmotionModelPackage *package;

@property (nonatomic, strong) GLKBaseEffect* mEffect;
@property (nonatomic, assign) int mCount;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) BOOL isRefreshing;

@end

@implementation DREmotionModelRender {
    live2d::Live2DModelOpenGL *live2DModel;
    live2d::Live2DModelOpenGL *live2DModel2;
    live2d::Live2DMotion *motion;
    live2d::MotionQueueManager *motionManager;

    GLuint vertexBufferObject;  /**< position, color.... */
    GLuint elementBufferObject; /**< index */
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        _modelScale = 2.0;
        [self initLive2d];
    }
    return self;
}

- (void)dealloc {
#ifdef DEBUG
    printf("===== DREmotionModelRender dealloc ======\n");
#endif
    [self destroyLive2d];
}

#pragma mark - OpenGLES
- (void)setupGL {
    [EAGLContext setCurrentContext:self.context];
}

- (void)tearDownGL {
    [EAGLContext setCurrentContext:nil];
    self.view = nil;
    self.context = nil;
    [self deleteBuffers];
}

- (void)deleteBuffers {
    if (vertexBufferObject != 0) {
        glDeleteBuffers(1, &vertexBufferObject);
        DRLog(@"Prepare to delete buffer: %d", vertexBufferObject);
    }
    if (elementBufferObject != 0) {
        glDeleteBuffers(1, &elementBufferObject);
        DRLog(@"Prepare to delete buffer: %d", elementBufferObject);
    }
}

#pragma mark - Handle Model
- (void)initLive2d {
    [self initialize];
}

- (void)initialize {
    live2d::Live2D::init();
    
    self.view.context = self.context;
    self.view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    self.view.delegate = self;
    [self setupGL];
    
    //纹理贴图
    NSString *rootPath = [[NSBundle mainBundle] pathForResource:@"VideoAssets" ofType:@"bundle"];
    NSString *dirPath = [rootPath stringByAppendingPathComponent:@"background_images"];
    NSArray *urls = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dirPath error:nil];
    NSString *filePath = [dirPath stringByAppendingPathComponent: urls[0]];
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@(1), GLKTextureLoaderOriginBottomLeft, nil];//GLKTextureLoaderOriginBottomLeft 纹理坐标系是相反的
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfFile:filePath options:options error:nil];
    //着色器
    self.mEffect = [[GLKBaseEffect alloc] init];
    self.mEffect.texture2d0.enabled = GL_TRUE;
    self.mEffect.texture2d0.name = textureInfo.name;

}

- (void)setupModel:(DREmotionModelPackage *)modelPackage {
    if (live2DModel) {
        delete live2DModel; // 若是多人聊天那么需要，遍历 model 数组逐个 delete 释放内存
        live2DModel = NULL;
    }
    live2DModel = live2d::Live2DModelOpenGL::loadModel(modelPackage.modelURL.path.UTF8String);
    
    [modelPackage.textureURLs enumerateObjectsUsingBlock:^(NSURL * _Nonnull url, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *path = url.path;
        NSDictionary *options = @{ GLKTextureLoaderApplyPremultiplication: @(NO),
                                   GLKTextureLoaderGenerateMipmaps: @(YES) };
        GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfFile: path
                                                                          options: options
                                                                            error: nil];
        int glTexNo = textureInfo.name;
        live2DModel->setTexture((int)idx, glTexNo);
    }];
    
    live2DModel -> setPartsOpacity(@"PARTS_01_ARM_L_B_001".UTF8String, 1);
    live2DModel -> setPartsOpacity(@"PARTS_01_ARM_R_B_001".UTF8String, 1);
    
    if (motion) {
        delete motion;
    }
//    motion = live2d::Live2DMotion::loadMotion(modelPackage.motionURLs[0].path.UTF8String);
//    motion -> setFadeIn(1000);
//    motion -> setFadeOut(1000);
//    motion -> setLoop(true);
//    if (motionManager) {
//        delete motionManager;
//    }
//    motionManager = new live2d::MotionQueueManager();
}

- (void)setupSecondModel:(DREmotionModelPackage *)modelPackage {
    live2DModel2 = live2d::Live2DModelOpenGL::loadModel(modelPackage.modelURL.path.UTF8String);
    
    [modelPackage.textureURLs enumerateObjectsUsingBlock:^(NSURL * _Nonnull url, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *path = url.path;
        NSDictionary *options = @{ GLKTextureLoaderApplyPremultiplication: @(NO),
                                   GLKTextureLoaderGenerateMipmaps: @(YES) };
        GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfFile: path
                                                                          options: options
                                                                            error: nil];
        int glTexNo = textureInfo.name;
        live2DModel2->setTexture((int)idx, glTexNo);
    }];

    live2DModel2 -> setPartsOpacity(@"PARTS_01_ARM_L_B_001".UTF8String, 0);
    live2DModel2 -> setPartsOpacity(@"PARTS_01_ARM_R_B_001".UTF8String, 0);
}

- (void)destroyLive2d {
    [self tearDownGL];
    if (live2DModel) {
        delete live2DModel;
    }
    
    if (live2DModel2) {
        delete live2DModel2;
    }
    
    if (motion) {
        delete motion;
    }
    
    if (motionManager) {
        delete motionManager;
    }
    
    live2d::Live2D::dispose();
}

#pragma mark - GLKViewDelegate
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    CGFloat width = self.viewWidth;
    CGFloat height = self.viewHeight;
    
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT); // GPU 的纹理没有加载完成会出现黑影，此时调用 glClear 会导致 EXC_BAD_ACCESS
    
    if (self.showBackgroundImage) {
        [self renderBackgroundImage];
    }
    
    CGSize screen = CGSizeMake(width, height);
    
    CGFloat scale = self.modelScale;
    if (live2DModel != NULL) {
        float scx = scale / live2DModel->getCanvasWidth();
        float scy = -scale / live2DModel->getCanvasWidth() *(screen.width/screen.height);
        float x = -1.0;
        float y = 1.0;
        float matrix []= {
            scx , 0 , 0 , 0 ,
            0 , scy ,0 , 0 ,
            0 , 0 , 1 , 0 ,
            x , y , 0 , 1
        } ;
        
        live2DModel -> setMatrix(matrix);
        if (motionManager) {
            if (motionManager->isFinished()) {
                //开始动作播放只进行一次，需要判断
                motionManager->startMotion(motion, false);
            }
            motionManager->updateParam(live2DModel);//更新動作
        }
    }
    
    
    
    
    if (self.refreshAction != nil) {
        self.refreshAction();
    }
    
    for (int i = 0; i < self.refreshActionArray.count; i++) {
        if ([self.refreshActionArray objectAtIndex:i]) {
            ((DREmotionRefreshAction)[self.refreshActionArray objectAtIndex:i])();
        }
        
    }
    
    if (live2DModel != NULL) {
        live2DModel->update();
    }
    if (self.showBackgroundImage) {
        DrawProfileCocos2D::preDraw();
    }
    
    if (live2DModel != NULL) {
        live2DModel->draw();
    }
    if (self.showBackgroundImage) {
        DrawProfileCocos2D::postDraw();
    }


    if (live2DModel2 != NULL) {
        float scx2 = 1 / live2DModel2->getCanvasWidth() ;
        float scy2 = -1 / live2DModel2->getCanvasWidth() *(screen.width/screen.height);
        float x2 = -0;
        float y2 = 0;
        float matrix2 []= {
            scx2 , 0 , 0 , 0 ,
            0 , scy2 ,0 , 0 ,
            0 , 0 , 1 , 0 ,
            x2 , y2 , 0 , 1
        } ;
        
        live2DModel2->setMatrix(matrix2) ;
        
        live2DModel2->update();
        live2DModel2->draw();
    }
    
}

- (void)renderBackgroundImage {
    //顶点数据，前三个是顶点坐标，后面两个是纹理坐标
    GLfloat squareVertexData[] =
    {
        1, -1, 0.0f,    1.0f, 0.0f, //右下
        -1, 1, 0.0f,    0.0f, 1.0f, //左上
        -1, -1, 0.0f,   0.0f, 0.0f, //左下
        1, 1, -0.0f,    1.0f, 1.0f, //右上
    };
    
    //顶点索引
    GLuint indices[] =
    {
        0, 1, 2,
        1, 3, 0
    };
    self.mCount = sizeof(indices) / sizeof(GLuint);
    
    [self deleteBuffers];
    
    //顶点数据缓存
    glGenBuffers(1, &vertexBufferObject);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBufferObject);
    glBufferData(GL_ARRAY_BUFFER, sizeof(squareVertexData), squareVertexData, GL_STATIC_DRAW);
    
    glGenBuffers(1, &elementBufferObject);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, elementBufferObject);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition); //顶点数据缓存
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 0);
    
    
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0); //纹理
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 3);
    
    
    //启动着色器
    [self.mEffect prepareToDraw];
    glDrawElements(GL_TRIANGLES, self.mCount, GL_UNSIGNED_INT, 0);

}

#pragma mark - Private
- (void)setupTimer {
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    self.displayLink.paused = NO;
}

- (void)setModelPose:(DRModelPoseType)poseType value:(double)value weight:(float)weight {
    NSString *poseString = DRModelPoseTitles[poseType];
    if (live2DModel != NULL) {
        live2DModel -> setParamFloat(poseString.UTF8String, value, weight);
    }
}

- (void)setModelPose:(DRModelPoseType)poseType
               value:(double)value
              weight:(float)weight
               model:(live2d::Live2DModelOpenGL *)model {
    NSString *poseString = DRModelPoseTitles[poseType];
    model -> setParamFloat(poseString.UTF8String, value, weight);
}

- (void)refreshModel {
    [self.view display];
}

- (void)startRefreshModel {
    [self setupTimer];
}
    
- (void)stopRefreshModel {
    if (self.isRefreshing) {
        [self.displayLink removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        [self.displayLink invalidate];
        self.displayLink = nil;
        self.isRefreshing = NO;
    }
}
    
#pragma mark - Public
- (signed long long)getUserTimeMSec {
    return live2d::UtSystem::getUserTimeMSec();
}

- (void)updateModel:(DREmotionModelPackage *)modelPackage {
    [self setupModel:modelPackage];
}

- (void)updateBackgroundImagePath:(NSString *)filePath {
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             @(1),
                             GLKTextureLoaderOriginBottomLeft, nil];
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfFile:filePath
                                                                      options:options error:nil];
    self.mEffect.texture2d0.name = textureInfo.name;
}
    
- (void)setModelViewFrame:(CGRect)frame {
    self.view.frame = CGRectMake(0, 0, self.viewWidth, self.viewHeight); //frame;
}

- (void)setModelPose:(DRModelPoseType)poseType number:(NSNumber *)number {
    [self setModelPose:poseType value:number.doubleValue];
}

- (void)setModelPose:(DRModelPoseType)poseType value:(double)value {
    [self setModelPose:poseType value:value  weight:0.75f];
}

- (void)setSecondModelPose:(DRModelPoseType)poseType value:(double)value {
    if (live2DModel2 != NULL) {
        [self setModelPose:poseType value:value weight:0.75f model:live2DModel2];
    }
}

- (void)enable {
    [self startRefreshModel];
    self.isRefreshing = YES;
}

- (void)disable {
    [self stopRefreshModel];
}

- (void)appendRefreshAction:(DREmotionRefreshAction)action {
    [self.refreshActionArray addObject:[action copy]];
}

#pragma mark - Getter
- (EAGLContext *)context {
    if (!_context) {
        _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    }
    return _context;
}

- (GLKView *)view {
    if (!_view) {
        _view = [[GLKView alloc] init];
    }
    return _view;
}

- (CGFloat)viewWidth {
    return _viewWidth > 0 ? : UIScreen.mainScreen.bounds.size.width;
}

- (CGFloat)viewHeight {
    return _viewHeight > 0 ? : UIScreen.mainScreen.bounds.size.height;
}

- (NSMutableArray<DREmotionRefreshAction> *)refreshActionArray {
    if (!_refreshActionArray) {
        _refreshActionArray = [[NSMutableArray alloc] init];
    }
    return _refreshActionArray;
}

- (CADisplayLink *)displayLink {
    if (!_displayLink) {
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(refreshModel)];
        if (@available(iOS 10.0, *)) {
            _displayLink.preferredFramesPerSecond = FRAME_PER_SECOND;
        } else {
            // Fallback on earlier versions
        }

    }
    return _displayLink;
}

@end
