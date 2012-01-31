//
//  PGSQLDispatch.m
//  PGSQLKit-Neil
//
//  Created by Neil Tiffin on 1/6/12.
//  Copyright (c) 2012 Performance Champions, Inc. All rights reserved.
//

// Values for __MAC_10_6 and __IPHONE_4_0 are used in case this code is compiled on systems
// where they are not defined and therefore will be evaluated as zero.
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

#pragma mark -
#pragma mark Dispatch Methods

- (NSInteger)findNextIndexToDispatch:(BOOL)longRunning
{    
    NSAssert(self.sqlConnections != nil, @"self.sqlConnections == nil");
    
    // See if we need to remove connections.  If not no harm.
    [self removeConnectionFromDispatcher];
    
    // if only allowed one then use it.
    if (self.maxNumberConnections == 1)
    {
        indexOfLastDispatch = 0;
        return 0;
    }
    
    NSInteger maxConnectionsCountToConsider = self.maxNumberConnections <= [sqlConnections count] ? self.maxNumberConnections : [sqlConnections count];

    NSUInteger indexOfNextDispatch = 0;
    // Find the first non-busy connections and use it.
    for (indexOfNextDispatch = 0; indexOfNextDispatch < maxConnectionsCountToConsider; indexOfNextDispatch++)
    {
        PGSQLDispatchConnection *aConn = [sqlConnections objectAtIndex:indexOfNextDispatch];
        if ([[aConn queueWaitingCount] intValue] == 0)
        {
            //then use this one
            //NSLog(@"Found existing non busy:%lu", indexOfNextDispatch);
            break;
        }
        else
        {
            //NSLog(@"Found existing busy:%lu", indexOfNextDispatch);
        }
    }
    
    // Check to make sure we found a non-busy connection.
    if (indexOfNextDispatch == maxConnectionsCountToConsider)
    {
        // Did not find non-busy connection so try to add a connection
        PGSQLConnection *connectionToClone = nil;
        if ([sqlConnections count] > 0)
        {
            // if we have a connections we clone our own connection.
            connectionToClone = [sqlConnections objectAtIndex:0];
        }
        else
        {
            // if we don't have a connection then clone the PGSQLConnection default connection.
            connectionToClone = [PGSQLConnection defaultConnection];
        }
        if ([self addConnectionToDispatcher:connectionToClone])
        {
            // Successful add. Remember init adds the first connection so no need to check for underflow.
            // Set dispatcher to use the last connection added.
            indexOfNextDispatch = [sqlConnections count] - 1;
        }
        else
        {
            //NSLog(@"Not able to add connection, maxConnectionsCountToConsider:%lu indexOfNextDispatch:%lu indexOfLastDispatch:%lu", maxConnectionsCountToConsider, indexOfNextDispatch, indexOfLastDispatch);
            // Was not able to add connection so do round robin add to a busy queue.
            // Don't use size of the connections array as the number of connections may have been reduced.
            
            indexOfNextDispatch = indexOfLastDispatch + 1;
            if (indexOfNextDispatch >= maxConnectionsCountToConsider)
            {
                indexOfNextDispatch = 0;
            }
            //NSLog(@"Calculated indexOfNextDispatch:%lu", indexOfNextDispatch);
        }
    }
    
    // handle long running by making sure queue #1 is never dispatched long running.
    if ((longRunning) && (indexOfNextDispatch == 1))
    {
        // If we only have one then it makes no difference because we never get here.
        indexOfNextDispatch++;
    }

    //NSLog(@"Going to dispatch to this one:%lu", indexOfNextDispatch);
    indexOfLastDispatch = indexOfNextDispatch;
    return indexOfNextDispatch;
}


- (PGSQLDispatchError_t)processResultsFromSQL:(NSString *)sql 
                                    expectLongRunning:(BOOL)longRunning
                             usingCallbackBlock:(void (^)(PGSQLRecordset *, NSString *))callbackBlock
{
    NSAssert(self.sqlConnections != nil, @"self.sqlConnections == nil");
    
    // Can't process unless we have at least 1 connection.
    if ([sqlConnections count] < 1)
    {
        return PGSQLDispatchErrorNoAvailableConnections;
    }
    else
    {
        NSUInteger indexOfNextDispatch = [self findNextIndexToDispatch:longRunning];
        NSAssert(indexOfNextDispatch < [self.sqlConnections count], @"Index out of range.");

        // ***************
        //  Dispatch SQL
        // ***************

        PGSQLDispatchConnection *dispatchConnection = [self.sqlConnections objectAtIndex:indexOfNextDispatch];
        NSAssert(dispatchConnection != nil, @"aConnection == nil");
        NSAssert(dispatchConnection.connectionQueue != NULL, @"aConnection.connectionQueue == NULL");
        NSLog(@"Dispatching to queue named:%s", dispatch_queue_get_label(dispatchConnection.connectionQueue));
        [dispatchConnection processResultsFromSQL:sql usingCallbackBlock:callbackBlock];
    }
    return PGSQLDispatchErrorNone;
}

- (void)removeConnectionFromDispatcher
{
#warning Need to test the code below.  Until then don't execute.
    return;
    
    if ([self.sqlConnections count] > self.maxNumberConnections)
    {
        PGSQLDispatchConnection *lastConn = [self.sqlConnections lastObject];
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
    // Check to make sure connections are sane.
    // Yep. Could have been done in the setter, but then I would have to implement atomic setter.
    if (maxNumberConnections < 1)
    {
        self.maxNumberConnections = 1;
    }
    if ((maxNumberConnections > 30))
    {
        self.maxNumberConnections =30;
    }
    if ([self.sqlConnections count] < self.maxNumberConnections)
    {
        // Need to add connection.
        if (connToClone != nil)
        {
            // Queue name is the same as the index.
            NSString *qName = [NSString stringWithFormat:@"com.postgresqlformac.PGSQLKit.DispatchSQLQueue%d", (int)[sqlConnections count]];
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

- (NSString *)stringDescriptionForErrorNumber:(PGSQLDispatchError_t)error;
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
            NSLog(@"%@ %s - Error, libpq is not thread safe.", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __func__);
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
