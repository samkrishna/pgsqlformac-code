//
//  PGSQLDispatch.m
//  PGSQLKit-Neil
//
//  Created by Neil Tiffin on 1/6/12.
//  Copyright (c) 2012 Performance Champions, Inc. All rights reserved.
//

// Values for __MAC_10_6 and __IPHONE_4_0 are used in case this code is compiled on systems
// where they are not defined and therfor will be evaluated as zero.
#if (MAC_OS_X_VERSION_MIN_REQUIRED >= 1060) || (__IPHONE_OS_VERSION_MIN_REQUIRED >= 40000)

#import "libpq-fe.h"

#import "PGSQLDispatch.h"
#import "PGSQLDispatchConnection.h"
#import "PGSQLConnection.h"
#import "PGSQLRecordset.h"

// Private Interface
@interface PGSQLDispatch ()

@property (nonatomic, retain) NSMutableArray *sqlConnections;

- (BOOL)addAConnectionToDispatcher:(PGSQLConnection *)connToClone;

@end

@implementation PGSQLDispatch

#pragma mark -
#pragma mark Property Accessors

@synthesize sqlConnections;
@synthesize maxNumberConnections;

-(void)setMaxNumberConnections:(NSUInteger)max
{
    if ((max > 0) && (max <= 30))
    {
        maxNumberConnections = max;
    }
}

#pragma mark -
#pragma mark Dispatch Methods

- (NSInteger)findNextIndexToDispatch
{    
    NSAssert(self.sqlConnections != nil, @"self.sqlConnections == nil");

    NSUInteger indexOfNextDispatch = 0;
    // Find the first non-busy connections and use it.
    for (indexOfNextDispatch = 0; indexOfNextDispatch < [sqlConnections count]; indexOfNextDispatch++)
    {
        PGSQLDispatchConnection *aConn = [sqlConnections objectAtIndex:indexOfNextDispatch];
        if ([[aConn queueWaitingCount] intValue] == 0)
        {
            //then use this one
            break;
        }
    }
    
    // Check to make sure we found a non-busy connection.
    if (indexOfNextDispatch == [sqlConnections count])
    {
        // Did not find non-busy connection so try to add a connection
        PGSQLConnection *connectionToClone = nil;
        if ([sqlConnections count] > 0)
        {
            connectionToClone = [sqlConnections objectAtIndex:0];
        }
        else
        {
            connectionToClone = [PGSQLConnection defaultConnection];
        }
        if ([self addAConnectionToDispatcher:connectionToClone])
        {
            // Successful add. Remember init adds the first connection so no need to check for underflow.
            // Set dispatcher to use the new connection.
            // Here we can use count because the connection would not have been added otherwise.
            indexOfNextDispatch = [sqlConnections count] - 2;
        }
        else
        {
            // Was not able to add connection so just do round robin add to a busy queue.
            // Don't use size of the connections array as the number of connections may have been reduced.
            indexOfNextDispatch = indexOfLastDispatch < (self.maxNumberConnections - 1) ? indexOfLastDispatch++ : 0;
        }
    }
    return indexOfNextDispatch;
}

- (NSInteger)processResultsFromSQL:(NSString *)sql usingCallbackBlock:(void (^)(PGSQLRecordset *))callbackBlock
{
    NSAssert(self.sqlConnections != nil, @"self.sqlConnections == nil");
    
    // cant process unless we have at least 1 connection.
    if ([sqlConnections count] < 1)
    {
        return 1;
    }
    else
    {
        NSUInteger indexOfNextDispatch = [self findNextIndexToDispatch];
        
        // Now we know which connection to use so dispatch SQL.
        PGSQLDispatchConnection *aConnection = [sqlConnections objectAtIndex:indexOfNextDispatch];
        dispatch_queue_t connectionQueue = aConnection.connectionQueue;
        
        [aConnection incConnectionStatistics];
        
        // ***************
        // Actual dispatch
        // ***************
        dispatch_async(connectionQueue, ^{
            BOOL connectionCheck = [aConnection checkAndRecoverConnection];
            if (connectionCheck == CONNECTION_BAD)
            {
                // Don't even try.
                dispatch_async(dispatch_get_main_queue(), ^{
                    callbackBlock(nil);
                    [aConnection decConnectionStatistics];
                });
            }
            else
            {
                PGSQLRecordset *resultsRecordSet = [aConnection open:sql];
                dispatch_async(dispatch_get_main_queue(), ^{
                    callbackBlock(resultsRecordSet);
                    [aConnection decConnectionStatistics];
                });
            }
        });
        indexOfLastDispatch = indexOfNextDispatch;
    }
    return 0;
}

- (BOOL)addAConnectionToDispatcher:(PGSQLConnection *)connToClone;
{
    NSAssert(self.sqlConnections != nil, @"self.sqlConnections == nil");
    
    if ([sqlConnections count] < self.maxNumberConnections)
    {
        if (connToClone != nil)
        {
            NSString *qName = [NSString stringWithFormat:@"PGSQLKit.dispatchQueue%d", (int)[sqlConnections count] + 1];
            PGSQLDispatchConnection *aConnection = [[PGSQLDispatchConnection alloc] initWithQueueName:qName connection:connToClone];
            [sqlConnections addObject:aConnection];
            [aConnection release];
            return YES;
        }
    }
    else if ([sqlConnections count] > self.maxNumberConnections)
    {
        // Need to remove connection
#warning Need to complete code to remove connection.
    }
        
    return NO; 
}

#pragma mark -
#pragma mark Lifecycle Methods

- (id)initWithConnection:(PGSQLConnection *)conn
{
    self = [super init];
    if (self)
    {
        if (PQisthreadsafe() == 1)
        {
            // libpq appears to be thread safe.
            self.sqlConnections = [[[NSMutableArray alloc] init] autorelease];
            NSUInteger processorCount = [[NSProcessInfo processInfo] processorCount];
            maxNumberConnections = processorCount < 2 ? 1 : processorCount - 1;
            indexOfLastDispatch = NSUIntegerMax;  // this is set high to force a reset to zero for the first dispatch.
            if (conn != nil)
            {
                if (![self addAConnectionToDispatcher:conn])
                {
                    NSLog(@"%@ %s - Warning, not able to add first connection.", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __func__);
                }
            }
            else
            {
                NSLog(@"%@ %s - Warning, a default connection has not been established.", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __func__);
            }
            // All OK.
            return self;
        }
        else
        {
            NSLog(@"%@ %s - Error, libpq is not threadsafe.", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __func__);
        }
    }
    
    // Initialization has failed.
    [self release];
    self = nil;
    return self;
}

+ (PGSQLDispatch *)sharedPGSQLDispatch
{
    static dispatch_once_t pred = 0;
    static PGSQLDispatch * _sharedPGSQLDispatch = nil;
    
    dispatch_once(&pred, ^{
        _sharedPGSQLDispatch = [[self alloc] initWithConnection:[PGSQLConnection defaultConnection]];
    });
    return _sharedPGSQLDispatch;
}

- (id)init
{
    return [self initWithConnection:[PGSQLConnection defaultConnection]];
}


- (void)dealloc
{
    self.sqlConnections = nil;
    [super dealloc];
}

@end
#endif
