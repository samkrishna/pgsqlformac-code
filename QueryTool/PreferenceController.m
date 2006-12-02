//
//  PreferenceController.m
//  Query Tool for PostgresN
//
//  Created by Neil Tiffin on 8/26/06.
//  Copyright 2006 Performance Champions, Inc.. All rights reserved.
//

#import "PreferenceController.h"


@implementation PreferenceController

-(id)init
{
	self = [super initWithWindowNibName:@"Preferences"];
	NSLog(@"Preference Controller init");
	return self;
}


-(void)loadUserDefaults
{
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	
	if ([userDefaults  boolForKey:UDShowInformationSchema])
	{
		[prefShowPGInfoSchema setState:NSOnState];
	}
	else
	{
		[prefShowPGInfoSchema setState:NSOffState];
	}
	if ([userDefaults  boolForKey:UDShowPGCatalogSchema])
	{
		[prefShowPGCatalogSchema setState:NSOnState];
	}
	else
	{
		[prefShowPGCatalogSchema setState:NSOffState];
	}
	if ([userDefaults  boolForKey:UDShowPGToastSchema])
	{
		[prefShowPGToastSchema setState:NSOnState];
	}
	else
	{
		[prefShowPGToastSchema setState:NSOffState];
	}
	if ([userDefaults  boolForKey:UDShowPGTempsSchema])
	{
		[prefShowPGTempSchema setState:NSOnState];
	}
	else
	{
		[prefShowPGTempSchema setState:NSOffState];
	}
	if ([userDefaults  boolForKey:UDShowPGPublicSchema])
	{
		[prefShowPGPublicSchema setState:NSOnState];
	}
	else
	{
		[prefShowPGPublicSchema setState:NSOffState];
	}
	
	if ([userDefaults  boolForKey:UDLogSQL])
	{
		[prefLogAllSQL setState:NSOnState];
	}
	else
	{
		[prefLogAllSQL setState:NSOffState];
	}
	if ([userDefaults  boolForKey:UDLogQueryInfo])
	{
		[prefLogInfoMessages setState:NSOnState];
	}
	else
	{
		[prefLogInfoMessages setState:NSOffState];
	}
	
	[prefPostgresqlHelpURL setStringValue:[userDefaults stringForKey:UDShowPostgreSQLHelp]];
	[prefPostgresqlSQLURL setStringValue:[userDefaults stringForKey:UDShowSQLCommandHelp]];	
}


-(void)windowDidLoad
{
	[self loadUserDefaults];
}


-(IBAction)defaultPreferences:(id)sender
{
	UNUSED_PARAMETER(sender);
	
	[prefShowPGInfoSchema setState:NSOnState];
	[prefShowPGCatalogSchema setState:NSOnState];
	[prefShowPGToastSchema setState:NSOffState];
	[prefShowPGTempSchema setState:NSOffState];
	[prefShowPGPublicSchema setState:NSOnState];
	[prefLogAllSQL setState:NSOnState];
	[prefLogInfoMessages setState:NSOnState];

	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ([fileManager fileExistsAtPath:@"/sw/share/doc/postgresql81/html/index.html"])
	{
		[prefPostgresqlHelpURL setStringValue:@"file:///sw/share/doc/postgresql81/html/index.html"];
	}
	else
	{
		[prefPostgresqlHelpURL setStringValue:@""];
	}
	if ([fileManager fileExistsAtPath:@"/sw/share/doc/postgresql81/html/sql-commands.html"])
	{
		[prefPostgresqlSQLURL setStringValue:@"file:///sw/share/doc/postgresql81/html/sql-commands.html"];
	}
	else
	{
		[prefPostgresqlSQLURL setStringValue:@""];
	}
}


