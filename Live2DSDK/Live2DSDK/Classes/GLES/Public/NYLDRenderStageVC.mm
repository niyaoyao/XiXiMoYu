//
//  NYLDRenderStageVC.m
//  Live2DSDK
//
//  Created by niyao on 3/26/25.
//

#import "NYLDRenderStageVC.h"
#import <math.h>
#import <string>
#import <QuartzCore/QuartzCore.h>
#import "CubismFramework.hpp"
#import <CubismMatrix44.hpp>
#import <CubismViewMatrix.hpp>
#import <GLKit/GLKit.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "NYLDModelManager.h"
#import "LAppSprite.h"
#import "TouchManager.h"
#import "LAppDefine.h"
#import "NYLDCubismMatrix44.h"
#import "LAppTextureManager.h"
#import "LAppPal.h"
#import "NYLDSDKManager.h"
#include "CubismOffscreenSurface_OpenGLES2.hpp"
#import "NYLDCubismMatrix44.h"
#import "NYLDCubismViewMatrix.h"
#import "LAppModel.h"

#define BUFFER_OFFSET(bytes) ((GLubyte *)NULL + (bytes))

using namespace std;
using namespace LAppDefine;


@interface NYLDRenderStageVC () {
    Csm::Rendering::CubismOffscreenSurface_OpenGLES2 renderBuffer;
}

@property (nonatomic, strong) LAppSprite *back; //背景画像
@property (nonatomic, strong) LAppSprite *gear; //歯車画像
@property (nonatomic, strong) LAppSprite *power; //電源画像
@property (nonatomic, strong) LAppSprite *renderSprite; //レンダリングターゲット描画用
@property (nonatomic, strong) TouchManager *touchManager; ///< タッチマネージャー
@property (nonatomic, strong) NYLDCubismMatrix44 *deviceToScreen;///< デバイスからスクリーンへの行列
@property (nonatomic, strong) NYLDCubismViewMatrix *viewMatrix;

@end

@implementation NYLDRenderStageVC
@synthesize mOpenGLRun;

- (void)dealloc
{
    [self releaseView];
    [super dealloc];
}

- (void)releaseView
{
    renderBuffer.DestroyOffscreenSurface();

    _renderSprite = nil;
    _gear = nil;
    _back = nil;
    _power = nil;

    GLKView *view = (GLKView*)self.view;

    view = nil;
    _viewMatrix = nil;
    _deviceToScreen = nil;
    _touchManager = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    mOpenGLRun = true;
    NYLog(@"1");
    _anotherTarget = false;
    _spriteColorR = _spriteColorG = _spriteColorB = _spriteColorA = 1.0f;
    _clearColorR = _clearColorG = _clearColorB = 1.0f;
    _clearColorA = 0.0f;

    // タッチ関係のイベント管理
    _touchManager = [[TouchManager alloc]init];

    // デバイス座標からスクリーン座標に変換するための
    _deviceToScreen = [[NYLDCubismMatrix44 alloc] init];//new CubismMatrix44();

    // 画面の表示の拡大縮小や移動の変換を行う行列
    _viewMatrix = [[NYLDCubismViewMatrix alloc] init]; //new CubismViewMatrix();

    [self initializeScreen];

    [super viewDidLoad];
    GLKView *view = (GLKView*)self.view;

    // GL描画周期を60FPSに設定
    self.preferredFramesPerSecond = 60;

    // OpenGL ES2を指定
    view.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    // set context
    [EAGLContext setCurrentContext:view.context];

    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);


    glGenBuffers(1, &_vertexBufferId);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBufferId);

    glGenBuffers(1, &_fragmentBufferId);
    glBindBuffer(GL_ARRAY_BUFFER,  _fragmentBufferId);
    [self initializeSprite];
}

