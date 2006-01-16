//
//  SqlDocument.m
//  Query Tool
//
//  Created by Andy Satori on Thu Jan 29 2004.
//  Copyright (c) 2004 Druware Software Designs. All rights reserved.
//

#import "SqlDocument.h"

@implementation SqlDocument

- (id)init
{
    self = [super init];

    return self;
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"SqlDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
	NSFont *font;
	NSFont *fixedFont;
	NSTextContainer *textContainer;
	NSSize  theSize;
		
    [super windowControllerDidLoadNib:aController];
		
	font = [NSFont fontWithName:@"Lucida Grande" size:10];
	fixedFont = [NSFont fontWithName:@"Monaco" size:9];
	
	[query setFont:fixedFont];
	textContainer = [query textContainer];
    theSize = [textContainer containerSize];
    theSize.width = 1.0e7;
    [textContainer setContainerSize:theSize];
    [textContainer setWidthTracksTextView:NO];
	
	[status setStringValue:[NSString stringWithString:@""]];
	
	// set the text view delegate
	[query setDelegate:self];
	[[query textStorage] setDelegate:self];
	
	// init the keyword arrays
	NSString *temp = [[NSString alloc] 
		initWithString:@"select from where order group by asc desc insert into delete drop create alter table procedure view function"];
	
	keywords = [[NSArray alloc] initWithArray:[temp componentsSeparatedByString:@" "]];
	[keywords retain];
	[keywords autorelease];
	
	window = [aController window];
	[self setupToolbar];
	
	[dbList removeAllItems];
		
	// load the file if it exists
	if ( fileContent != nil ) 
	{
		//[query replaceCharactersInRange:NSMakeRange(0, 0) withRTFD:fileContent];
		[query setString:fileContent];
		[self colorRange:NSMakeRange(0, [fileContent length])];
		[self updateChangeCount:NSChangeCleared];
	}
	
	[self performSelector:@selector(onConnect:) withObject:self afterDelay:0.0];
}

- (NSData *)dataRepresentationOfType:(NSString *)aType
{
	
	return [[query string] dataUsingEncoding:NSASCIIStringEncoding];
}

- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)docType
{
	fileContent = [[NSString alloc] initWithContentsOfFile:fileName];
	return fileContent != nil;
}

- (IBAction)onConnect:(id)sender
{
    /* read the preferences and add them to the drop downs */
	
	[status setStringValue:[NSString stringWithString:@"Waiting for connection information"]];
	
	[host setStringValue:@"localhost"];
	[port setStringValue:@"5432"];
    
    [NSApp beginSheet:panelConnect 
       modalForWindow:window
        modalDelegate:nil
       didEndSelector:nil
          contextInfo:nil];
}

- (IBAction)onConnectOK:(id)sender
{
	// make sure we have a connection object
	if (conn != nil)
	{
		[conn release];
	}
	conn = [[Connection alloc] init];
	[status setStringValue:[NSString stringWithFormat:@"Connecting to %@...", [conn host]]];
	
	// set the connection parameters					
	[conn setUserName:[userName stringValue]];
	[conn setPassword:[password stringValue]];

	[conn setHost:[host stringValue]];
	[conn setPort:[port stringValue]];
	
	// close the sheet
	[NSApp stopModal];            
    [NSApp endSheet:panelConnect];
    [panelConnect orderOut:self];
    [panelConnect close];
	
	// perform the connection
	
	[conn setDbName:@""];	
	[conn connect];
	if (![conn isConnected]) 
	{
		[conn setDbName:@"template1"];
		[conn connect];
	}
	
	if ([conn isConnected]) 
	{
		[status setStringValue:[NSString stringWithFormat:@"Connected to %@ on %@ as %@", 
			[conn dbName], [conn host], [conn userName]]];
		int i;
		for (i = 0; i < [[conn databases] count]; i++)
		{
			[dbList addItemWithTitle:[[[conn databases] itemAtIndex:i] name]];
			if ([[[[conn databases] itemAtIndex:i] name] isEqualToString:[conn currentDatabase]])
			{
				[dbList selectItemAtIndex:i];
			}
		}
		
	} else {
		[status setStringValue:@"Connection failed: %@"];
		// [status setStringValue:[NSString stringWithFormat:@"Connected to %@ as %@", 
		//	[conn host], [conn userName]]];
	}
}

