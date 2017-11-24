
//
//  WDAudioPlayerItem.m
//  AuidoDemo
//
//  Created by VD on 2017/11/22.
//  Copyright © 2017年 VD. All rights reserved.
//

#import "WDAudioPlayerItem.h"

@implementation WDAudioPlayerItem
{
    WDAudioFileProvider *_fileProvider;
    WDAudioFilePreprocessor *_filePreprocessor;
    AudioFileID _fileID;
    AudioStreamBasicDescription _fileFormat;
    NSUInteger _bitRate;
    NSUInteger _dataOffset;
    NSUInteger _estimatedDuration;
}
@synthesize fileProvider = _fileProvider;
@synthesize filePreprocessor = _filePreprocessor;
@synthesize fileID = _fileID;
@synthesize fileFormat = _fileFormat;
@synthesize bitRate = _bitRate;
@synthesize dataOffset = _dataOffset;
@synthesize estimatedDuration = _estimatedDuration;

+ (instancetype)playbackItemWithFileProvider:(WDAudioFileProvider *)item
{
    return [[WDAudioPlayerItem alloc]initWithFileProvider:item];
}

- (instancetype)initWithFileProvider:(WDAudioFileProvider *)item
{
    if(self = [super init])
    {
        _fileProvider = item;
        if ([[self audioFile] respondsToSelector:@selector(audioFilePreprocessor)]) {
            _filePreprocessor = [[self audioFile] audioFilePreprocessor];
        }
    }
    return self;
    
}
- (void)dealloc
{
    if([self isOpened])
    {
        [self close];
    }
}

#pragma mark public Methods
static OSStatus audio_file_read(void *inClientData,
                                SInt64 inPosition,
                                UInt32 requestCount,
                                void *buffer,
                                UInt32 *actualCount)
{
    __unsafe_unretained WDAudioPlayerItem *item = (__bridge WDAudioPlayerItem *)inClientData;

    if (inPosition + requestCount > [[item mappedData] length]) {
        if (inPosition >= [[item mappedData] length]) {
            *actualCount = 0;
        }
        else {
            *actualCount = (UInt32)((SInt64)[[item mappedData] length] - inPosition);
        }
    }
    else {
        *actualCount = requestCount;
    }

    if (*actualCount == 0) {
        return noErr;
    }

    if ([item filePreprocessor] == nil) {
        memcpy(buffer, (uint8_t *)[[item mappedData] bytes] + inPosition, *actualCount);
    }
    else {
        NSData *input = [NSData dataWithBytesNoCopy:(uint8_t *)[[item mappedData] bytes] + inPosition
                                             length:*actualCount
                                       freeWhenDone:NO];
        NSData *output = [[item filePreprocessor] handleData:input offset:(NSUInteger)inPosition];
        memcpy(buffer, [output bytes], [output length]);
    }

    return noErr;
}
- (BOOL)isOpened
{
    return _fileID != NULL;
}
- (NSData *)mappedData
{
    return _fileProvider.mappedData;
}

- (NSURL *)cachedURL
{
    return  [_fileProvider cachedURL];
}

- (id<WDAudioFile>)audioFile{
    return [_fileProvider audioFile];
}

static SInt64 audio_file_get_size(void *inClientData)
{
    __unsafe_unretained WDAudioPlayerItem *item = (__bridge WDAudioPlayerItem *)inClientData;
    return (SInt64)[[item mappedData] length];
}


- (BOOL)open
{
    if ([self isOpened]) {
        return YES;
    }
    if (![self _openWithFileTypeHint:0] &&
        ![self _openWithFallbacks]) {
        _fileID = NULL;
        return NO;
    }
    
    if (![self _fillFileFormat] ||
        ![self _fillMiscProperties]) {
        AudioFileClose(_fileID);
        _fileID = NULL;
        return NO;
    }
    
    return YES;
}
- (void)close
{
    if (![self isOpened]) {
        return;
    }
    
    AudioFileClose(_fileID);
    _fileID = NULL;
}

#pragma mark private Methods