- (void)initializeScreen
{
    NYLog(@"2");
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    int width = screenRect.size.width;
    int height = screenRect.size.height;

    // 縦サイズを基準とする
    float ratio = static_cast<float>(width) / static_cast<float>(height);
    float left = -ratio;
    float right = ratio;
    float bottom = ViewLogicalLeft;
    float top = ViewLogicalRight;

    // デバイスに対応する画面の範囲。 Xの左端, Xの右端, Yの下端, Yの上端
    [_viewMatrix setScreenRectWithLeft:left right:right bottom:bottom top:top];
//    _viewMatrix->SetScreenRect(left, right, bottom, top);
//    _viewMatrix->Scale(ViewScale, ViewScale);
    [_viewMatrix scaleX:ViewScale y:ViewScale];
    [_deviceToScreen loadIdentity];
//    _deviceToScreen->LoadIdentity(); // サイズが変わった際などリセット必須
    if (width > height)
    {
      float screenW = fabsf(right - left);
//      _deviceToScreen->ScaleRelative(screenW / width, -screenW / width);
        [_deviceToScreen scaleRelativeX:screenW / width y:-screenW / width];
    }
    else
    {
      float screenH = fabsf(top - bottom);
//      _deviceToScreen->ScaleRelative(screenH / height, -screenH / height);
        [_deviceToScreen scaleRelativeX:screenH / height y:-screenH / height];
    }
//    _deviceToScreen->TranslateRelative(-width * 0.5f, -height * 0.5f);
    [_deviceToScreen translateRelativeX:-width * 0.5f y:-height * 0.5f];
    // 表示範囲の設定
    [_viewMatrix setMaxScale:ViewMaxScale];
    [_viewMatrix setMinScale:ViewMinScale];
//    _viewMatrix->SetMaxScale(ViewMaxScale); // 限界拡大率
//    _viewMatrix->SetMinScale(ViewMinScale); // 限界縮小率

    // 表示できる最大範囲
//    _viewMatrix->SetMaxScreenRect(
//                                  ViewLogicalMaxLeft,
//                                  ViewLogicalMaxRight,
//                                  ViewLogicalMaxBottom,
//                                  ViewLogicalMaxTop
//                                  );
    [_viewMatrix setMaxScreenRectWithLeft:ViewLogicalMaxLeft
                                    right:ViewLogicalMaxRight
                                   bottom:ViewLogicalMaxBottom
                                      top:ViewLogicalMaxTop];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    //時間更新
    LAppPal::UpdateTime();
    NYLog(@"4");
    NYLog(@"mOpenGLRun:%d", mOpenGLRun);
    if(mOpenGLRun)
    {
        // 画面クリア
        glClear(GL_COLOR_BUFFER_BIT);

        [_back render:_vertexBufferId fragmentBufferID:_fragmentBufferId];

        [_gear render:_vertexBufferId fragmentBufferID:_fragmentBufferId];

        [_power render:_vertexBufferId fragmentBufferID:_fragmentBufferId];

//        LAppLive2DManager* Live2DManager = [LAppLive2DManager getInstance];
//        [Live2DManager SetViewMatrix:_viewMatrix];
//        [Live2DManager onUpdate];
        
        NYLDModelManager *manager = [NYLDModelManager shared];
        [manager SetViewMatrix:_viewMatrix];
        [manager onUpdate];

        // 各モデルが持つ描画ターゲットをテクスチャとする場合はスプライトへの描画はここ
        if (_renderTarget == NYLDSelectTargetModelFrameBuffer && _renderSprite)
        {
            float uvVertex[] =
            {
                0.0f, 0.0f,
                1.0f, 0.0f,
                0.0f, 1.0f,
                1.0f, 1.0f,
            };
            int num = [manager GetModelNum];
            NYLog(@"GetModelNum: %d", num);
            for(csmUint32 i=0; i<num; i++)
            {
                float opacity = [manager getModelOpacityWithIndex:i];
                float a = i < 1 ? 1.0f : opacity; // 片方のみ不透明度を取得できるようにする
                [_renderSprite SetColor:1.0f g:1.0f b:1.0f a:a];

                if ([manager modelExistsWithIndex:i])
                {
                   
                    GLuint textureId = [manager modelTextureIdWithIndex:i];
                    [_renderSprite renderImmidiate:_vertexBufferId
                                  fragmentBufferID:_fragmentBufferId
                                         TextureId:textureId
                                           uvArray:uvVertex];
                }
            }
        }

        glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    }
}