- (IBAction)onConnectCancel:(id)sender
{
    [NSApp stopModal];            
    [NSApp endSheet:panelConnect];
    [panelConnect orderOut:self];
    [panelConnect close];
	[status setStringValue:@"Connection cancelled."];
}

- (IBAction)onDisconnect:(id)sender
{

	if ([conn isConnected])
	{
		[conn disconnect];
		[status setStringValue:@"Connection closed."];
	}
}

// this should be implemented as a thread
// further, it should also parse the command for multiple statements.

- (IBAction)onExecuteQuery:(id)sender
{
	// execute the current query on the current database
	if (![conn isConnected]) 
	{
		[conn disconnect];
	}
	
	[working startAnimation:sender];
	[status setStringValue:@"Executing Query"];
	
	NSMutableString *result = [[NSMutableString alloc] init];
	
	// get the query from the query window
	
	NSString *toBeRun;
	if ([query selectedRange].length > 0)
	{
		toBeRun = [[query string] substringWithRange:[query selectedRange]];
	} else {
		toBeRun = [query string];
	}
	
	NSArray *arrQuery = [toBeRun componentsSeparatedByString:@";"];
	
	int x = 0;
	for (x = 0; x < [arrQuery count]; x++)
	{
		NSString *sql = [arrQuery objectAtIndex:x];
		
		RecordSet *rs = [conn execQuery:sql];
		
		if (rs == nil) 
		{
			if ([conn errorDescription] != nil)
			{
				NSLog([conn errorDescription]);
				[status setStringValue:[conn errorDescription]];
				[working stopAnimation:sender];
				return;
			}
			continue;
		}
		
		long i;
		
		// clean up the table
		for (i = [[dataOutput tableColumns] count] - 1; i >= 0; i--)
		{
			[dataOutput removeTableColumn:(NSTableColumn *)[[dataOutput tableColumns] objectAtIndex:i]];
		}
		if (dataSource != nil)
		{
			[dataSource release];
		}
		dataSource = [[DataSource alloc] init];
		
		// Raw View
		if ([rs count] > 0)
		{
			for (i = 0; i < [rs count]; i++)
			{
				// set up the header
				if (i == 0)
				{
					long x = 0;
					for (x = 0; x < [[[rs itemAtIndex:i] fields] count]; x++)
					{
						NSTableColumn *tc = [[NSTableColumn alloc] init];
						[tc setIdentifier:[NSString stringWithFormat:@"%d",  x]];
						[[tc headerCell] setStringValue:[[[[rs itemAtIndex:i] fields] itemAtIndex:x] name]];
						[dataOutput addTableColumn:tc];
						[result appendFormat:@"%-15s  ", [[[[[rs itemAtIndex:i] fields] itemAtIndex:x] name] cString]];
					}
					[result appendString:@"\n\n"];
				}
				long x = 0;
				NSMutableDictionary *dict = [dataSource addItem];
				for (x = 0; x < [[[rs itemAtIndex:i] fields] count]; x++)
				{
					[dict setValue:[[[[rs itemAtIndex:i] fields] itemAtIndex:x] value]
							 forKey:[NSString stringWithFormat:@"%d",  x]];
					
					[result appendFormat:@"%-15s  ", [[[[[rs itemAtIndex:i] fields] itemAtIndex:x] value] cString]];
				}
				[result appendString:@"\n"];
			}
		}
		[rawOutput setString:result];
			
		[dataOutput setDataSource:dataSource];
		[dataOutput reloadData];
		
		// long recordcount = [conn execCommand:sql];
	}
	
	[status setStringValue:@"Query Completed."];
	[working stopAnimation:sender];
}


