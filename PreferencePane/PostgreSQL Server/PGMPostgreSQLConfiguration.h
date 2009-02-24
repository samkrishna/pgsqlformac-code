//
//  PGMPostgreSQLConfiguration.h
//  PostgreSQL Server
//
//  Created by Andy Satori on 2/19/09.
//  Copyright 2009 Druware Software Designs. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PGPostgreSQLConfFile.h"


@interface PGMPostgreSQLConfiguration : NSObject {
	
	IBOutlet NSPanel *thisPanel;
	PGPostgreSQLConfFile *pgConfiguration;
	
	BOOL shouldRestartService;
	
	NSMutableDictionary *currentEntry;
	
	IBOutlet NSTextView *rawSource;
	
	IBOutlet NSTableView *allConnectionList;
	
	IBOutlet NSPanel *connectionDetails;
	IBOutlet NSTextField *database;
	IBOutlet NSTextField *userName;
	IBOutlet NSPopUpButton *type;
	IBOutlet NSPopUpButton *group;
	IBOutlet NSTextField *option;
	IBOutlet NSPopUpButton *method;
	NSWindow *parentWindow;
}

- (void)showModalForWindow:(NSWindow *)window;

- (IBAction)onOK:(id)sender;
- (IBAction)onCancel:(id)sender;

- (BOOL)shouldRestartService;


@end
