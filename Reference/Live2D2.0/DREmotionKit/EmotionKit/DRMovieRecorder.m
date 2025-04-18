//
//  DRMovieRecorder.m
//  doutu
//
//  Created by niyao on 6/12/18.
//  Copyright © 2018 dourui. All rights reserved.
//

#import "DRMovieRecorder.h"
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "DRAudioRecorder.h"

@interface DRMovieRecorder() <DRAudioRecorderDelegate>
@property (strong, nonatomic) AVAssetWriter *videoWriter;
@property (strong, nonatomic) AVAssetWriterInput *videoWriterInput;
@property (strong, nonatomic) AVAssetWriterInputPixelBufferAdaptor *avAdaptor;
@property (strong, nonatomic) CADisplayLink *displayLink;
@property (strong, nonatomic) NSDictionary *outputBufferPoolAuxAttributes;
@property (nonatomic) CFTimeInterval firstTimeStamp;
@property (strong, nonatomic) NSURL *videoURL;

// Audio
@property (nonatomic, strong) DRAudioRecorder *audioRecorder;
@property (nonatomic, strong) AVAudioSession *audioSession;
@property (nonatomic, strong) NSURL *audioSavedURL;
@property (nonatomic, assign) BOOL audioRequestGranted;

@end

@implementation DRMovieRecorder {
    dispatch_queue_t _render_queue;
    dispatch_queue_t _append_pixelBuffer_queue;
    dispatch_semaphore_t _frameRenderingSemaphore;
    dispatch_semaphore_t _pixelAppendSemaphore;
    
    CGSize _viewSize;
    CGFloat _scale;
    
    CGColorSpaceRef _rgbColorSpace;
    CVPixelBufferPoolRef _outputBufferPool;
    
//    dispatch_queue_t  _audioRecordQueue;
}

#pragma mark - initializers
- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initFileRootPath];
        _viewSize = [UIApplication sharedApplication].delegate.window.bounds.size;
        _scale = [UIScreen mainScreen].scale;
        // record half size resolution for retina iPads
        if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) && _scale > 1) {
            _scale = 1.0;
        }
        
        _append_pixelBuffer_queue = dispatch_queue_create("group.dourui.movie.append.queue", DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(_append_pixelBuffer_queue, dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0));
        _render_queue = dispatch_queue_create("group.dourui.movie.render.queue", DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(_render_queue, dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0));
        _frameRenderingSemaphore = dispatch_semaphore_create(1);
        _pixelAppendSemaphore = dispatch_semaphore_create(1);
       
        _status = DRMovieRecorderStatusInitialized;
        
        _audioSession = [AVAudioSession sharedInstance];
        __weak typeof (self) weakSelf = self;
        [_audioSession requestRecordPermission:^(BOOL granted) {
            weakSelf.audioRequestGranted = granted;
            if (weakSelf.audioRequestCompletion) {
                weakSelf.audioRequestCompletion(granted);
            }
        }];
    }
    return self;
}

- (void)dealloc {
#if DEBUG
    NSLog(@"====== DRMovieRecorder dealloc ======");
#endif
}

#pragma mark - Private
- (void)initFileRootPath {
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    
    NSError *error = nil;
    [defaultManager createDirectoryAtPath:[DRMovieRecorder videoRootURL].path withIntermediateDirectories:YES attributes:nil error:&error];
    if (error != nil) {
        @throw error;
    }
    
    [DRMovieRecorder clearCacheWithFilePath:[DRMovieRecorder videoRootURL].path];
}

