
//
//  WDAudioStreamer+options.m
//  AuidoDemo
//
//  Created by VD on 2017/11/24.
//  Copyright © 2017年 VD. All rights reserved.
//

#import "WDAudioStreamer+options.h"
NSString *const kWDAudioStreamerVolumeKey = @"kWDAudioStreamerVolumeKey";
const NSUInteger kWDAudioStreamerBufferTime = 200;

static WDAudioStreamerOptions gOptions = WDAudioStreamerDefaultOptions;

@implementation WDAudioStreamer (options)
+ (WDAudioStreamerOptions)options
{
    return gOptions;
}

+ (void)setOptions:(WDAudioStreamerOptions)options
{
    if (!!((gOptions ^ options) & WDAudioStreamerKeepPersistentVolume) &&
        !(options & WDAudioStreamerKeepPersistentVolume)) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kWDAudioStreamerVolumeKey];
    }
    
    gOptions = options;
}
@end
