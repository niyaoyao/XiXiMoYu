//
//  DREmotionModelController.h
//  DREmotionKit
//
//  Created by niyao on 11/1/17.
//  Copyright © 2017 dourui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "DREmotionModelPackage.h"

#define FRAME_PER_SECOND 60.0

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, DRModelPoseType) {
    DRModelPoseHeadAngleX = 0,              /**< 頭部左右旋轉 PARAM_ANGLE_X -30.0 ~ 30.0 */
    DRModelPoseHeadAngleY,                  /**< 上下點頭 PARAM_ANGLE_Y -30.0 ~ 30.0 */
    DRModelPoseHeadAngleZ,                  /**< 左右搖頭晃腦 PARAM_ANGLE_Z -30.0 ~ 30.0 */
    
    DRModelPoseEyeOpenLeft,                 /**< 左眼開啟大小程度 PARAM_EYE_L_OPEN 0.0 ~ 2.0 */
    DRModelPoseEyeOpenRight,                /**< 右眼開啟大小程度 PARAM_EYE_R_OPEN 0.0 ~ 2.0 */
    
    DRModelPoseEyeSmileLeft,                /**< 左眼微笑程度 PARAM_EYE_L_SMILE 0.0 ~ 1.0 */
    DRModelPoseEyeSmileRight,               /**< 右眼微笑程度 PARAM_EYE_R_SMILE 0.0 ~ 1.0 */
    
    DRModelPoseEyeForm,                     /**< 眼睛的樣子, -1.0 看起來比較兇, 1.0 看起來比較楚楚可憐 PARAM_EYE_FORM -1.0 ~ 1.0 */
    
    DRModelPoseEyeBallX,                    /**< 眼球看左看右 PARAM_EYE_BALL_X -1.0 ~ 1.0 */
    DRModelPoseEyeBallY,                    /**< 眼球看上看下 PARAM_EYE_BALL_Y -1.0 ~ 1.0 */
    
    DRModelPoseEyeBallForm,                 /**< 眼球大小 PARAM_EYE_BALL_FORM -1.0 ~ 0.0 */
    
    DRModelPoseBrowLeftY,                   /**< 左邊眉毛的高低 PARAM_BROW_L_Y  -1.0 ~ 1.0 */
    DRModelPoseBrowRightY,                  /**< 右邊眉毛的高低 PARAM_BROW_R_Y -1.0 ~ 1.0 */
    
    DRModelPoseBrowLeftX,                   /**< 左邊眉毛的前高後低, 或是後高前低 PARAM_BROW_L_X -1.0 ~ 1.0 */
    DRModelPoseBrowRightX,                  /**< 右邊眉毛的前高後低, 或是後高前低 PARAM_BROW_R_X -1.0 ~ 1.0 */
    
    DRModelPoseBrowLeftAngle,               /**< 左邊眉毛加強版的前高後低, 後高前低  PARAM_BROW_L_ANGLE -1.0 ~ 1.0 */
    DRModelPoseBrowRightAngle,              /**< 右邊眉毛加強版的前高後低, 後高前低 PARAM_BROW_R_ANGLE -1.0 ~ 1.0 */
    
    DRModelPoseBrowLeftForm,                /**< 左邊眉毛生氣或是高興 PARAM_BROW_L_FORM -1.0 ~ 1.0 */
    DRModelPoseBrowRightForm,               /**< 右邊眉毛生氣或是高興 PARAM_BROW_R_FORM -1.0 ~ 1.0 */
    
    
    DRModelPoseMouthForm,                   /**< 微笑或是凹凹嘴 PARAM_MOUTH_FORM -1.0 ~ 1.0 */
    DRModelPoseMouthOpenY,                  /**< 嘴巴打開或是關閉 PARAM_MOUTH_OPEN_Y 0.0 ~ 1.0 */
    
    DRModelPoseFaceShy,                     /**< 臉頰紅暈 PARAM_TERE 0.0 ~ 1.0 */
    
    DRModelPoseBodyAngleX,                  /**< 身體中心朝向的方向 PARAM_BODY_ANGLE_X -10.0 ~ 10.0 */
    DRModelPoseBodyAngleY,                  /**< 身體上下起伏 PARAM_BODY_ANGLE_Y -10.0 ~ 10.0 */
    DRModelPoseBodyAngleZ,                  /**< 身體左右搖擺 PARAM_BODY_ANGLE_Z -10.0 ~ 10.0 */
    
    DRModelPoseBreath,                      /**< 呼吸起伏 PARAM_BREATH 0.0 ~ 1.0 */
    
    DRModelPoseArmLeftA,                    /**< 左手動作(A 類型) PARAM_ARM_L_A  -1.0 ~ 1.0 */
    DRModelPoseArmRightA,                   /**< 右手動作(A 類型) PARAM_ARM_R_A -1.0 ~ 1.0 */
    DRModelPoseArmLeftB,                    /**< 左手動作(B 類型) PARAM_ARM_L_B -1.0 ~ 1.0 */
    DRModelPoseArmRightB,                   /**< 右手動作(B 類型) PARAM_ARM_R_B -1.0 ~ 1.0 */
    
    DRModelPoseHairFront,                        /**< 前发 PARAM_HAIR_FRONT -1.0 ~ 1.0 */
    DRModelPoseHairSide,                        /**< 发 PARAM_HAIR_SIDE -1.0 ~ 1.0 */
    DRModelPoseHairBack,                        /**< 后发 PARAM_HAIR_BACK -1.0 ~ 1.0 */
    DRModelPoseHairBackLeft,                        /**< 左后发 PARAM_HAIR_BACK_L -1.0 ~ 1.0 */
    DRModelPoseHairBackRight,                        /**< 右后发 PARAM_HAIR_BACK_R -1.0 ~ 1.0 */
    
    DRModelPoseHeadAngleX_3,              /**< 頭部左右旋轉 PARAM_ANGLE_X -30.0 ~ 30.0 */
    DRModelPoseHeadAngleY_3,                  /**< 上下點頭 PARAM_ANGLE_Y -30.0 ~ 30.0 */
    DRModelPoseHeadAngleZ_3,                  /**< 左右搖頭晃腦 PARAM_ANGLE_Z -30.0 ~ 30.0 */
    
    DRModelPoseEyeOpenLeft_3,                 /**< 左眼開啟大小程度 PARAM_EYE_L_OPEN 0.0 ~ 2.0 */
    DRModelPoseEyeOpenRight_3,                /**< 右眼開啟大小程度 PARAM_EYE_R_OPEN 0.0 ~ 2.0 */
    
    DRModelPoseEyeSmileLeft_3,                /**< 左眼微笑程度 PARAM_EYE_L_SMILE 0.0 ~ 1.0 */
    DRModelPoseEyeSmileRight_3,               /**< 右眼微笑程度 PARAM_EYE_R_SMILE 0.0 ~ 1.0 */
    
    DRModelPoseEyeForm_3,                     /**< 眼睛的樣子, -1.0 看起來比較兇, 1.0 看起來比較楚楚可憐 PARAM_EYE_FORM -1.0 ~ 1.0 */
    
    DRModelPoseEyeBallX_3,                    /**< 眼球看左看右 PARAM_EYE_BALL_X -1.0 ~ 1.0 */
    DRModelPoseEyeBallY_3,                    /**< 眼球看上看下 PARAM_EYE_BALL_Y -1.0 ~ 1.0 */
    
    DRModelPoseEyeBallForm_3,                 /**< 眼球大小 PARAM_EYE_BALL_FORM -1.0 ~ 0.0 */
    
    DRModelPoseBrowLeftY_3,                   /**< 左邊眉毛的高低 PARAM_BROW_L_Y  -1.0 ~ 1.0 */
    DRModelPoseBrowRightY_3,                  /**< 右邊眉毛的高低 PARAM_BROW_R_Y -1.0 ~ 1.0 */
    
    DRModelPoseBrowLeftX_3,                   /**< 左邊眉毛的前高後低, 或是後高前低 PARAM_BROW_L_X -1.0 ~ 1.0 */
    DRModelPoseBrowRightX_3,                  /**< 右邊眉毛的前高後低, 或是後高前低 PARAM_BROW_R_X -1.0 ~ 1.0 */
    
    DRModelPoseBrowLeftAngle_3,               /**< 左邊眉毛加強版的前高後低, 後高前低  PARAM_BROW_L_ANGLE -1.0 ~ 1.0 */
    DRModelPoseBrowRightAngle_3,              /**< 右邊眉毛加強版的前高後低, 後高前低 PARAM_BROW_R_ANGLE -1.0 ~ 1.0 */
    
    DRModelPoseBrowLeftForm_3,                /**< 左邊眉毛生氣或是高興 PARAM_BROW_L_FORM -1.0 ~ 1.0 */
    DRModelPoseBrowRightForm_3,               /**< 右邊眉毛生氣或是高興 PARAM_BROW_R_FORM -1.0 ~ 1.0 */
    
    
    DRModelPoseMouthForm_3,                   /**< 微笑或是凹凹嘴 PARAM_MOUTH_FORM -1.0 ~ 1.0 */
    DRModelPoseMouthOpenY_3,                  /**< 嘴巴打開或是關閉 PARAM_MOUTH_OPEN_Y 0.0 ~ 1.0 */
    
    DRModelPoseFaceShy_3,                     /**< 臉頰紅暈 PARAM_TERE 0.0 ~ 1.0 */
    
    DRModelPoseBodyAngleX_3,                  /**< 身體中心朝向的方向 PARAM_BODY_ANGLE_X -10.0 ~ 10.0 */
    DRModelPoseBodyAngleY_3,                  /**< 身體上下起伏 PARAM_BODY_ANGLE_Y -10.0 ~ 10.0 */
    DRModelPoseBodyAngleZ_3,                  /**< 身體左右搖擺 PARAM_BODY_ANGLE_Z -10.0 ~ 10.0 */
    
    DRModelPoseBreath_3,                      /**< 呼吸起伏 PARAM_BREATH 0.0 ~ 1.0 */
    
    DRModelPoseArmLeftA_3,                    /**< 左手動作(A 類型) PARAM_ARM_L_A  -1.0 ~ 1.0 */
    DRModelPoseArmRightA_3,                   /**< 右手動作(A 類型) PARAM_ARM_R_A -1.0 ~ 1.0 */
    DRModelPoseArmLeftB_3,                    /**< 左手動作(B 類型) PARAM_ARM_L_B -1.0 ~ 1.0 */
    DRModelPoseArmRightB_3,                   /**< 右手動作(B 類型) PARAM_ARM_R_B -1.0 ~ 1.0 */
    
    DRModelPoseHairFront_3,                        /**< 前发 PARAM_HAIR_FRONT -1.0 ~ 1.0 */
    DRModelPoseHairSide_3,                        /**< 发 PARAM_HAIR_SIDE -1.0 ~ 1.0 */
    DRModelPoseHairBack_3,                        /**< 后发 PARAM_HAIR_BACK -1.0 ~ 1.0 */
    DRModelPoseHairBackLeft_3,                        /**< 左后发 PARAM_HAIR_BACK_L -1.0 ~ 1.0 */
    DRModelPoseHairBackRight_3,                        /**< 右后发 PARAM_HAIR_BACK_R -1.0 ~ 1.0 */
    
};