-(void)setupWriter {
    _rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
    NSDictionary *bufferAttributes = @{(id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA),
                                       (id)kCVPixelBufferCGBitmapContextCompatibilityKey : @YES,
                                       (id)kCVPixelBufferWidthKey : @(_viewSize.width * _scale),
                                       (id)kCVPixelBufferHeightKey : @(_viewSize.height * _scale),
                                       (id)kCVPixelBufferBytesPerRowAlignmentKey : @(_viewSize.width * _scale * 4)
                                       };
    
    _outputBufferPool = NULL;
    CVPixelBufferPoolCreate(NULL, NULL, (__bridge CFDictionaryRef)(bufferAttributes), &_outputBufferPool);
    
    
    NSError *error = nil;
    self.videoURL = [DRMovieRecorder saveURLWithFileName:_videoFileName extension:@"mp4"];
    [DRMovieRecorder removeFileAt:self.videoURL];
    _videoWriter = [[AVAssetWriter alloc] initWithURL:self.videoURL ?: [self tempFileURL]
                                             fileType:AVFileTypeQuickTimeMovie
                                                error:&error];
    NSParameterAssert(_videoWriter);
    if (error != nil) {
        _status = DRMovieRecorderStatusError;
    }
    
    NSInteger pixelNumber = _viewSize.width * _viewSize.height * _scale;
    NSDictionary* videoCompression = @{AVVideoAverageBitRateKey: @(pixelNumber * 11.4)};
    
    NSDictionary* videoSettings = @{AVVideoCodecKey: AVVideoCodecH264,
                                    AVVideoWidthKey: [NSNumber numberWithInt:_viewSize.width*_scale],
                                    AVVideoHeightKey: [NSNumber numberWithInt:_viewSize.height*_scale],
                                    AVVideoCompressionPropertiesKey: videoCompression};
    
    _videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    NSParameterAssert(_videoWriterInput);
    if (error != nil) {
        _status = DRMovieRecorderStatusError;
    }
    
    _videoWriterInput.expectsMediaDataInRealTime = YES;
    _videoWriterInput.transform = [self videoTransformForDeviceOrientation];
    
    _avAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_videoWriterInput sourcePixelBufferAttributes:nil];
    
    
    if ([_videoWriter canAddInput:_videoWriterInput]) {
        [_videoWriter addInput:_videoWriterInput];
        
        BOOL startWritting = [_videoWriter startWriting];
        if (!startWritting) {
            _status = DRMovieRecorderStatusWriterFailed;
        }
        [_videoWriter startSessionAtSourceTime:CMTimeMake(0, 1000)];
        _status = DRMovieRecorderStatusWriterInitialized;
    } else {
        _status = DRMovieRecorderStatusWriterFailed;
    }
}

- (CGAffineTransform)videoTransformForDeviceOrientation {
    CGAffineTransform videoTransform;
    switch ([UIDevice currentDevice].orientation) {
        case UIDeviceOrientationLandscapeLeft:
            videoTransform = CGAffineTransformMakeRotation(-M_PI_2);
            break;
        case UIDeviceOrientationLandscapeRight:
            videoTransform = CGAffineTransformMakeRotation(M_PI_2);
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            videoTransform = CGAffineTransformMakeRotation(M_PI);
            break;
        default:
            videoTransform = CGAffineTransformIdentity;
    }
    return videoTransform;
}

- (void)completeRecordingSession:(VideoCompletionBlock)completionBlock {
    __weak typeof (self) weakSelf = self;
    dispatch_async(_render_queue, ^{
        dispatch_sync(_append_pixelBuffer_queue, ^{
            
            [_videoWriterInput markAsFinished];
            weakSelf.status = DRMovieRecorderStatusFinishing;
            [_videoWriter finishWritingWithCompletionHandler:^{
                if (weakSelf.audioRequestGranted) {
                    [weakSelf finishMovieCompositionHandler:^{
                        void (^completion)(void) = ^() {
                            [weakSelf cleanup];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if (completionBlock) completionBlock(weakSelf.videoURL, nil);
                            });
                        };
                        
                        if (weakSelf.videoURL) {
                            completion();
                        } else {
                            NSError *error = [NSError errorWithDomain:@"DRMovieRecorder"
                                                                 code:18062200
                                                             userInfo:@{NSLocalizedDescriptionKey : @"Video URL is nil!"}];
                            if (completionBlock) completionBlock(nil, error);
                        }
                        
                    }];
                } else {
                    void (^completion)(void) = ^() {
                        [weakSelf cleanup];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (completionBlock) completionBlock(weakSelf.videoURL, nil);
                        });
                    };
                    
                    if (weakSelf.videoURL) {
                        completion();
                    } else {
                        NSError *error = [NSError errorWithDomain:@"DRMovieRecorder"
                                                             code:18062201
                                                         userInfo:@{NSLocalizedDescriptionKey : @"Video URL is nil!"}];
                        if (completionBlock) completionBlock(nil, error);
                    }
                }
                weakSelf.status = DRMovieRecorderStatusFinished;
            }];
        });
    });
}

