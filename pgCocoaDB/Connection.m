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
	
	connected = NO;
	
	host = [[NSString alloc] initWithString:@"localhost"];
	port = [[NSString alloc] initWithString:@"5432"];
	options = nil;
	tty = nil;
	dbName = [[NSString alloc] initWithString:@"template1"];
	
	dbs = nil;
	
	errorDescription = nil;
	sqlLog = [[NSMutableString alloc] init];
	
	return self;
}

-(void)dealloc
{
	if (connected)
	{
		[self disconnect];
	}
	[host release];
	[port release];
	[options release];
	[tty release];
	[dbName release];
	[userName release];
	[password release];
	[dbs release];
	[errorDescription release];
	[sqlLog release];
	
	[super dealloc];
}

- (BOOL)connect
{	
	// connect to the server (attempt) /// should use PQsetdbLogin()
	if (dbs != nil) {
		[dbs release];
		dbs = nil;
	}
	
	pgconn = (PGconn *)PQsetdbLogin([host cString], [port cString],
					 [options cString], NULL, 
					 [dbName cString], [userName cString], [password cString]);
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

		PQfinish(pgconn);
		connected = NO;
		return NO;
    }
	
	if (errorDescription)
		[errorDescription release];
	errorDescription = nil;
	
	// set up notification
	PQsetNoticeProcessor(pgconn, handle_pq_notice, self);

	[self setSQLLog:[NSMutableString stringWithFormat:@"Connected to database %@.\n", dbName]];
	connected = YES;
	return YES;
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
	connected = NO;
	return YES;
}

// accessor methods 

- (BOOL)isConnected
{
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


- (RecordSet *)execQueryLog:(NSString *)sql
{
	return [self execQuery:sql logInfo:1 logSQL:0];
}


- (RecordSet *)execQueryNoLog:(NSString *)sql
{
	return [self execQuery:sql logInfo:0 logSQL:0];
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
		return nil; 
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
				[self appendSQLLog:[NSString stringWithFormat: @"%d rows affected.\n", nRecords]];
			}
			PQclear(res);			
			return rs;
			break;
		}
		
		case PGRES_COMMAND_OK:
		{
			if (strlen(PQcmdStatus(res)))
			{
				[self appendSQLLog:[NSString  stringWithFormat:@"%s\n", PQcmdStatus(res)]];
			}
			if ((strlen(PQcmdTuples(res)) > 0) && (logInfo))
			{
				[self appendSQLLog:[NSString stringWithFormat: @"%s rows affected.\n", PQcmdTuples(res)]];
			}
			PQclear(res);
			return nil;
			break;
		}

		case PGRES_EMPTY_QUERY:
		{
			if (logInfo)
			{
				[self appendSQLLog:@"Postgres reported Empty Query\n"];
			}
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

@end
