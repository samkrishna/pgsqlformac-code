//
//  PGSQLConnection.m
//  PGSQLKit
//
//  Created by Andy Satori on 5/8/07.
//  Copyright 2007 Druware Software Designs. All rights reserved.
//

#import "PGSQLConnection.h"

@implementation PGSQLConnection

NSString *const GenDBConnectionDidCompleteNotification = @"GenDBConnectionDidCompleteNotification";
NSString *const GenDBCommandDidCompleteNotification = @"GenDBCommandDidCompleteNotification";

NSString *const PGSQLConnectionDidCompleteNotification = @"PGSQLConnectionDidCompleteNotification";
NSString *const PGSQLCommandDidCompleteNotification = @"PGSQLCommandDidCompleteNotification";

#pragma mark -
#pragma mark Compatibility Functions

// Really should use -(PGSQLConnectionBase *)clone instead.  This is provided for
// compatibility only.
-(PGSQLConnection *)clone
{
    return (PGSQLConnection *)[super clone];
}

#pragma mark -
#pragma mark Async Functions

- (void)connectAsync
{
	// perform the connection on a thread
	[NSThread detachNewThreadSelector:@selector(performConnectThread) toTarget:self withObject:nil];		
}

- (void)performConnectThread
{
	// allocate the thread, begin the connection and send the notification when done.
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSMutableDictionary *info = [[[NSMutableDictionary alloc] init] autorelease];
	
	if ([self connect])
	{
		[info setValue:nil forKey:@"Error"];
	} else {
		[info setValue:[self lastError] forKey:@"Error"];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:PGSQLConnectionDidCompleteNotification
														object:nil
													  userInfo:info];
    [[NSNotificationCenter defaultCenter] postNotificationName:GenDBConnectionDidCompleteNotification
														object:nil
													  userInfo:info];

	[pool drain];
}

- (void)execCommandAsync:(NSString *)sql
{
	// perform the connection on a thread
	[NSThread detachNewThreadSelector:@selector(performExecCommand:) toTarget:self withObject:sql];		
}

- (void)performExecCommand:(id)sqlCommand
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSString *sql = (NSString *)sqlCommand;
	
	NSMutableDictionary *info = [[[NSMutableDictionary alloc] init] autorelease];
	
	NSNumber *recordCount = [[[NSNumber alloc] initWithInt:[self execCommand:sql]] autorelease];
	[info setValue:recordCount forKey:@"RecordCount"];
	[info setValue:[self lastError] forKey:@"Error"];
	[info setValue:[self lastCmdStatus] forKey:@"Status"];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:PGSQLCommandDidCompleteNotification
														object:nil
													  userInfo:info];
	[[NSNotificationCenter defaultCenter] postNotificationName:GenDBCommandDidCompleteNotification
														object:nil
													  userInfo:info];
	[pool drain];
}

- (void)openAsync:(NSString *)sql
{
	// perform the connection on a thread
	[NSThread detachNewThreadSelector:@selector(performOpen:) toTarget:self withObject:sql];		
}

- (void)performOpen:(id)sqlCommand
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSString *sql = (NSString *)sqlCommand;
	
	NSMutableDictionary *info = [[[NSMutableDictionary alloc] init] autorelease];
	
	PGSQLRecordset *rs = (PGSQLRecordset*)[self open:sql];
    
	[info setValue:rs forKey:@"Recordset"];
	[info setValue:[self lastError] forKey:@"Error"];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:PGSQLCommandDidCompleteNotification
														object:nil
													  userInfo:info];
    [[NSNotificationCenter defaultCenter] postNotificationName:GenDBCommandDidCompleteNotification
														object:nil
													  userInfo:info];

	[pool drain];
}

- (NSString *)datasourceFilter
{
    return nil; // this method is not valid for PostgreSQL
}

- (void)setDatasourceFilter:(NSString *)value
{
	return;
}

- (BOOL)enableCursors
{
	return enableCursors;
}
- (void)setEnableCursors:(BOOL)value
{
	enableCursors = value;
}

@end
