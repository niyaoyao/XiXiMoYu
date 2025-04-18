//
//  DRMovieRecorder+VideoComposition.m
//  doutu
//
//  Created by niyao on 6/13/18.
//  Copyright © 2018 dourui. All rights reserved.
//

#import "DRMovieRecorder+VideoComposition.h"
#import <AVFoundation/AVFoundation.h>

@implementation DRMovieRecorder (VideoComposition)

+ (NSURL *)synchronizedComposionWithURLs:(NSArray <NSURL *> *)videoURLs {
    NSURL *savedURL = nil;
    savedURL = [self synchronizedVideoCompositionWithFirst:videoURLs[0] secondURL:videoURLs[1]];
    if (videoURLs.count > 2) {
        for (int i = 2; i < videoURLs.count; i++) {
            savedURL = [self synchronizedVideoCompositionWithFirst:savedURL secondURL:videoURLs[i]];
        }
    }
    return  savedURL;
}

+ (void)videoCompositionWithURLs:(NSArray <NSURL *> *)videoURLs completion:(void(^)(NSURL *fURL))completion {
    
    NSError *error = nil;
    __block CGSize renderSize = CGSizeMake(0, 0);
    
    NSMutableArray *layerInstructionArray = [[NSMutableArray alloc] init];
    AVMutableComposition *mixComposition = [AVMutableComposition composition];
    
    CMTime totalDuration = CMTimeMake(0, 60);//kCMTimeZero;
    
    // 先去 assetTrack 也为了取 renderSize
    
    NSMutableArray *assetTrackArray = [[NSMutableArray alloc] init];
    NSMutableArray *assetArray = [[NSMutableArray alloc] init];
    NSDictionary *optDict = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    
    [videoURLs enumerateObjectsUsingBlock:^(NSURL * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        AVAsset *asset = [[AVURLAsset alloc] initWithURL:obj options:optDict]; //[AVAsset assetWithURL:obj];

        if (!asset) {
            *stop = YES;
        }
        
        [assetArray addObject:asset];
        
        NSArray *dataSourceArray = [NSArray arrayWithArray: [asset tracksWithMediaType:AVMediaTypeVideo]];
        AVAssetTrack *assetTrack = ([dataSourceArray count]>0) ? [dataSourceArray objectAtIndex:0] : nil;
        [assetTrackArray addObject:assetTrack];
        
        renderSize.width = MAX(renderSize.width, assetTrack.naturalSize.width);
        renderSize.height = MAX(renderSize.height, assetTrack.naturalSize.height);
    }];
    
    CGFloat renderW = renderSize.width;
    for (int i = 0; i < [assetArray count] && i < [assetTrackArray count]; i++) {
        
        AVAsset *asset = [assetArray objectAtIndex:i];
        AVAssetTrack *assetTrack = [assetTrackArray objectAtIndex:i];
        
        AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        
        [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                            ofTrack:assetTrack
                             atTime:totalDuration
                              error:&error];
        
        AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        AVAssetTrack *audioAssetTrack = ([[asset tracksWithMediaType:AVMediaTypeAudio] count] > 0) ?
        [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] : nil;

        [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                            ofTrack:audioAssetTrack
                             atTime:totalDuration
                              error:nil];
        
        totalDuration = CMTimeAdd(totalDuration, asset.duration);
        //fix orientationissue
        
        AVMutableVideoCompositionLayerInstruction *layerInstruciton = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];

        [layerInstruciton setOpacity:0.0 atTime:totalDuration];
        [layerInstructionArray addObject:layerInstruciton];
        
    }
    
    //获取保存路径
    NSURL *mergeFileURL = [DRMovieRecorder saveURLWithFileName:kVideoFileName extension:@"mp4"];
    [DRMovieRecorder removeFileAt:mergeFileURL];
    
    //导出合并的视频
    AVMutableVideoCompositionInstruction *mainInstruciton = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruciton.timeRange = CMTimeRangeMake(kCMTimeZero, totalDuration);
    mainInstruciton.layerInstructions = layerInstructionArray;
    
    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
    mainCompositionInst.instructions = @[mainInstruciton];
    mainCompositionInst.frameDuration = CMTimeMake(1, 60);
    mainCompositionInst.renderSize = renderSize;
    
