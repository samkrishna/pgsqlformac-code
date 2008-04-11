//
//  PGSQLConnection.m
//  PGSQLKit
//
//  Created by Andy Satori on 5/8/07.
//  Copyright 2007 Druware Software Designs. All rights reserved.
//

#import "PGSQLConnection.h"
#include "libpq-fe.h"
#import <sys/time.h>
#import <Security/Security.h>
#import <CoreFoundation/CoreFoundation.h>
#import <stdlib.h>

// When a pqlib notice is raised this function gets called
void
handle_pq_notice(void *arg, const char *message)
{
	PGSQLConnection *theConn = (PGSQLConnection *) arg;
	//NSLog(@"%s", message);
	[theConn  appendSQLLog:[NSString stringWithFormat: @"%s\n", message]];
}

@implementation PGSQLConnection

NSString *const PGSQLConnectionDidCompleteNotification = @"PGSQLConnectionDidCompleteNotification";
NSString *const PGSQLCommandDidCompleteNotification = @"PGSQLCommandDidCompleteNotification";

#pragma mark Class Methods

+(id)defaultConnection
{
	if (globalConnection == nil)
	{
		return nil;
	}
	
	return globalConnection;
}

#pragma mark Instance Methods

-(id)init
{
    self = [super init];
	
	if (self != nil) {
		isConnected	= NO;
		errorDescription = nil;
		sqlLog = [[NSMutableString alloc] init];		
		
		pgconn = nil;
		host = [[NSString alloc] initWithString:@"localhost"];
		port = [[NSString alloc] initWithString:@"5432"];
		options = nil;
		tty = nil;
		dbName = [[NSString alloc] initWithString:@"template1"];
		userName = nil;
		password = nil;
		sslMode = nil;
		service = nil;
		krbsrvName = nil;
		connectionString = nil;
		
		if (globalConnection == nil)
		{
			[self retain];
			globalConnection = self;
		}
	}
	    
    return self;
}

-(void)dealloc
{
	[self close];
	
	[host release];
	[port release];
	[options release];
	[tty release];
	[dbName release];
	[userName release];
	[password release];
	[sslMode release];
	[service release];
	[krbsrvName release];
	[connectionString release];
	[errorDescription release];
	[sqlLog release];
	
	[super dealloc];
}


- (void)connectAsync
{
	// perform the connection on a thread
	[NSThread detachNewThreadSelector:@selector(performConnectThread) toTarget:self withObject:nil];		
}

- (void)performConnectThread
{
	// allocate the thread, begin the connection and send the notification when done.
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
	
	if ([self connect])
	{
		[info setValue:nil forKey:@"Error"];
	} else {
		[info setValue:[self lastError] forKey:@"Error"];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:PGSQLConnectionDidCompleteNotification
														object:nil
													  userInfo:info];
	[pool release];
}


- (BOOL)connect {

	// replace with postgres connect code
	[self close];
	
	if (connectionString == nil)
	{
		connectionString = [self makeConnectionString];
		[connectionString retain];
	}
	NSAssert( (connectionString != nil), @"Attempted to connect to PostgreSQL with empty connectionString.");
	pgconn = (PGconn *)PQconnectdb([connectionString cString]);
	if (PQoptions(pgconn))
	{
		NSLog(@"Options: %s", PQoptions(pgconn));
	}
	
	if (PQstatus(pgconn) == CONNECTION_BAD) 
	{
		NSLog(@"Connection to database '%@' failed.", dbName);
		NSLog(@"\t%s", PQerrorMessage(pgconn));
		errorDescription = [NSString stringWithFormat:@"%s", PQerrorMessage(pgconn)];
		[self appendSQLLog:[NSMutableString stringWithFormat:@"Connection to database %@ Failed.\n", dbName]];
		[self appendSQLLog:[NSMutableString stringWithFormat:@"Connection string: %@\n\n", connectionString]];
		
		PQfinish(pgconn);
		pgconn = nil;
		isConnected = NO;
		return NO;
    }
	
	// TODO if good connection should we remove password from memory
	//	or should it be encrypted?
	
	// TODO password should be asked for in dialog used and then erased?
	
	if (errorDescription)
	{
		[errorDescription release];
		errorDescription = nil;
	}
	// set up notification
	PQsetNoticeProcessor(pgconn, handle_pq_notice, self);
	
	if (sqlLog != nil) {
		[sqlLog release];
	}
	sqlLog = [[NSMutableString alloc] init];
	[self appendSQLLog:[NSMutableString stringWithFormat:@"Connected to database %@ on %@.\n", dbName, [[NSCalendarDate calendarDate] description]]];
	isConnected = YES;
	return YES;
}

