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
	[self loadUserDefaults];
	[[self window] close];
	
}

@end
