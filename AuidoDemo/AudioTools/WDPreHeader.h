//
//  WDPreHeader.h
//  RunTime
//
//  Created by VD on 2017/11/20.
//  Copyright © 2017年 VD. All rights reserved.
//

#ifndef WDPreHeader_h
#define WDPreHeader_h

#ifdef DEBUG
#define WDLOG(...)  NSLog(__VA_ARGS__)
#else
define WDLOG(...)
#endif

#ifndef STR
#define STR(s) [NSString stringWithFormat:@"%s",s]
#endif



#endif /* WDPreHeader_h */