- (BOOL)close
{
	if (pgconn == nil) { return NO; }
	if (isConnected == NO) { return NO; }
	
	[self appendSQLLog:[NSMutableString stringWithString:@"Disconnected from database.\n"]];
	PQfinish(pgconn);
	pgconn = nil;
	isConnected = NO;
	return YES;
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
	
	NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
	
	NSNumber *recordCount = [[NSNumber alloc] initWithInt:[self execCommand:sql]];
	[info setValue:recordCount forKey:@"RecordCount"];
	[info setValue:[self lastError] forKey:@"Error"];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:PGSQLCommandDidCompleteNotification
														object:nil
													  userInfo:info];
	[pool release];
}

- (BOOL)execCommand:(NSString *)sql
{
	PGresult* res;
	
	if (pgconn == nil) 
	{ 
		errorDescription = [NSString stringWithString:@"Object is not Connected."];		
		return nil; 
	}
	
	res = PQexec(pgconn, [sql cString]);
	if (PQresultStatus(res) != PGRES_COMMAND_OK) 
	{
		errorDescription = [NSString stringWithString:@"Command failed."];
		PQclear(res);
		return NO;
    }
	if (strlen(PQcmdStatus(res)))
	{
		[self appendSQLLog:[NSString stringWithFormat:@"%s\n", PQcmdStatus(res)]];
	}
//	results = [[[NSString alloc] initWithCString:PQcmdTuples(res)] autorelease];
	
	PQclear(res);	
	return YES;	
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
	
	NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
	
	PGSQLRecordset *rs = [self open:sql];
	[info setValue:rs forKey:@"Recordset"];
	[info setValue:[self lastError] forKey:@"Error"];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:PGSQLCommandDidCompleteNotification
														object:nil
													  userInfo:info];
	[pool release];
}

- (PGSQLRecordset *)open:(NSString *)sql
{
	struct timeval start, finished;
	double elapsed_time;
	long seconds, usecs;
	PGresult* res;
	
	[errorDescription release];
	errorDescription = nil;
	
	if (pgconn == nil) 
	{ 
		errorDescription = @"Object is not Connected.";	
		[self appendSQLLog:@"Object is not Connected.\n"];
		return nil; 
	}
	
	if (logSQL)
	{
		[self appendSQLLog: [NSString stringWithFormat:@"%@\n", [sql stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]]];
	}
	
	gettimeofday(&start, 0);
	res = PQexec(pgconn, [sql cString]);
	if (logInfo)
	{
		gettimeofday(&finished, 0);
		seconds = finished.tv_sec - start.tv_sec;
		usecs = finished.tv_usec - start.tv_usec;
		if (usecs < 0)
		{
			seconds--;
			usecs = usecs + 1000000;
		}
		elapsed_time = (double) seconds *1000.0 + (double) usecs *0.001;
		[self appendSQLLog: [NSString stringWithFormat: @"Completed in %d milliseconds.\n", (long) elapsed_time]];
	}
	switch (PQresultStatus(res))
	{
		case PGRES_TUPLES_OK:
		{
			// build the recordset
			PGSQLRecordset *rs = [[[PGSQLRecordset alloc] initWithResult:res] autorelease];
			
			if (logInfo)
			{
				long nRecords = PQntuples(res);
				[self appendSQLLog:[NSString stringWithFormat: @"%d rows affected.\n\n", nRecords]];
			}
						
			return rs;
			break;
		}
			
		case PGRES_COMMAND_OK:
		{
			if (logInfo)
			{
				[self appendSQLLog:@"Query ran successfully.\n"];
			}
			PQclear(res);
			return nil;
			break;
		}
			
		case PGRES_EMPTY_QUERY:
		{
			[self appendSQLLog:@"Postgres reported Empty Query\n"];
			PQclear(res);
			return nil;
			break;
		}
			
		case PGRES_COPY_OUT:
		case PGRES_COPY_IN:
		case PGRES_BAD_RESPONSE:
		case PGRES_NONFATAL_ERROR:
		case PGRES_FATAL_ERROR:
		default:
		{
			errorDescription = [NSString stringWithFormat:@"PostgreSQL Error: %s", PQresultErrorMessage(res)];
			[self appendSQLLog:[NSString stringWithFormat:@"PostgreSQL Error: %s\n", PQresultErrorMessage(res)]];
			PQclear(res);
			return nil;
		}
	}
}

