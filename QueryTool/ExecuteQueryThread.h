//
//  ExecuteQueryThread.h
//  QueryToolForPostgresN
//
//  Created by Neil Tiffin on 9/17/06.
//  Copyright 2006 Performance Champions, Inc.. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <pgCocoaDB/PGCocoaDB.h>

enum QueryToolQueryStatus { QueryNoStatus, QueryRunning, QueryCompleted, QueryError };
enum QueryToolConnectionStatus { ConnNoStatus, Connected, ConnError };

@interface ExecuteQueryThread : NSObject
{
	NSLock *threadLock;
	enum QueryToolQueryStatus queryStatus;
	enum QueryToolConnectionStatus connStatus;
	
	RecordSet *threadResults;		// is kept until next query
	Connection *connection;			// is persistant through multiple executions
	NSString *connectionString;
	NSString *errorString;
}

- (BOOL)createNewSQLConnection:(NSString *)aString;
- (void)executeQueryThread:(id)theDocument;

@end
