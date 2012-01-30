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

static PGSQLConnection *globalPGSQLConnection;

@interface PGSQLConnection ()

@property (readwrite, retain) NSDate *startTimeStamp;
@property (readwrite, retain) NSString *errorDescription;

@end

@implementation PGSQLConnection

@synthesize errorDescription;
@synthesize startTimeStamp;
@synthesize logInfo;
@synthesize logSQL;
@synthesize maxConnectionRetries;

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
		self.errorDescription = nil;
        self.maxConnectionRetries = 5;
        
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
	self.errorDescription = nil;
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

	[pool drain];
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
		self.errorDescription = [[NSString stringWithFormat:@"%s", PQerrorMessage(pgconn)] autorelease];

		NSLog(@"Connection to database '%@' failed.", dbName);
		NSLog(@"\t%@", self.errorDescription);
		[self appendSQLLog:[NSString stringWithFormat:@"Connection to database %@ Failed.\n", dbName]]; 
		[self appendSQLLog:[NSString stringWithFormat:@"Connection string: %@\n\n", connectionString]]; 
		// append error too??

		PQfinish(pgconn);
		pgconn = nil;
		return NO;
    }
	
	// TODO if good connection should we remove password from memory
	//	or should it be encrypted?
	
	// TODO password should be asked for in dialog used and then erased?
	
    self.errorDescription = nil;
	
    // set up notification
	PQsetNoticeProcessor(pgconn, handle_pq_notice, self);
	
	if (sqlLog != nil) {
		[sqlLog release];
	}
	sqlLog = [[NSMutableString alloc] init];
	[self appendSQLLog:[NSString stringWithFormat:@"Connected to database %@.\n", dbName]];
	return YES;
}

- (BOOL)close
{
	if (pgconn == nil) { return NO; }
	if ([self isConnected] == NO) { return NO; }
	
	[self appendSQLLog:[NSString stringWithString:@"Disconnected from database.\n"]];
	PQfinish(pgconn);
	pgconn = nil;
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
		
	if ([self isConnected])
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
	[pool drain];
}