-(IBAction)savePreferences:(id)sender;
{
	UNUSED_PARAMETER(sender);
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	if ([prefShowPGInfoSchema state])
	{
		[userDefaults setObject:@"yes" forKey:UDShowInformationSchema];
	}
	else
	{
		[userDefaults setObject:@"no" forKey:UDShowInformationSchema];
	}
	if ([prefShowPGCatalogSchema state])
	{
		[userDefaults setObject:@"yes" forKey:UDShowPGCatalogSchema];
	}
	else
	{
		[userDefaults setObject:@"no" forKey:UDShowPGCatalogSchema];
	}
	if ([prefShowPGToastSchema state])
	{
		[userDefaults setObject:@"yes" forKey:UDShowPGToastSchema];
	}
	else
	{
		[userDefaults setObject:@"no" forKey:UDShowPGToastSchema];
	}
	if ([prefShowPGTempSchema state])
	{
		[userDefaults setObject:@"yes" forKey:UDShowPGTempsSchema];
	}
	else
	{
		[userDefaults setObject:@"no" forKey:UDShowPGTempsSchema];
	}
	if ([prefShowPGPublicSchema state])
	{
		[userDefaults setObject:@"yes" forKey:UDShowPGPublicSchema];
	}
	else
	{
		[userDefaults setObject:@"no" forKey:UDShowPGPublicSchema];
	}

	if ([prefLogAllSQL state])
	{
		[userDefaults setObject:@"yes" forKey:UDLogSQL];
	}
	else
	{
		[userDefaults setObject:@"no" forKey:UDLogSQL];
	}
	if ([prefLogInfoMessages state])
	{
		[userDefaults setObject:@"yes" forKey:UDLogQueryInfo];
	}
	else
	{
		[userDefaults setObject:@"no" forKey:UDLogQueryInfo];
	}
	
	[userDefaults setObject:[prefPostgresqlHelpURL stringValue] forKey:UDShowPostgreSQLHelp];
	[userDefaults setObject:[prefPostgresqlSQLURL stringValue] forKey:UDShowSQLCommandHelp];
	[[NSUserDefaults standardUserDefaults] synchronize];
	[[self window] close];
}


-(IBAction)cancelPreferences:(id)sender;
{
	UNUSED_PARAMETER(sender);
	[self loadUserDefaults];
	[[self window] close];
	
}

/*
 NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
	 host, @"host", 
	 port, @"port", 
	 dbName, @"dbname", 
	 userName, @"user", 
	 nil];
	return dict;
*/

-(IBAction)deleteConnection:(id)sender;
{
	UNUSED_PARAMETER(sender);
	NSLog(@"%s: deleteConnection not implemented.", __FILE__);
	// TODO
}

-(IBAction)newConnection:(id)sender;
{
	UNUSED_PARAMETER(sender);
	NSLog(@"%s: newConnection not implemented.", __FILE__);
	// TODO
}

-(IBAction)selectConnection:(id)sender;
{
	UNUSED_PARAMETER(sender);
	NSLog(@"%s: selectConnection not implemented.", __FILE__);
	// TODO
}


