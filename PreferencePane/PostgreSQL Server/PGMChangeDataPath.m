//
//  PGMChangeDataPath.m
//  PostgreSQL Server
//
//  Created by Andy Satori on 2/16/09.
//  Copyright 2009 Druware Software Designs. All rights reserved.
//

#import "PGMChangeDataPath.h"


@implementation PGMChangeDataPath


- (void)showModalForWindow:(NSWindow *)window
{
	parentWindow = window;
	
	// show the dialog modal
	// load the nib
	if (![NSBundle loadNibNamed:@"ChangeDataPathPanel" owner:self]) 
	{
		NSLog(@"Error loading nib.");
		return;
	}
	
	[dataFilePath setStringValue:currentPath];
	
	[NSApp beginSheet:thisPanel  
	   modalForWindow:parentWindow 
		modalDelegate:nil
	   didEndSelector:nil
		  contextInfo:nil];

	[NSApp runModalForWindow:thisPanel];
}

- (void)setCurrentPath:(NSString *)value
{
	currentPath = [[NSString alloc] initWithString:value];
}

- (IBAction)onBrowseForFolder:(id)sender
{
	
}

- (IBAction)onSetDataPath:(id)sender
{
	[NSApp stopModal];
	[NSApp endSheet:thisPanel];
	[thisPanel orderOut:self];	
}

- (IBAction)onCancelSetDataPath:(id)sender
{
	[NSApp stopModal];
	[NSApp endSheet:thisPanel];
	[thisPanel orderOut:self];	
}

@end
