

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

static id <WDAudioFile> gHintFile = nil;
static WDAudioFileProvider *gHintProvider = nil;
static BOOL gLastProviderIsFinished = NO;


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
    if (_sha256 == nil &&
        [WDAudioStreamer options] & WDAudioStreamerRequireSHA256 &&
        [self mappedData] != nil) {
        unsigned char hash[CC_SHA256_DIGEST_LENGTH];
        CC_SHA256([[self mappedData] bytes], (CC_LONG)[[self mappedData] length], hash);
        
        NSMutableString *result = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
        for (size_t i = 0; i < CC_SHA256_DIGEST_LENGTH; ++i) {
            [result appendFormat:@"%02x", hash[i]];
        }
        
        _sha256 = [result copy];
    }
    
    return _sha256;
}
@end


@implementation _WDRemoteAudioFileProvider
@synthesize finished = _requestCompleted;

- (instancetype)_initWithAudioFile:(id <WDAudioFile>)audioFile
{
    self = [super _initWithAudioFile:audioFile];
    if (self) {
        _audioFileURL = [audioFile audioFileURL];
        if ([audioFile respondsToSelector:@selector(audioFileHost)]) {
            _audioFileHost = [audioFile audioFileHost];
        }
        
        if ([WDAudioStreamer options] & WDAudioStreamerRequireSHA256) {
            _sha256Ctx = (CC_SHA256_CTX *)malloc(sizeof(CC_SHA256_CTX));
            CC_SHA256_Init(_sha256Ctx);
        }
        
        [self _openAudioFileStream];
        [self _createRequest];
        [_httpRequest start];
    }
    
    return self;
}

- (void)dealloc
{
    @synchronized(_httpRequest) {
        [_httpRequest setCompletedBlock:NULL];
        [_httpRequest setProgressBlock:NULL];
        [_httpRequest setDidReceiveResponseBlock:NULL];
        [_httpRequest setDidReceiveDataBlock:NULL];
        
        [_httpRequest cancel];
    }
    
    if (_sha256Ctx != NULL) {
        free(_sha256Ctx);
    }
    
    [self _closeAudioFileStream];
    
    if ([WDAudioStreamer options] & WDAudioStreamerRemoveCacheOnDeallocation) {
        [[NSFileManager defaultManager] removeItemAtPath:_cachedPath error:NULL];
    }
}

+ (NSString *)_sha256ForAudioFileURL:(NSURL *)audioFileURL
{
    NSString *string = [audioFileURL absoluteString];
    unsigned char hash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256([string UTF8String], (CC_LONG)[string lengthOfBytesUsingEncoding:NSUTF8StringEncoding], hash);
    
    NSMutableString *result = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (size_t i = 0; i < CC_SHA256_DIGEST_LENGTH; ++i) {
        [result appendFormat:@"%02x", hash[i]];
    }
    
    return result;
}

