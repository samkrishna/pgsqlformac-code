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
	
	if ([userDefaults  boolForKey:@"PGSqlForMac_QueryTool_ShowInformationSchema"])
	{
		[prefShowPGInfoSchema setState:NSOnState];
	}
	else
	{
		[prefShowPGInfoSchema setState:NSOffState];
	}
	if ([userDefaults  boolForKey:@"PGSqlForMac_QueryTool_ShowPGCatalogSchema"])
	{
		[prefShowPGCatalogSchema setState:NSOnState];
	}
	else
	{
		[prefShowPGCatalogSchema setState:NSOffState];
	}
	if ([userDefaults  boolForKey:@"PGSqlForMac_QueryTool_ShowPGToastSchema"])
	{
		[prefShowPGToastSchema setState:NSOnState];
	}
	else
	{
		[prefShowPGToastSchema setState:NSOffState];
	}
	if ([userDefaults  boolForKey:@"PGSqlForMac_QueryTool_ShowPGTempsSchema"])
	{
		[prefShowPGTempSchema setState:NSOnState];
	}
	else
	{
		[prefShowPGTempSchema setState:NSOffState];
	}
	if ([userDefaults  boolForKey:@"PGSqlForMac_QueryTool_ShowPGPublicSchema"])
	{
		[prefShowPGPublicSchema setState:NSOnState];
	}
	else
	{
		[prefShowPGPublicSchema setState:NSOffState];
	}
	
	if ([userDefaults  boolForKey:@"PGSqlForMac_QueryTool_LogSQL"])
	{
		[prefLogAllSQL setState:NSOnState];
	}
	else
	{
		[prefLogAllSQL setState:NSOffState];
	}
	if ([userDefaults  boolForKey:@"PGSqlForMac_QueryTool_LogQueryInfo"])
	{
		[prefLogInfoMessages setState:NSOnState];
	}
	else
	{
		[prefLogInfoMessages setState:NSOffState];
	}
	
	[prefPostgresqlHelpURL setStringValue:[userDefaults stringForKey:@"PGSqlForMac_QueryTool_ShowPostgreSQLHelp"]];
	[prefPostgresqlSQLURL setStringValue:[userDefaults stringForKey:@"PGSqlForMac_QueryTool_ShowSQLCommandHelp"]];	
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

	[prefPostgresqlHelpURL setStringValue:@"file:///sw/share/doc/postgresql81/html/index.html"];
	[prefPostgresqlSQLURL setStringValue:@"file:///sw/share/doc/postgresql81/html/sql-commands.html"];
}


