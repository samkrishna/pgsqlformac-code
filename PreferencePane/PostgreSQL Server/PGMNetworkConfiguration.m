//
//  PGMNetworkConfiguration.m
//  PostgreSQL Server
//
//  Created by Andy Satori on 2/19/09.
//  Copyright 2009 Druware Software Designs. All rights reserved.
//


// TODO: Reparse the file when leaving Source view.

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

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	// update the hbafile source
	// if the current view is the data view update the source
	// else reparse the source and update the data view
    
    // TODO: if this is the source tab, reparse the source otherwise regenerate it
    if ([[tabViewItem identifier] isEqualToString:@"source"] == NSOrderedSame)
    {
        // parse the data
        [hbaConfiguration setSource:[rawSource string]];
       	[allConnectionList reloadData];
    } else {
        // generate the source
        [hbaConfiguration generateSourceData];
        [rawSource setString:[hbaConfiguration source]];
    }
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
    // don't do anything if
    
	NSMutableDictionary *dict = [[[hbaConfiguration allConnections] items] objectAtIndex:[allConnectionList selectedRow]];	
	
	[dict setValue:[address stringValue] forKey:@"address"];
	[dict setValue:[database stringValue] forKey:@"database"];
	[dict setValue:[userName stringValue] forKey:@"user"];
	[dict setValue:[option stringValue] forKey:@"option"];
	[dict setValue:[type titleOfSelectedItem] forKey:@"type"];
	[dict setValue:[group titleOfSelectedItem] forKey:@"group"];
	[dict setValue:[method titleOfSelectedItem] forKey:@"method"];
		
	[allConnectionList reloadData];
    
    // rebuild the source data so it can be saved.
    [hbaConfiguration generateSourceData];
    [rawSource setString:[hbaConfiguration source]];
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

- (IBAction)onAddConnection:(id)sender
{
    // add a new record
    // adjust all ines from the current record up one.
    // select the newly added record.
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
	
	[dict setValue:@"127.0.0.1/32" forKey:@"address"];
	[dict setValue:@"postgres" forKey:@"database"];
	[dict setValue:@"all" forKey:@"user"];
	[dict setValue:@"" forKey:@"option"];
	[dict setValue:@"host" forKey:@"type"];
	[dict setValue:@"IPv4" forKey:@"group"];
	[dict setValue:@"trust" forKey:@"method"];
    
    // we really want the following to adjust the line #'s based
    // upon the current selection, but for the moment, make it
    // work, then make it pretty
    
    NSNumber *lineNumber;
    if ([allConnectionList selectedRow] >= 0)
    {
        NSDictionary *selectedObject = [[[hbaConfiguration allConnections] items] objectAtIndex:[allConnectionList selectedRow]];
        // use the selected object, and adjust all other line#'s up by one
        lineNumber = [[NSNumber alloc] initWithInt:[[selectedObject valueForKey:@"Line#"] intValue] + 1];
        
        // adjust line numbers from a line number
        [hbaConfiguration incrementLineNumbersFromNumber:[lineNumber intValue]];
        
    } else {
        // find the highest line# and add one.
        // lineNumber = [[NSNumber alloc] initWithInt:[hbaConfiguration getMaxLineNumberForGroup:[dict valueForKey:@"group"]] + 1];
        lineNumber = [[NSNumber alloc] initWithInt:[hbaConfiguration getMaxLineNumber] + 1];
    }
    [dict setObject:lineNumber forKey:@"Line#"];
    
    NSLog(@"New Dictionary: %@", dict);

        
        // clear the current record
        NSLog(@"DeslectAll");
        [allConnectionList deselectAll:sender];
        
    // add the new dict to the list
    if ([allConnectionList selectedRow] >= 0)
    {
        [[[hbaConfiguration allConnections] items] insertObject:dict
                                                        atIndex:[allConnectionList selectedRow]];
    } else {
        [[[hbaConfiguration allConnections] items] addObject:dict];
    }
    
    [allConnectionList reloadData];
    
    NSMutableIndexSet *mutableIndexSet = [[NSMutableIndexSet alloc] init];
    [mutableIndexSet addIndex:[[[hbaConfiguration allConnections] items] count]];
    [allConnectionList selectRowIndexes:mutableIndexSet byExtendingSelection:NO];
    
    // rebuild the source data so it can be saved.
    [hbaConfiguration generateSourceData];
    [rawSource setString:[hbaConfiguration source]];
    
    return;
}

- (IBAction)onRemoveConnection:(id)sender
{
    // remove the select item from the list.
    NSNumber *lineNumber;
    if ([allConnectionList selectedRow] >= 0)
    {
        NSDictionary *selectedObject = [[[hbaConfiguration allConnections] items] objectAtIndex:[allConnectionList selectedRow]];
        // use the selected object, and adjust all other line#'s down by one
        lineNumber = [[NSNumber alloc] initWithInt:[[selectedObject valueForKey:@"Line#"] intValue]];
        
        // adjust line numbers from a line number
        [hbaConfiguration decrementLineNumbersFromNumber:[lineNumber intValue]];
        
        // remove the old one
        [[[hbaConfiguration allConnections] items] removeObjectAtIndex:[allConnectionList selectedRow]];
        
        [allConnectionList deselectAll:sender];
        
        [allConnectionList reloadData];
        
        // rebuild the source data so it can be saved.
        [hbaConfiguration generateSourceData];
        [rawSource setString:[hbaConfiguration source]];
    }
        
    return;
}

@end
