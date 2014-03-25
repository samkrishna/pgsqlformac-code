//
//  Debug.m
//  PostgreSQL_Server
//
//  Created by neiltiffin on 3/24/14.
//  Copyright 2014 Performance Champions, Inc.
//  All rights reserved except full permission to use is given to Andy Satori and Druware Software Designs.
//

#import "Debug.h"

#ifdef DEBUG
    #ifdef NS_BLOCK_ASSERTIONS
        #error Block Assertions is defined.
    #endif

#else
    #ifndef NS_BLOCK_ASSERTIONS
        #error Block Assertions is not defined.
    #endif
#endif

@implementation Debug

    // call using [Debug debugErrorBreakInCode:@""];
    // will cause the debugger to breakpoint if exception breakpoins are on
+ (void)debugErrorBreakInCode:(NSString *)errorString
{
#ifdef DEBUG
    [NSException raise:@"Debug Error" format:@"%@", errorString];
#else
    return;
#endif
}

+ (void)logStuff:(NSString *)filename line:(int)line method:(NSString *)method;
{
    NSLog(@"<%@:%d:%@>",filename, line, method);
}

@end