- (void)cleanup {
    self.avAdaptor = nil;
    self.videoWriterInput = nil;
    self.videoWriter = nil;
    self.firstTimeStamp = 0;
    self.outputBufferPoolAuxAttributes = nil;
    CGColorSpaceRelease(_rgbColorSpace);
    CVPixelBufferPoolRelease(_outputBufferPool);
}

- (void)writeVideoFrame {
    // throttle the number of frames to prevent meltdown
    // technique gleaned from Brad Larson's answer here: http://stackoverflow.com/a/5956119
    if (dispatch_semaphore_wait(_frameRenderingSemaphore, DISPATCH_TIME_NOW) != 0) {
        return;
    }
    
    __weak typeof (self) weakSelf = self;
    dispatch_async(_render_queue, ^{
        @autoreleasepool{
            if (![_videoWriterInput isReadyForMoreMediaData]) return;
            
            if (!weakSelf.firstTimeStamp) {
                weakSelf.firstTimeStamp = _displayLink.timestamp;
            }
            CFTimeInterval elapsed = (_displayLink.timestamp - self.firstTimeStamp);
            CMTime time = CMTimeMakeWithSeconds(elapsed, 1000);
            
            CVPixelBufferRef pixelBuffer = NULL;
            CGContextRef bitmapContext = [weakSelf createPixelBufferAndBitmapContext:&pixelBuffer];
            
            if ([weakSelf.delegate respondsToSelector:@selector(writeBackgroundFrameInContext:)]) {
                [weakSelf.delegate writeBackgroundFrameInContext:&bitmapContext];
            }
            // draw each window into the context (other windows include UIKeyboard, UIAlert)
            // FIX: UIKeyboard is currently only rendered correctly in portrait orientation
            dispatch_sync(dispatch_get_main_queue(), ^{
                @autoreleasepool{
                    
                    UIGraphicsPushContext(bitmapContext); {
                        CGRect rect = CGRectMake(0, 0, _viewSize.width, _viewSize.height);
                        if (self.recordView != nil) {
                            [self.recordView drawViewHierarchyInRect:rect afterScreenUpdates:NO];
                        } else {
                            for (UIWindow *window in [[UIApplication sharedApplication] windows]) {
                                [window drawViewHierarchyInRect:rect afterScreenUpdates:NO];
                            }
                        }
                    } UIGraphicsPopContext();
                    
                }
            });
            
            // append pixelBuffer on a async dispatch_queue, the next frame is rendered whilst this one appends
            // must not overwhelm the queue with pixelBuffers, therefore:
            // check if _append_pixelBuffer_queue is ready
            // if it’s not ready, release pixelBuffer and bitmapContext
            if (dispatch_semaphore_wait(_pixelAppendSemaphore, DISPATCH_TIME_NOW) == 0) {
                dispatch_async(_append_pixelBuffer_queue, ^{
                    @autoreleasepool{
                        if (weakSelf.status == DRMovieRecorderStatusRecording && _videoWriter.status == AVAssetWriterStatusWriting ) {
                            BOOL success = [_avAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:time];
                            if (!success) {
#if DEBUG
                                NSLog(@"Warning: Unable to write buffer to video");
#endif
                            }
                        } else {
#if DEBUG
                            NSLog(@"Status is %lu", weakSelf.status);
#endif
                        }
                        CGContextRelease(bitmapContext);
                        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
                        CVPixelBufferRelease(pixelBuffer);
                        
                        dispatch_semaphore_signal(_pixelAppendSemaphore);
                    }
                });
            } else {
                CGContextRelease(bitmapContext);
                CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
                CVPixelBufferRelease(pixelBuffer);
            }
            
            dispatch_semaphore_signal(_frameRenderingSemaphore);
        }
    });
}

