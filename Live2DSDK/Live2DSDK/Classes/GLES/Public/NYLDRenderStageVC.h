//
//  NYLDRenderStageVC.h
//  Live2DSDK
//
//  Created by niyao on 3/26/25.
//

#import <GLKit/GLKit.h>
#import "NYCommon.h"



NS_ASSUME_NONNULL_BEGIN

@interface NYLDRenderStageVC : GLKViewController <GLKViewDelegate>

@property (nonatomic, assign) bool mOpenGLRun;
@property (nonatomic) GLuint vertexBufferId;
@property (nonatomic) GLuint fragmentBufferId;
@property (nonatomic) GLuint programId;

@property (nonatomic) bool anotherTarget;

@property (nonatomic) float spriteColorR;
@property (nonatomic) float spriteColorG;
@property (nonatomic) float spriteColorB;
@property (nonatomic) float spriteColorA;
@property (nonatomic) float clearColorR;
@property (nonatomic) float clearColorG;
@property (nonatomic) float clearColorB;
@property (nonatomic) float clearColorA;
@property (nonatomic) NYLDSelectTarget renderTarget;

/**
 * @brief 解放処理
 */
- (void)dealloc;

/**
 * @brief 解放する。
 */
- (void)releaseView;

/**
 * @brief 画像の初期化を行う。
 */
- (void)initializeSprite;

/**
 * @brief X座標をView座標に変換する。
 *
 * @param[in]       deviceX            デバイスX座標
 */
- (float)transformViewX:(float)deviceX;

/**
 * @brief Y座標をView座標に変換する。
 *
 * @param[in]       deviceY            デバイスY座標
 */
- (float)transformViewY:(float)deviceY;

/**
 * @brief X座標をScreen座標に変換する。
 *
 * @param[in]       deviceX            デバイスX座標
 */
- (float)transformScreenX:(float)deviceX;

/**
 * @brief Y座標をScreen座標に変換する。
 *
 * @param[in]       deviceY            デバイスY座標
 */
- (float)transformScreenY:(float)deviceY;

/**
 * @brief   モデル1体を描画する直前にコールされる
 */
//- (void)PreModelDraw:(LAppModel&) refModel;
//
///**
// * @brief   モデル1体を描画した直後にコールされる
// */
//- (void)PostModelDraw:(LAppModel&) refModel;

/**
 * @brief   別レンダリングターゲットにモデルを描画するサンプルで
 *           描画時のαを決定する
 */
- (float)GetSpriteAlpha:(int)assign;

/**
 * @brief レンダリング先を切り替える
 */
- (void)SwitchRenderingTarget:(NYLDSelectTarget) targetType;

/**
 * @brief レンダリング先をデフォルト以外に切り替えた際の背景クリア色設定
 * @param[in]   r   赤(0.0~1.0)
 * @param[in]   g   緑(0.0~1.0)
 * @param[in]   b   青(0.0~1.0)
 */
- (void)SetRenderTargetClearColor:(float)r g:(float)g b:(float)b;

@end

NS_ASSUME_NONNULL_END
