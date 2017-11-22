//
//  WDRecoder.h
//  AuidoDemo
//
//  Created by VD on 2017/11/22.
//  Copyright © 2017年 VD. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol WDRecoderDelegate
@required

- (BOOL)needSaveToLocal;

- (NSString *)audioFilePath;

@end

@interface WDRecoder : NSObject

@property (nonatomic,assign,readonly) BOOL saveToLocal;
@property (nonatomic,assign,readonly) NSString * audioFilePath;
@property (nonatomic,weak) id<WDRecoderDelegate> delegate;


- (void)startRecoarder:(NSError **)error;

- (void)stopRecoard;



@end
