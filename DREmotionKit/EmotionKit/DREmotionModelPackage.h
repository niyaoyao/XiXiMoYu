//
//  DREmotionModelPackage.h
//  doutu
//
//  Created by Zhang Hang on 2017/12/4.
//  Copyright © 2017年 dourui. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 表情模型（Live2D）包数据结构
 */
@interface DREmotionModelPackage : NSObject

@property (nonatomic, readonly) NSUInteger packageId; /**< main.js id */
@property (nonatomic, readonly) NSUInteger version;
@property (nonatomic, readonly, copy, nonnull) NSString *name;
@property (nonatomic, readonly, copy, nonnull) NSURL *rootURL;
@property (nonatomic, readonly, copy, nonnull) NSURL *avatarURL;
@property (nonatomic, readonly, copy, nonnull) NSURL *modelURL;
@property (nonatomic, readonly, copy, nonnull) NSArray<NSURL *> *textureURLs;
@property (nonatomic, readonly, copy, nonnull) NSArray<NSURL *> *avatarURLs;
@property (nonatomic, readonly, copy, nonnull) NSArray<NSURL *> *motionURLs;

- (instancetype _Nonnull)initWithPackageId:(NSUInteger)packageId
                                   version:(NSUInteger)version
                                      name:(NSString *_Nonnull)name
                                   rootURL:(NSURL *_Nonnull)rootURL
                                 avatarURL:(NSURL *_Nonnull)avatarURL
                                  modelURL:(NSURL *_Nonnull)modelURL
                               textureURLs:(NSArray<NSURL *> *_Nonnull)textureURLs
                                avatarURLs:(NSArray<NSURL *> *_Nonnull)avatarURLs
                                motionURLs:(NSArray<NSURL *> *_Nonnull)motionURLs;
@end
