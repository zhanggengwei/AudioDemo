//
//  WDAudioPlayerItem.h
//  AuidoDemo
//
//  Created by VD on 2017/11/22.
//  Copyright © 2017年 VD. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AudioUnit/AudioUnit.h>
#import "WDAudioFileProvider.h"
#import "WDAudioFile.h"
#import "WDAudioFilePreprocessor.h"
#import <AudioToolbox/AudioToolbox.h>
#import "WDPreHeader.h"


@interface WDAudioPlayerItem : NSObject

+ (instancetype)playbackItemWithFileProvider:(WDAudioFileProvider *)item;
- (instancetype)initWithFileProvider:(WDAudioFileProvider *)item;

@property (nonatomic, readonly) WDAudioFileProvider *fileProvider;
@property (nonatomic, readonly) WDAudioFilePreprocessor *filePreprocessor;
@property (nonatomic, readonly) id <WDAudioFile> audioFile;

@property (nonatomic, readonly) NSURL *cachedURL;
@property (nonatomic, readonly) NSData *mappedData;

@property (nonatomic, readonly) AudioFileID fileID;
@property (nonatomic, readonly) AudioStreamBasicDescription fileFormat;
@property (nonatomic, readonly) NSUInteger bitRate;
@property (nonatomic, readonly) NSUInteger dataOffset;
@property (nonatomic, readonly) NSUInteger estimatedDuration;

@property (nonatomic, readonly, getter=isOpened) BOOL opened;

- (BOOL)open;
- (void)close;


@end
