//
//  Connection.h
//  PGDB
//
//  Created by Andy Satori on Thu Jan 29 2004.
//  Copyright (c) 2004 Druware Software Designs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Record.h"
#import "Recordset.h"
#import "Databases.h"

@interface Connection : NSObject 
{
	BOOL			 connected;
	
	NSString		*host;
	NSString		*port;
	NSString		*options;
	NSString		*tty;		// ignored now
	NSString		*dbName;
	NSString		*userName;
	NSString		*password;
	NSString		*sslMode;	// allow, prefer, require
	NSString		*service;	// service name
	NSString		*krbsrvName;
	
	NSMutableString		*connectionString;
	
	Databases		*dbs;
	
	NSString		*errorDescription;
	NSMutableString		*sqlLog;
	
	void			*pgconn;
}

- (BOOL)connect;
- (BOOL)connectUsingString:(NSString *)aConnectionString;
- (BOOL)connectToHost:(NSString *)toHost
			  onPort:(NSString *)onPort
		 withOptions:(NSString *)withOptions
			  useTTY:(NSString *)useTTY
		 useDatabase:(NSString *)userDB;
- (BOOL)disconnect;

- (BOOL)isConnected;

- (NSString *)host;
- (void)setHost:(NSString *)newHost;

- (NSString *)port;
- (void)setPort:(NSString *)newPort;

- (NSString *)options;
- (void)setOptions:(NSString *)newOptions;

- (NSString *)tty;
- (void)setTty:(NSString *)newTty;

- (NSString *)dbName;
- (void)setDbName:(NSString *)newDbName;

- (NSString *)userName;
- (void)setUserName:(NSString *)value;

- (NSString *)password;
- (void)setPassword:(NSString *)value;

- (NSString *)sslMode;
- (void)setSslMode:(NSString *)value;

- (NSString *)service;
- (void)setService:(NSString *)value;

- (NSString *)krbsrvName;
- (void)setKrbsrvName:(NSString *)value;

- (NSString *)errorDescription;
- (void)setErrorDescription:(NSString *)ed;

- (NSString *)connectionString;
- (void)setConnectionString:(NSString *)ed;

- (NSMutableString *)sqlLog;
- (void)setSQLLog:(NSString *)value;
- (void)appendSQLLog:(NSString *)value;

- (RecordSet *)execQuery:(NSString *)sql;
- (RecordSet *)execQueryLogInfo:(NSString *)sql;
- (RecordSet *)execQueryLogInfoLogSQL:(NSString *)sql;
- (RecordSet *)execQueryNoLog:(NSString *)sql;
- (RecordSet *)execQuery:(NSString *)sql logInfo:(bool)logInfo logSQL:(bool)logSQL;
- (NSString *)execCommand:(NSString *)sql;

- (Databases *)databases;

- (NSString *)currentDatabase;

- (int)cancelQuery;
- (NSMutableString *)makeConnectionString;

@end
