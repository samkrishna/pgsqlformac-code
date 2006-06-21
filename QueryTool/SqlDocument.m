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
    // If you need to use a subclass of NSWindowController or if your document supports multiple
	//   NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
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

	// make the query window the first responder
	[window makeFirstResponder: query];
	
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
	
	[query setSelectedRange:NSMakeRange(0,0)];
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

-(void)setNewExplorerConn
{
	// create the schema explorer
	if (explorer)	// we have already come through
	{
		ExplorerModel *tmp = explorer;
		
		explorer =[[ExplorerModel alloc] initWithConnection: conn];
		[schemaView setDataSource:explorer]; // explorer does the work.
		[schemaView setMenuActionTarget:self];
		[tmp release];
	}
	else
	{
		explorer =[[ExplorerModel alloc] initWithConnection: conn];
		[schemaView setDataSource:explorer]; // explorer does the work.
		[schemaView setMenuActionTarget:self];
	}
	//[explorer printLog];
}	

- (IBAction)onConnect:(id)sender
{
    /* read the preferences and add them to the drop downs */
	NSString * aDefault;
	
	[status setStringValue:[NSString stringWithString:@"Waiting for connection information"]];
	
	aDefault = [[NSUserDefaults standardUserDefaults] stringForKey:@"PGSqlForMac_DefaultHost"];
	if (aDefault)
	{
		[host setStringValue:aDefault];
	}
	else
	{
		[host setStringValue:@"localhost"];
	}
	aDefault = [[NSUserDefaults standardUserDefaults] stringForKey:@"PGSqlForMac_DefaultUserName"];
	if (aDefault)
	{
		[userName setStringValue:aDefault];
	}
	aDefault = [[NSUserDefaults standardUserDefaults] stringForKey:@"PGSqlForMac_DefaultDatabaseName"];
	if (aDefault)
	{
		[databaseName setStringValue:aDefault];
	}
	aDefault = [[NSUserDefaults standardUserDefaults] stringForKey:@"PGSqlForMac_DefaultPort"];
	if (aDefault)
	{
		[port setStringValue:aDefault];
	}
	else
	{
		[port setStringValue:@"5432"];
	}
	    
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
	[conn setDbName:[databaseName stringValue]];
	
	[conn setHost:[host stringValue]];
	[conn setPort:[port stringValue]];
	
	// update user defaults
	[[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithString:[userName stringValue]] forKey:@"PGSqlForMac_DefaultUserName"];
	[[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithString:[conn host]] forKey:@"PGSqlForMac_DefaultHost"];
	[[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithString:[port stringValue]] forKey:@"PGSqlForMac_DefaultPort"];
	[[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithString:[databaseName stringValue]] forKey:@"PGSqlForMac_DefaultDatabaseName"];
	[[NSUserDefaults standardUserDefaults] synchronize];
		
	// close the sheet
	[NSApp stopModal];            
    [NSApp endSheet:panelConnect];
    [panelConnect orderOut:self];
    [panelConnect close];
	
	// perform the connection
	
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
		// create the schema explorer
		[self setNewExplorerConn];			
		
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
		
		[schemaView setDataSource:nil];
		[explorer release];
		explorer = nil;
	}
}

// TODO this should be implemented as a thread
// further, it should also parse the command for multiple statements (or should it?  NT)

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
	
	/* FIXME does not correctly handle quoted queries */
	/* For example:
		CREATE or REPLACE FUNCTION pgcocoa_test_schema.sum_n_product
		(IN x integer, IN y integer, OUT  sum integer, OUT  prod integer) AS $$
		BEGIN
			sum := x + y;
			prod := x * y;
		END; $$ LANGUAGE plpgsql;
	*/
	
	NSArray *arrQuery = [toBeRun componentsSeparatedByString:@";"];
	
	int x;
	//for (x = 0; x < [arrQuery count]; x++)
	for (x = 0; x < 1; x++)
	{
		//NSString *sql = [arrQuery objectAtIndex:x];
		//RecordSet *rs = [conn execQuery:sql];
		RecordSet *rs = [conn execQuery:toBeRun];
		
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
		[schemaView setDataSource:nil];
		[explorer release];
		explorer = nil;
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
		// create the schema explorer
		[self setNewExplorerConn];			
	} else {
		[status setStringValue:@"Connection failed."];
	}
}