- (void)initializeSprite
{
    NYLog(@"3");
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    int width = screenRect.size.width;
    int height = screenRect.size.height;

//    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    LAppTextureManager* textureManager = [NYLDModelManager shared].textureManager; //[delegate getTextureManager];
    const string resourcesPath = ResourcesPath;

    string imageName = BackImageName;
    TextureInfo* backgroundTexture = [textureManager createTextureFromPngFile:resourcesPath+imageName];
    float x = width * 0.5f;
    float y = height * 0.5f;
    float fWidth = 300.0f;
    float fHeight = 300.0f;
    fWidth = static_cast<float>(width );
    fHeight = static_cast<float>(height);
    _back = [[LAppSprite alloc] initWithMyVar:x Y:y Width:fWidth Height:fHeight TextureId:backgroundTexture->textureId];
    NYLog(@"backgroundTexture->textureId]: %d", backgroundTexture->textureId);
    imageName = GearImageName;
    TextureInfo* gearTexture = [textureManager createTextureFromPngFile:resourcesPath+imageName];
    x = static_cast<float>(gearTexture->width * 0.5f);
    y = static_cast<float>(gearTexture->height * 0.5f);
    fWidth = static_cast<float>(gearTexture->width);
    fHeight = static_cast<float>(gearTexture->height);
    _gear = [[LAppSprite alloc] initWithMyVar:x Y:y Width:fWidth Height:fHeight TextureId:gearTexture->textureId];
    NYLog(@"gearTexture->textureId]: %d", gearTexture->textureId);
    imageName = PowerImageName;
    TextureInfo* powerTexture = [textureManager createTextureFromPngFile:resourcesPath+imageName];
    x = static_cast<float>(width - powerTexture->width * 0.5f);
    y = static_cast<float>(powerTexture->height * 0.5f);
    fWidth = static_cast<float>(powerTexture->width);
    fHeight = static_cast<float>(powerTexture->height);
    _power = [[LAppSprite alloc] initWithMyVar:x Y:y Width:fWidth Height:fHeight TextureId:powerTexture->textureId];
    NYLog(@"powerTexture->textureId]: %d", powerTexture->textureId);
    x = static_cast<float>(width) * 0.5f;
    y = static_cast<float>(height) * 0.5f;
    fWidth = static_cast<float>(width*2);
    fHeight = static_cast<float>(height*2);
    _renderSprite = [[LAppSprite alloc] initWithMyVar:x Y:y Width:fWidth/2 Height:fHeight/2 TextureId:0];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.view];

    [_touchManager touchesBegan:point.x DeciveY:point.y];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.view];

    float viewX = [self transformViewX:[_touchManager getX]];
    float viewY = [self transformViewY:[_touchManager getY]];

    [_touchManager touchesMoved:point.x DeviceY:point.y];
//    [[LAppLive2DManager getInstance] onDrag:viewX floatY:viewY];
    [[NYLDModelManager shared] onDrag:viewX floatY:viewY];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    NYLog(@"%@", touch.view);

    CGPoint point = [touch locationInView:self.view];
    float pointY = [self transformTapY:point.y];

    // タッチ終了
//    LAppLive2DManager* live2DManager = [LAppLive2DManager getInstance];
    [[NYLDModelManager shared] onDrag:0.0f floatY:0.0f];
    {
        // シングルタップ
        float getX = [_touchManager getX];// 論理座標変換した座標を取得。
        float getY = [_touchManager getY]; // 論理座標変換した座標を取得。
        float x = [_deviceToScreen transformX:getX];//->TransformX(getX);
        float y = [_deviceToScreen transformY:getY];//->TransformY(getY);

        if (DebugTouchLogEnable)
        {
            LAppPal::PrintLogLn("[APP]touchesEnded x:%.2f y:%.2f", x, y);
        }
        [[NYLDModelManager shared] onTap:x floatY:y];

        // 歯車にタップしたか
        if ([_gear isHit:point.x PointY:pointY])
        {
            [[NYLDModelManager shared] nextScene];
        }

        // 電源ボタンにタップしたか
        if ([_power isHit:point.x PointY:pointY])
        {
//            AppDelegate *delegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
//            [delegate finishApplication];

        }
    }
}

