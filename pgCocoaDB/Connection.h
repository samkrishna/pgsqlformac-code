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
	NSString		*tty;
	NSString		*dbName;
	NSString		*userName;
	NSString		*password;
	
	NSString		*errorDescription;
	
	void			*pgconn;
}

- (BOOL)connect;
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

- (NSString *)errorDescription;

- (RecordSet *)execQuery:(NSString *)sql;
- (NSString *)execCommand:(NSString *)sql;

- (Databases *)databases;

@end
