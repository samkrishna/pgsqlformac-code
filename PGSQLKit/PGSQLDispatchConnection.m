//
//  PGSQLDispatchConnection.m
//  PGSQLKit-Neil
//
//  Created by Neil Tiffin on 1/7/12.
//  Copyright (c) 2012 Performance Champions, Inc. All rights reserved.
//

// Values for __MAC_10_6 and __IPHONE_4_0 are used in case this code is compiled on systems
// where they are not defined and therefore will be evaluated as zero.
#if (MAC_OS_X_VERSION_MIN_REQUIRED >= 1060) || (__IPHONE_OS_VERSION_MIN_REQUIRED >= 40000)

#import "PGSQLDispatchConnection.h"
#import "libpq-fe.h"

@interface PGSQLDispatchConnection ()

@property (retain, readwrite) NSNumber *queueWaitingCount;

@end

@implementation PGSQLDispatchConnection

#pragma mark -
#pragma mark Accessors

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
#pragma mark Dispatch Methods
- (void)processResultsFromSQL:(NSString *)sql 
           usingCallbackBlock:(void (^)(PGSQLRecordset *, NSString *))callbackBlock
{    
    [self incConnectionStatistics];
    [callbackBlock retain];
    
    dispatch_async(self.connectionQueue, ^{
        PGSQLConnectionCheckType connectionCheck = [self checkAndRecoverConnection];
        if (connectionCheck == PGSQLConnectionCheckOK)
        {
            // Process SQL.
            __block PGSQLRecordset *resultsRecordSet = [[self open:sql] retain];
            
            // Get any error.
            NSString *myErrorDescription = nil;
            if (self.errorDescription != nil)
            {
                myErrorDescription = [self.errorDescription copy];
            }
            
            //const char *queueName = dispatch_queue_get_label(dispatch_get_current_queue());
            //NSLog(@"%s Results Recordset: %@", queueName, resultsRecordSet);
            //NSLog(@"%s Results Error String: %@", queueName, errorDescription);
            
            // Process the callback.
            dispatch_queue_t mainQueue = dispatch_get_main_queue();
            dispatch_async(mainQueue, ^{
                //NSLog(@"Processing Good Connection Callback Recordset: %@", resultsRecordSet);
                //NSLog(@"Processing Good Connection Callback Error String: %@", errorDescription);
                callbackBlock(resultsRecordSet, myErrorDescription);
                [self decConnectionStatistics];
                [resultsRecordSet release];
                [myErrorDescription release];
                [callbackBlock release];
            });
        }
        else
        {
            // Connection is bad so don't even try to process SQL, just callback with error and nil results.
            // Get any error.
            NSString *myErrorDescription = nil;
            if (self.errorDescription != nil)
            {
                myErrorDescription = [self.errorDescription copy];
            }
            
            // Process the callback.
            dispatch_queue_t mainQueue = dispatch_get_main_queue();
            dispatch_async(mainQueue, ^{
                //NSLog(@"Processing Bad Connection Callback with Error: %@", errorDescription);
                callbackBlock(nil, myErrorDescription);
                [self decConnectionStatistics];
                [myErrorDescription release];
                [callbackBlock release];
            });
        }
    });
}

#pragma mark -
#pragma mark Lifecycle Methods

- (id)initWithQueueName:(NSString *)queueName connection:(PGSQLConnectionBase *)connection
{
    self = [super init];
    if (self)
    {
#if (MAC_OS_X_VERSION_MIN_REQUIRED >= 1070)
        connectionQueue = dispatch_queue_create([queueName cStringUsingEncoding:[NSString defaultCStringEncoding]], DISPATCH_QUEUE_SERIAL);
#else
        connectionQueue = dispatch_queue_create([queueName cStringUsingEncoding:[NSString defaultCStringEncoding]], NULL);
#endif
        // dispatch_set_target_queue(<#dispatch_object_t object#>, <#dispatch_queue_t queue#>);
        self.queueWaitingCount = [NSNumber numberWithInt:0];
        if (connection)
        {
            [self setServer:[connection server]];
            [self setPort:[connection port]]; 
            [self setUserName:[connection userName]];
            [self setPassword:[connection password]];
            [self setDatabaseName:[connection databaseName]];
            [self setDefaultEncoding:[connection defaultEncoding]];
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
            NSLog(@"%@ %s - Error, connection passed as parameter is nil.", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __func__);
        }
    }
    [self release];
    self = nil;
    return self;
}

// For completeness, should not be used as queues should have unique names.
- (id)init
{
    return [self initWithQueueName:@"PGSQLKit.MyQueue" connection:[PGSQLConnectionBase defaultConnection]];
}


- (void)dealloc
{
    dispatch_release(connectionQueue);
    self.queueWaitingCount = nil;
    [super dealloc];
}

@end
#endif