- (IBAction)onSetDatabase:(id)sender
{
	if ([conn isConnected])
	{
		[conn disconnect];
	}
	
	if ([[[dbList selectedItem]  title] length] == 0)
	{
		[conn setDbName:@""];
	} else {
		[conn setDbName:[[dbList selectedItem] title]];
	}
	
	// perform the connection
	if ([conn connect])
	{
		[status setStringValue:[NSString stringWithFormat:@"Connected to %@ on %@ as %@", 
			[conn dbName], [conn host], [conn userName]]];
	} else {
		[status setStringValue:@"Connection failed."];
	}
}

- (BOOL)isValueKeyword:(NSString *)value
{
	int x;
	NSString *trimmedValue = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	for (x = 0; x < [keywords count]; x++)
	{
		NSString *keyword = (NSString *)[keywords objectAtIndex:x];
		if ([keyword caseInsensitiveCompare:trimmedValue] == NSOrderedSame)
		{
			return YES;
		}
	}
	return NO;	
}

- (void)setAttributesForWord:(NSRange)rangeOfCurrentWord
{
	// set the attributes of the string 
	NSTextStorage *ts = [query textStorage];
	NSColor *tagColor = [NSColor colorWithCalibratedRed: 0.2 green: 0.2 blue: 1.0 alpha: 1.0];
	NSDictionary *atts = [NSDictionary dictionaryWithObject:tagColor
													 forKey:NSForegroundColorAttributeName];
	[[query layoutManager] removeTemporaryAttribute:NSForegroundColorAttributeName forCharacterRange:rangeOfCurrentWord];
	
	if ([self isValueKeyword:[[ts attributedSubstringFromRange:rangeOfCurrentWord] string]])
	{
		[[query layoutManager] setTemporaryAttributes:atts forCharacterRange:rangeOfCurrentWord];
	}
}

- (void)colorRange:(NSRange)rangeToColor
{
	// loop through the range, breaking at each delimiter to set the attributes
	long i;
	
	i = rangeToColor.location;
	NSRange rangeOfWord;
	rangeOfWord.location = rangeToColor.location;
	for (i = rangeToColor.location; i < (rangeToColor.location + rangeToColor.length); i++) 
	{
		// break on delimiters
		if ([[NSCharacterSet whitespaceAndNewlineCharacterSet] 
			characterIsMember:[[query string] characterAtIndex:i]]) // needs to be altered to 'delimiter'
		{
			rangeOfWord.length = i - rangeOfWord.location;
			[self setAttributesForWord:rangeOfWord];
			rangeOfWord.location = i;
			rangeOfWord.length = 0;
		}
	}
	
	//NSLog(@"To be implemented");
	
}

 - (void)textViewDidChangeSelection:(NSNotification *)aNotification
{
	// based upon the current locatiodn, scan forward and backward to the nearest
	// delimiter and highlight the current word based upon that delimiter	
	NSTextStorage *ts = [query textStorage];
	
	NSRange rangeOfEdit = [ts editedRange];
	NSRange rangeOfCurrentWord = [ts editedRange];
	
	
	if (rangeOfEdit.length == 0) {
		return;
	}
	if (rangeOfEdit.length > 1) {
		[self colorRange:rangeOfEdit];
		return;
	}
	
	// if the edited range contains no delimiters...
	long i = rangeOfEdit.location;
	if (i >= [[ts string] length]) { i = [[ts string] length] - 1; }
	
	while ([[ts string] characterAtIndex:i] != ' ')
	{
		if (i <= 0) { break; }
		i--;
	}
	if ([[ts string] characterAtIndex:i] == ' ')  
	{
		i++;
	}
	rangeOfCurrentWord.location = i ;	
	
	i = rangeOfEdit.location;
	if (i >= [[ts string] length]) { i = [[ts string] length] - 1; }
	while ([[ts string] characterAtIndex:i] != ' ')
	{
		if (i >= ([[ts string] length] - 1)) { break; }
		i++;
	}
	rangeOfCurrentWord.length = i - rangeOfCurrentWord.location + 1;
	
	[self setAttributesForWord:rangeOfCurrentWord];
	[self updateChangeCount:NSChangeDone]; 
}

- (NSArray *)textView:(NSTextView *)textView completions:(NSArray *)words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(int *)index
{
	// implement the system
	return nil;
	
}

@end
