//
//  WDMPMediaLibraryAssetLoader.h
//  AuidoDemo
//
//  Created by VD on 2017/11/24.
//  Copyright © 2017年 VD. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE

#import <Foundation/Foundation.h>

typedef void (^WDMediaLibraryAssetLoaderCompletedBlock)(void);

@interface WDMPMediaLibraryAssetLoader : NSObject

+ (instancetype)loaderWithURL:(NSURL *)url;
- (instancetype)initWithURL:(NSURL *)url;

@property (nonatomic, strong, readonly) NSURL *assetURL;
@property (nonatomic, strong, readonly) NSString *cachedPath;
@property (nonatomic, strong, readonly) NSString *mimeType;
@property (nonatomic, strong, readonly) NSString *fileExtension;

@property (nonatomic, assign, readonly, getter=isFailed) BOOL failed;

@property (copy) WDMPMediaLibraryAssetLoaderCompletedBlock completedBlock;

- (void)start;
- (void)cancel;

@end

#endif /* TARGET_OS_IPHONE */