#pragma mark // 录制视频压缩质量调整
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    exporter.videoComposition = mainCompositionInst;
    exporter.outputURL = mergeFileURL;
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.shouldOptimizeForNetworkUse = YES;
    
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        if (completion) {
            completion(exporter.outputURL);
        }
    }];
}


+ (NSURL *)synchronizedVideoCompositionWithFirst:(NSURL *)firstURL
                        secondURL:(NSURL *)secondURL {
    __block NSURL *savedURL = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [DRMovieRecorder videoCompositionWithFirst:firstURL secondURL:secondURL completion:^(NSURL *fURL) {
        savedURL = fURL;
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return savedURL;
}
+ (void)videoCompositionWithFirst:(NSURL *)firstURL
                        secondURL:(NSURL *)secondURL
                       completion:(void(^)(NSURL *fURL))completion {
    NSDictionary *optDict = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVAsset *firstAsset = [[AVURLAsset alloc] initWithURL:firstURL options:optDict];
    AVAsset *secondAsset = [[AVURLAsset alloc] initWithURL:secondURL options:optDict];
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    //为视频类型的的Track
    AVMutableCompositionTrack *compositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    //由于没有计算当前CMTime的起始位置，现在插入0的位置,所以合并出来的视频是后添加在前面，可以计算一下时间，插入到指定位置
    //CMTimeRangeMake 指定起去始位置
    CMTimeRange firstTimeRange = CMTimeRangeMake(kCMTimeZero, firstAsset.duration);
    CMTimeRange secondTimeRange = CMTimeRangeMake(kCMTimeZero, secondAsset.duration);
    NSError *error = nil;
    [compositionTrack insertTimeRange:secondTimeRange ofTrack:[secondAsset tracksWithMediaType:AVMediaTypeVideo][0] atTime:kCMTimeZero error:&error];
    if (error != nil) {
        @throw error;
    }
    [compositionTrack insertTimeRange:firstTimeRange ofTrack:[firstAsset tracksWithMediaType:AVMediaTypeVideo][0] atTime:kCMTimeZero error:&error];
    if (error != nil) {
        @throw error;
    }
    
    //只合并视频，导出后声音会消失，所以需要把声音插入到混淆器中
    //添加音频,添加本地其他音乐也可以,与视频一致
    AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    [audioTrack insertTimeRange:secondTimeRange ofTrack:[secondAsset tracksWithMediaType:AVMediaTypeAudio][0] atTime:kCMTimeZero error:&error];
    if (error != nil) {
        @throw error;
    }
    [audioTrack insertTimeRange:firstTimeRange ofTrack:[firstAsset tracksWithMediaType:AVMediaTypeAudio][0] atTime:kCMTimeZero error:&error];
    if (error != nil) {
        @throw error;
    }
    
    //获取保存路径
    NSURL *mergeFileURL = [DRMovieRecorder saveURLWithFileName:kVideoFileName extension:@"mp4"];
    [DRMovieRecorder removeFileAt:mergeFileURL];
    NSString *filePath = mergeFileURL.path;
    AVAssetExportSession *exporterSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
    exporterSession.outputFileType = AVFileTypeMPEG4;
    exporterSession.outputURL = [NSURL fileURLWithPath:filePath]; //如果文件已存在，将造成导出失败
    exporterSession.shouldOptimizeForNetworkUse = YES; //用于互联网传输
    [exporterSession exportAsynchronouslyWithCompletionHandler:^{
        if (completion) {
            completion(exporterSession.outputURL);
        }
    }];
}

@end
