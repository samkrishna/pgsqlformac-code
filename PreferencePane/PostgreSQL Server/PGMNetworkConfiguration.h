//
//  PGMNetworkConfiguration.h
//  PostgreSQL Server
//
//  Created by Andy Satori on 2/19/09.
//  Copyright 2009 Druware Software Designs. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PGHBAFile.h"

@interface PGMNetworkConfiguration : NSObject {
	
	IBOutlet NSPanel *thisPanel;
	PGHBAFile *hbaConfiguration;
	
	BOOL shouldRestartService;
	
	NSMutableDictionary *currentEntry;
	
	IBOutlet NSTextView *rawSource;
	
	IBOutlet NSTableView *allConnectionList;
	
	IBOutlet NSPanel *connectionDetails;
	IBOutlet NSTextField *database;
	IBOutlet NSTextField *userName;
	IBOutlet NSPopUpButton *type;
	IBOutlet NSPopUpButton *group;
	IBOutlet NSTextField *address;
	IBOutlet NSPopUpButton *method;
	IBOutlet NSTextField *option;
	NSWindow *parentWindow;
}

- (void)showModalForWindow:(NSWindow *)window;

- (IBAction)onSelectRecord:(id)sender;
- (IBAction)onSetRecord:(id)sender;

- (IBAction)onOK:(id)sender;
- (IBAction)onCancel:(id)sender;

- (BOOL)shouldRestartService;

@end
