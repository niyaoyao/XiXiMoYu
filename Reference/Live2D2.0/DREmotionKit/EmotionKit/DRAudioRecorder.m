//
//  DRAudioRecorder.m
//  DRAudioRecorder
//
//  Created by niyao on 6/25/18.
//  Copyright © 2018 dourui. All rights reserved.
//

#import "DRAudioRecorder.h"
#import <AVFoundation/AVAudioSession.h>

@interface DRAudioRecorder () 

//@property (nonatomic, strong) IFlyPcmRecorder *pcmRecorder;
@property (nonatomic, assign, readwrite) DRAudioRecorderStatus status;
@property (nonatomic, strong) NSMutableData *audioData;

@end


@implementation DRAudioRecorder {
    dispatch_queue_t _audioRecordQueue;
    dispatch_queue_t _audioDataDelegateQueue;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupRecorder];
        _status = DRAudioRecorderStatusInitailized;
        _audioRecordQueue = dispatch_queue_create("group.dourui.audio.record.queue", DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(_audioRecordQueue, dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0));
        _audioDataDelegateQueue = dispatch_queue_create("group.dourui.audio.data.queue", DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(_audioDataDelegateQueue,  dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0));
    }
    return self;
}

- (void)setupRecorder {
    //Initialize recorder
//    if (_pcmRecorder == nil) {
//        _pcmRecorder = [IFlyPcmRecorder sharedInstance];
//    }
//
//    [_pcmRecorder setSample:@"16000"];
//    [_pcmRecorder setSaveAudioPath: nil];
}


+ (NSURL *)saveURLWithFileName:(NSString *)fileName extension:(NSString *)extension {
    NSArray *paths = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *documentsURL = [paths lastObject];
    NSString *component = [NSString stringWithFormat:@"%@.%@", fileName, extension];
    return [documentsURL URLByAppendingPathComponent:component];
}

- (BOOL)start {
    __block BOOL success = NO;
    dispatch_sync(_audioRecordQueue, ^{
        @autoreleasepool {
            // set the category of AVAudioSession
//            [IFlyAudioSession initRecordingAudioSession];
//            success = [_pcmRecorder start];
//            _pcmRecorder.delegate = self;
            if (success) {
                _status = DRAudioRecorderStatusStart;
            } else {
                _status = DRAudioRecorderStatusStartFailed;
            }
        }
    });
    return success;
}

- (BOOL)stop {
//    [_pcmRecorder stop];
    [[AVAudioSession sharedInstance] setActive:NO
                                   withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                                         error:nil];
    BOOL success = [self saveWaveFileWithAudioData:self.audioData];
    if (success) {
        self.audioData = nil;
        _status = DRAudioRecorderStatusStop;
    } else {
        _status = DRAudioRecorderStatusStopFailed;
    }
    return success;
}

- (BOOL)saveWaveFileWithAudioData:(NSData *)audioData {
    long sampleRate = 16000;
    Byte waveHead[44];
    waveHead[0] = 'R';
    waveHead[1] = 'I';
    waveHead[2] = 'F';
    waveHead[3] = 'F';
    
    long totalDatalength = [audioData length] + 44;
    waveHead[4] = (Byte)(totalDatalength & 0xff);
    waveHead[5] = (Byte)((totalDatalength >> 8) & 0xff);
    waveHead[6] = (Byte)((totalDatalength >> 16) & 0xff);
    waveHead[7] = (Byte)((totalDatalength >> 24) & 0xff);
    
    waveHead[8] = 'W';
    waveHead[9] = 'A';
    waveHead[10] = 'V';
    waveHead[11] = 'E';
    
    waveHead[12] = 'f';
    waveHead[13] = 'm';
    waveHead[14] = 't';
    waveHead[15] = ' ';
    
    waveHead[16] = 16;  //size of 'fmt '
    waveHead[17] = 0;
    waveHead[18] = 0;
    waveHead[19] = 0;
    
    waveHead[20] = 1;   //format
    waveHead[21] = 0;
    
    waveHead[22] = 1;   //chanel
    waveHead[23] = 0;
    
    waveHead[24] = (Byte)(sampleRate & 0xff);
    waveHead[25] = (Byte)((sampleRate >> 8) & 0xff);
    waveHead[26] = (Byte)((sampleRate >> 16) & 0xff);
    waveHead[27] = (Byte)((sampleRate >> 24) & 0xff);
    
    long byteRate = sampleRate * 2 * (16 >> 3);;
    waveHead[28] = (Byte)(byteRate & 0xff);
    waveHead[29] = (Byte)((byteRate >> 8) & 0xff);
    waveHead[30] = (Byte)((byteRate >> 16) & 0xff);
    waveHead[31] = (Byte)((byteRate >> 24) & 0xff);
    
    waveHead[32] = 2*(16 >> 3);
    waveHead[33] = 0;
    
    waveHead[34] = 16;
    waveHead[35] = 0;
    
    waveHead[36] = 'd';
    waveHead[37] = 'a';
    waveHead[38] = 't';
    waveHead[39] = 'a';
    
    long totalAudiolength = [audioData length];
    
    waveHead[40] = (Byte)(totalAudiolength & 0xff);
    waveHead[41] = (Byte)((totalAudiolength >> 8) & 0xff);
    waveHead[42] = (Byte)((totalAudiolength >> 16) & 0xff);
    waveHead[43] = (Byte)((totalAudiolength >> 24) & 0xff);
    
    NSMutableData *wavData = [[NSMutableData alloc] initWithBytes:&waveHead length:sizeof(waveHead)];
    [wavData appendData:audioData];
    
#if DEBUG
    NSLog(@"Wave Date Length: %lu", (unsigned long)[wavData length]);
#endif
    BOOL success = [wavData writeToFile:self.savedURL.path atomically:YES];
    return success;
}

- (void)onIFlyRecorderBuffer:(const void *)buffer bufferSize:(int)size {
    @autoreleasepool {
        NSData *audioBuffer = [NSData dataWithBytes:buffer length:size];
        [self.audioData appendData:audioBuffer];
        if (_status != DRAudioRecorderStatusRecording) {
            _status = DRAudioRecorderStatusRecording;
        }
        if ([self.delegate respondsToSelector:@selector(recorderDidProcessAudioData:)]) {
            dispatch_async(_audioDataDelegateQueue, ^{
                [self.delegate recorderDidProcessAudioData:audioBuffer];
            });
        }
    }
}

//- (void)onIFlyRecorderError:(IFlyPcmRecorder *)recoder theError:(int)error {
//    _status = DRAudioRecorderStatusError;
//    if ([self.delegate respondsToSelector:@selector(recorderDidProcessError:)]) {
//        if (error != 0) {
//            NSError *err = [NSError errorWithDomain:@"Audio Recorder Domain"
//                                               code:error
//                                           userInfo:@{ NSLocalizedDescriptionKey : @"Audio Recorder Error" }];
//            [self.delegate recorderDidProcessError:err];
//        } else {
//            [self.delegate recorderDidProcessError:nil];
//        }
//    }
//}

- (NSMutableData *)audioData {
    if (!_audioData) {
        _audioData = [[NSMutableData alloc] init];
    }
    return _audioData;
}

@end
