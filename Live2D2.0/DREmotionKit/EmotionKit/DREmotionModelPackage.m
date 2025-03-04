//
//  DREmotionModelPackage.m
//  doutu
//
//  Created by Zhang Hang on 2017/12/4.
//  Copyright © 2017年 dourui. All rights reserved.
//

#import "DREmotionModelPackage.h"

@interface DREmotionModelPackage()

@property (nonatomic, readwrite) NSUInteger packageId;
@property (nonatomic, readwrite) NSUInteger version;
@property (nonatomic, readwrite, nonnull) NSString *name;
@property (nonatomic, readwrite, nonnull) NSURL *rootURL;
@property (nonatomic, readwrite, nonnull) NSURL *avatarURL;
@property (nonatomic, readwrite, nonnull) NSURL *modelURL;
@property (nonatomic, readwrite, nonnull) NSArray<NSURL *> *textureURLs;
@property (nonatomic, readwrite, nonnull) NSArray<NSURL *> *avatarURLs;
@property (nonatomic, readwrite, nonnull) NSArray<NSURL *> *motionURLs;

@end

@implementation DREmotionModelPackage

- (instancetype _Nonnull)initWithPackageId:(NSUInteger)packageId
                                   version:(NSUInteger)version
                                      name:(NSString *)name rootURL:(NSURL *)rootURL
                                 avatarURL:(NSURL *)avatarURL
                                  modelURL:(NSURL *)modelURL
                               textureURLs:(NSArray<NSURL *> *)textureURLs
                                avatarURLs:(NSArray<NSURL *> *)avatarURLs
                                motionURLs:(NSArray<NSURL *> *)motionURLs {
    self = [super init];
    self.packageId = packageId;
    self.version = version;
    self.name = [name copy];
    self.rootURL = [rootURL copy];
    self.avatarURL = [avatarURL copy];
    self.modelURL = [modelURL copy];
    self.textureURLs = [textureURLs copy];
    self.avatarURLs = [avatarURLs copy];
    self.motionURLs = [motionURLs copy];
    return self;
}
@end
