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
NSString * const    UDUserDefaultsVersion = @"PGSqlForMac_QueryTool_UserDefaultsVersion";
NSString * const    UDShowInformationSchema = @"PGSqlForMac_QueryTool_ShowInformationSchema";
NSString * const    UDShowPGCatalogSchema = @"PGSqlForMac_QueryTool_ShowPGCatalogSchema";
NSString * const    UDShowPGToastSchema = @"PGSqlForMac_QueryTool_ShowPGToastSchema";
NSString * const    UDShowPGTempsSchema = @"PGSqlForMac_QueryTool_ShowPGTempsSchema";
NSString * const    UDShowPGPublicSchema = @"PGSqlForMac_QueryTool_ShowPGPublicSchema";
NSString * const    UDLogSQL = @"PGSqlForMac_QueryTool_LogSQL";
NSString * const    UDLogQueryInfo = @"PGSqlForMac_QueryTool_LogQueryInfo";
NSString * const    UDShowPostgreSQLHelp = @"PGSqlForMac_QueryTool_ShowPostgreSQLHelp";
NSString * const    UDShowSQLCommandHelp = @"PGSqlForMac_QueryTool_ShowSQLCommandHelp";
NSString * const    UDResultsTableFontName = @"PGSqlForMac_QueryTool_ResultsTableFontName";
NSString * const    UDResultsTableFontSize = @"PGSqlForMac_QueryTool_ResultsTableFontSize";
NSString * const    UDHighlight_Keywords = @"PGSqlForMac_QueryTool_Highlight_Keywords";
NSString * const    UDSchemaTableFontName = @"PGSqlForMac_QueryTool_SchemaTableFontName";
NSString * const    UDSchemaTableFontSize = @"PGSqlForMac_QueryTool_SchemaTableFontSize";

// New connection key names for connection dictionary
NSString * const	UDConnArrayName = @"ConnArray";
NSString * const    UDConnName = @"Name";
NSString * const    UDConnUserName = @"UserName";
NSString * const    UDConnHost = @"Host";
NSString * const    UDConnPort = @"Port";
NSString * const    UDConnDatabaseName = @"DatabaseName";

// Last Connection Name
NSString * const    UDLastConn = @"LastConnection";

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
