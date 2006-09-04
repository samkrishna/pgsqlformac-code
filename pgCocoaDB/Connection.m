//
//  Connection.m
//  PGDB
//
//  Created by Andy Satori on Thu Jan 29 2004.
//  Copyright (c) 2004 Druware Software Designs. All rights reserved.
//

#import "Connection.h"
#include "libpq-fe.h"
#import <sys/time.h>

// When a pqlib notice is raised this function gets called
void
handle_pq_notice(void *arg, const char *message)
{
	Connection *theConn = (Connection *) arg;
	//NSLog(@"%s", message);
	[theConn  appendSQLLog:[NSString stringWithFormat: @"%s\n", message]];
}


@implementation Connection

- (id)init
{
	self = [super init];
	
	pgconn = nil;
	dbs = nil;	
	connected = NO;
	
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
	
	errorDescription = nil;
	sqlLog = [[NSMutableString alloc] init];
	
	return self;
}

-(void)dealloc
{

	[self disconnect];
	
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
	[dbs release];
	[errorDescription release];
	[sqlLog release];
	
	[super dealloc];
}


- (BOOL)connect
{
	[self disconnect];

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
		[self setErrorDescription:[NSString stringWithFormat:@"%s", PQerrorMessage(pgconn)]];
		[self appendSQLLog:[NSMutableString stringWithFormat:@"Connection to database %@ Failed.\n", dbName]];
		[self appendSQLLog:[NSMutableString stringWithFormat:@"Connection string: %@\n\n", connectionString]];
		
		PQfinish(pgconn);
		pgconn = nil;
		connected = NO;
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
	
	[self setSQLLog:[NSMutableString stringWithFormat:@"Connected to database %@ on %@.\n", dbName, [[NSCalendarDate calendarDate] description]]];
	connected = YES;
	return YES;
}

- (BOOL)connectUsingString:(NSString *)aConnectionString
{
	[self setConnectionString:aConnectionString];	
	return [self connect];
}

- (BOOL)connectToHost:(NSString *)toHost
	 		   onPort:(NSString *)onPort 
	 	  withOptions:(NSString *)withOptions
			   useTTY:(NSString *)useTTY
		  useDatabase:(NSString *)userDB
{
	[self setHost:toHost];
	[self setPort:onPort];
	[self setOptions:withOptions];
	[self setTty:useTTY];
	[self setDbName:userDB];
	
	[self setConnectionString:nil];
	return [self connect];
}

- (BOOL)disconnect
{
	if (pgconn == nil) { return NO; }
	if (connected == NO) { return NO; }
	
	if (dbs != nil) {
		[dbs release];
		dbs = nil;
	}
	
	[self appendSQLLog:[NSMutableString stringWithString:@"Disconnected from database.\n"]];
	PQfinish(pgconn);
	pgconn = nil;
	connected = NO;
	return YES;
}

// accessor methods 

- (BOOL)isConnected
{
	// TODO check to make sure connection is still alive
	// TODO if not alive then should make use PQreset to attempt to re-establish
	return connected;
}

- (NSString *)host 
{
    return host;
}

- (void)setHost:(NSString *)newHost 
{
    if (host != newHost) 
	{
        [host release];
        host = [newHost copy];
    }
	[self setConnectionString:nil];
}

- (NSString *)port
{
    return port;
}

- (void)setPort:(NSString *)newPort
{
    if (port != newPort) 
	{
        [port release];
        port = [newPort copy];
    }
	[self setConnectionString:nil];
}

- (NSString *)options
{
	return options;
}

- (void)setOptions:(NSString *)newOptions
{
    if (options != newOptions) 
	{
        [options release];
        options = [newOptions copy];
    }
	[self setConnectionString:nil];
}

- (NSString *)tty;
{
	return tty;
}

- (void)setTty:(NSString *)newTty;
{
    if (tty != newTty) 
	{
        [tty release];
        tty = [newTty copy];
    }
	[self setConnectionString:nil];
}