- (void)onSelectSelectTableMenuItem:(id)sender
{
	NSIndexSet *theRows =[schemaView selectedRowIndexes];
	unsigned int currentRow =[theRows firstIndex];
	NSString *tableName = [[schemaView itemAtRow:currentRow] baseTable];
	NSString *schemaName = [[schemaView itemAtRow:currentRow] baseSchema];
	
	// TODO validation, if any.
	NSString *sql =[NSString stringWithFormat:@"\nSELECT * FROM %@.%@;\n", schemaName, tableName];
	[query insertText:sql];
}

- (void)onSelectCreateTableMenuItem:(id)sender
{
	NSIndexSet *theRows =[schemaView selectedRowIndexes];
	unsigned int currentRow =[theRows firstIndex];
	NSString *tableName = [[schemaView itemAtRow:currentRow] baseTable];
	NSString *schemaName = [[schemaView itemAtRow:currentRow] baseSchema];

	// TODO validation, if any.
	NSString *sql = [[explorer schema] getTableSQLFromSchema:schemaName fromTableName:tableName pretty:1];
	[query insertText:sql];
}

- (void)onSelectCreateBakTableMenuItem:(id)sender
{
	NSIndexSet *theRows =[schemaView selectedRowIndexes];
	unsigned int currentRow =[theRows firstIndex];
	NSString *tableName = [[schemaView itemAtRow:currentRow] baseTable];
	NSString *schemaName = [[schemaView itemAtRow:currentRow] baseSchema];
	
	// TODO validation, if any.
	NSCalendarDate *theDate = [NSCalendarDate calendarDate];
	NSString *datestr = [theDate descriptionWithCalendarFormat:@"%Y_%m_%d_%H%M"];
	NSString *backupTableName = [NSString stringWithFormat:@"%@.%@_%@", schemaName, tableName, datestr];
	NSString *sql =[NSString stringWithFormat:@"\nSELECT * INTO TABLE %@\nFROM %@.%@;\n", backupTableName, schemaName, tableName];
	[query insertText:sql];
}

- (void)onSelectAlterTableRenameMenuItem:(id)sender
{
	NSIndexSet *theRows =[schemaView selectedRowIndexes];
	unsigned int currentRow =[theRows firstIndex];
	NSString *tableName = [[schemaView itemAtRow:currentRow] baseTable];
	NSString *schemaName = [[schemaView itemAtRow:currentRow] baseSchema];
	
	// TODO validation, if any.
	NSString *sql = [NSString stringWithFormat:@"ALTER TABLE %@.%@ RENAME TO new_name;\n", schemaName, tableName];
	[query insertText:sql];
}

- (void)onSelectVacuumTableMenuItem:(id)sender
{
	NSIndexSet *theRows =[schemaView selectedRowIndexes];
	unsigned int currentRow =[theRows firstIndex];
	NSString *tableName = [[schemaView itemAtRow:currentRow] baseTable];
	NSString *schemaName = [[schemaView itemAtRow:currentRow] baseSchema];
	
	// TODO validation, if any.
	NSString *sql = [NSString stringWithFormat:@"VACUUM FULL VERBOSE ANALYZE %@.%@;\n", schemaName, tableName];
	[query insertText:sql];
}

- (void)onSelectTruncateTableMenuItem:(id)sender
{
	NSIndexSet *theRows =[schemaView selectedRowIndexes];
	unsigned int currentRow =[theRows firstIndex];
	NSString *tableName = [[schemaView itemAtRow:currentRow] baseTable];
	NSString *schemaName = [[schemaView itemAtRow:currentRow] baseSchema];
	
	// TODO validation, if any.
	NSString *sql = [NSString stringWithFormat:@"TRUNCATE TABLE %@.%@;\n", schemaName, tableName];
	[query insertText:sql];
}

- (void)onSelectDropTableMenuItem:(id)sender
{
	NSIndexSet *theRows =[schemaView selectedRowIndexes];
	unsigned int currentRow =[theRows firstIndex];
	NSString *tableName = [[schemaView itemAtRow:currentRow] baseTable];
	NSString *schemaName = [[schemaView itemAtRow:currentRow] baseSchema];
	
	// TODO validation, if any.
	NSString *sql = [NSString stringWithFormat:@"DROP TABLE %@.%@;\n", schemaName, tableName];
	[query insertText:sql];
}


