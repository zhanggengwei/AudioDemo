//
//  NSData+WDMappedFile.h
//  DOUASDemo
//
//  Created by VD on 2017/11/20.
//  Copyright © 2017年 VD. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (WDMappedFile)

+ (instancetype)dou_dataWithMappedContentsOfFile:(NSString *)path;
+ (instancetype)dou_dataWithMappedContentsOfURL:(NSURL *)url;

+ (instancetype)dou_modifiableDataWithMappedContentsOfFile:(NSString *)path;
+ (instancetype)dou_modifiableDataWithMappedContentsOfURL:(NSURL *)url;

- (void)dou_synchronizeMappedFile;

@end