-(IBAction)savePreferences:(id)sender;
{
	UNUSED_PARAMETER(sender);
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	if ([prefShowPGInfoSchema state])
	{
		[userDefaults setObject:@"yes" forKey:@"PGSqlForMac_QueryTool_ShowInformationSchema"];
	}
	else
	{
		[userDefaults setObject:@"no" forKey:@"PGSqlForMac_QueryTool_ShowInformationSchema"];
	}
	if ([prefShowPGCatalogSchema state])
	{
		[userDefaults setObject:@"yes" forKey:@"PGSqlForMac_QueryTool_ShowPGCatalogSchema"];
	}
	else
	{
		[userDefaults setObject:@"no" forKey:@"PGSqlForMac_QueryTool_ShowPGCatalogSchema"];
	}
	if ([prefShowPGToastSchema state])
	{
		[userDefaults setObject:@"yes" forKey:@"PGSqlForMac_QueryTool_ShowPGToastSchema"];
	}
	else
	{
		[userDefaults setObject:@"no" forKey:@"PGSqlForMac_QueryTool_ShowPGToastSchema"];
	}
	if ([prefShowPGTempSchema state])
	{
		[userDefaults setObject:@"yes" forKey:@"PGSqlForMac_QueryTool_ShowPGTempsSchema"];
	}
	else
	{
		[userDefaults setObject:@"no" forKey:@"PGSqlForMac_QueryTool_ShowPGTempsSchema"];
	}
	if ([prefShowPGPublicSchema state])
	{
		[userDefaults setObject:@"yes" forKey:@"PGSqlForMac_QueryTool_ShowPGPublicSchema"];
	}
	else
	{
		[userDefaults setObject:@"no" forKey:@"PGSqlForMac_QueryTool_ShowPGPublicSchema"];
	}

	if ([prefLogAllSQL state])
	{
		[userDefaults setObject:@"yes" forKey:@"PGSqlForMac_QueryTool_LogSQL"];
	}
	else
	{
		[userDefaults setObject:@"no" forKey:@"PGSqlForMac_QueryTool_LogSQL"];
	}
	if ([prefLogInfoMessages state])
	{
		[userDefaults setObject:@"yes" forKey:@"PGSqlForMac_QueryTool_LogQueryInfo"];
	}
	else
	{
		[userDefaults setObject:@"no" forKey:@"PGSqlForMac_QueryTool_LogQueryInfo"];
	}
	
	[userDefaults setObject:[prefPostgresqlHelpURL stringValue] forKey:@"PGSqlForMac_QueryTool_ShowPostgreSQLHelp"];
	[userDefaults setObject:[prefPostgresqlSQLURL stringValue] forKey:@"PGSqlForMac_QueryTool_ShowSQLCommandHelp"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	[[self window] close];
}


-(IBAction)cancelPreferences:(id)sender;
{
	UNUSED_PARAMETER(sender);
	[self loadUserDefaults];
	[[self window] close];
	
}

-(void)createApplicationDefaultPreferences
{
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	
	// does not track application version numbering, for future use should we need to
	// drastically change the prefs we will be able to determine what version of prefs
	// the user has.
	if ([userDefaults stringForKey:@"PGSqlForMac_QueryTool_User_Defaults_Version"] == nil)
	{
		[userDefaults setObject:@"1.0.0" forKey:@"PGSqlForMac_QueryTool_Pref_Version"];
	}
	
	
	if ([userDefaults stringForKey:@"PGSqlForMac_QueryTool_ShowInformationSchema"] == nil)
	{
		[userDefaults setObject:@"yes" forKey:@"PGSqlForMac_QueryTool_ShowInformationSchema"];
	}
	if ([userDefaults stringForKey:@"PGSqlForMac_QueryTool_ShowPGCatalogSchema"] == nil)
	{
		[userDefaults setObject:@"yes" forKey:@"PGSqlForMac_QueryTool_ShowPGCatalogSchema"];
	}
	if ([userDefaults stringForKey:@"PGSqlForMac_QueryTool_ShowPGToastSchema"] == nil)
	{
		[userDefaults setObject:@"no" forKey:@"PGSqlForMac_QueryTool_ShowPGToastSchema"];
	}
	if ([userDefaults stringForKey:@"PGSqlForMac_QueryTool_ShowPGTempsSchema"] == nil)
	{
		[userDefaults setObject:@"no" forKey:@"PGSqlForMac_QueryTool_ShowPGTempsSchema"];
	}
	if ([userDefaults stringForKey:@"PGSqlForMac_QueryTool_ShowPGPublicSchema"] == nil)
	{
		[userDefaults setObject:@"yes" forKey:@"PGSqlForMac_QueryTool_ShowPGPublicSchema"];
	}
	if ([userDefaults stringForKey:@"PGSqlForMac_QueryTool_LogSQL"] == nil)
	{
		[userDefaults setObject:@"yes" forKey:@"PGSqlForMac_QueryTool_LogSQL"];
	}
	if ([userDefaults stringForKey:@"PGSqlForMac_QueryTool_LogQueryInfo"] == nil)
	{
		[userDefaults setObject:@"yes" forKey:@"PGSqlForMac_QueryTool_LogQueryInfo"];
	}
	
	
	if ([userDefaults stringForKey:@"PGSqlForMac_QueryTool_SchemaTableFontName"] == nil)
	{
		[userDefaults setObject:@"Lucida Grande" forKey:@"PGSqlForMac_QueryTool_SchemaTableFontName"];
	}
	if ([userDefaults stringForKey:@"PGSqlForMac_QueryTool_SchemaTableFontSize"] == nil)
	{
		[userDefaults setFloat:12.0 forKey:@"PGSqlForMac_QueryTool_SchemaTableFontSize"];
	}
	if ([userDefaults stringForKey:@"PGSqlForMac_QueryTool_ResultsTableFontName"] == nil)
	{
		[userDefaults setObject:@"Lucida Grande" forKey:@"PGSqlForMac_QueryTool_ResultsTableFontName"];
	}
	if ([userDefaults stringForKey:@"PGSqlForMac_QueryTool_ResultsTableFontSize"] == nil)
	{
		[userDefaults setFloat:12.0 forKey:@"PGSqlForMac_QueryTool_ResultsTableFontSize"];
	}
	
	
	if ([userDefaults stringForKey:@"PGSqlForMac_QueryTool_Highlight_Keywords"] == nil)
	{
		[userDefaults setObject:@"select from where order group by asc desc insert into delete drop create alter table procedure view function"
						 forKey:@"PGSqlForMac_QueryTool_Highlight_Keywords"];
	}
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ([userDefaults stringForKey:@"PGSqlForMac_QueryTool_ShowPostgreSQLHelp"] == nil)
	{
		if ([fileManager fileExistsAtPath:@"/sw/share/doc/postgresql81/html/index.html"])
		{
			[userDefaults setObject:@"file:///sw/share/doc/postgresql81/html/index.html"
							 forKey:@"PGSqlForMac_QueryTool_ShowPostgreSQLHelp"];
		}
	}
	if ([userDefaults stringForKey:@"PGSqlForMac_QueryTool_ShowSQLCommandHelp"] == nil)
	{
		if ([fileManager fileExistsAtPath:@"/sw/share/doc/postgresql81/html/sql-commands.html"])
		{
			[userDefaults setObject:@"file:///sw/share/doc/postgresql81/html/sql-commands.html"
							 forKey:@"PGSqlForMac_QueryTool_ShowSQLCommandHelp"];
		}
	}	
}

@end