- (NSString *)dbName;
{
	return dbName;
}

- (void)setDbName:(NSString *)newDbName;
{
    if (dbName != newDbName) 
	{
        [dbName release];
        dbName = [newDbName copy];
    }
	[self setConnectionString:nil];
}

- (NSString *)userName 
{
    return userName;
}

- (void)setUserName:(NSString *)value 
{
    if (userName != value) 
	{
        [userName release];
        userName = [value copy];
    }
	[self setConnectionString:nil];
}

- (NSString *)password 
{
    return password;
}

- (void)setPassword:(NSString *)value 
{
    if (password != value) 
	{
        [password release];
        password = [value copy];
    }
	[self setConnectionString:nil];
}

- (NSString *)connectionString 
{
    return connectionString;
}

- (void)setConnectionString:(NSString *)value 
{
    if (connectionString != value) 
	{
        [connectionString release];
        connectionString = [value copy];
    }
}

- (NSString *)sslMode
{
	return sslMode;
}

- (void)setSslMode:(NSString *)value
{
    if (sslMode != value) 
	{
        [sslMode release];
        sslMode = [value copy];
	}
}

- (NSString *)service;
{
	return service;
}

- (void)setService:(NSString *)value;
{
    if (service != value) 
	{
        [service release];
        service = [value copy];
	}
}

- (NSString *)krbsrvName;
{
	return krbsrvName;
}

- (void)setKrbsrvName:(NSString *)value;
{
    if (krbsrvName != value) 
	{
        [krbsrvName release];
        krbsrvName = [value copy];
	}
}


- (Databases *)databases
{
	if (!connected) 
	{
		return nil;
	}
	
	if (dbs != nil) {
		return dbs;
	}
	
	PGresult	*res;
	NSString	*sql = @"select * from pg_database where datallowconn = 't' order by datname asc"; 
	
	// TODO restructure to use [self execQueryNoLog];
	res = PQexec(pgconn, [sql cString]);
	if (PQresultStatus(res) != PGRES_TUPLES_OK) 
	{
		[self setErrorDescription:[NSString stringWithString:@"Command did not return any data."]];
		PQclear(res);
		return nil;
    }
	
	// build the collection
	[dbs release];
	dbs = [[Databases alloc] init];
	long nFields = PQnfields(res);
	long nRecords = PQntuples(res);
	long i = 0;
	
	for ( i = 0; i < nRecords; i++)
	{
		// add the database
		Database *db = [dbs addItem];
		
		long x = 0;
		for  ( x = 0; x < nFields; x++)
		{
			NSString *fValue = [[[NSString alloc] initWithCString:PQgetvalue(res, i, x)] autorelease];
			
			switch (x)
			{
				case 0: // datname
					[db setName:fValue];
					break;
				default:
					break;
			} 
		}
	}
	
	return dbs;
	
}


- (NSString *)currentDatabase
{	
	char * currentDatabase = PQdb(pgconn);
	if (currentDatabase)
	{
		return [NSString stringWithCString:currentDatabase];
	}
	else
	{
		return [NSString stringWithString:@"Current database not defined."];
	}
}


- (NSString *)errorDescription;
{
	return errorDescription;
}

- (void)setErrorDescription:(NSString *)ed;
{
	[ed retain];
	[errorDescription release];
	errorDescription = ed;
}


- (NSMutableString *)sqlLog;
{
	return sqlLog;
}


- (void)setSQLLog:(NSString *)value 
{
	[sqlLog release];
	sqlLog = [[NSMutableString alloc] initWithString:value];
}

- (void)appendSQLLog:(NSString *)value 
{
	if (sqlLog == nil)
	{
		sqlLog = [[NSMutableString alloc] initWithString:value];
	}
	else
	{
		[sqlLog appendString:value];
	}
}



/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
- (RecordSet *)execQuery:(NSString *)sql
{
#if PG_COCOA_DEBUG == 1
	return [self execQuery:sql logInfo:0 logSQL:0];
#else
	return [self execQuery:sql logInfo:0 logSQL:0];
#endif
}

