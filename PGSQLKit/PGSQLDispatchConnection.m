//
//  PGSQLDispatchConnection.m
//  PGSQLKit-Neil
//
//  Created by Neil Tiffin on 1/7/12.
//  Copyright (c) 2012 Performance Champions, Inc. All rights reserved.
//

// Values for __MAC_10_6 and __IPHONE_4_0 are used in case this code is compiled on systems
// where they are not defined and therfor will be evaluated as zero.
#if (MAC_OS_X_VERSION_MIN_REQUIRED >= 1060) || (__IPHONE_OS_VERSION_MIN_REQUIRED >= 40000)

#import "PGSQLDispatchConnection.h"
#import "libpq-fe.h"

@interface PGSQLDispatchConnection ()

@property (retain, readwrite) NSNumber *queueWaitingCount;

@end

@implementation PGSQLDispatchConnection

#pragma mark -
#pragma mark Accessors Methods

@synthesize connectionQueue;
@synthesize queueWaitingCount;

#pragma mark -
#pragma mark Statistics Methods

- (void)incConnectionStatistics
{
    // Increment queue counter    
     self.queueWaitingCount = [NSNumber numberWithInt:[queueWaitingCount intValue] + 1];
}

- (void)decConnectionStatistics
{    
    // Decrement queue counter
    self.queueWaitingCount = [NSNumber numberWithInt:[queueWaitingCount intValue] - 1];
}

#pragma mark -
#pragma mark Lifecycle Methods

- (id)initWithQueueName:(NSString *)queueName connection:(PGSQLConnection *)connection
{
    self = [super init];
    if (self) {
        connectionQueue = dispatch_queue_create([queueName cStringUsingEncoding:[NSString defaultCStringEncoding]], NULL);
        self.queueWaitingCount = [NSNumber numberWithInt:0];
        if (connection)
        {
            [self setServer:[connection server]];
            [self setPort:[connection port]]; 
            [self setUserName:[connection userName]];
            [self setPassword:[connection password]];
            [self setDatabaseName:[connection databaseName]];
            if ([self connect])
            {
                // init complete.
                return self;
            }
            else
            {
                NSLog(@"%@ %s - Error, not able to open connection.", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __func__);
            }
        }
        else
        {
            NSLog(@"%@ %s - Error, defaultConnection has not been established.", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __func__);
        }
    }
    [self release];
    self = nil;
    return self;
}

- (id)init
{
    return [self initWithQueueName:@"PGSQLKit.MyQueue" connection:[PGSQLConnection defaultConnection]];
}


- (void)dealloc
{
    dispatch_release(connectionQueue);
    queueWaitingCount = nil;
    [super dealloc];
}

@end
#endif