- (float)transformViewX:(float)deviceX
{
    float screenX = [_deviceToScreen transformX:deviceX];//->TransformX(deviceX); // 論理座標変換した座標を取得。
    return [_viewMatrix invertTransformX:screenX];//->InvertTransformX(screenX); // 拡大、縮小、移動後の値。
}

- (float)transformViewY:(float)deviceY
{
    float screenY = [_deviceToScreen transformY:deviceY];//->TransformY(deviceY); // 論理座標変換した座標を取得。
    return [_viewMatrix invertTransformY:screenY];//->InvertTransformY(screenY); // 拡大、縮小、移動後の値。
}

- (float)transformScreenX:(float)deviceX
{
    return [_deviceToScreen transformX:deviceX]; //->TransformX(deviceX);
}

- (float)transformScreenY:(float)deviceY
{
    return [_deviceToScreen transformY:deviceY];//->TransformY(deviceY);
}

- (float)transformTapY:(float)deviceY
{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    int height = screenRect.size.height;
    return deviceY * -1 + height;
}

- (void)PreModelDraw:(LAppModel&)refModel
{
    NYLog(@"5");
    // 別のレンダリングターゲットへ向けて描画する場合の使用するフレームバッファ
    Csm::Rendering::CubismOffscreenSurface_OpenGLES2* useTarget = NULL;

    if (_renderTarget != NYLDSelectTargetNone)
    {// 別のレンダリングターゲットへ向けて描画する場合

        // 使用するターゲット
        useTarget = (_renderTarget == NYLDSelectTargetViewFrameBuffer) ? &renderBuffer : &refModel.GetRenderBuffer();

        if (!useTarget->IsValid())
        {// 描画ターゲット内部未作成の場合はここで作成
            CGRect screenRect = [[UIScreen mainScreen] nativeBounds];
            int width = screenRect.size.width;
            int height = screenRect.size.height;

            // モデル描画キャンバス
            useTarget->CreateOffscreenSurface(height, width);
        }

        // レンダリング開始
        useTarget->BeginDraw();
        useTarget->Clear(_clearColorR, _clearColorG, _clearColorB, _clearColorA); // 背景クリアカラー
    }
}

- (void)PostModelDraw:(LAppModel&)refModel
{
    NYLog(@"6");
    // 別のレンダリングターゲットへ向けて描画する場合の使用するフレームバッファ
    Csm::Rendering::CubismOffscreenSurface_OpenGLES2* useTarget = NULL;

    if (_renderTarget != NYLDSelectTargetNone)
    {// 別のレンダリングターゲットへ向けて描画する場合

        // 使用するターゲット
        useTarget = (_renderTarget == NYLDSelectTargetViewFrameBuffer) ? &renderBuffer : &refModel.GetRenderBuffer();

        // レンダリング終了
        useTarget->EndDraw();

        // LAppViewの持つフレームバッファを使うなら、スプライトへの描画はここ
        if (_renderTarget == NYLDSelectTargetViewFrameBuffer && _renderSprite)
        {
            float uvVertex[] =
            {
                0.0f, 0.0f,
                1.0f, 0.0f,
                0.0f, 1.0f,
                1.0f, 1.0f,
            };

            float a = [self GetSpriteAlpha:0];
            [_renderSprite SetColor:1.0f g:1.0f b:1.0f a:a];
            [_renderSprite renderImmidiate:_vertexBufferId fragmentBufferID:_fragmentBufferId TextureId:useTarget->GetColorBuffer() uvArray:uvVertex];
        }
    }
}

- (void)SwitchRenderingTarget:(NYLDSelectTarget)targetType
{
    _renderTarget = targetType;
}

- (void)SetRenderTargetClearColor:(float)r g:(float)g b:(float)b
{
    _clearColorR = r;
    _clearColorG = g;
    _clearColorB = b;
}

- (float)GetSpriteAlpha:(int)assign
{
    // assignの数値に応じて適当に決定
    float alpha = 0.25f + static_cast<float>(assign) * 0.5f; // サンプルとしてαに適当な差をつける
    if (alpha > 1.0f)
    {
        alpha = 1.0f;
    }
    if (alpha < 0.1f)
    {
        alpha = 0.1f;
    }

    return alpha;
}

@end
