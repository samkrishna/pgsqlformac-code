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
	
	host = [[[[NSString alloc] initWithString:@"localhost"] retain] autorelease];
	port = [[[[NSString alloc] initWithString:@"5432"] retain] autorelease];
	options = [[[[NSString alloc] init] retain] autorelease];
	tty = [[[[NSString alloc] init] retain] autorelease];
	dbName = [[[[NSString alloc] initWithString:@"template1"] retain] autorelease];
	
	dbs = nil;
	
	errorDescription = [[[[NSString alloc] init] retain] autorelease];
	sqlLog = [[NSMutableString alloc] init];
	
	return self;
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
		[errorDescription release];
		errorDescription = [[NSString alloc] initWithFormat:@"%s", PQerrorMessage(pgconn)];
		[[errorDescription retain] autorelease];
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
    return [[host retain] autorelease];
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
    return [[port retain] autorelease];
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
	return [[options retain] autorelease];
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
	return [[tty retain] autorelease];
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
	return [[dbName retain] autorelease];
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
    return [[userName retain] autorelease];
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
    return [[password retain] autorelease];
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
		[errorDescription release];
		errorDescription = [[NSString alloc] initWithString:@"Command did not return any data."];
		[[errorDescription retain] autorelease];
		PQclear(res);
		return nil;
    }
	
	// build the collection
	dbs = [[[[Databases alloc] init] retain] autorelease];
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
			NSString *fValue = [[NSString alloc] initWithCString:PQgetvalue(res, i, x)];
			
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
		return [[[NSString stringWithCString:currentDatabase] retain] autorelease];
	}
	else
	{
		return [[NSString alloc] initWithString:@"Current database not defined."];;
	}
}


- (NSString *)errorDescription;
{
	return [[errorDescription retain] autorelease];
}


- (NSMutableString *)sqlLog;
{
	return [[sqlLog retain] autorelease];
}


- (void)setSQLLog:(NSString *)value 
{
	[sqlLog release];
	sqlLog = [NSMutableString stringWithString:value];
	[sqlLog retain];
}

- (void)appendSQLLog:(NSString *)value 
{
	if (sqlLog == nil)
	{
		sqlLog = [NSMutableString stringWithString:value];
		[sqlLog retain];
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
		errorDescription = [[NSString alloc] initWithString:@"Object is not Connected."];
		[[errorDescription retain] autorelease];
		
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
			RecordSet *rs = [[[[RecordSet alloc] init] retain] autorelease];
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
			errorDescription = [[NSString alloc] initWithFormat:@"PostgreSQL Error: %s",
				PQresultErrorMessage(res)];
			[[errorDescription retain] autorelease];
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
		[errorDescription release];
		errorDescription = [[NSString alloc] initWithString:@"Object is not Connected."];
		[[errorDescription retain] autorelease];
		
		return nil; 
	}
	
	res = PQexec(pgconn, [sql cString]);
	if (PQresultStatus(res) != PGRES_COMMAND_OK) 
	{
		[errorDescription release];
		errorDescription = [[NSString alloc] initWithString:@"Command failed."];
		[[errorDescription retain] autorelease];
		PQclear(res);
		return nil;
    }
	if (strlen(PQcmdStatus(res)))
	{
		[self appendSQLLog:[[NSString alloc] initWithFormat:@"%s\n", PQcmdStatus(res)]];
	}
	results = [[[[NSString alloc] initWithCString:PQcmdTuples(res)] retain] autorelease];
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
	[errorDescription release];
	errorDescription = [[NSString alloc] initWithFormat:@"%s", buffer];
	return result;
}

@end