// column
- (void)onSelectColSelectMenuItem:(id)sender
{
	NSIndexSet *theRows =[schemaView selectedRowIndexes];
	unsigned currentIndex = [theRows firstIndex];
	NSString *tableName = [[schemaView itemAtRow:currentIndex] baseTable];
	NSString *schemaName = [[schemaView itemAtRow:currentIndex] baseSchema];
	NSAssert(tableName,@"onSelectColSelectMenuItem: no table name.");
	NSAssert(schemaName, @"onSelectColSelectMenuItem: no schema name.");
	bool first = true;
	
	NSMutableString *sql = [[[NSMutableString alloc] init] autorelease];
	[sql appendString:@"SELECT "];
	while (currentIndex != NSNotFound) {
		if (!first)
		{
			[sql appendString:@", "];
		}
		[sql appendString:[[schemaView itemAtRow:currentIndex] name]];
		currentIndex = [theRows indexGreaterThanIndex: currentIndex];
		first = false;
	}
	[sql appendFormat:@" FROM %@.%@;",schemaName, tableName];
	[query insertText:sql];
}

- (void)onSelectColsMenuItem:(id)sender
{
	NSIndexSet *theRows =[schemaView selectedRowIndexes];
	bool first = true;
	
	unsigned currentIndex = [theRows firstIndex];
	NSMutableString *sql = [[[NSMutableString alloc] init] autorelease];
	while (currentIndex != NSNotFound) {
		if (!first)
		{
			[sql appendString:@", "];
		}
		[sql appendString:[[schemaView itemAtRow:currentIndex] name]];
		currentIndex = [theRows indexGreaterThanIndex: currentIndex];
		first = false;
	}	
	[query insertText:sql];
}

- (void)onSelectCreateIndexOnColsMenuItem:(id)sender
{
	NSIndexSet *theRows =[schemaView selectedRowIndexes];
	unsigned currentIndex = [theRows firstIndex];
	NSString *tableName = [[schemaView itemAtRow:currentIndex] baseTable];
	NSString *schemaName = [[schemaView itemAtRow:currentIndex] baseSchema];
	NSAssert(tableName,@"onSelectCreateIndexOnColsMenuItem: no table name.");
	NSAssert(schemaName, @"onSelectCreateIndexOnColsMenuItem: no schema name.");
	bool first = true;
	
	//TODO make number auto determined
	NSMutableString *sql = [[[NSMutableString alloc] init] autorelease];
	[sql appendFormat:@"CREATE INDEX %@_idx1 ON %@.%@ (", tableName, schemaName, tableName];
	while (currentIndex != NSNotFound) {
		if (!first)
		{
			[sql appendString:@", "];
		}
		[sql appendString:[[schemaView itemAtRow:currentIndex] name]];
		currentIndex = [theRows indexGreaterThanIndex: currentIndex];
		first = false;
	}
	[sql appendFormat:@" );",schemaName, tableName];
	[query insertText:sql];
}

- (void)onSelectCreateUniqIndexOnColsMenuItem:(id)sender
{
	NSIndexSet *theRows =[schemaView selectedRowIndexes];
	unsigned currentIndex = [theRows firstIndex];
	NSString *tableName = [[schemaView itemAtRow:currentIndex] baseTable];
	NSString *schemaName = [[schemaView itemAtRow:currentIndex] baseSchema];
	NSAssert(tableName,@"onSelectCreateUniqIndexOnColsMenuItem: no table name.");
	NSAssert(schemaName, @"onSelectCreateUniqIndexOnColsMenuItem: no schema name.");
	bool first = true;
	
	//TODO make number auto determined
	NSMutableString *sql = [[[NSMutableString alloc] init] autorelease];
	[sql appendFormat:@"CREATE UNIQUE INDEX %@_idx1 ON %@.%@ (", tableName, schemaName, tableName];
	while (currentIndex != NSNotFound) {
		if (!first)
		{
			[sql appendString:@", "];
		}
		[sql appendString:[[schemaView itemAtRow:currentIndex] name]];
		currentIndex = [theRows indexGreaterThanIndex: currentIndex];
		first = false;
	}
	[sql appendFormat:@" );",schemaName, tableName];
	[query insertText:sql];
}

