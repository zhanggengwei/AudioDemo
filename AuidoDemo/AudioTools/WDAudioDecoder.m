
//
//  WDAudioDecoder.m
//  AuidoDemo
//
//  Created by VD on 2017/11/22.
//  Copyright © 2017年 VD. All rights reserved.
//

#import "WDAudioDecoder.h"
#import "WDPreHeader.h"

typedef struct {
    AudioFileID afid;
    SInt64 pos;
    void *srcBuffer;
    UInt32 srcBufferSize;
    AudioStreamBasicDescription srcFormat;
    UInt32 srcSizePerPacket;
    UInt32 numPacketsPerRead;
    AudioStreamPacketDescription *pktDescs;
} AudioFileIO;

typedef struct {
    AudioStreamBasicDescription inputFormat;
    AudioStreamBasicDescription outputFormat;
    
    AudioFileIO afio;
    
    SInt64 decodeValidFrames;
    AudioStreamPacketDescription *outputPktDescs;
    
    UInt32 outputBufferSize;
    void *outputBuffer;
    
    UInt32 numOutputPackets;
    SInt64 outputPos;
    
    pthread_mutex_t mutex;
} DecodingContext;

@implementation WDAudioDecoder
{
    AudioConverterRef _audioConvert;
    AudioStreamBasicDescription _outputFormat;
    WDAudioLPCM * _lpcm;
    NSInteger _bufferSize;
    WDAudioPlayerItem * _playbackItem;
    DecodingContext _decoderContext;
    BOOL _decodingContextInitialized;
}
+ (AudioStreamBasicDescription)defaultOutputFormat
{
    static AudioStreamBasicDescription output;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        output.mFormatID = kAudioFormatLinearPCM;
        output.mSampleRate = 44100;
        output.mChannelsPerFrame = 2;
        
        output.mBytesPerFrame = output.mChannelsPerFrame * (output.mBitsPerChannel / 8);
        
        output.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger|kLinearPCMFormatFlagIsPacked;
        
        output.mBytesPerPacket = output.mFramesPerPacket * output.mBytesPerFrame;
        
        output.mBitsPerChannel = 16;
        output.mFramesPerPacket = 1;
        
        
    });
    return output;
}

- (instancetype)initWithPlaybackItem:(WDAudioPlayerItem *)playbackItem bufferSize:(NSUInteger)bufferSize
{
    if(self = [super init])
    {
        _outputFormat = [self.class defaultOutputFormat];
        _playbackItem = playbackItem;
        _bufferSize =  bufferSize;
        _lpcm = [WDAudioLPCM new];
        [self _createAudioConverter];
    }
    return self;
}

- (void)dealloc
{
    if(_audioConvert)
    {
        AudioConverterDispose(_audioConvert);
    }
}


- (void)_createAudioConverter
{
    AudioStreamBasicDescription inputFormat = [_playbackItem fileFormat];
    OSStatus status = AudioConverterNew(&inputFormat,&_outputFormat, &_audioConvert);
    if(status!=noErr)
    {
        _audioConvert = NULL;
        WDLOG(@"%s error =%d line = %d",__PRETTY_FUNCTION__,status,__LINE__);
        return;
    }
}
- (void)_fillMagicCookieForAudioFileID:(AudioFileID)inputFile
{
    UInt32 cookieSize = 0;
    OSStatus status = AudioFileGetPropertyInfo(inputFile, kAudioFilePropertyMagicCookieData, &cookieSize, NULL);
    if((status!=noErr)&&cookieSize)
    {
        void * property = malloc(cookieSize);
        status = AudioFileGetProperty(inputFile, kAudioFilePropertyMagicCookieData, &cookieSize, property);
        if(status!=noErr)
        {
            status = AudioConverterSetProperty(_audioConvert, kAudioFilePropertyMagicCookieData, cookieSize, property);
        }
        free(property);
    }
}

@end
