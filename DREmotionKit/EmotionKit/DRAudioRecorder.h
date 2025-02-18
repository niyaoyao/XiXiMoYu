//
//  DRAudioRecorder.h
//  DRAudioRecorder
//
//  Created by niyao on 6/25/18.
//  Copyright © 2018 dourui. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol DRAudioRecorderDelegate <NSObject>

@optional
- (void)recorderDidProcessAudioData:(NSData *)audioData;
- (void)recorderDidProcessError:(NSError *)error;

@end


typedef NS_ENUM(NSInteger, DRAudioRecorderStatus) {
    DRAudioRecorderStatusInitailized,
    DRAudioRecorderStatusStart,
    DRAudioRecorderStatusStartFailed,
    DRAudioRecorderStatusRecording,
    DRAudioRecorderStatusStop,
    DRAudioRecorderStatusStopFailed,
    DRAudioRecorderStatusError,
};


@interface DRAudioRecorder : NSObject

@property (nonatomic, weak  ) id<DRAudioRecorderDelegate> delegate;
@property (nonatomic, assign, readonly) DRAudioRecorderStatus status;
@property (nonatomic, strong) NSURL *savedURL;

- (void)setupRecorder;
- (BOOL)start;
- (BOOL)stop;

@end
