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

// Private Interface
@interface PGSQLDispatch ()

- (BOOL)addAConnectionToDispatcher;

@end

@implementation PGSQLDispatch

@synthesize maxNumberConnections;

#pragma mark -
#pragma mark Singleton Methods

static PGSQLDispatch *sharedPGSQLDispatch = nil;

+ (PGSQLDispatch *)sharedPGSQLDispatch
{
	@synchronized(self)
	{
		if (sharedPGSQLDispatch == nil)
		{
			sharedPGSQLDispatch = [[super allocWithZone:NULL] init];
		}
	}
	return sharedPGSQLDispatch;
}

+ (id)allocWithZone:(NSZone *)zone
{
	return [[self sharedPGSQLDispatch] retain];
}

- (id)copyWithZone:(NSZone *)zone
{
	return self;
}

- (id)retain
{
	return self;
} 

- (NSUInteger)retainCount 
{
	return NSUIntegerMax; 
}

- (oneway void)release
{
    ;
}

- (id)autorelease
{
	return self;
}

#pragma mark -
#pragma mark Dispatch Methods

- (NSInteger)resultsFromSQL:(NSString *)sql toObject:(id)resultsToObject usingSelector:(SEL)resultsToSelector
{
    // cant process unless we have at least 1 connection.
    if ([sqlConnections count] < 1)
    {
        return 1;
    }
    else
    {
        // Perform dispatch logic
        
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
                indexOfNextDispatch = [sqlConnections count] - 2;
            }
            else
            {
                // Was not able to add connection so just do round robin add to a busy queue.
                indexOfNextDispatch = indexOfLastDispatch < ([sqlConnections count] -1) ? indexOfLastDispatch++ : 0;
            }
        }
        
        // Now we know which connection to use so dispatch SQL.
        PGSQLDispatchConnection *aConnection = [sqlConnections objectAtIndex:indexOfNextDispatch];
        dispatch_queue_t connectionQueue = aConnection.connectionQueue;
        indexOfLastDispatch = indexOfNextDispatch;
        
        // Increment connection busy counter
        [sqlConnectionsStatistics replaceObjectAtIndex:indexOfNextDispatch withObject:
         [NSNumber numberWithInt:[[sqlConnectionsStatistics objectAtIndex:indexOfNextDispatch] intValue] + 1]];
        
        // Actual dispatch
        dispatch_async(connectionQueue, ^{
            PGSQLRecordset *resultsRecordSet = [aConnection open:sql];
            dispatch_async(dispatch_get_main_queue(), ^{
                [resultsToObject performSelector:resultsToSelector withObject:resultsRecordSet];
                
                // Decrement connection busy counter
                [sqlConnectionsStatistics replaceObjectAtIndex:indexOfNextDispatch withObject:
                 [NSNumber numberWithInt:[[sqlConnectionsStatistics objectAtIndex:indexOfNextDispatch] intValue] - 1]];
            });
        });
    }
    return 0;
}

- (BOOL)addAConnectionToDispatcher
{
    if ([sqlConnections count] < self.maxNumberConnections)
    {
        NSString *qName = [NSString stringWithFormat:@"PGSQLKit.dispatchQueue%d", (int)[sqlConnections count] + 1];
        PGSQLDispatchConnection *aConnection = [[PGSQLDispatchConnection alloc] initWithQueueName:qName];
        [sqlConnections addObject:aConnection];
        [sqlConnectionsStatistics addObject:[NSNumber numberWithInt:0]];
        [aConnection release];
        return YES;
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
                sqlConnections = [[NSMutableArray alloc] init];
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
    [sqlConnections release];
    [sqlConnectionsStatistics release];
    [super dealloc];
}

@end
