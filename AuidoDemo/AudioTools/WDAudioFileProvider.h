//
//  WDAudioFileProvider.h
//  AuidoDemo
//
//  Created by VD on 2017/11/23.
//  Copyright © 2017年 VD. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WDAudioFile.h"

typedef void (^WDAudioFileProviderEventBlock)(void);

//提供文件，网络音频流的工具
@interface WDAudioFileProvider : NSObject
+ (instancetype)fileProviderWithAudioFile:(id <WDAudioFile>)audioFile;
+ (void)setHintWithAudioFile:(id <WDAudioFile>)audioFile;

@property (nonatomic, readonly) id <WDAudioFile> audioFile;
@property (nonatomic, copy) WDAudioFileProviderEventBlock eventBlock;

@property (nonatomic, readonly) NSString *cachedPath;
@property (nonatomic, readonly) NSURL *cachedURL;

@property (nonatomic, readonly) NSString *mimeType;
@property (nonatomic, readonly) NSString *fileExtension;
@property (nonatomic, readonly) NSString *sha256;

@property (nonatomic, readonly) NSData *mappedData;

@property (nonatomic, readonly) NSUInteger expectedLength;
@property (nonatomic, readonly) NSUInteger receivedLength;
@property (nonatomic, readonly) NSUInteger downloadSpeed;

@property (nonatomic, readonly, getter=isFailed) BOOL failed;
@property (nonatomic, readonly, getter=isReady) BOOL ready;
@property (nonatomic, readonly, getter=isFinished) BOOL finished;

@end
