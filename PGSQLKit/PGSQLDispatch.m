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

- (BOOL)addConnectionToDispatcher:(PGSQLConnection *)connToClone;
- (void)removeConnectionFromDispatcher;

@end

@implementation PGSQLDispatch

#pragma mark -
#pragma mark Property Accessors

@synthesize sqlConnections;
@synthesize maxNumberConnections;
@synthesize queryTimeoutSeconds;

-(void)setMaxNumberConnections:(NSUInteger)max
{
    if ((max > 0) && (max <= 30))
    {
        maxNumberConnections = max;
    }
}

#pragma mark -
#pragma mark Dispatch Methods

- (NSInteger)findNextIndexToDispatch:(BOOL)longRunning
{    
    NSAssert(self.sqlConnections != nil, @"self.sqlConnections == nil");

#warning Need to implement longRunning
    
    // See if we need to remove connections.  If not no harm.
    //[self removeConnectionFromDispatcher];
    
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
        if ([self addConnectionToDispatcher:connectionToClone])
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


- (PGSQLDispatchError_t)processResultsFromSQL:(NSString *)sql 
                                    longRunning:(BOOL)longRunning
                             usingCallbackBlock:(void (^)(PGSQLRecordset *, NSString *))callbackBlock
{
    NSAssert(self.sqlConnections != nil, @"self.sqlConnections == nil");
    
    // cant process unless we have at least 1 connection.
    if ([sqlConnections count] < 1)
    {
        return PGSQLDispatchErrorNoAvailableConnections;
    }
    else
    {
        NSUInteger indexOfNextDispatch = [self findNextIndexToDispatch:longRunning];
        
        // Now we know which connection to use so dispatch SQL.
        __block PGSQLDispatchConnection *aConnection = [[sqlConnections objectAtIndex:indexOfNextDispatch] retain];
        NSAssert(aConnection.connectionQueue != NULL, @"aConnection.connectionQueue != NULL");
                
        [aConnection incConnectionStatistics];

        [callbackBlock retain];
        
        // ***************
        // Actual dispatch
        // ***************
        dispatch_async(aConnection.connectionQueue, ^{
            //dispatch_retain(currentDispatchQueue);
            PGSQLConnectionCheckType connectionCheck = [aConnection checkAndRecoverConnection];
            if (connectionCheck == PGSQLConnectionCheckOK)
            {
                // Process SQL.
                __block PGSQLRecordset *resultsRecordSet = [[aConnection open:sql] retain];
                
                // Get any error.
                __block NSString *errorDescription = [aConnection.errorDescription copy];
                
                NSLog(@"Results Recordset: %@", resultsRecordSet);
                NSLog(@"Results Error String: %@", errorDescription);
                
                // Process the callback.
                dispatch_queue_t mainQueue = dispatch_get_main_queue();
                dispatch_async(mainQueue, ^{
                    NSLog(@"Processing Good Connection Callback Recordset: %@", resultsRecordSet);
                    NSLog(@"Processing Good Connection Callback Error String: %@", errorDescription);
                    callbackBlock(resultsRecordSet, errorDescription);
                    [aConnection decConnectionStatistics];
                    [resultsRecordSet release];
                    [errorDescription release];
                    [aConnection release];
                    [callbackBlock release];
                });
            }
            else
            {
                // Connection is bad so don't even try, just callback with error and nil results.
                __block NSString *errorDescription = [aConnection.errorDescription copy];
                                
                // Process the callback.
                dispatch_queue_t mainQueue = dispatch_get_main_queue();
                dispatch_async(mainQueue, ^{
                    NSLog(@"Processing Bad Connection Callback with Error: %@", errorDescription);
                    callbackBlock(nil, errorDescription);
                    [aConnection decConnectionStatistics];
                    [errorDescription release];
                    [aConnection release];
                    [callbackBlock release];
                });
            }
        });
        indexOfLastDispatch = indexOfNextDispatch;
    }
    return PGSQLDispatchErrorNone;
}

- (void)removeConnectionFromDispatcher
{
    if ([sqlConnections count] > self.maxNumberConnections)
    {
        PGSQLDispatchConnection *lastConn = [sqlConnections lastObject];
        if ([[lastConn queueWaitingCount] intValue] == 0)
        {
            // Ok to remove
            [sqlConnections removeLastObject];
        }
    }
}

- (BOOL)addConnectionToDispatcher:(PGSQLConnection *)connToClone;
{
    NSAssert(self.sqlConnections != nil, @"self.sqlConnections == nil");
    
    if ([sqlConnections count] < self.maxNumberConnections)
    {
        // Need to add connection.
        if (connToClone != nil)
        {
            NSString *qName = [NSString stringWithFormat:@"com.postgresqlformac.PGSQLKit.DispatchSQLQueue%d", (int)[sqlConnections count] + 1];
            PGSQLDispatchConnection *aConnection = [[PGSQLDispatchConnection alloc] initWithQueueName:qName connection:connToClone];
            if(aConnection == nil)
            {
                NSAssert(0, @"aConnection == nil while attempting to add connection.");
                return NO;
            }
            [sqlConnections addObject:aConnection];
            NSLog(@"Added Connection with queue name: %@", qName);
            [aConnection release];
            return YES;
        }
    }        
    return NO; 
}

- (NSString *)stringDescriptionForErrorNumber:(NSInteger)error;
{
    switch (error)
    {
        case PGSQLDispatchErrorNone:
            return nil;
        case PGSQLDispatchErrorNoAvailableConnections:
            return @"No available connections.";
        default:
            return @"Error Not defined.";
    }
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
                if (![self addConnectionToDispatcher:conn])
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

#ifdef DEBUG
#pragma mark -
#pragma mark Debug Methods

- (NSUInteger)totalQueuedBlocks
{
    NSAssert(self.sqlConnections != nil, @"self.sqlConnections == nil");
    NSUInteger result = 0;
    for (PGSQLDispatchConnection *c in self.sqlConnections)
    {
        NSNumber *queWaitingCount = [c queueWaitingCount];
        result = result + [queWaitingCount integerValue];
    }
    return result;
}

#endif

@end

#endif
