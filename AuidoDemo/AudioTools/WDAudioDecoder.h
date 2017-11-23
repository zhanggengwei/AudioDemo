//
//  WDAudioDecoder.h
//  AuidoDemo
//
//  Created by VD on 2017/11/22.
//  Copyright © 2017年 VD. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioUnit/AudioUnit.h>
#import <AudioToolbox/AudioToolbox.h>
#import "WDAudioPlayerItem.h"
#import "WDAudioLPCM.h"

typedef NS_ENUM(NSUInteger, WDAudioDecoderStatus) {
    WDAudioDecoderSucceeded,
    WDAudioDecoderFailed,
    WDAudioDecoderEndEncountered,
    WDAudioDecoderWaiting
};

@interface WDAudioDecoder : NSObject

+ (AudioStreamBasicDescription)defaultOutputFormat;

+ (instancetype)decoderWithPlaybackItem:(WDAudioPlayerItem *)playbackItem
                             bufferSize:(NSUInteger)bufferSize;

- (instancetype)initWithPlaybackItem:(WDAudioPlayerItem *)playbackItem
                          bufferSize:(NSUInteger)bufferSize;
- (BOOL)setUp;
- (void)tearDown;

- (WDAudioDecoderStatus)decodeOnce;
- (void)seekToTime:(NSUInteger)milliseconds;

@property (nonatomic, readonly) WDAudioPlayerItem *playbackItem;
@property (nonatomic, readonly) WDAudioLPCM *lpcm;

@end
