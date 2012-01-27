//
//  PGSQLDispatch.m
//  PGSQLKit-Neil
//
//  Created by Neil Tiffin on 1/6/12.
//  Copyright (c) 2012 Performance Champions, Inc. All rights reserved.
//

#import "libpq-fe.h"

#import "PGSQLDispatch.h"
#import "PGSQLDispatchConnection.h"
#import "PGSQLConnection.h"
#import "PGSQLRecordset.h"

// Private Interface
@interface PGSQLDispatch ()

@property (nonatomic, retain) NSMutableArray *sqlConnections;
@property (nonatomic, retain) NSMutableArray *sqlConnectionsStatistics;

- (BOOL)addAConnectionToDispatcher;

@end

@implementation PGSQLDispatch

#pragma mark -
#pragma mark Property Accessors

@synthesize sqlConnections;
@synthesize sqlConnectionsStatistics;

@synthesize maxNumberConnections;

-(void)setMaxNumberConnections:(NSUInteger)max
{
    if ((max > 0) && (max <= 30))
    {
        maxNumberConnections = max;
    }
}

#pragma mark -
#pragma mark Singleton Methods

+ (PGSQLDispatch *)sharedPGSQLDispatch
{
    static dispatch_once_t pred = 0;
    static PGSQLDispatch * _sharedPGSQLDispatch = nil;
    
    dispatch_once(&pred, ^{
        _sharedPGSQLDispatch = [[self alloc] init];
    });
    return _sharedPGSQLDispatch;
}


#pragma mark -
#pragma mark Dispatch Methods

- (NSInteger)findNextIndexToDispatch
{    
    NSAssert(self.sqlConnections != nil, @"self.sqlConnections == nil");
    NSAssert(self.sqlConnectionsStatistics != nil, @"self.sqlConnectionsStatistics == nil");

    NSUInteger indexOfNextDispatch = 0;
    // Find the first non-busy connections and use it.
    for (indexOfNextDispatch = 0; indexOfNextDispatch < [sqlConnections count]; indexOfNextDispatch++)
    {
        if ([[sqlConnectionsStatistics objectAtIndex:indexOfNextDispatch] intValue] == 0)
        {
            //then use this one
            break;
        }
    }
    
    // Check to make sure we found a non-busy connection.
    if (indexOfNextDispatch == [sqlConnections count])
    {
        // Did not find non-busy connection so try to add a connection
        if ([self addAConnectionToDispatcher])
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

- (void)addConnectionStatistics:(NSInteger)index
{
    NSAssert(self.sqlConnectionsStatistics != nil, @"self.sqlConnectionsStatistics == nil");
    // This is where we start statistics tracking

    // Increment connection busy counter
    [sqlConnectionsStatistics replaceObjectAtIndex:index withObject:
     [NSNumber numberWithInt:[[sqlConnectionsStatistics objectAtIndex:index] intValue] + 1]];
    
}

- (void)removeConnectionStatistics:(NSInteger)index
{
    NSAssert(self.sqlConnectionsStatistics != nil, @"self.sqlConnectionsStatistics == nil");
    // This is where we end statistics tracking.

    // Decrement connection busy counter when done.
    [sqlConnectionsStatistics replaceObjectAtIndex:index withObject:
     [NSNumber numberWithInt:[[sqlConnectionsStatistics objectAtIndex:index] intValue] - 1]];
}

- (NSInteger)processResultsFromSQL:(NSString *)sql withObject:(id)resultsToObject usingSelector:(SEL)resultsToSelector
{
    NSAssert(self.sqlConnections != nil, @"self.sqlConnections == nil");
    NSAssert(self.sqlConnectionsStatistics != nil, @"self.sqlConnectionsStatistics == nil");

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
        
        [self addConnectionStatistics:indexOfNextDispatch];
        
        // Actual dispatch
        dispatch_async(connectionQueue, ^{
            PGSQLRecordset *resultsRecordSet = [aConnection open:sql];
            dispatch_async(dispatch_get_main_queue(), ^{
                [resultsToObject performSelector:resultsToSelector withObject:resultsRecordSet];
                
                [self removeConnectionStatistics:indexOfNextDispatch];
            });
        });
        indexOfLastDispatch = indexOfNextDispatch;
    }
    return 0;
}

- (NSInteger)processResultsFromSQL:(NSString *)sql usingCallbackBlock:(void (^)(PGSQLRecordset *))callbackBlock
{
    NSAssert(self.sqlConnections != nil, @"self.sqlConnections == nil");
    NSAssert(self.sqlConnectionsStatistics != nil, @"self.sqlConnectionsStatistics == nil");
    
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
        
        [self addConnectionStatistics:indexOfNextDispatch];
        
        // Actual dispatch
        dispatch_async(connectionQueue, ^{
            PGSQLRecordset *resultsRecordSet = [aConnection open:sql];
            dispatch_async(dispatch_get_main_queue(), ^{
                callbackBlock(resultsRecordSet);
                [self removeConnectionStatistics:indexOfNextDispatch];
            });
        });
        indexOfLastDispatch = indexOfNextDispatch;
    }
    return 0;
}

- (BOOL)addAConnectionToDispatcher
{
    NSAssert(self.sqlConnections != nil, @"self.sqlConnections == nil");
    NSAssert(self.sqlConnectionsStatistics != nil, @"self.sqlConnectionsStatistics == nil");
    
    if ([sqlConnections count] < self.maxNumberConnections)
    {
        NSString *qName = [NSString stringWithFormat:@"PGSQLKit.dispatchQueue%d", (int)[sqlConnections count] + 1];
        PGSQLDispatchConnection *aConnection = [[PGSQLDispatchConnection alloc] initWithQueueName:qName];
        [sqlConnections addObject:aConnection];
        [sqlConnectionsStatistics addObject:[NSNumber numberWithInt:0]];
        [aConnection release];
        return YES;
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

- (id)init
{
    self = [super init];
    if (self)
    {
        if (PQisthreadsafe() == 1)
        {
            // libpq appears to be thread safe.
            PGSQLConnection *defaultConnection = [PGSQLConnection defaultConnection];
            if (([PGSQLConnection defaultConnection] != nil) && (defaultConnection.isConnected == YES))
            {
                self.sqlConnections = [[[NSMutableArray alloc] init] autorelease];
                self.sqlConnectionsStatistics = [[[NSMutableArray alloc] init] autorelease];
                maxNumberConnections = 4;
                indexOfLastDispatch = NSUIntegerMax;  // this is set high to force a reset to zero for the first dispatch.
                if ([self addAConnectionToDispatcher])
                {
                    // All conditions have been met for initialization.
                    return self;   
                }
                [sqlConnections release];
                sqlConnections = nil;
                NSLog(@"%@ %s - Error, not able to open first connection.", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __func__);
            }
            else
            {
                NSLog(@"%@ %s - Error, a default connection has not been established.", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __func__);
            }
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

- (void)dealloc
{
    self.sqlConnections = nil;
    self.sqlConnectionsStatistics = nil;
    [super dealloc];
}

@end
