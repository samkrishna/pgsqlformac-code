//
//  Debug.h
//  PostgreSQL_Server
//
//  Created by neiltiffin on 3/24/14.
//
//

#import <Foundation/Foundation.h>

#ifdef DEBUG
    #define DEBUG_LOG_METHOD [Debug logStuff:[[NSString stringWithUTF8String:__FILE__] lastPathComponent] line:__LINE__ method:NSStringFromSelector(_cmd)];
#else
    #define DEBUG_LOG_METHOD
#endif

#define NSLogRect(r) NSLog(@"%s x=%f, y=%f, w=%f, h=%f", #r, r.origin.x, r.origin.y, r.size.width, r.size.height)

@interface Debug : NSObject

    // call using [Debug debugErrorBreakInCode:@""];
    // will cause the debugger to breakpoint if exception breakpoints are on
+ (void)debugErrorBreakInCode:(NSString *)errorString;

+ (void)logStuff:(NSString *)filename line:(int)line method:(NSString *)method;

@end
