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
#import <Foundation/Foundation.h>
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

NSString *const GenDBConnectionDidCompleteNotification = @"GenDBConnectionDidCompleteNotification";
NSString *const GenDBCommandDidCompleteNotification = @"GenDBCommandDidCompleteNotification";

NSString *const PGSQLConnectionDidCompleteNotification = @"PGSQLConnectionDidCompleteNotification";
NSString *const PGSQLCommandDidCompleteNotification = @"PGSQLCommandDidCompleteNotification";

#pragma mark Class Methods

+(id)defaultConnection
{
	if (globalPGSQLConnection == nil)
	{
		return nil;
	}
	
	return globalPGSQLConnection;
}

#pragma mark Instance Methods

-(id)init
{
    self = [super init];
	
	if (self != nil) {
		isConnected	= NO;
		errorDescription = nil;
		sqlLog = [[NSMutableString alloc] init];		
		
		// this will default to NSUTF8StringEncoding with PG9
		defaultEncoding = NSMacOSRomanStringEncoding;
		
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
		
		commandStatus = nil;
		
		if (globalPGSQLConnection == nil)
		{
			[self retain];
			globalPGSQLConnection = self;
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
	[commandStatus release];
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
	pgconn = (PGconn *)PQconnectdb([connectionString cStringUsingEncoding:NSUTF8StringEncoding]);
#ifdef DEBUG
	if (PQoptions(pgconn))
	{
		NSLog(@"Options: %s", PQoptions(pgconn));
	}
#endif
	
	if (PQstatus(pgconn) == CONNECTION_BAD) 
	{
		errorDescription = [NSString stringWithFormat:@"%s", PQerrorMessage(pgconn)];
		[errorDescription retain];

		NSLog(@"Connection to database '%@' failed.", dbName);
		NSLog(@"\t%@", errorDescription);
		[self appendSQLLog:[NSString stringWithFormat:@"Connection to database %@ Failed.\n", dbName]]; 
		[self appendSQLLog:[NSString stringWithFormat:@"Connection string: %@\n\n", connectionString]]; 
		// append error too??

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
	[self appendSQLLog:[NSString stringWithFormat:@"Connected to database %@.\n", dbName]];
	isConnected = YES;
	return YES;
}

- (BOOL)close
{
	if (pgconn == nil) { return NO; }
	if (isConnected == NO) { return NO; }
	
	[self appendSQLLog:[NSString stringWithString:@"Disconnected from database.\n"]];
	PQfinish(pgconn);
	pgconn = nil;
	isConnected = NO;
	return YES;
}

-(PGSQLConnection *)clone
{
	PGSQLConnection *newConnection = [[[PGSQLConnection alloc] init] autorelease];
	[newConnection setServer:host];
	[newConnection setPort:port]; 
	[newConnection setUserName:userName];
	[newConnection setPassword:password];
	[newConnection setDatabaseName:dbName];
		
	if (isConnected)
	{
		[newConnection connect];
	}
	
	return newConnection;
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
	[pool release];
}

- (BOOL)execCommand:(NSString *)sql
{
	PGresult* res;
	
	if(errorDescription) {
		[errorDescription release];
		errorDescription = nil;	
	}
	if(commandStatus) {
		[commandStatus release];
		commandStatus = nil;	
	}
	if (pgconn == nil) 
	{ 
		errorDescription = [NSString stringWithString:@"Object is not Connected."];		
		[errorDescription retain];
		return NO; 
	}
	
	res = PQexec(pgconn, [sql cStringUsingEncoding:defaultEncoding]);
	if (res == nil) 
	{ 
		errorDescription = [NSString stringWithString:@"ERROR: No response (PGRES_FATAL_ERROR)"];		
		[errorDescription retain];
		return NO; 
	}
	if (PQresultStatus(res) != PGRES_COMMAND_OK) 
	{
		errorDescription = [NSString stringWithFormat:@"%s", PQerrorMessage(pgconn)];
		[errorDescription retain];

		PQclear(res);
		return NO;
    }
	if (strlen(PQcmdStatus(res)))
	{
		commandStatus = [NSString stringWithFormat:@"%s", PQcmdStatus(res)];
		[commandStatus retain];
		[self appendSQLLog:[NSString stringWithFormat:@"%@\n", commandStatus]];
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
	
	NSMutableDictionary *info = [[[NSMutableDictionary alloc] init] autorelease];
	
	PGSQLRecordset *rs = [self open:sql];
    
	[info setValue:rs forKey:@"Recordset"];
	[info setValue:[self lastError] forKey:@"Error"];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:PGSQLCommandDidCompleteNotification
														object:nil
													  userInfo:info];
    [[NSNotificationCenter defaultCenter] postNotificationName:GenDBCommandDidCompleteNotification
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
	res = PQexec(pgconn, [sql cStringUsingEncoding:NSUTF8StringEncoding]);
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
			[rs setDefaultEncoding:defaultEncoding];
			
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
			[errorDescription retain];
			[self appendSQLLog:[NSString stringWithFormat:@"%@\n", errorDescription]];
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

-(NSString *)sqlEncodeData:(NSData *)toEncode
{
	unsigned char *result;
	size_t resultLength = 0;
	
	result = PQescapeByteaConn ((PGconn *)pgconn, (const unsigned char *)[toEncode bytes],
								 [toEncode length], &resultLength);
	
	NSString *encodedString = [[[NSString alloc] initWithCString:(const char *)result] autorelease];
	
	PQfreemem(result);
	
	return encodedString;	
}


-(NSData *)sqlDecodeData:(NSData *)toDecode
{
	unsigned char *result;
	size_t resultLength = 0;
	
	result = PQunescapeBytea((const unsigned char *)[toDecode bytes], &resultLength);
	
	NSData *decodedData = [[[NSData alloc] initWithBytes:result length:resultLength] autorelease];
	
	PQfreemem(result);
	
	return decodedData;	
} 

-(NSString *)sqlEncodeString:(NSString *)toEncode
{
	size_t result;
	int	error;
	char *sqlEncodeCharArray = malloc(1 + ([toEncode length] * 2)); // per the libpq doc.
	const char *sqlCharArrayToEncode = [toEncode cStringUsingEncoding:defaultEncoding];
	size_t length = strlen(sqlCharArrayToEncode);
	
	result = PQescapeStringConn ((PGconn *)pgconn, sqlEncodeCharArray,
								 (const char *)[toEncode cStringUsingEncoding:defaultEncoding], 
								 length, &error);
	
	NSString *encodedString = [[[NSString alloc] initWithCString:sqlEncodeCharArray] autorelease];
	free(sqlEncodeCharArray);
	
	return encodedString;	
	
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

-(NSString *)lastCmdStatus {
	return commandStatus;
}

- (NSMutableString *)sqlLog {
	return sqlLog;
}

-(NSStringEncoding)defaultEncoding
{
	return defaultEncoding;
}

-(void)setDefaultEncoding:(NSStringEncoding)value
{
    if (defaultEncoding != value) {
        defaultEncoding = value;
    }	
	
}


@end