static NSString * _Nonnull const DRModelPoseTitles[] = {
    [DRModelPoseHeadAngleX] = @"PARAM_ANGLE_X",
    [DRModelPoseHeadAngleY] = @"PARAM_ANGLE_Y",
    [DRModelPoseHeadAngleZ] = @"PARAM_ANGLE_Z",
    
    [DRModelPoseEyeOpenLeft] = @"PARAM_EYE_L_OPEN",
    [DRModelPoseEyeOpenRight] = @"PARAM_EYE_R_OPEN",
    
    [DRModelPoseEyeSmileLeft] = @"PARAM_EYE_L_SMILE",
    [DRModelPoseEyeSmileRight] = @"PARAM_EYE_R_SMILE",
    
    [DRModelPoseEyeForm] = @"PARAM_EYE_FORM",
    
    [DRModelPoseEyeBallX] = @"PARAM_EYE_BALL_X",
    [DRModelPoseEyeBallY] = @"PARAM_EYE_BALL_Y",
    
    [DRModelPoseEyeBallForm] = @"PARAM_EYE_BALL_FORM",
    
    [DRModelPoseBrowLeftY] = @"PARAM_BROW_L_Y",
    [DRModelPoseBrowRightY] = @"PARAM_BROW_R_Y",
    
    [DRModelPoseBrowLeftX] = @"PARAM_BROW_L_X",
    [DRModelPoseBrowRightX] = @"PARAM_BROW_R_X",
    
    [DRModelPoseBrowLeftAngle] = @"PARAM_BROW_L_ANGLE",
    [DRModelPoseBrowRightAngle] = @"PARAM_BROW_R_ANGLE",
    
    [DRModelPoseBrowLeftForm] = @"PARAM_BROW_L_FORM",
    [DRModelPoseBrowRightForm] = @"PARAM_BROW_R_FORM",
    
    [DRModelPoseMouthForm] = @"PARAM_MOUTH_FORM",
    [DRModelPoseMouthOpenY] = @"PARAM_MOUTH_OPEN_Y",
    
    [DRModelPoseFaceShy] = @"PARAM_TERE",
    
    [DRModelPoseBodyAngleX] = @"PARAM_BODY_ANGLE_X",
    [DRModelPoseBodyAngleY] = @"PARAM_BODY_ANGLE_Y",
    [DRModelPoseBodyAngleZ] = @"PARAM_BODY_ANGLE_Z",
    
    [DRModelPoseBreath] = @"PARAM_BREATH",
    
    [DRModelPoseArmLeftA] = @"PARAM_ARM_L_A",
    [DRModelPoseArmRightA] = @"PARAM_ARM_R_A",
    [DRModelPoseArmLeftB] = @"PARAM_ARM_L_B",
    [DRModelPoseArmRightB] = @"PARAM_ARM_R_B",
    
    [DRModelPoseHairFront] = @"PARAM_HAIR_FRONT",
    [DRModelPoseHairSide] = @"PARAM_HAIR_SIDE",
    [DRModelPoseHairBack] = @"PARAM_HAIR_BACK",
    [DRModelPoseHairBackLeft] = @"PARAM_HAIR_BACK_L",
    [DRModelPoseHairBackRight] = @"PARAM_HAIR_BACK_R",
    
    // 3.x
   
    [DRModelPoseHeadAngleX_3] = @"ParamAngleX",
    [DRModelPoseHeadAngleY_3] = @"ParamAngleY",
    [DRModelPoseHeadAngleZ_3] = @"ParamAngleZ",
    
    [DRModelPoseEyeOpenLeft_3] = @"ParamEyeLOpen",
    [DRModelPoseEyeOpenRight_3] = @"ParamEyeROpen",
    
    [DRModelPoseEyeSmileLeft_3] = @"ParamEyeLSmile",
    [DRModelPoseEyeSmileRight_3] = @"ParamEyeRSmile",
    
    [DRModelPoseEyeForm_3] = @"PARAM_EYE_FORM",
    
    [DRModelPoseEyeBallX_3] = @"ParamEyeBallX",
    [DRModelPoseEyeBallY_3] = @"ParamEyeBallY",
    
    [DRModelPoseEyeBallForm_3] = @"PARAM_EYE_BALL_FORM",
    
    [DRModelPoseBrowLeftY_3] = @"ParamBrowLY",
    [DRModelPoseBrowRightY_3] = @"ParamBrowRY",
    
    [DRModelPoseBrowLeftX_3] = @"PARAM_BROW_L_X",
    [DRModelPoseBrowRightX_3] = @"PARAM_BROW_R_X",
    
    [DRModelPoseBrowLeftAngle_3] = @"ParamBrowLAngle",
    [DRModelPoseBrowRightAngle_3] = @"ParamBrowRAngle",
    
    [DRModelPoseBrowLeftForm_3] = @"ParamBrowLForm",
    [DRModelPoseBrowRightForm_3] = @"ParamBrowRForm",
    
    [DRModelPoseMouthForm_3] = @"ParamMouthForm",
    [DRModelPoseMouthOpenY_3] = @"ParamMouthOpenY",
    
    [DRModelPoseFaceShy_3] = @"PARAM_TERE",
    
    [DRModelPoseBodyAngleX_3] = @"ParamBodyAngleX",
    [DRModelPoseBodyAngleY_3] = @"ParamBodyAngleY",
    [DRModelPoseBodyAngleZ_3] = @"ParamBodyAngleZ",
    
    [DRModelPoseBreath_3] = @"ParamBreath",
    
    [DRModelPoseArmLeftA_3] = @"PARAM_ARM_L_A",
    [DRModelPoseArmRightA_3] = @"PARAM_ARM_R_A",
    [DRModelPoseArmLeftB_3] = @"PARAM_ARM_L_B",
    [DRModelPoseArmRightB_3] = @"PARAM_ARM_R_B",
    
    [DRModelPoseHairFront_3] = @"ParamHairFront",
    [DRModelPoseHairSide_3] = @"PARAM_HAIR_SIDE",
    [DRModelPoseHairBack_3] = @"ParamHairBack",
    [DRModelPoseHairBackLeft_3] = @"PARAM_HAIR_BACK_L",
    [DRModelPoseHairBackRight_3] = @"PARAM_HAIR_BACK_R",
    
};

