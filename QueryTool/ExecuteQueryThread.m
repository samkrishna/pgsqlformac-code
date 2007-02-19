//
//  ExecuteQueryThread.m
//  QueryToolForPostgresN
//
//  Created by Neil Tiffin on 9/17/06.
//  Copyright 2006 Performance Champions, Inc.. All rights reserved.
//

#import "ExecuteQueryThread.h"
@class SQLDocument;

@implementation ExecuteQueryThread 

- (id)init
{
	[super init];
	threadLock = [[NSLock alloc] init];
	return self;
}

- (void)dealloc
{
	[connection disconnect];
	[connection release];
	[threadLock release];
	[connectionString release];
	[threadResults release];
	[super dealloc];
}

- (BOOL)createNewSQLConnection:(NSString *)aString
{
	[connectionString release];
	[connection disconnect];
	[connection release];
	
	connectionString = aString;
	[connectionString retain];
	connection = [[Connection alloc] init];
	[connection connectUsingString:connectionString];
	if ([connection connectUsingString:connectionString])
	{
		connStatus = Connected;
		return YES;
	}
	connStatus = ConnError;
	return NO;
}

- (void)executeQueryThread:(id)theDocument
{
	if (queryStatus == QueryRunning)
	{
		return;
	}
	
	if (connStatus != Connected) 
	{
		queryStatus = QueryError;
		return;
	}
	queryStatus = QueryRunning;
	
	[errorString release];
	errorString = nil;
	
	[threadResults release];
	threadResults = nil;
	
	threadResults = [connection execQueryLogInfoLogSQL:[(SQLDocument *)theDocument currentQuery]];

	if ([connection errorDescription] != nil)
	{
		NSLog([connection errorDescription]);
		errorString = [NSString stringWithString:[connection errorDescription]];
	}
	
	//queryStatus == QueryDone;
	[(SQLDocument *)theDocument threadComplete];
}

@end
