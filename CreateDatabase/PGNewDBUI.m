#import "PGNewDBUI.h"

@implementation PGNewDBUI

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
	[encoding removeAllItems];
	[encoding addItemWithTitle:@"- default -"];
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
			
			[templates removeAllItems];
			[templates addItemWithTitle:@"- default -"];
			// load the rest from a quick query of the database
			
			RecordSet *rs = [_conn execQuery:@"select datname from pg_database where datistemplate = 't' and datallowconn = 't'"];
			int i ;
			for (i = 0; i < [rs count]; i++)
			{
				[templates addItemWithTitle:[[[[rs itemAtIndex:i] fields] itemAtIndex:0] value]];
			}
			
			[back setEnabled:YES];
		
			break;
		case 1: // set up the task and call the thread
			if ([[database stringValue] length] == 0) { return; }
			
			[resultStatus startAnimation:self];
			[back setEnabled:NO];
			
			[NSThread detachNewThreadSelector:@selector(createDatabase) toTarget:self withObject:nil];
			break;
		default: // all done
			[NSApp terminate:sender];
			break;
	}

	[tabs selectNextTabViewItem:sender];
	return;
}

- (void)createDatabase
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
    // Do processing here
	NSMutableString *cmd = [[NSMutableString alloc] initWithString:@""];
	
	[cmd appendString:[NSString stringWithFormat:@"CREATE DATABASE %@ WITH ",
		[database stringValue]]];
		
	// if the owner is set, then add it
	[cmd appendString:[NSString stringWithFormat:@"OWNER %@ ",
		[owner stringValue]]];
	
	// if the template is not the default then add it
	if ([templates indexOfSelectedItem] != 0)
	{
		[cmd appendString:[NSString stringWithFormat:@"TEMPLATE %@ ",
			[[templates selectedItem] title]]];
	}
	
	// if the encoding is not the default then add it
	if ([encoding indexOfSelectedItem] != 0)
	{
		[cmd appendString:[NSString stringWithFormat:@"ENCODING %@ ",
			[[encoding selectedItem] title]]];	
	}
	
	// pg 8 features
	if ([versionSevenFeaturesOnly state] != NSOnState)
	{
		// if the tablespace is set then add it
		[cmd appendString:[NSString stringWithFormat:@"TABLESPACE %@ ",
			[tableSpace stringValue]]];	
	}
	
	[resultOutput setString:@""];
	[resultOutput setString:[NSString stringWithFormat:@"executing sql command: %@\n", 
		cmd]];
		
	[_conn execCommand:cmd];
	
	[resultOutput setString:@"Database Created."];
	
	[next setTitle:@"Done"];
	[back setEnabled:NO];

	[resultStatus stopAnimation:self];
	
	[pool release];
	[NSThread exit];
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
