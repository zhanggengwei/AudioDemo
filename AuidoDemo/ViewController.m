//
//  ViewController.m
//  AuidoDemo
//
//  Created by VD on 2017/11/22.
//  Copyright © 2017年 VD. All rights reserved.
//

#import "ViewController.h"
#import "WDSimpleHTTPRequest.h"

@interface ViewController ()
@property (nonatomic,strong) WDSimpleHTTPRequest * manager;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.manager = [WDSimpleHTTPRequest requestWithURL:[NSURL URLWithString:@"http://mr1.doubanio.com/27fb317e112de158a9d52293d18e7b14/0/fm/song/p372_128k.mp4"]];
 
    [_manager setCompletedBlock:^{
        NSLog(@"complete");
       // [_self _requestDidComplete];
    }];
    
    [_manager setProgressBlock:^(double downloadProgress) {
         NSLog(@"progress %f",downloadProgress);
    }];
    
    [_manager setDidReceiveResponseBlock:^{
      
    }];
    
    [_manager setDidReceiveDataBlock:^(NSData *data) {
         NSLog(@"data==%@",data);
    }];
    [self.manager start];
    
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
