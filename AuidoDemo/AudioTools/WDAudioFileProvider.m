

//
//  WDAudioFileProvider.m
//  AuidoDemo
//
//  Created by VD on 2017/11/23.
//  Copyright © 2017年 VD. All rights reserved.
//

#import "WDAudioFileProvider.h"
#import "WDPreHeader.h"
#import "NSData+WDDataFile.h"
#import "WDSimpleHTTPRequest.h"
#include <MobileCoreServices/MobileCoreServices.h>
#import <AudioUnit/AudioUnit.h>
#include <CommonCrypto/CommonDigest.h>
#import <AudioToolbox/AudioToolbox.h>
#import "WDAudioStreamer+options.h"



@interface WDAudioFileProvider()
{
@public
    id <WDAudioFile> _audioFile;
    WDAudioFileProviderEventBlock _eventBlock;
    NSString *_cachedPath;
    NSURL *_cachedURL;
    NSString *_mimeType;
    NSString *_fileExtension;
    NSString *_sha256;
    NSData *_mappedData;
    NSUInteger _expectedLength;
    NSUInteger _receivedLength;
    BOOL _failed;
}
- (instancetype)_initWithAudioFile:(id <WDAudioFile>)audioFile;
@end

@interface _WDLocalAudioFileProvider:WDAudioFileProvider

@end

@interface _WDRemoteAudioFileProvider:WDAudioFileProvider
{
    WDSimpleHTTPRequest * _httpRequest;
    NSURL *_audioFileURL;
    NSString *_audioFileHost;
    
    CC_SHA256_CTX *_sha256Ctx;
    
    AudioFileStreamID _audioFileStreamID;
    BOOL _requiresCompleteFile;
    BOOL _readyToProducePackets;
    BOOL _requestCompleted;
}
@end

@interface _WDAudioMediaLibraryFileProvider:WDAudioFileProvider
@end


@implementation WDAudioFileProvider
{
   
}
- (instancetype)_initWithAudioFile:(id<WDAudioFile>)audioFile
{
    return nil;
}
+ (instancetype)fileProviderWithAudioFile:(id <WDAudioFile>)audioFile
{
    return nil;
}
+ (void)setHintWithAudioFile:(id <WDAudioFile>)audioFile
{
    
}
@end


@implementation _WDLocalAudioFileProvider
- (instancetype)_initWithAudioFile:(id<WDAudioFile>)audioFile
{
    if(self = [super _initWithAudioFile:audioFile])
    {
        _cachedURL = [audioFile audioFileURL];
        _audioFile = audioFile;
        _cachedPath = [_cachedURL path];
        BOOL isDir;
        if((![[NSFileManager defaultManager]fileExistsAtPath:_cachedPath isDirectory:&isDir])||isDir)
        {
            WDLOG(@"function=%s line =%d,_cachedPath=%@",__PRETTY_FUNCTION__,__LINE__,_cachedPath);
            return nil;
        }
        _mappedData = [NSData wd_dataWithMappedContentsOfURL:_cachedURL];
        _receivedLength = _mappedData.length;
        _expectedLength = _mappedData.length;
        
    }
    return self;
}

- (NSString *)mimeType
{
    if (_mimeType == nil &&
        [self fileExtension] != nil) {
        CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[self fileExtension], NULL);
        if (uti != NULL) {
            _mimeType = CFBridgingRelease(UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType));
            CFRelease(uti);
        }
    }
    
    return _mimeType;
}

- (NSString *)fileExtension
{
    if (_fileExtension == nil) {
        _fileExtension = [[[self audioFile] audioFileURL] pathExtension];
    }
    return _fileExtension;
}

- (NSUInteger)downloadSpeed
{
    return _receivedLength;
}

- (BOOL)isReady
{
    return YES;
}
- (BOOL)isFinished
{
    return YES;
}
- (NSString *)sha256
{
    WDLOG(@"not supported sha256");
    return nil;
}
@end


@implementation _WDRemoteAudioFileProvider
@synthesize finished = _requestCompleted;
static void audio_file_stream_property_listener_proc(void *inClientData,
                                                     AudioFileStreamID inAudioFileStream,
                                                     AudioFileStreamPropertyID inPropertyID,
                                                     UInt32 *ioFlags)
{
//    __unsafe_unretained _DOUAudioRemoteFileProvider *fileProvider = (__bridge _DOUAudioRemoteFileProvider *)inClientData;
//    [fileProvider _handleAudioFileStreamProperty:inPropertyID];
}

static void audio_file_stream_packets_proc(void *inClientData,
                                           UInt32 inNumberBytes,
                                           UInt32 inNumberPackets,
                                           const void *inInputData,
                                           AudioStreamPacketDescription    *inPacketDescriptions)
{
//    __unsafe_unretained _DOUAudioRemoteFileProvider *fileProvider = (__bridge _DOUAudioRemoteFileProvider *)inClientData;
//    [fileProvider _handleAudioFileStreamPackets:inInputData
//                                  numberOfBytes:inNumberBytes
//                                numberOfPackets:inNumberPackets
//                             packetDescriptions:inPacketDescriptions];
}
- (instancetype)_initWithAudioFile:(id<WDAudioFile>)audioFile
{
    if(self = [super _initWithAudioFile:audioFile])
    {
        _audioFile = audioFile;
        _audioFileURL = [audioFile audioFileURL];
        //
        if([WDAudioStreamer options]&WDAudioStreamerRequireSHA256)
        {
            _sha256Ctx = (CC_SHA256_CTX *)malloc(sizeof(CC_SHA256_CTX));
            CC_SHA256_Init(_sha256Ctx);
        }
        [self _openAudioFileStream];
        [self _createRequest];
        [_httpRequest start];
        
    }
    return self;
}

- (void)_openAudioFileStream
{
    [self _openAudioFileStreamWithFileTypeHint:0];
    
}
- (void)_openAudioFileStreamWithFileTypeHint:(AudioFileTypeID)fileTypeHint
{
    OSStatus status = AudioFileStreamOpen((__bridge void *)self,
                                          audio_file_stream_property_listener_proc,
                                          audio_file_stream_packets_proc,
                                          fileTypeHint,
                                          &_audioFileStreamID);
    
    if (status != noErr) {
        _audioFileStreamID = NULL;
    }
}
- (void)_closeAudioFileStream
{
    if(_audioFileStreamID){
       AudioFileStreamClose(_audioFileStreamID);
        _audioFileStreamID = NULL;
    }
    //取消正在进行的网络请求
    [_httpRequest cancel];
}

- (void)_createRequest
{
    _httpRequest = [WDSimpleHTTPRequest requestWithURL:_audioFileURL];
    _httpRequest.didReceiveDataBlock = ^(NSData *data) {
        
    };
    _httpRequest.didReceiveResponseBlock = ^{
        
    };
    _httpRequest.completedBlock = ^{
        
    };
    _httpRequest.progressBlock = ^(double downloadProgress) {
        
    };
}

- (void)dealloc
{
 
}



@end



@implementation _WDAudioMediaLibraryFileProvider

@end


