
#import "WDAudioAnalyzer.h"
#import "WDAudioAnalyzer_Private.h"
#include <Accelerate/Accelerate.h>
#include <pthread.h>
#include <mach/mach_time.h>

@interface WDAudioAnalyzer () {
@private
  int16_t _sampleBuffer[kWDAudioAnalyzerSampleCount];
  struct {
    float sample[kWDAudioAnalyzerSampleCount];
    float left[kWDAudioAnalyzerCount];
    float right[kWDAudioAnalyzerCount];
  } _vectors;

  struct {
    float left[kWDAudioAnalyzerLevelCount];
    float right[kWDAudioAnalyzerLevelCount];
    float overall[kWDAudioAnalyzerLevelCount];
  } _levels;

  uint64_t _interval;
  uint64_t _lastTime;

  BOOL _enabled;
  pthread_mutex_t _mutex;
}
@end

@implementation WDAudioAnalyzer

@synthesize enabled = _enabled;

+ (instancetype)analyzer
{
  return [[self alloc] init];
}

- (id)init
{
  self = [super init];
  if (self) {
    _enabled = NO;
    pthread_mutex_init(&_mutex, NULL);

    _lastTime = 0;
    [self setInterval:0.1];

    [self flush];
  }

  return self;
}

- (void)dealloc
{
  pthread_mutex_destroy(&_mutex);
}

- (void)handleLPCMSamples:(int16_t *)samples count:(NSUInteger)count
{
  pthread_mutex_lock(&_mutex);

  if (samples == NULL ||
      count == 0) {
    pthread_mutex_unlock(&_mutex);
    return;
  }

  if (!_enabled) {
    pthread_mutex_unlock(&_mutex);
    return;
  }

  uint64_t currentTime = mach_absolute_time();
  if (currentTime - _lastTime < _interval) {
    pthread_mutex_unlock(&_mutex);
    return;
  }
  else {
    _lastTime = currentTime;
  }

  if (count >= kWDAudioAnalyzerSampleCount) {
    [self _analyzeLinearPCMSamples:samples];
  }
  else {
    memcpy(_sampleBuffer, samples, sizeof(int16_t) * count);
    memset(_sampleBuffer + count, 0, sizeof(int16_t) * (kWDAudioAnalyzerSampleCount - count));
    [self _analyzeLinearPCMSamples:_sampleBuffer];
  }

  pthread_mutex_unlock(&_mutex);
}

- (void)flush
{
  pthread_mutex_lock(&_mutex);
  vDSP_vclr(_levels.overall, 1, kWDAudioAnalyzerLevelCount);
  pthread_mutex_unlock(&_mutex);
}

+ (double)_absoluteTimeConversion
{
  static double conversion;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    mach_timebase_info_data_t info;
    mach_timebase_info(&info);
    conversion = 1.0e-9 * info.numer / info.denom;
  });

  return conversion;
}

- (NSTimeInterval)interval
{
  return [[self class] _absoluteTimeConversion] * _interval;
}

- (void)setInterval:(NSTimeInterval)interval
{
  pthread_mutex_lock(&_mutex);
  _interval = (uint64_t)llrint(round(interval / [[self class] _absoluteTimeConversion]));
  pthread_mutex_unlock(&_mutex);
}

- (void)setEnabled:(BOOL)enabled
{
  if (_enabled != enabled) {
    pthread_mutex_lock(&_mutex);
    _enabled = enabled;
    pthread_mutex_unlock(&_mutex);
  }
}

- (void)copyLevels:(float *)levels
{
  pthread_mutex_lock(&_mutex);
  if (levels != NULL) {
    memcpy(levels, _levels.overall, sizeof(float) * kWDAudioAnalyzerLevelCount);
  }
  pthread_mutex_unlock(&_mutex);
}

- (void)_analyzeLinearPCMSamples:(const int16_t *)samples
{
  [self _splitStereoSamples:samples];

  [self processChannelVectors:_vectors.left toLevels:_levels.left];
  [self processChannelVectors:_vectors.right toLevels:_levels.right];

  [self _updateLevels];
}

- (void)_splitStereoSamples:(const int16_t *)samples
{
  static const float scale = INT16_MAX;
  vDSP_vflt16((int16_t *)samples, 1, _vectors.sample, 1, kWDAudioAnalyzerSampleCount);
  vDSP_vsdiv(_vectors.sample, 1, (float *)&scale, _vectors.sample, 1, kWDAudioAnalyzerSampleCount);

  DSPSplitComplex complexSplit;
  complexSplit.realp = _vectors.left;
  complexSplit.imagp = _vectors.right;

  vDSP_ctoz((const DSPComplex *)_vectors.sample, 2, &complexSplit, 1, kWDAudioAnalyzerCount);
}

- (void)_updateLevels
{
  static const float scale = 2.0f;
  vDSP_vadd(_levels.left, 1, _levels.right, 1, _levels.overall, 1, kWDAudioAnalyzerLevelCount);
  vDSP_vsdiv(_levels.overall, 1, (float *)&scale, _levels.overall, 1, kWDAudioAnalyzerLevelCount);

  static const float min = 0.0f;
  static const float max = 1.0f;
  vDSP_vclip(_levels.overall, 1, (float *)&min, (float *)&max, _levels.overall, 1, kWDAudioAnalyzerLevelCount);
}

- (void)processChannelVectors:(const float *)vectors toLevels:(float *)levels
{
  [self doesNotRecognizeSelector:_cmd];
}

@end
