//
//  PreferenceController.h
//  Query Tool for PostgresN
//
//  Created by Neil Tiffin on 8/26/06.
//  Copyright 2006 Performance Champions, Inc.. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QueryTool.h"

/* Active NSUserDefaults Key Strings */
extern  NSString * UDUserDefaultsVersion;
extern  NSString * UDShowInformationSchema;
extern  NSString * UDShowPGCatalogSchema;
extern  NSString * UDShowPGToastSchema;
extern  NSString * UDShowPGTempsSchema;
extern  NSString * UDShowPGPublicSchema;
extern  NSString * UDLogSQL;
extern  NSString * UDLogQueryInfo;
extern  NSString * UDShowPostgreSQLHelp;
extern  NSString * UDShowSQLCommandHelp;
extern  NSString * UDResultsTableFontName;
extern  NSString * UDResultsTableFontSize;
extern  NSString * UDHighlight_Keywords;
extern  NSString * UDSchemaTableFontName;
extern  NSString * UDSchemaTableFontSize;

// New connection key names for connection dictionary
extern  NSString *     UDConnArrayName;
extern  NSString *     UDConnName;
extern  NSString *     UDConnUserName;
extern  NSString *     UDConnHost;
extern  NSString *     UDConnPort;
extern  NSString *     UDConnDatabaseName;

// Last Connection Name
extern  NSString *     UDLastConn;

@interface PreferenceController : NSWindowController {	
	IBOutlet NSButton		*prefShowPGInfoSchema;
	IBOutlet NSButton		*prefShowPGCatalogSchema;
	IBOutlet NSButton		*prefShowPGToastSchema;
	IBOutlet NSButton		*prefShowPGTempSchema;
	IBOutlet NSButton		*prefShowPGPublicSchema;
	
	IBOutlet NSButton		*prefLogAllSQL;
	IBOutlet NSButton		*prefLogInfoMessages;
	
	IBOutlet NSTextField	*prefPostgresqlHelpURL;
	IBOutlet NSTextField	*prefPostgresqlSQLURL;
	
	IBOutlet NSTextField	*prefConnUserName;
	IBOutlet NSTextField	*prefConnPassword;
	IBOutlet NSTextField	*prefConnDBName;
	IBOutlet NSTextField	*prefConnServer;
	IBOutlet NSTextField	*prefConnPort;
}

-(IBAction)defaultPreferences:(id)sender;
-(IBAction)savePreferences:(id)sender;
-(IBAction)cancelPreferences:(id)sender;
-(IBAction)deleteConnection:(id)sender;
-(IBAction)newConnection:(id)sender;
-(IBAction)selectConnection:(id)sender;

-(void)createApplicationDefaultPreferences;

@end

/* Userdefaults History */
/* Version */
/* 1 = Prior to correct UDUserDefaultsVersion value */
/* 2 = current */