-(void)createApplicationDefaultPreferences
{
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	
	// does not track application version numbering, for future use should we need to
	// drastically change the prefs we will be able to quickly determine what version of prefs
	// the user has.
	if ([userDefaults stringForKey:UDUserDefaultsVersion] == nil)
	{
		[userDefaults setObject:@"2" forKey:UDUserDefaultsVersion];
	}
	if ([userDefaults stringForKey:UDShowInformationSchema] == nil)
	{
		[userDefaults setObject:@"yes" forKey:UDShowInformationSchema];
	}
	if ([userDefaults stringForKey:UDShowPGCatalogSchema] == nil)
	{
		[userDefaults setObject:@"yes" forKey:UDShowPGCatalogSchema];
	}
	if ([userDefaults stringForKey:UDShowPGToastSchema] == nil)
	{
		[userDefaults setObject:@"no" forKey:UDShowPGToastSchema];
	}
	if ([userDefaults stringForKey:UDShowPGTempsSchema] == nil)
	{
		[userDefaults setObject:@"no" forKey:UDShowPGTempsSchema];
	}
	if ([userDefaults stringForKey:UDShowPGPublicSchema] == nil)
	{
		[userDefaults setObject:@"yes" forKey:UDShowPGPublicSchema];
	}
	if ([userDefaults stringForKey:UDLogSQL] == nil)
	{
		[userDefaults setObject:@"yes" forKey:UDLogSQL];
	}
	if ([userDefaults stringForKey:UDLogQueryInfo] == nil)
	{
		[userDefaults setObject:@"yes" forKey:UDLogQueryInfo];
	}
	
	
	if ([userDefaults stringForKey:UDSchemaTableFontName] == nil)
	{
		[userDefaults setObject:@"Lucida Grande" forKey:UDSchemaTableFontName];
	}
	if ([userDefaults stringForKey:UDSchemaTableFontSize] == nil)
	{
		[userDefaults setFloat:12.0 forKey:UDSchemaTableFontSize];
	}
	if ([userDefaults stringForKey:UDResultsTableFontName] == nil)
	{
		[userDefaults setObject:@"Lucida Grande" forKey:UDResultsTableFontName];
	}
	if ([userDefaults stringForKey:UDResultsTableFontSize] == nil)
	{
		[userDefaults setFloat:12.0 forKey:UDResultsTableFontSize];
	}
	
	
	if ([userDefaults stringForKey:UDHighlight_Keywords] == nil)
	{
		[userDefaults setObject:@"select from where order group by asc desc insert into delete drop create alter table procedure view function"
						 forKey:UDHighlight_Keywords];
	}
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ([userDefaults stringForKey:UDShowPostgreSQLHelp] == nil)
	{
		if ([fileManager fileExistsAtPath:@"/sw/share/doc/postgresql81/html/index.html"])
		{
			[userDefaults setObject:@"file:///sw/share/doc/postgresql81/html/index.html"
							 forKey:UDShowPostgreSQLHelp];
		}
	}
	if ([userDefaults stringForKey:UDShowSQLCommandHelp] == nil)
	{
		if ([fileManager fileExistsAtPath:@"/sw/share/doc/postgresql81/html/sql-commands.html"])
		{
			[userDefaults setObject:@"file:///sw/share/doc/postgresql81/html/sql-commands.html"
							 forKey:UDShowSQLCommandHelp];
		}
	}
	if ([userDefaults arrayForKey:UDConnArrayName] == nil)
	{
		// Create dictionary with connection details.
		NSMutableDictionary *aConnDict = [NSMutableDictionary dictionaryWithCapacity:6];
		
		[aConnDict setObject:@"" forKey:UDConnUserName];
		[aConnDict setObject:@"localhost" forKey:UDConnHost];
		[aConnDict setObject:@"5432" forKey:UDConnPort];
		[aConnDict setObject:@"" forKey:UDConnDatabaseName];
		[aConnDict setObject:@"Default" forKey:UDConnName];
				
		// Update UserDefaults.
		NSMutableArray *connArray = [NSMutableArray arrayWithCapacity:1];
		[connArray addObject:aConnDict];
		[userDefaults setObject:connArray forKey:UDConnArrayName];
		NSLog(@"Adding new Connection Array: %s, Line %d", __FILE__, __LINE__);
		
		[userDefaults setObject:@"None" forKey:UDLastConn];
	}
	
	/* remove old user defaults */
	
	/* Added 2006_11_11 */
	NSString * const    UDUserDefaultsVersionOLD1 = @"PGSqlForMac_QueryTool_User_Defaults_Version";
	NSString * const    UDUserDefaultsVersionOLD2 = @"PGSqlForMac_QueryTool_Pref_Version";
	if ([userDefaults stringForKey:UDUserDefaultsVersionOLD1] != nil)
	{
		[userDefaults removeObjectForKey:UDUserDefaultsVersionOLD1];
	}
	if ([userDefaults stringForKey:UDUserDefaultsVersionOLD2] != nil)
	{
		[userDefaults removeObjectForKey:UDUserDefaultsVersionOLD2];
	}
	
	/* Added 2006_12_01 */
	NSString * const    UDDefaultUserName = @"PGSqlForMac_QueryTool_DefaultUserName";
	NSString * const    UDDefaultHost = @"PGSqlForMac_QueryTool_DefaultHost";
	NSString * const    UDDefaultPort = @"PGSqlForMac_QueryTool_DefaultPort";
	NSString * const    UDDefaultDatabaseName = @"PGSqlForMac_QueryTool_DefaultDatabaseName";
	if ([userDefaults stringForKey:UDDefaultUserName] != nil)
	{
		[userDefaults removeObjectForKey:UDDefaultUserName];
	}
	if ([userDefaults stringForKey:UDDefaultHost] != nil)
	{
		[userDefaults removeObjectForKey:UDDefaultHost];
	}
	if ([userDefaults stringForKey:UDDefaultPort] != nil)
	{
		[userDefaults removeObjectForKey:UDDefaultPort];
	}
	if ([userDefaults stringForKey:UDDefaultDatabaseName] != nil)
	{
		[userDefaults removeObjectForKey:UDDefaultDatabaseName];
	}
	
	
}

@end
