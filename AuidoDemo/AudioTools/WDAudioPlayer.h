//
//  WDAudioPlayer.h
//  AuidoDemo
//
//  Created by VD on 2017/11/22.
//  Copyright © 2017年 VD. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WDAudioPlayerItem.h"
#import <UIKit/UIKit.h>



typedef enum : NSUInteger {
    WDAudioPlayerIdle,//空闲
    WDAudioPlayerBuffering,//缓冲
    WDAudioPlayerStop,//停止
    WDAudioPlayerPlaying,//播放状态,
    WDAudioPlayerFinished,//播放结束
    WDAudioPlayerError
} WDAudioPlayerStatus;


@protocol WDAudioPlayerDelegate

@end



@interface WDAudioPlayer : NSObject

@property (nonatomic,strong,readonly) WDAudioPlayerItem * currentItem;

@property (nonatomic,strong) NSArray<WDAudioPlayerItem *> * items;

@property (nonatomic,assign,readonly) CGFloat current_duration;

@property (nonatomic,weak) id<WDAudioPlayerDelegate>delegate;

@property (nonatomic,assign,readonly)WDAudioPlayerStatus status;

@property (nonatomic,assign) CGFloat volume;  //default 0.5; 声音

- (void)nextAudio;

- (void)previousAudio;

- (void)stop;

- (void)play;

- (void)reset;

@end



