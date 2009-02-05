//
//  PGNCController.h
//  PostgreSQL Network Configuration
//
//  Created by Andy Satori on 11/13/08.
//  Copyright 2008 Druware Software Designs. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <Security/Authorization.h>
#include <Security/AuthorizationTags.h>

#import "PGHBAFile.h"

@interface PGNCController : NSObject {
	PGHBAFile *hbaConfiguration;
	
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
}

-(IBAction)onAddEntry:(id)sender;
-(IBAction)onEditEntry:(id)sender;
-(IBAction)onDeleteEntry:(id)sender;
-(IBAction)onEditOK:(id)sender;
-(IBAction)onEditCancel:(id)sender;

-(IBAction)fetchActiveConfiguration:(id)sender;
-(IBAction)pushNewConfiguration:(id)sender;

@end