- (void)onSelectAlterAddColMenuItem:(id)sender
{
	NSIndexSet *theRows =[schemaView selectedRowIndexes];
	unsigned int currentRow =[theRows firstIndex];
	NSString *tableName = [[schemaView itemAtRow:currentRow] baseTable];
	NSString *schemaName = [[schemaView itemAtRow:currentRow] baseSchema];
	NSAssert(tableName,@"onSelectCreateViewMenuItem: no table name.");
	NSAssert(schemaName, @"onSelectCreateViewMenuItem: no schema name.");
	
	NSString *sql = [NSString stringWithFormat:@"TODO %@ %@\n", schemaName, tableName];
	[query insertText:sql];
}

- (void)onSelectAlterRenameColMenuItem:(id)sender
{
	NSIndexSet *theRows =[schemaView selectedRowIndexes];
	unsigned int currentRow =[theRows firstIndex];
	NSString *tableName = [[schemaView itemAtRow:currentRow] baseTable];
	NSString *schemaName = [[schemaView itemAtRow:currentRow] baseSchema];
	NSAssert(tableName,@"onSelectCreateViewMenuItem: no table name.");
	NSAssert(schemaName, @"onSelectCreateViewMenuItem: no schema name.");
	
	NSString *sql = [NSString stringWithFormat:@"TODO %@ %@\n", schemaName, tableName];
	[query insertText:sql];
}

- (void)onSelectCreateTabColsMenuItem:(id)sender
{
	NSIndexSet *theRows =[schemaView selectedRowIndexes];
	unsigned currentIndex = [theRows firstIndex];
	NSString *tableName = [[schemaView itemAtRow:currentIndex] baseTable];
	NSString *schemaName = [[schemaView itemAtRow:currentIndex] baseSchema];
	NSAssert(tableName,@"onSelectCreateUniqIndexOnColsMenuItem: no table name.");
	NSAssert(schemaName, @"onSelectCreateUniqIndexOnColsMenuItem: no schema name.");
	bool first = true;
	
	//TODO make number auto determined
	NSMutableString *sql = [[[NSMutableString alloc] init] autorelease];
	[sql appendFormat:@"CREATE TABLE %@.%@ (\n", schemaName, tableName];
	while (currentIndex != NSNotFound) {
		if (!first)
		{
			[sql appendString:@",\n"];
		}
		[sql appendString:[[schemaView itemAtRow:currentIndex] name]];
		[sql appendFormat:@" %@", [[schemaView itemAtRow:currentIndex] displayColumn2]];
		currentIndex = [theRows indexGreaterThanIndex: currentIndex];
		first = false;
	}
	[sql appendFormat:@"\n);",schemaName, tableName];
	[query insertText:sql];
}

- (void)onSelectDropColMenuItem:(id)sender
{
	NSIndexSet *theRows =[schemaView selectedRowIndexes];
	unsigned int currentRow =[theRows firstIndex];
	NSString *tableName = [[schemaView itemAtRow:currentRow] baseTable];
	NSString *schemaName = [[schemaView itemAtRow:currentRow] baseSchema];
	NSAssert(tableName,@"onSelectCreateViewMenuItem: no table name.");
	NSAssert(schemaName, @"onSelectCreateViewMenuItem: no schema name.");
	
	NSString *sql = [NSString stringWithFormat:@"TODO %@ %@\n", schemaName, tableName];
	[query insertText:sql];
}

// views
- (void)onSelectCreateViewMenuItem:(id)sender
{
	NSIndexSet *theRows =[schemaView selectedRowIndexes];
	unsigned int currentRow =[theRows firstIndex];
	NSString *viewName = [[schemaView itemAtRow:currentRow] baseTable];
	NSString *schemaName = [[schemaView itemAtRow:currentRow] baseSchema];
	NSAssert(viewName,@"onSelectCreateViewMenuItem: no view name.");
	NSAssert(schemaName, @"onSelectCreateViewMenuItem: no schema name.");
	
	NSString *sql = [[explorer schema] getViewSQLFromSchema:schemaName fromView:viewName pretty:1];
	[query insertText:sql];
}