-(NSMutableString *)makeConnectionString
{
	NSMutableString *connStr = [[[NSMutableString alloc] init] autorelease];
	
	if (connectionString)
	{
		[connStr appendString:connectionString];
		return connStr;
	}
	if (host)
	{
		[connStr appendFormat:@" host='%@' ", host];
	}
	if (port)
	{
		[connStr appendFormat:@" port='%@' ", port];
	}	
	if (options)
	{
		[connStr appendFormat:@" options='%@' ", options];
	}	
	if (dbName)
	{
		[connStr appendFormat:@" dbname='%@' ", dbName];
	}	
	if (userName)
	{
		[connStr appendFormat:@" user='%@' ", userName];
	}	
	if (password)
	{
		[connStr appendFormat:@" password='%@' ", password];
	}
	if (sslMode)
	{
		[connStr appendFormat:@" sslmode='%@' ", sslMode];
	}
	if (service)
	{
		[connStr appendFormat:@" service='%@' ", service];
	}
	if (krbsrvName)
	{
		[connStr appendFormat:@" krbsrvname='%@' ", krbsrvName];
	}
	return connStr;
}



#pragma mark Dictionary Tools

- (BOOL)insertIntoTable:(NSString *)table fromDictionary:(NSDictionary *)dict
{
	return NO;
}

- (BOOL)updateTable:(NSString *)table fromDictionary:(NSDictionary *)dict
{
	return NO;
}

#pragma mark Property Accessors

- (BOOL)isConnected {
	return isConnected;
}

- (NSString *)connectionString {
    return [[connectionString retain] autorelease];
}

- (void)setConnectionString:(NSString *)value {
    if (connectionString != value) {
        [connectionString release];
        connectionString = [value copy];
    }
}

- (NSString *)userName {
    return [[userName retain] autorelease];
}

- (void)setUserName:(NSString *)value {
    if (userName != value) {
        [userName release];
        userName = [value copy];
    }
}

- (NSString *)password {
    return [[password retain] autorelease];
}

- (void)setPassword:(NSString *)value {
    if (password != value) {
        [password release];
        password = [value copy];
    }
}

- (NSString *)server {
    return [[host retain] autorelease];
}

- (void)setServer:(NSString *)value {
    if (host != value) {
        [host release];
        host = [value copy];
    }
}

-(NSString *)port {
    return [[port retain] autorelease];
}

-(void)setPort:(NSString *)value {
    if (port != value) {
        [port release];
        port = [value copy];
    }
}

-(NSString *)databaseName {
    return [[dbName retain] autorelease];
}

-(void)setDatabaseName:(NSString *)value {
    if (dbName != value) {
        [dbName release];
        dbName = [value copy];
    }
}


- (NSString *)lastError {
    return errorDescription;
}

- (NSMutableString *)sqlLog {
	return sqlLog;
}

- (void)appendSQLLog:(NSString *)value {
	if (sqlLog == nil)
	{
		sqlLog = [[NSMutableString alloc] initWithString:value];
	}
	else
	{
		[sqlLog appendString:value];
	}
}

@end
