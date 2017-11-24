//
//  WDAudioStreamer+options.h
//  AuidoDemo
//
//  Created by VD on 2017/11/24.
//  Copyright © 2017年 VD. All rights reserved.
//

#import "WDAudioStreamer.h"

extern NSString *const kWDAudioStreamerVolumeKey;
extern const NSUInteger kWDAudioStreamerBufferTime;

typedef NS_OPTIONS(NSUInteger, WDAudioStreamerOptions) {
    WDAudioStreamerKeepPersistentVolume = 1 << 0,
    WDAudioStreamerRemoveCacheOnDeallocation = 1 << 1,
    WDAudioStreamerRequireSHA256 = 1 << 2,
    
    WDAudioStreamerDefaultOptions = WDAudioStreamerKeepPersistentVolume |
    WDAudioStreamerRemoveCacheOnDeallocation
};

@interface WDAudioStreamer (options)

+ (WDAudioStreamerOptions)options;
+ (void)setOptions:(WDAudioStreamerOptions)options;

@end
