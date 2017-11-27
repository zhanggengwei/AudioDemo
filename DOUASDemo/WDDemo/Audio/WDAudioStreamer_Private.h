/* vim: set ft=objc fenc=utf-8 sw=2 ts=2 et: */
/*
 *  WDAudioStreamer - A Core Audio based streaming audio player for iOS/Mac:
 *
 *      https://github.com/douban/WDAudioStreamer
 *
 *  Copyright 2013-2016 Douban Inc.  All rights reserved.
 *
 *  Use and distribution licensed under the BSD license.  See
 *  the LICENSE file for full text.
 *
 *  Authors:
 *      Chongyu Zhu <i@lembacon.com>
 *
 */

#import "WDAudioStreamer.h"

@class WDAudioFileProvider;
@class WDAudioPlaybackItem;
@class WDAudioDecoder;

@interface WDAudioStreamer ()

@property (assign) WDAudioStreamerStatus status;
@property (strong) NSError *error;

@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, assign) NSInteger timingOffset;

@property (nonatomic, readonly) WDAudioFileProvider *fileProvider;
@property (nonatomic, strong) WDAudioPlaybackItem *playbackItem;
@property (nonatomic, strong) WDAudioDecoder *decoder;

@property (nonatomic, assign) double bufferingRatio;

#if TARGET_OS_IPHONE
@property (nonatomic, assign, getter=isPausedByInterruption) BOOL pausedByInterruption;
#endif /* TARGET_OS_IPHONE */

@end
