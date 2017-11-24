/* vim: set ft=objc fenc=utf-8 sw=2 ts=2 et: */
/*
 *  WDAudioStreamer - A Core Audio based streaming audio player for iOS/Mac:
 *
 *      https://github.com/WDban/WDAudioStreamer
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

#if TARGET_OS_IPHONE

#import "WDEAGLView.h"

typedef NS_ENUM(NSUInteger, WDAudioVisualizerInterpolationType) {
  WDAudioVisualizerLinearInterpolation,
  WDAudioVisualizerSmoothInterpolation
};

@interface WDAudioVisualizer : WDEAGLView

@property (nonatomic, assign) NSUInteger stepCount;
@property (nonatomic, assign) WDAudioVisualizerInterpolationType interpolationType;

@end

#endif /* TARGET_OS_IPHONE */
