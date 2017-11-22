//
//  WDAudioStreamer.h
//  AuidoDemo
//
//  Created by VD on 2017/11/22.
//  Copyright © 2017年 VD. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface WDAudioStreamer : NSObject

@property (nonatomic,assign) CGFloat expectedLength;
@property (nonatomic,assign) CGFloat receiveLength;
@property (nonatomic,assign) CGFloat downloadSpeed;

@property (nonatomic, readonly) NSString *cachedPath;
@property (nonatomic, readonly) NSURL *cachedURL;
@property (nonatomic, readonly) NSString * sha256;

@property (nonatomic, assign, readonly) NSTimeInterval duration;
@property (nonatomic, assign) NSTimeInterval currentTime;

@property (nonatomic, assign, readonly) double bufferingRatio;

- (void)play;
- (void)pause;
- (void)stop;


@end