- (void)onSelectCreateViewTemplateMenuItem:(id)sender
{
	NSIndexSet *theRows =[schemaView selectedRowIndexes];
	unsigned int currentRow =[theRows firstIndex];
	NSString *tableName = [[schemaView itemAtRow:currentRow] baseTable];
	NSString *schemaName = [[schemaView itemAtRow:currentRow] baseSchema];
	
	NSString *sql = [NSString stringWithFormat:@"CREATE OR REPLACE VIEW %@.%@ () AS\n    SELECT * FROM <schema>.<table>;\n", schemaName, tableName];
	[query insertText:sql];
}

- (void)onSelectDropViewMenuItem:(id)sender
{
	NSIndexSet *theRows =[schemaView selectedRowIndexes];
	unsigned int currentRow =[theRows firstIndex];
	NSString *tableName = [[schemaView itemAtRow:currentRow] baseTable];
	NSString *schemaName = [[schemaView itemAtRow:currentRow] baseSchema];
	
	NSString *sql = [NSString stringWithFormat:@"DROP VIEW %@.%@;\n", schemaName, tableName];
	[query insertText:sql];
}

// functions
- (void)onSelectCreateFunctionMenuItem:(id)sender
{
	NSIndexSet *theRows =[schemaView selectedRowIndexes];
	unsigned int currentRow =[theRows firstIndex];
	NSString *functionName = [[schemaView itemAtRow:currentRow] name];
	NSString *schemaName = [[schemaView itemAtRow:currentRow] baseSchema];
	NSAssert(functionName,@"onSelectCreateFunctionMenuItem: no function name.");
	NSAssert(schemaName, @"onSelectCreateFunctionMenuItem: no schema name.");
	
	NSString *sql = [[explorer schema] getFunctionSQLFromSchema: schemaName fromFunctionName:functionName pretty:0];
	[query insertText:sql];
}

- (void)onSelectCreateFunctionTemplateMenuItem:(id)sender
{
	NSIndexSet *theRows =[schemaView selectedRowIndexes];
	unsigned int currentRow =[theRows firstIndex];
	NSString *functionName = [[schemaView itemAtRow:currentRow] name];
	NSString *schemaName = [[schemaView itemAtRow:currentRow] baseSchema];
	NSAssert(functionName,@"onSelectCreateFunctionTemplateMenuItem: no function name.");
	NSAssert(schemaName, @"onSelectCreateFunctionTemplateMenuItem: no schema name.");
	
	//TODO put name back into the template
	NSString *sql = [NSString stringWithFormat:@"CREATE or REPLACE FUNCTION %@.function_name() RETURNS int AS $$ \n\
DECLARE \n\
	-- declarations\n\
	return_val integer := 30;\n\
BEGIN \n\
	-- SQL\n\
	return return_val;\n\
END; \n\
$$ LANGUAGE plpgsql; \n", schemaName];

	[query insertText:sql];
}

- (void)onSelectDropFunctionMenuItem:(id)sender
{
	NSIndexSet *theRows =[schemaView selectedRowIndexes];
	unsigned int currentRow =[theRows firstIndex];
	NSString *functionName = [[schemaView itemAtRow:currentRow] name];
	NSString *schemaName = [[schemaView itemAtRow:currentRow] baseSchema];
	NSAssert(functionName,@"onSelectDropFunctionMenuItem: no function name.");
	NSAssert(schemaName, @"onSelectDropFunctionMenuItem: no schema name.");
	
	NSString *sql = [NSString stringWithFormat:@"DROP FUNCTION %@.%@;\n", schemaName, functionName];
	[query insertText:sql];
}

// index
- (void)onSelectDropIndexMenuItem:(id)sender
{
	NSIndexSet *theRows =[schemaView selectedRowIndexes];
	unsigned int currentRow =[theRows firstIndex];
	NSString *indexName = [[schemaView itemAtRow:currentRow] name];
	NSString *schemaName = [[schemaView itemAtRow:currentRow] baseSchema];
	NSAssert(indexName,@"onSelectDropIndexMenuItem: no index name.");
	NSAssert(schemaName, @"onSelectDropIndexMenuItem: no schema name.");
	
	NSString *sql = [NSString stringWithFormat:@"DROP INDEX %@.%@;\n", schemaName, indexName];
	[query insertText:sql];
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
