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
//只考虑本地音频网络音频 ipods中的音频暂时忽略
@interface WDAudioPlayerItem : NSObject
@property (nonatomic,strong) NSString * cachePath;
@property (nonatomic,strong) NSString * fileExtension;
@property (nonatomic,strong) NSString * mineType;
@property (nonatomic,assign) CGFloat  duration;
@property (nonatomic, readonly) AudioStreamBasicDescription fileFormat;
@end

@interface WDAudioPlayerLocalItem : WDAudioPlayerItem
@property (nonatomic,strong) NSURL * localURL;
@property (nonatomic,strong) NSString * local;
@end


@interface WDAudioPlayerRemoteItem : WDAudioPlayerItem
@property (nonatomic,strong) NSURL * audioURL;
@end