- (CGContextRef)createPixelBufferAndBitmapContext:(CVPixelBufferRef *)pixelBuffer
{
    CVPixelBufferPoolCreatePixelBuffer(NULL, _outputBufferPool, pixelBuffer);
    CVPixelBufferLockBaseAddress(*pixelBuffer, 0);
    
    CGContextRef bitmapContext = NULL;
    bitmapContext = CGBitmapContextCreate(CVPixelBufferGetBaseAddress(*pixelBuffer),
                                          CVPixelBufferGetWidth(*pixelBuffer),
                                          CVPixelBufferGetHeight(*pixelBuffer),
                                          8, CVPixelBufferGetBytesPerRow(*pixelBuffer), _rgbColorSpace,
                                          kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst
                                          );
    CGContextScaleCTM(bitmapContext, _scale, _scale);
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, _viewSize.height);
    CGContextConcatCTM(bitmapContext, flipVertical);
    
    return bitmapContext;
}

- (void)startRecordAudio {
    if (!(self.audioRecorder.status == DRAudioRecorderStatusRecording)) {
        if ([self.delegate respondsToSelector:@selector(recorderShouldStartRecordAudio)]) {
            BOOL shouldStartAudio = [self.delegate recorderShouldStartRecordAudio];
            if (shouldStartAudio) {
                [self.audioRecorder start];
            } else {
                NSAssert(shouldStartAudio, @"Should Not Start Audio");
            }
        }
    }
    
    
}

- (void)finishMovieCompositionHandler:(void (^)(void))handler {
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc]init];
    AVMutableCompositionTrack *mutableCompositionVideoTrack = nil;
    AVMutableCompositionTrack *mutableCompositionAudioTrack = nil;
    AVMutableVideoCompositionInstruction *totalVideoCompositionInstruction = [[AVMutableVideoCompositionInstruction alloc]init];
    
    AVURLAsset *aVideoAsset = [AVURLAsset assetWithURL: self.videoURL];
    AVURLAsset *aAudioAsset = [AVURLAsset assetWithURL: self.audioSavedURL];
    
    mutableCompositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    mutableCompositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    
    NSArray<AVAssetTrack *> *videoTrackers = [aVideoAsset tracksWithMediaType:AVMediaTypeVideo];
    NSAssert(!(0 >= videoTrackers.count), @"VideoTrackers.count Error!");
    
    NSArray<AVAssetTrack *> * audioTrackers = [aAudioAsset tracksWithMediaType:AVMediaTypeAudio];
    NSAssert(!(0 >= audioTrackers.count), @"AudioTrackers.count Error!");
    
    AVAssetTrack *aVideoAssetTrack = videoTrackers[0];
    AVAssetTrack *aAudioAssetTrack = audioTrackers[0];
    
    CMTimeRange videoTimeRange = CMTimeRangeMake(kCMTimeZero, aVideoAsset.duration);
    
    [mutableCompositionVideoTrack insertTimeRange:videoTimeRange ofTrack:aVideoAssetTrack atTime:kCMTimeZero error:nil];
    [mutableCompositionAudioTrack insertTimeRange:videoTimeRange ofTrack:aAudioAssetTrack atTime:kCMTimeZero error:nil];
    
    
    totalVideoCompositionInstruction.timeRange = videoTimeRange;
    
    AVMutableVideoComposition *mutableVideoComposition = [[AVMutableVideoComposition alloc]init];
    
    mutableVideoComposition.frameDuration = CMTimeMake(1, self.displayLink.preferredFramesPerSecond);
    
    NSString *fileName = [self.videoFileName stringByReplacingOccurrencesOfString:@"temp" withString:@""];
    NSURL *savePathUrl = [DRMovieRecorder saveURLWithFileName:fileName extension:@"mp4"];
    [DRMovieRecorder removeFileAt:savePathUrl];
    AVAssetExportSession *assetExport = [[AVAssetExportSession alloc]initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    assetExport.outputFileType = AVFileTypeMPEG4;
    assetExport.outputURL = savePathUrl;
    assetExport.shouldOptimizeForNetworkUse = YES;
    
    self.videoURL = savePathUrl;
    [assetExport exportAsynchronouslyWithCompletionHandler:handler];
}

#pragma mark - File
- (NSURL *)documentFileURLWith:(NSString *)fileName extension:(NSString *)extension {
    return [[DRMovieRecorder videoRootURL] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", fileName, extension]];
}

- (NSURL *)tempFileURL {
    NSString *outputPath = [NSHomeDirectory() stringByAppendingPathComponent:@"tmp/screenCapture.mp4"];
    [self removeTempFilePath:outputPath];
    return [NSURL fileURLWithPath:outputPath];
}

- (void)removeTempFilePath:(NSString *)filePath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath]) {
        NSError *error;
        if ([fileManager removeItemAtPath:filePath error:&error] == NO) {
            NSLog(@"Could not delete old recording:%@", [error localizedDescription]);
        }
    }
}

