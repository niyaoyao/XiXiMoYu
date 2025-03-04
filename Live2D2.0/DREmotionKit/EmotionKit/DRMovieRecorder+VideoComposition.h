//
//  DRMovieRecorder+VideoComposition.h
//  doutu
//
//  Created by niyao on 6/13/18.
//  Copyright © 2018 dourui. All rights reserved.
//

#import "DRMovieRecorder.h"

@interface DRMovieRecorder (VideoComposition)

+ (NSURL *)synchronizedComposionWithURLs:(NSArray <NSURL *> *)videoURLs;
+ (void)videoCompositionWithURLs:(NSArray <NSURL *> *)videoURLs completion:(void(^)(NSURL *fURL))completion;
@end