//static dispatch_queue_t emotionModelQueue() {
//    static dispatch_queue_t kEmotionModelQueue;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        kEmotionModelQueue = dispatch_queue_create("group.dourui.doutu.emotion.model.queue", DISPATCH_QUEUE_SERIAL);
//    });
//    dispatch_set_target_queue(kEmotionModelQueue, dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0));
//    return kEmotionModelQueue;
//}

typedef void (^DREmotionRefreshAction)();

/**
 表情模型（Live2D）渲染控制器
 */
@interface DREmotionModelRender : NSObject

@property (nonatomic, assign) CGFloat viewWidth;
@property (nonatomic, assign) CGFloat viewHeight;
@property (nonatomic, strong, readonly) GLKView *view;
@property (nonatomic, strong) NSMutableArray <NSString *> *stickerImagesUrl;
@property (nonatomic, copy  ) DREmotionRefreshAction refreshAction;
@property (nonatomic, strong) NSMutableArray <DREmotionRefreshAction > *refreshActionArray;
@property (nonatomic, assign) BOOL showBackgroundImage;
@property (nonatomic, assign) CGFloat modelScale;

- (void)updateModel:(DREmotionModelPackage *)modelPackage;
- (void)updateBackgroundImagePath:(NSString *)filePath;
- (void)setModelViewFrame:(CGRect)frame;
- (void)setModelPose:(DRModelPoseType)poseType number:(NSNumber *)number;
- (void)setModelPose:(DRModelPoseType)poseType value:(double)value;
- (void)setSecondModelPose:(DRModelPoseType)poseType value:(double)value;
- (void)enable;
- (void)disable;
- (signed long long)getUserTimeMSec;

/**
 Only for multiple voice chat

 @param modelPackage package
 */
- (void)setupSecondModel:(DREmotionModelPackage *)modelPackage;

- (void)appendRefreshAction:(DREmotionRefreshAction)action;
@end



NS_ASSUME_NONNULL_END