+ (NSString *)_cachedPathForAudioFileURL:(NSURL *)audioFileURL
{
    NSString *filename = [NSString stringWithFormat:@"douas-%@.tmp", [self _sha256ForAudioFileURL:audioFileURL]];
    return [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
}

- (void)_invokeEventBlock
{
    if (_eventBlock != NULL) {
        _eventBlock();
    }
}

- (void)_requestDidComplete
{
    if ([_httpRequest isFailed] ||
        !([_httpRequest statusCode] >= 200 && [_httpRequest statusCode] < 300)) {
        _failed = YES;
    }
    else {
        _requestCompleted = YES;
        [_mappedData wd_synchronizeMappedFile];
    }
    
    if (!_failed &&
        _sha256Ctx != NULL) {
        unsigned char hash[CC_SHA256_DIGEST_LENGTH];
        CC_SHA256_Final(hash, _sha256Ctx);
        
        NSMutableString *result = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
        for (size_t i = 0; i < CC_SHA256_DIGEST_LENGTH; ++i) {
            [result appendFormat:@"%02x", hash[i]];
        }
        
        _sha256 = [result copy];
    }
    
    if (gHintFile != nil &&
        gHintProvider == nil) {
        gHintProvider = [[[self class] alloc] _initWithAudioFile:gHintFile];
    }
    
    [self _invokeEventBlock];
}

- (void)_requestDidReportProgress:(double)progress
{
    [self _invokeEventBlock];
}

- (void)_requestDidReceiveResponse
{
    _expectedLength = [_httpRequest responseContentLength];
    
    _cachedPath = [[self class] _cachedPathForAudioFileURL:_audioFileURL];
    _cachedURL = [NSURL fileURLWithPath:_cachedPath];
    
    [[NSFileManager defaultManager] createFileAtPath:_cachedPath contents:nil attributes:nil];
#if TARGET_OS_IPHONE
    [[NSFileManager defaultManager] setAttributes:@{NSFileProtectionKey: NSFileProtectionNone}
                                     ofItemAtPath:_cachedPath
                                            error:NULL];
#endif /* TARGET_OS_IPHONE */
    [[NSFileHandle fileHandleForWritingAtPath:_cachedPath] truncateFileAtOffset:_expectedLength];
    
    _mimeType = [[_httpRequest responseHeaders] objectForKey:@"Content-Type"];
    
    _mappedData = [NSData wd_modifiableDataWithMappedContentsOfFile:_cachedPath];
}

- (void)_requestDidReceiveData:(NSData *)data
{
    if (_mappedData == nil) {
        return;
    }
    
    NSUInteger availableSpace = _expectedLength - _receivedLength;
    NSUInteger bytesToWrite = MIN(availableSpace, [data length]);
    
    memcpy((uint8_t *)[_mappedData bytes] + _receivedLength, [data bytes], bytesToWrite);
    _receivedLength += bytesToWrite;
    
    if (_sha256Ctx != NULL) {
        CC_SHA256_Update(_sha256Ctx, [data bytes], (CC_LONG)[data length]);
    }
    
    if (!_readyToProducePackets && !_failed && !_requiresCompleteFile) {
        OSStatus status = kAudioFileStreamError_UnsupportedFileType;
        
        if (_audioFileStreamID != NULL) {
            status = AudioFileStreamParseBytes(_audioFileStreamID,
                                               (UInt32)[data length],
                                               [data bytes],
                                               0);
        }
        
        if (status != noErr && status != kAudioFileStreamError_NotOptimized) {
            NSArray *fallbackTypeIDs = [self _fallbackTypeIDs];
            for (NSNumber *typeIDNumber in fallbackTypeIDs) {
                AudioFileTypeID typeID = (AudioFileTypeID)[typeIDNumber unsignedLongValue];
                [self _closeAudioFileStream];
                [self _openAudioFileStreamWithFileTypeHint:typeID];
                
                if (_audioFileStreamID != NULL) {
                    status = AudioFileStreamParseBytes(_audioFileStreamID,
                                                       (UInt32)_receivedLength,
                                                       [_mappedData bytes],
                                                       0);
                    
                    if (status == noErr || status == kAudioFileStreamError_NotOptimized) {
                        break;
                    }
                }
            }
            
            if (status != noErr && status != kAudioFileStreamError_NotOptimized) {
                _failed = YES;
            }
        }
        
        if (status == kAudioFileStreamError_NotOptimized) {
            [self _closeAudioFileStream];
            _requiresCompleteFile = YES;
        }
    }
}

- (void)_createRequest
{
    _httpRequest = [WDSimpleHTTPRequest requestWithURL:_audioFileURL];
    if (_audioFileHost != nil) {
        [_httpRequest setHost:_audioFileHost];
    }
    __unsafe_unretained _WDRemoteAudioFileProvider *_self = self;
    
    [_httpRequest setCompletedBlock:^{
        [_self _requestDidComplete];
    }];
    
    [_httpRequest setProgressBlock:^(double downloadProgress) {
        [_self _requestDidReportProgress:downloadProgress];
    }];
    
    [_httpRequest setDidReceiveResponseBlock:^{
        [_self _requestDidReceiveResponse];
    }];
    
    [_httpRequest setDidReceiveDataBlock:^(NSData *data) {
        [_self _requestDidReceiveData:data];
    }];
}

- (void)_handleAudioFileStreamProperty:(AudioFileStreamPropertyID)propertyID
{
    if (propertyID == kAudioFileStreamProperty_ReadyToProducePackets) {
        _readyToProducePackets = YES;
    }
}

- (void)_handleAudioFileStreamPackets:(const void *)packets
                        numberOfBytes:(UInt32)numberOfBytes
                      numberOfPackets:(UInt32)numberOfPackets
                   packetDescriptions:(AudioStreamPacketDescription *)packetDescriptioins
{
}

static void audio_file_stream_property_listener_proc(void *inClientData,
                                                     AudioFileStreamID inAudioFileStream,
                                                     AudioFileStreamPropertyID inPropertyID,
                                                     UInt32 *ioFlags)
{
    __unsafe_unretained _WDRemoteAudioFileProvider *fileProvider = (__bridge _WDRemoteAudioFileProvider *)inClientData;
    [fileProvider _handleAudioFileStreamProperty:inPropertyID];
}

static void audio_file_stream_packets_proc(void *inClientData,
                                           UInt32 inNumberBytes,
                                           UInt32 inNumberPackets,
                                           const void *inInputData,
                                           AudioStreamPacketDescription    *inPacketDescriptions)
{
    __unsafe_unretained _WDRemoteAudioFileProvider *fileProvider = (__bridge _WDRemoteAudioFileProvider *)inClientData;
    [fileProvider _handleAudioFileStreamPackets:inInputData
                                  numberOfBytes:inNumberBytes
                                numberOfPackets:inNumberPackets
                             packetDescriptions:inPacketDescriptions];
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
    if (_audioFileStreamID != NULL) {
        AudioFileStreamClose(_audioFileStreamID);
        _audioFileStreamID = NULL;
    }
}

- (NSArray *)_fallbackTypeIDs
{
    NSMutableArray *fallbackTypeIDs = [NSMutableArray array];
    NSMutableSet *fallbackTypeIDSet = [NSMutableSet set];
    
    struct {
        CFStringRef specifier;
        AudioFilePropertyID propertyID;
    } properties[] = {
        { (__bridge CFStringRef)[self mimeType], kAudioFileGlobalInfo_TypesForMIMEType },
        { (__bridge CFStringRef)[self fileExtension], kAudioFileGlobalInfo_TypesForExtension }
    };
    
    const size_t numberOfProperties = sizeof(properties) / sizeof(properties[0]);
    
    for (size_t i = 0; i < numberOfProperties; ++i) {
        if (properties[i].specifier == NULL) {
            continue;
        }
        
        UInt32 outSize = 0;
        OSStatus status;
        
        status = AudioFileGetGlobalInfoSize(properties[i].propertyID,
                                            sizeof(properties[i].specifier),
                                            &properties[i].specifier,
                                            &outSize);
        if (status != noErr) {
            continue;
        }
        
        size_t count = outSize / sizeof(AudioFileTypeID);
        AudioFileTypeID *buffer = (AudioFileTypeID *)malloc(outSize);
        if (buffer == NULL) {
            continue;
        }
        
        status = AudioFileGetGlobalInfo(properties[i].propertyID,
                                        sizeof(properties[i].specifier),
                                        &properties[i].specifier,
                                        &outSize,
                                        buffer);
        if (status != noErr) {
            free(buffer);
            continue;
        }
        
        for (size_t j = 0; j < count; ++j) {
            NSNumber *tid = [NSNumber numberWithUnsignedLong:buffer[j]];
            if ([fallbackTypeIDSet containsObject:tid]) {
                continue;
            }
            
            [fallbackTypeIDs addObject:tid];
            [fallbackTypeIDSet addObject:tid];
        }
        
        free(buffer);
    }
    
    return fallbackTypeIDs;
}

- (NSString *)fileExtension
{
    if (_fileExtension == nil) {
        _fileExtension = [[[[self audioFile] audioFileURL] path] pathExtension];
    }
    
    return _fileExtension;
}

- (NSUInteger)downloadSpeed
{
    return [_httpRequest downloadSpeed];
}

- (BOOL)isReady
{
    if (!_requiresCompleteFile) {
        return _readyToProducePackets;
    }
    
    return _requestCompleted;
}

@end



@implementation _WDAudioMediaLibraryFileProvider

@end

@implementation WDAudioFileProvider
@synthesize audioFile = _audioFile;
@synthesize eventBlock = _eventBlock;
@synthesize cachedPath = _cachedPath;
@synthesize cachedURL = _cachedURL;
@synthesize mimeType = _mimeType;
@synthesize fileExtension = _fileExtension;
@synthesize sha256 = _sha256;
@synthesize mappedData = _mappedData;
@synthesize expectedLength = _expectedLength;
@synthesize receivedLength = _receivedLength;
@synthesize failed = _failed;

+ (instancetype)_fileProviderWithAudioFile:(id <WDAudioFile>)audioFile
{
    if (audioFile == nil) {
        return nil;
    }
    
    NSURL *audioFileURL = [audioFile audioFileURL];
    if (audioFileURL == nil) {
        return nil;
    }
    
    if ([audioFileURL isFileURL]) {
        return [[_WDLocalAudioFileProvider alloc] _initWithAudioFile:audioFile];
    }
#if TARGET_OS_IPHONE
    else if ([[audioFileURL scheme] isEqualToString:@"ipod-library"]) {
        return [[_WDAudioMediaLibraryFileProvider alloc] _initWithAudioFile:audioFile];
    }
#endif /* TARGET_OS_IPHONE */
    else {
        return [[_WDRemoteAudioFileProvider alloc] _initWithAudioFile:audioFile];
    }
}

+ (instancetype)fileProviderWithAudioFile:(id <WDAudioFile>)audioFile
{
    if ((audioFile == gHintFile ||
         [audioFile isEqual:gHintFile]) &&
        gHintProvider != nil) {
        WDAudioFileProvider *provider = gHintProvider;
        gHintFile = nil;
        gHintProvider = nil;
        gLastProviderIsFinished = [provider isFinished];
        
        return provider;
    }
    
    gHintFile = nil;
    gHintProvider = nil;
    gLastProviderIsFinished = NO;
    
    return [self _fileProviderWithAudioFile:audioFile];
}

+ (void)setHintWithAudioFile:(id <WDAudioFile>)audioFile
{
    if (audioFile == gHintFile ||
        [audioFile isEqual:gHintFile]) {
        return;
    }
    
    gHintFile = nil;
    gHintProvider = nil;
    
    if (audioFile == nil) {
        return;
    }
    
    NSURL *audioFileURL = [audioFile audioFileURL];
    if (audioFileURL == nil ||
#if TARGET_OS_IPHONE
        [[audioFileURL scheme] isEqualToString:@"ipod-library"] ||
#endif /* TARGET_OS_IPHONE */
        [audioFileURL isFileURL]) {
        return;
    }
    
    gHintFile = audioFile;
    
    if (gLastProviderIsFinished) {
        gHintProvider = [self _fileProviderWithAudioFile:gHintFile];
    }
}

- (instancetype)_initWithAudioFile:(id <WDAudioFile>)audioFile
{
    self = [super init];
    if (self) {
        _audioFile = audioFile;
    }
    
    return self;
}

- (NSUInteger)downloadSpeed
{
    [self doesNotRecognizeSelector:_cmd];
    return 0;
}

- (BOOL)isReady
{
    [self doesNotRecognizeSelector:_cmd];
    return NO;
}

- (BOOL)isFinished
{
    [self doesNotRecognizeSelector:_cmd];
    return NO;
}


@end





