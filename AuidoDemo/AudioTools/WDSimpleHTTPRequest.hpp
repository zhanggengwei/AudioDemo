//
//  WDSimpleHTTPRequest.hpp
//  AuidoDemo
//
//  Created by VD on 2017/11/23.
//  Copyright © 2017年 VD. All rights reserved.
//

#ifndef WDSimpleHTTPRequest_hpp
#define WDSimpleHTTPRequest_hpp

#include <stdio.h>
#include <iostream>
#include <Foundation/Foundation.h>




using namespace std;
class WDSimpleHTTPRequest {
public:
    NSUInteger timeoutInterval;
    NSString * userAgent;
    NSString * host;
    WDSimpleHTTPRequest(NSURL * url);
    
    static NSInteger defaultTimeoutInterval();
    static NSString * defaultUserAgent;
    
    NSData * getResponseData();
    NSString * getResponseString();
    NSString * getStatusMessage();
    NSDictionary * getResponseHeaders();
    NSUInteger getResponseContentLength();
    NSUInteger getStatusCode();
    NSUInteger getDownloadSpeed();
    BOOL getFailed();
    
    void start();
    void cancel();
    
    
    
};

#endif /* WDSimpleHTTPRequest_hpp */