#pragma mark - DRAudioRecorderDelegate
- (void)recorderDidProcessError:(NSError *)error {
    
}

- (void)recorderDidProcessAudioData:(NSData *)audioData {
    if ([self.delegate respondsToSelector:@selector(recorderDidCaptureAudioData:)]) {
        [self.delegate recorderDidCaptureAudioData:audioData];
    }
}

#pragma mark - Getter & Setter
- (DRAudioRecorder *)audioRecorder {
    if (!_audioRecorder) {
        _audioRecorder = [[DRAudioRecorder alloc] init];
        _audioSavedURL = [DRMovieRecorder saveURLWithFileName:_videoFileName extension:@"wav"];
        [DRMovieRecorder removeFileAt:_audioSavedURL];
        _audioRecorder.savedURL = _audioSavedURL;
        _audioRecorder.delegate = self;
    }
    return _audioRecorder;
}

#pragma mark - Public
+ (NSURL *)videoRootURL {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths[0];
    return [[NSURL URLWithString:documentsDirectory] URLByAppendingPathComponent:@"video" isDirectory:YES];
}

+ (NSURL *)saveURLWithFileName:(NSString *)fileName extension:(NSString *)extension {
    NSArray *paths = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *documentsURL = [paths lastObject];
    NSString *component = [NSString stringWithFormat:@"%@.%@", fileName, extension];
    return [[documentsURL URLByAppendingPathComponent:@"video"] URLByAppendingPathComponent:component];
}

+ (void)removeFileAt:(NSURL *)fileURL {
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:fileURL.path]) {
        NSError *error = nil;
        [fm removeItemAtURL:fileURL error:&error];
        if (error != nil) {
            @throw error;
        }
    }
}

+ (NSURL *)videoFileOutputURL {
    return [self saveURLWithFileName:kVideoFileName extension:@"mp4"];
}

+ (NSURL *)videoThumbURL {
    return [self saveURLWithFileName:kVideoThumbName extension:@"png"];
}

+ (BOOL)clearCacheWithFilePath:(NSString *)path {
    NSArray *subPathArr = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
    NSString *filePath = nil;
    NSError *error = nil;
    
    for (NSString *subPath in subPathArr) {
        filePath = [path stringByAppendingPathComponent:subPath];
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
        if (error) {
            return NO;
        }
    }
    return YES;
}


- (void)setVideoURL:(NSURL *)videoURL {
    NSAssert(self.status != DRMovieRecorderStatusRecording, @"videoURL can not be changed whilst recording is in progress");
    _videoURL = videoURL;
}

- (BOOL)startRecording {
    if (self.status != DRMovieRecorderStatusRecording) {
        [self setupWriter];
        self.status = (_videoWriter.status == AVAssetWriterStatusWriting) ?
        DRMovieRecorderStatusRecording : DRMovieRecorderStatusWriterFailed;
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(writeVideoFrame)];
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        if (self.audioRequestGranted) { //&& !self.audioRecorder.isRecording) {
            [self startRecordAudio];
        }
    }
    return self.status == DRMovieRecorderStatusRecording;
}

- (void)stopRecordingWithCompletion:(VideoCompletionBlock)completionBlock {
    if (self.status == DRMovieRecorderStatusRecording) {
        [_displayLink removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        [_displayLink invalidate];
        _displayLink = nil;
        
        if (self.audioRecorder.status == DRAudioRecorderStatusRecording) {
            [self.audioRecorder stop];
            if ([self.delegate respondsToSelector:@selector(recorderDidStopRecordAudio)]) {
                [self.delegate recorderDidStopRecordAudio];
            }
        }
        self.status = DRMovieRecorderStatusStop;
        [self completeRecordingSession:completionBlock];
    } else {
        NSError *error = [NSError errorWithDomain:@"DRMovieRecorder"
                                             code:18062202
                                         userInfo:@{NSLocalizedDescriptionKey : @"Recorder Status Error!"}];
        if (completionBlock) completionBlock(nil, error);
    }
}

@end
