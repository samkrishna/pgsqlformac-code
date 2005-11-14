//
//  PGNewUserUI.m
//  Create User
//
//  Created by Andy Satori on 2/21/05.
//  Copyright 2005 Druware Software Designs. All rights reserved.
//

#import "PGNewUserUI.h"


@implementation PGNewUserUI

- (id)init
{
    [super init];
	
	_conn = nil;
	
    return self;
}

- (void)awakeFromNib
{
	BOOL isRunning = NO;
		
	_conn = [[[[Connection alloc] init] autorelease] retain];
	
	// set the defaults
	[groups removeAllItems];
	[groups addItemWithTitle:@"- default -"];
	
	// load the rest from a plist
	
	return;
}

- (IBAction)onBack:(id)sender
{
	[tabs selectPreviousTabViewItem:sender];
	[back setEnabled:NO];
}

- (IBAction)onCancel:(id)sender
{
	[NSApp terminate:sender];
}

- (IBAction)onNext:(id)sender
{
	// based upon the current page, determine the needed action
	switch ([tabs indexOfTabViewItem:[tabs selectedTabViewItem]])
	{
		case 0: // connection data
			if ([[server stringValue] length] == 0) { return; }
			if ([[port stringValue] length] == 0) { return; }
			if ([[user stringValue] length] == 0) { return; }
			
			[_conn setUserName:[user stringValue]];
			[_conn setHost:[server stringValue]];
			[_conn setPort:[port stringValue]];
			[_conn setPassword:[password stringValue]];
			
			if (![_conn connect])
			{
				// show an alert because it failed to connect.
				
				NSAlert *alert = [NSAlert 
					alertWithMessageText:@"Database Connection failed" 
					defaultButton:@"OK" alternateButton:nil 
					otherButton:nil informativeTextWithFormat:@"%@", [_conn errorDescription]]; 
				[alert beginSheetModalForWindow:[NSApp mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
				return;
			}
			
			[groups removeAllItems];
			[groups addItemWithTitle:@"- default -"];
			// load the rest from a quick query of the database
			
			RecordSet *rs = [_conn execQuery:@"select groname from pg_group order by groname asc"];
			int i ;
			for (i = 0; i < [rs count]; i++)
			{
				[groups addItemWithTitle:[[[[rs itemAtIndex:i] fields] itemAtIndex:0] value]];
			}
			
			[back setEnabled:YES];
		
			break;
		case 1: // set up the task and call the thread
			if ([[newLogin stringValue] length] == 0) { return; }
			if ([[newPassword stringValue] compare:[newConfPassword stringValue]] != NSOrderedSame) 
			{ 
				// show and alert regarding why!
				return; 
			}
			
			[resultStatus startAnimation:self];
			[back setEnabled:NO];

			
			// [NSThread detachNewThreadSelector:@selector(createUser) toTarget:self withObject:nil];
			[self createUser];
			
			break;
		default: // all done
			[NSApp terminate:sender];
			break;
	}

	[tabs selectNextTabViewItem:sender];
	return;
}

- (void)createUser
{
	//NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
    // Do processing here
	NSMutableString *cmd = [[NSMutableString alloc] initWithString:@""];
	
	[cmd appendString:[NSString stringWithFormat:@"CREATE USER %@ WITH ",
		[newLogin stringValue]]];
		
	// if the owner is set, then add it
	[cmd appendString:[NSString stringWithFormat:@"PASSWORD '%@' ",
		[newPassword stringValue]]];

	// sysUID
	if ([[newUID stringValue] length] != 0) 
	{
		[cmd appendString:[NSString stringWithFormat:@"SYSID '%@' ",
			[newUID stringValue]]];	
	}
	
	// if the template is not the default then add it
	if ([allowCreateDB state] ==  NSOnState)
	{
		[cmd appendString:[NSString stringWithString:@"CREATEDB "]];
	}
	
	// if the encoding is not the default then add it
	if ([allowCreateUser state] ==  NSOnState)
	{
		[cmd appendString:[NSString stringWithString:@"CREATEUSER "]];
	}
	
	// 
	if ([groups indexOfSelectedItem] != 0)
	{
		// if the tablespace is set then add it
		[cmd appendString:[NSString stringWithFormat:@"IN GROUP '%@' ",
			[[groups selectedItem] title]]];	
	}
	
	// expirationDate
	if ([[newExpirationDate stringValue] length] != 0) 
	{
		[cmd appendString:[NSString stringWithFormat:@"VALID UNTIL '%@' ",
			[newExpirationDate stringValue]]];	
	}
	
	[resultOutput setString:@""];
	[resultOutput setString:[NSString stringWithFormat:@"executing sql command: %@\n", 
		cmd]];
		
	[_conn execCommand:cmd];
	
	[resultOutput setString:@"User Created."];
	
	[next setTitle:@"Done"];
	[back setEnabled:NO];

	[resultStatus stopAnimation:self];
	
	//[pool release];
	//[NSThread exit];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	if ([_conn isConnected])
	{
		[_conn disconnect];
		[_conn release];
		_conn = nil;
	}

    [NSApp terminate:self];
    return;
}

@end