- (BOOL)execCommand:(NSString *)sql
{
	PGresult* res;
	
	self.errorDescription = nil;	

	if(commandStatus) {
		[commandStatus release];
		commandStatus = nil;	
	}
    if ([self checkAndRecoverConnection] == PGSQLConnectionCheckError)
	{
		return NO; // Note: Errors are logged by checkAndRecoverConnection
	}
	const char *cString = [sql cStringUsingEncoding:defaultEncoding];
	if (cString == NULL) 
	{ 
		self.errorDescription = [[NSString stringWithString:@"ERROR: command could not be losslessly converted to c string."] autorelease];
        return NO;
    }    
	res = PQexec(pgconn, cString);
	if (res == nil) 
	{ 
		self.errorDescription = [[NSString stringWithString:@"ERROR: No response (PGRES_FATAL_ERROR)"] autorelease];		
		return NO; 
	}
	if (PQresultStatus(res) != PGRES_COMMAND_OK) 
	{
		self.errorDescription = [[NSString stringWithFormat:@"%s", PQerrorMessage(pgconn)] autorelease];

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

	[pool drain];
}

- (PGSQLRecordset *)open:(NSString *)sql
{
	double elapsed_time_in_ms;
	PGresult* res;
	
	self.errorDescription = nil;
	
	if ([self checkAndRecoverConnection] == PGSQLConnectionCheckError)
	{
		return nil; // Note: Errors are logged by checkAndRecoverConnection
	}
	
	if (logSQL)
	{
		[self appendSQLLog: [NSString stringWithFormat:@"%@\n", [sql stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]]];
	}
	
	self.startTimeStamp = [NSDate date];    // this might be used by PGSQLDispatch so it should always be set.
                                            // be sure to reset to nil when done.
    const char *cString = [sql cStringUsingEncoding:defaultEncoding];
    if (cString == NULL)
    {
		self.errorDescription = [[NSString stringWithString:@"ERROR: command could not be losslessly converted to c string."] autorelease];
        [self appendSQLLog:[NSString stringWithFormat:@"%@\n", self.errorDescription]];
        return nil;
    }
	res = PQexec(pgconn, cString);
	if (logInfo)
	{
        //  If the receiver is earlier than the current date and time, the return value is negative.
		elapsed_time_in_ms = -1000.0 * [self.startTimeStamp timeIntervalSinceNow];
		[self appendSQLLog: [NSString stringWithFormat: @"Completed in %.2f milliseconds.\n", elapsed_time_in_ms]];
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
						
            self.startTimeStamp = nil;
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
            self.startTimeStamp = nil;
			return nil;
			break;
		}
			
		case PGRES_EMPTY_QUERY:
		{
			[self appendSQLLog:@"Postgres reported Empty Query\n"];
			PQclear(res);
            self.startTimeStamp = nil;
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
			self.errorDescription = [[NSString stringWithFormat:@"PostgreSQL Error: %s", PQresultErrorMessage(res)] autorelease];
			[self appendSQLLog:[NSString stringWithFormat:@"%@\n", self.errorDescription]];
			PQclear(res);
            self.startTimeStamp = nil;
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
	
	NSString *encodedString = [[[NSString alloc] initWithFormat:@"%s",(const char *)result] autorelease];
	
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
	//size_t result;
	int	error;
	char *sqlEncodeCharArray = malloc(1 + ([toEncode length] * 2)); // per the libpq doc.
	const char *sqlCharArrayToEncode = [toEncode cStringUsingEncoding:defaultEncoding];
	size_t length = strlen(sqlCharArrayToEncode);
	
	PQescapeStringConn ((PGconn *)pgconn, sqlEncodeCharArray,
								 (const char *)[toEncode cStringUsingEncoding:defaultEncoding], 
								 length, &error);
	
	NSString *encodedString = [[[NSString alloc] initWithFormat:@"%s",sqlEncodeCharArray] autorelease];
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

#pragma mark -
#pragma mark Check & Connection Recovery Methods

- (BOOL)isConnected
{
    if (pgconn == nil)
    {
        return NO;
    }
    ConnStatusType currentConnStatus = PQstatus(pgconn);
	return (currentConnStatus == CONNECTION_OK);
}

- (PGSQLConnectionCheckType)checkAndRecoverConnection
{
    if (pgconn == nil)
    {
        return PGSQLConnectionCheckError;
    }
    
    ConnStatusType currentConnStatus = PQstatus(pgconn);
    // This code only works for synchronious operation otherwise other status may be retreived.
    if (currentConnStatus == CONNECTION_OK)
    {
        // No need for recovery all ok.
        return (PGSQLConnectionCheckOK);
    }
    
    // Attempt to recover connection
    NSUInteger loopCount = 0;
    while (currentConnStatus == CONNECTION_BAD)
    {
        PQreset(pgconn);
        currentConnStatus = PQstatus(pgconn);
        if (loopCount >= self.maxConnectionRetries)
        {
            break;
        }
        loopCount++;
    }
    if (currentConnStatus == CONNECTION_BAD)
    {
        // Still bad after multiple attempts at recovery.
        self.errorDescription = [[NSString stringWithFormat:@"Not able to reestablish connection to database '%@' on server '%@'.", dbName, self.server] autorelease];
        NSLog(@"%@", errorDescription);
        [self appendSQLLog:[NSString stringWithFormat:@"%@\n", self.errorDescription]];
        
        // See if we can get a little more info.
        PGPing pingResult = PQping(pgconn);
        switch (pingResult)
        {
            case PQPING_OK:
                NSLog(@"The server '%@' is running and appears to be accepting connections.", self.server);
                [self appendSQLLog:[NSString stringWithFormat:@"The server '%@' is running and appears to be accepting connections.\n", self.server]];
                break;
            case PQPING_REJECT:
                NSLog(@"The server '%@' is running but is in a state that disallows connections (startup, shutdown, or crash recovery).", self.server);
                [self appendSQLLog:[NSString stringWithFormat:@"The server '%@' is running but is in a state that disallows connections (startup, shutdown, or crash recovery).\n", self.server]];
                break;
            case PQPING_NO_RESPONSE:
                NSLog(@"The server '%@' could not be contacted. This might indicate that the server is not running, or that there is something wrong with the given "
                      @"connection parameters (for example, wrong port number), or that there is a network connectivity problem (for example, a firewall blocking the connection request).", self.server);
                [self appendSQLLog:[NSString stringWithFormat:@"The server '%@' could not be contacted. This might indicate that the server is not running, or that there is something wrong with the given "
                                    @"connection parameters (for example, wrong port number), or that there is a network connectivity problem (for example, a firewall blocking the connection request).\n", self.server]];
                break;
            case PQPING_NO_ATTEMPT:
                NSLog(@"No attempt was made to contact the server '%@', because the supplied parameters were obviously incorrect or there was some client-side problem (for example, out of memory).", self.server);
                [self appendSQLLog:[NSString stringWithFormat:@"No attempt was made to contact the server '%@', because the supplied parameters were obviously incorrect or there was some client-side problem (for example, out of memory).\n", self.server]];
                break;
            default:
                NSLog(@"Undefined PQping() result.");
                break;
        }
        return (PGSQLConnectionCheckError);
    }
    // Successfully recovered.
    return (PGSQLConnectionCheckOK);
}



#pragma mark -
#pragma mark Dictionary Tools

- (BOOL)insertIntoTable:(NSString *)table fromDictionary:(NSDictionary *)dict
{
	return NO;
}

- (BOOL)updateTable:(NSString *)table fromDictionary:(NSDictionary *)dict
{
	return NO;
}

#pragma mark -
#pragma mark Property Accessors


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