- (RecordSet *)execQueryNoLog:(NSString *)sql
{
	return [self execQuery:sql logInfo:0 logSQL:0];
}


- (RecordSet *)execQueryLogInfo:(NSString *)sql
{
	return [self execQuery:sql logInfo:1 logSQL:0];
}


- (RecordSet *)execQueryLogInfoLogSQL:(NSString *)sql
{
	return [self execQuery:sql logInfo:1 logSQL:1];
}


- (RecordSet *)execQuery:(NSString *)sql logInfo:(bool)logInfo logSQL:(bool)logSQL
{
	struct timeval start, finished;
	double elapsed_time;
	long seconds, usecs;
	PGresult* res;
	
	[errorDescription release];
	errorDescription = nil;

	if (pgconn == nil) 
	{ 
		[self setErrorDescription:@"Object is not Connected."];	
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
			RecordSet *rs = [[[RecordSet alloc] init] autorelease];
			long nFields = PQnfields(res);
			long nRecords = PQntuples(res);
			long i = 0;
			
			for ( i = 0; i < nRecords; i++)
			{
				// add the record
				Record *rec = [rs addItem];
				
				long x = 0;
				for  ( x = 0; x < nFields; x++)
				{
					Field *field = [[rec fields] addItem];
					[field setName:[NSString stringWithFormat:@"%s", PQfname(res, x)]];
					[field setValue:[NSString stringWithFormat:@"%s", PQgetvalue(res, i, x)]];
					//[field setDataType:(int)PQftype(res, i)];
				}
			}
			if (logInfo)
			{
				[self appendSQLLog:[NSString stringWithFormat: @"%d rows affected.\n\n", nRecords]];
			}
			PQclear(res);			
			return rs;
			break;
		}
		
		case PGRES_COMMAND_OK:
		{
			if (logInfo)
			{
				[self appendSQLLog:@"Query ran successfully.\n"];
				/* these do not return valuable info.
				if (strlen(PQcmdStatus(res)))
				{
					[self appendSQLLog:[NSString  stringWithFormat:@"Command Status: %s\n", PQcmdStatus(res)]];
				}
				if (PQcmdTuples(res))
				{
					[self appendSQLLog:[NSString stringWithFormat: @"%d rows affected.\n", PQcmdTuples(res)]];
				}
				 */
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
			[self setErrorDescription:[NSString stringWithFormat:@"PostgreSQL Error: %s", PQresultErrorMessage(res)]];
			[self appendSQLLog:[NSString stringWithFormat:@"PostgreSQL Error: %s\n", PQresultErrorMessage(res)]];
			PQclear(res);
			return nil;
		}
	}
}

- (NSString *)execCommand:(NSString *)sql
{
	PGresult* res;
	NSString *results;
	
	if (pgconn == nil) 
	{ 
		[self setErrorDescription:[NSString stringWithString:@"Object is not Connected."]];		
		return nil; 
	}
	
	res = PQexec(pgconn, [sql cString]);
	if (PQresultStatus(res) != PGRES_COMMAND_OK) 
	{
		[self setErrorDescription:[NSString stringWithString:@"Command failed."]];
		PQclear(res);
		return nil;
    }
	if (strlen(PQcmdStatus(res)))
	{
		[self appendSQLLog:[NSString stringWithFormat:@"%s\n", PQcmdStatus(res)]];
	}
	results = [[[NSString alloc] initWithCString:PQcmdTuples(res)] autorelease];
	PQclear(res);	
	return results;
}

- (int)cancelQuery
{
	int result = 0;
	char buffer[512];
	PGcancel * pg_cancel = PQgetCancel(pgconn);
	
	result = PQcancel(pg_cancel, buffer, 512);	
	PQfreeCancel(pg_cancel);
	[self setErrorDescription:[NSString stringWithFormat:@"%s", buffer]];
	return result;
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


@end
