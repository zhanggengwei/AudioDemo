//
//  WDHTTPRequest.m
//  AuidoDemo
//
//  Created by VD on 2017/11/23.
//  Copyright © 2017年 VD. All rights reserved.
//

#import "WDHTTPRequest.h"
#include <sys/types.h>
#include <sys/sysctl.h>
#include <pthread.h>
static struct
{
    pthread_cond_t cond;
    pthread_mutex_t mutex;
    pthread_t thread;
    CFRunLoopRef runLoop;
    
}controller;

static void * main_controller(void * data)
{
    pthread_setname_np("wd-thread-");
    pthread_mutex_lock(&controller.mutex);
    controller.runLoop = CFRunLoopGetCurrent();
    pthread_mutex_unlock(&controller.mutex);
    pthread_cond_signal(&controller.cond);
    
    
    CFRunLoopSourceContext context;
    bzero(&context, sizeof(context));
    CFRunLoopSourceRef source = CFRunLoopSourceCreate(kCFAllocatorDefault, 0, &context);
    CFRunLoopAddSource(controller.runLoop,source,kCFRunLoopDefaultMode);
    CFRunLoopRun();
    CFRunLoopRemoveSource(controller.runLoop, source, kCFRunLoopDefaultMode);
    
    CFRelease(source);
    pthread_mutex_destroy(&controller.mutex);
    pthread_cond_destroy(&controller.cond);
    
    return NULL;
};

static CFRunLoopRef controller_get_runloop()
{
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        pthread_mutex_init(&controller.mutex, NULL);
        pthread_cond_init(&controller.cond, NULL);
        controller.runLoop = NULL;
        pthread_create(&controller.thread, NULL, main_controller, NULL);
       
        pthread_mutex_lock(&controller.mutex);
        if (controller.runLoop == NULL) {
            pthread_cond_wait(&controller.cond, &controller.mutex);
        }
        pthread_mutex_unlock(&controller.mutex);

    });
    return controller.runLoop;
};

@implementation WDHTTPRequest

@end
