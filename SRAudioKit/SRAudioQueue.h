//
//  SRAudioQueue.h
//  SRAudioKitDemoForOSX
//
//  Created by Heeseung Seo on 2015. 2. 9..
//  Copyright (c) 2015년 Seorenn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SRAudioQueue : NSObject

@property (nonatomic, strong) NSURL *outputFileURL;

- (void)start;
- (void)stop;

@end
