/* vim: set ft=objc fenc=utf-8 sw=2 ts=2 et: */
/*
 *  WDAudioStreamer - A Core Audio based streaming audio player for iOS/Mac:
 *
 *      https://github.com/douban/WDAudioStreamer
 *
 *  Copyright 2013-2016 Douban Inc.  All rights reserved.
 *
 *  Use and distribution licensed under the BSD license.  See
 *  the LICENSE file for full text.
 *
 *  Authors:
 *      Chongyu Zhu <i@lembacon.com>
 *
 */

#import "WDAudioSpatialAnalyzer.h"
#import "WDAudioAnalyzer_Private.h"

@implementation WDAudioSpatialAnalyzer

- (void)processChannelVectors:(const float *)vectors toLevels:(float *)levels
{
  for (size_t i = 0; i < kWDAudioAnalyzerLevelCount; ++i) {
    levels[i] = vectors[kWDAudioAnalyzerCount * i / kWDAudioAnalyzerLevelCount];
  }
}

@end
