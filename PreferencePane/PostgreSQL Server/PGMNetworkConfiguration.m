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
	fixedFont = [NSFont fontWithName:@"Monaco" size:10];
	
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
	
	// set up the popup buttons
	[type removeAllItems];
	[type addItemWithTitle:@""];
	[type addItemWithTitle:@"local"];
	[type addItemWithTitle:@"host"];
	[type addItemWithTitle:@"hostssl"];
	[type addItemWithTitle:@"hostnossl"];
	
	[group removeAllItems];
	[group addItemWithTitle:@""];
	[group addItemWithTitle:@"Local"];
	[group addItemWithTitle:@"IPv4"];
	[group addItemWithTitle:@"IPv6"];
	
	[method removeAllItems];
	[method addItemWithTitle:@""]; 
	[method addItemWithTitle:@"trust"]; 
	[method addItemWithTitle:@"reject"]; 
	[method addItemWithTitle:@"md5"];
	[method addItemWithTitle:@"crypt"];
	[method addItemWithTitle:@"password"]; 
	[method addItemWithTitle:@"gss"]; 
	[method addItemWithTitle:@"sspi"];
	[method addItemWithTitle:@"krb5"]; 
	[method addItemWithTitle:@"ident"]; 
	[method addItemWithTitle:@"pam"];
	[method addItemWithTitle:@"ldap"];
	 	
	[NSApp beginSheet:thisPanel  
	   modalForWindow:parentWindow 
		modalDelegate:nil
	   didEndSelector:nil
		  contextInfo:nil];
	
	[NSApp runModalForWindow:thisPanel];
}

- (IBAction)onChangeView:(id)sender
{
	// update the hbafile source
}

- (IBAction)onSelectRecord:(id)sender
{
	if ([allConnectionList selectedRow] < 0)
	{
		[address setStringValue:@""];
		[database setStringValue:@""];
		[userName setStringValue:@""];
		[option setStringValue:@""];
		
		[type selectItemWithTitle:@""];
		[group selectItemWithTitle:@""];
		[method selectItemWithTitle:@""];
		
		[address setEnabled:NO];
		[database setEnabled:NO];
		[userName setEnabled:NO];
		[option setEnabled:NO];
		
		[type setEnabled:NO];
		[group setEnabled:NO];
		[method setEnabled:NO];
		return;
	}
	
	// get the dictionary to make this easier
	
	NSMutableDictionary *dict = [[[hbaConfiguration allConnections] items] objectAtIndex:[allConnectionList selectedRow]];	

	// use the selected record from the list and display the details for edit.
	[address setStringValue:[dict valueForKey:@"address"]];
	[database setStringValue:[dict valueForKey:@"database"]];
	[userName setStringValue:[dict valueForKey:@"user"]];
	[option setStringValue:[dict valueForKey:@"option"]];
	
	[type selectItemWithTitle:[dict valueForKey:@"type"]];
	[group selectItemWithTitle:[dict valueForKey:@"group"]];
	[method selectItemWithTitle:[dict valueForKey:@"method"]];
	
	[address setEnabled:YES];
	[database setEnabled:YES];
	[userName setEnabled:YES];
	[option setEnabled:YES];
	
	[type setEnabled:YES];
	[group setEnabled:YES];
	[method setEnabled:YES];
}

- (IBAction)onSetRecord:(id)sender
{
	NSMutableDictionary *dict = [[[hbaConfiguration allConnections] items] objectAtIndex:[allConnectionList selectedRow]];	
	
	[dict setValue:[address stringValue] forKey:@"address"];
	[dict setValue:[database stringValue] forKey:@"database"];
	[dict setValue:[userName stringValue] forKey:@"user"];
	[dict setValue:[option stringValue] forKey:@"option"];
	[dict setValue:[type titleOfSelectedItem] forKey:@"type"];
	[dict setValue:[group titleOfSelectedItem] forKey:@"group"];
	[dict setValue:[method titleOfSelectedItem] forKey:@"method"];
		
	[allConnectionList reloadData];
}

- (IBAction)onOK:(id)sender
{
	shouldRestartService = YES;	
	
	[hbaConfiguration setSource:[rawSource string]];
	[hbaConfiguration saveToFile:@"/var/tmp/pg_hba.conf.out"];
	
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
