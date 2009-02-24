//
//  PGMPostgreSQLConfiguration.m
//  PostgreSQL Server
//
//  Created by Andy Satori on 2/19/09.
//  Copyright 2009 Druware Software Designs. All rights reserved.
//

#import "PGMPostgreSQLConfiguration.h"


@implementation PGMPostgreSQLConfiguration

- (void)showModalForWindow:(NSWindow *)window
{
	parentWindow = window;
	
	shouldRestartService = NO;
	
	// show the dialog modal
	// load the nib
	if (![NSBundle loadNibNamed:@"PostgreSQLConfigurationPanel" owner:self]) 
	{
		NSLog(@"Error loading nib.");
		return;
	}
	
	
	NSFont *fixedFont;
	NSTextContainer *textContainer;
	NSSize  theSize;
	fixedFont = [NSFont fontWithName:@"Monaco" size:10];
	
	[rawSource setFont:fixedFont];
	textContainer = [rawSource textContainer];
    theSize = [textContainer containerSize];
    theSize.width = 1.0e7;
    [textContainer setContainerSize:theSize];
    [textContainer setWidthTracksTextView:NO];
	
	// load the ui from the file
	// load the file.
	pgConfiguration = [[PGPostgreSQLConfFile alloc] initWithContentsOfFile:@"/var/tmp/postgresql.conf.in"];
	[[pgConfiguration retain] autorelease];
	
	// set up the UI
	
	[rawSource setString:[pgConfiguration source]];
	
	[NSApp beginSheet:thisPanel  
	   modalForWindow:parentWindow 
		modalDelegate:nil
	   didEndSelector:nil
		  contextInfo:nil];
	
	[NSApp runModalForWindow:thisPanel];
}

- (IBAction)onOK:(id)sender
{
	shouldRestartService = YES;	
	
	[pgConfiguration setSource:[rawSource string]];
	[pgConfiguration saveToFile:@"/var/tmp/postgresql.conf.out"];
	
	[NSApp stopModal];
	[NSApp endSheet:thisPanel];
	[thisPanel orderOut:self];	
}

- (IBAction)onCancel:(id)sender
{
	shouldRestartService = NO;
	
	[NSApp stopModal];
	[NSApp endSheet:thisPanel];
	[thisPanel orderOut:self];	
}

- (BOOL)shouldRestartService
{
	return shouldRestartService;
}

@end
