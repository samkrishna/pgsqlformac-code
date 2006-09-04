//
//  PreferenceController.h
//  Query Tool for PostgresN
//
//  Created by Neil Tiffin on 8/26/06.
//  Copyright 2006 Performance Champions, Inc.. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QueryTool.h"

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
}

-(IBAction)defaultPreferences:(id)sender;
-(IBAction)savePreferences:(id)sender;
-(IBAction)cancelPreferences:(id)sender;

-(void)createApplicationDefaultPreferences;

@end
