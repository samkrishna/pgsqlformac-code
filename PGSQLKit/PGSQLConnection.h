//
//  PGSQLConnection.h
//  PGSQLKit
//
//  Created by Andy Satori on 5/8/07.
//  Copyright 2007 Druware Software Designs. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PGSQLRecordset.h"

@interface PGSQLConnection : NSObject {	
	BOOL isConnected;
	
	NSString *connectionString;
	
	NSString *errorDescription;
	NSMutableString	*sqlLog;
	
	/* platform specific definitions */
	
	BOOL logInfo;
	BOOL logSQL;
	
	void			*pgconn;
	
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
		
	NSString		*commandStatus;
}

+(id)defaultConnection;

-(BOOL)close;
-(BOOL)connect;
-(void)connectAsync;
-(BOOL)execCommand:(NSString *)sql;
-(void)execCommandAsync:(NSString *)sql;
-(PGSQLRecordset *)open:(NSString *)sql;
-(void)openAsync:(NSString *)sql;
-(NSMutableString *)makeConnectionString;

-(BOOL)isConnected;

-(NSString *)connectionString;
-(void)setConnectionString:(NSString *)value;

-(NSString *)userName;
-(void)setUserName:(NSString *)value;

-(NSString *)password;
-(void)setPassword:(NSString *)value;

-(NSString *)server;
-(void)setServer:(NSString *)value;

-(NSString *)port;
-(void)setPort:(NSString *)value;

-(NSString *)databaseName;
-(void)setDatabaseName:(NSString *)value;

-(NSString *)lastError;

-(NSMutableString *)sqlLog;
-(void)appendSQLLog:(NSString *)value;
	
-(NSString *)lastCmdStatus;

FOUNDATION_EXPORT NSString * const PGSQLConnectionDidCompleteNotification;
FOUNDATION_EXPORT NSString * const PGSQLCommandDidCompleteNotification;	

@end

static PGSQLConnection *globalPGSQLConnection;
