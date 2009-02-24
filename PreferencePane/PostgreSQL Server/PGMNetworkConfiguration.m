//
//  PGMNetworkConfiguration.m
//  PostgreSQL Server
//
//  Created by Andy Satori on 2/19/09.
//  Copyright 2009 Druware Software Designs. All rights reserved.
//

#import "PGMNetworkConfiguration.h"


@implementation PGMNetworkConfiguration

- (void)showModalForWindow:(NSWindow *)window
{
	parentWindow = window;
	
	shouldRestartService = NO;
	
	// show the dialog modal
	// load the nib
	if (![NSBundle loadNibNamed:@"NetworkConfigurationPanel" owner:self]) 
	{
		NSLog(@"Error loading nib.");
		return;
	}
	
	
	NSFont *fixedFont;
	NSTextContainer *textContainer;
	NSSize  theSize;
	fixedFont = [NSFont fontWithName:@"Monaco" size:9];
	
	[rawSource setFont:fixedFont];
	textContainer = [rawSource textContainer];
    theSize = [textContainer containerSize];
    theSize.width = 1.0e7;
    [textContainer setContainerSize:theSize];
    [textContainer setWidthTracksTextView:NO];
	
	// load the ui from the file
	// load the file.
	hbaConfiguration = [[PGHBAFile alloc] initWithContentsOfFile:@"/var/tmp/pg_hba.conf.in"];
	[[hbaConfiguration retain] autorelease];
	
	// set up the UI
	
	[rawSource setString:[hbaConfiguration source]];
	[allConnectionList setDataSource:[hbaConfiguration allConnections]];
	[allConnectionList reloadData];	
	 	
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
	
	[hbaConfiguration saveToFile:@"/var/tmp/pg_hba.conf.in"];
	
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
