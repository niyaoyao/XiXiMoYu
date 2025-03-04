//
//  DRMovieRecorder.h
//  doutu
//
//  Created by niyao on 6/12/18.
//  Copyright © 2018 dourui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
typedef void(^DRMovieRecorderCompletion)(NSURL * _Nullable url, NSError * _Nullable error);
typedef void(^DRMovieRecorderRequestRecordPermission)(BOOL granted);

typedef NS_ENUM(NSUInteger, DRMovieRecorderStatus) {
    DRMovieRecorderStatusUninitialized,
    DRMovieRecorderStatusInitialized,
    DRMovieRecorderStatusRecording,
    DRMovieRecorderStatusStop,
    DRMovieRecorderStatusFinishing,
    DRMovieRecorderStatusFinished,
    DRMovieRecorderStatusWriterInitialized,
    DRMovieRecorderStatusWriterFailed,
    DRMovieRecorderStatusError,
    DRMovieRecorderStatusUnknown,
};

#define kVideoTempFileName @"doutu_temp"
#define kVideoFileName  @"doutu"
#define kVideoThumbName  @"doutu_thumb"

typedef void (^VideoCompletionBlock)(NSURL * _Nullable savedURL, NSError * _Nullable error);
@protocol DRMovieRecorderDelegate;

@interface DRMovieRecorder : NSObject

@property (nonatomic, strong) NSString *videoFileName;
@property (nonatomic, assign) DRMovieRecorderStatus status;
@property (nonatomic, weak  ) UIView *recordView;
@property (nonatomic, copy  ) DRMovieRecorderRequestRecordPermission audioRequestCompletion;
@property (nonatomic, weak  ) id <DRMovieRecorderDelegate> delegate;

+ (NSURL *)videoRootURL;
+ (NSURL *)saveURLWithFileName:(NSString *)fileName extension:(NSString *)extension;
+ (void)removeFileAt:(NSURL *)fileURL;
+ (NSURL *)videoFileOutputURL;
+ (NSURL *)videoThumbURL;

- (BOOL)startRecording;
- (void)stopRecordingWithCompletion:(VideoCompletionBlock)completionBlock;
@end

@protocol DRMovieRecorderDelegate <NSObject>

@optional
- (void)writeBackgroundFrameInContext:(CGContextRef * _Nullable)contextRef;

- (void)recorderDidCaptureAudioData:(NSData * _Nullable)audioData;
- (BOOL)recorderShouldStartRecordAudio;
- (void)recorderDidStopRecordAudio;
@end
NS_ASSUME_NONNULL_END