- (BOOL)_fillMiscProperties
{
    OSStatus status;
    UInt32 bitRate;
    UInt32 size = sizeof(bitRate);
    status = AudioFileGetProperty(_fileID, kAudioFilePropertyBitRate, &size, &bitRate);
    if(status!=noErr)
    {
        WDLOG(@"%d %s",status,__PRETTY_FUNCTION__);
        return NO;
    }
    _bitRate = bitRate;
    UInt32 dataOffset;
    size = sizeof(dataOffset);
    status = AudioFileGetProperty(_fileID, kAudioFilePropertyDataOffset,&size, &dataOffset);
    if(status!=noErr)
    {
        return NO;
    }
    _dataOffset = dataOffset;
    UInt32 estimatedDuration;
    size = sizeof(estimatedDuration);
    status = AudioFileGetProperty(_fileID, kAudioFilePropertyDataOffset, &size, &estimatedDuration);
    if(status!=noErr)
    {
        return NO;
    }
    _estimatedDuration = estimatedDuration * 1000.0;
    return YES;
}

- (BOOL)_fillFileFormat
{
    UInt32 size;
    OSStatus status;
    
    status = AudioFileGetPropertyInfo(_fileID,kAudioFormatProperty_FormatList, &size, NULL);
    if (status!=noErr) {
        return NO;
    }
    UInt32 numFormats = size/sizeof(AudioFormatListItem);
    AudioFormatListItem * formatList = (AudioFormatListItem *)malloc(size);
    
    status = AudioFileGetProperty(_fileID, kAudioFormatProperty_FormatList,&size,formatList);
    if (status != noErr) {
        free(formatList);
        return NO;
    }
    if(numFormats==1)
    {
       _fileFormat = formatList[0].mASBD;
    }else
    {
        status = AudioFileGetPropertyInfo(_fileID, kAudioFormatProperty_DecodeFormatIDs, &size,NULL);
        if(status!=noErr)
        {
            free(formatList);
            return NO;
        }
        UInt32 numDecoders = size / sizeof(OSType);
        OSType *decoderIDS = (OSType *)malloc(size);
        status = AudioFormatGetProperty(kAudioFormatProperty_DecodeFormatIDs, 0, NULL, &size, decoderIDS);
        if (status != noErr) {
            free(formatList);
            free(decoderIDS);
            return NO;
        }
        UInt32 i;
        for (i = 0; i < numFormats; ++i) {
            OSType decoderID = formatList[i].mASBD.mFormatID;
            
            BOOL found = NO;
            for (UInt32 j = 0; j < numDecoders; ++j) {
                if (decoderID == decoderIDS[j]) {
                    found = YES;
                    break;
                }
            }
            
            if (found) {
                break;
            }
        }
        
        free(decoderIDS);
        
        if (i >= numFormats) {
            free(formatList);
            return NO;
        }
        
        _fileFormat = formatList[i].mASBD;
        
    }
    free(formatList);
    return YES;
    
}

- (BOOL)_openWithFileTypeHint:(AudioFileTypeID)fileTypeHint
{
    OSStatus status;
    status = AudioFileOpenWithCallbacks((__bridge void *)self,
                                        audio_file_read,
                                        NULL,
                                        audio_file_get_size,
                                        NULL,
                                        fileTypeHint,
                                        &_fileID);
    
    return status == noErr;
}
- (BOOL)_openWithFallbacks
{
    NSArray *fallbackTypeIDs = [self _fallbackTypeIDs];
    for (NSNumber *typeIDNumber in fallbackTypeIDs) {
        AudioFileTypeID typeID = (AudioFileTypeID)[typeIDNumber unsignedLongValue];
        if ([self _openWithFileTypeHint:typeID]) {
            return YES;
        }
    }
    
    return NO;
}
- (NSArray *)_fallbackTypeIDs
{
    NSMutableArray *fallbackTypeIDs = [NSMutableArray array];
    NSMutableSet *fallbackTypeIDSet = [NSMutableSet set];
    
    struct {
        CFStringRef specifier;
        AudioFilePropertyID propertyID;
    } properties[] = {
        { (__bridge CFStringRef)[_fileProvider mimeType], kAudioFileGlobalInfo_TypesForMIMEType },
        { (__bridge CFStringRef)[_fileProvider fileExtension], kAudioFileGlobalInfo_TypesForExtension }
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




@end
