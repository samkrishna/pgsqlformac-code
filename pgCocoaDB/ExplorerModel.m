//
//  ExplorerModel.m
//  pgCocoaDBn
//
//  Created by Neil Tiffin on 3/12/06.
//  Copyright 2006 Performance Champions Inc. All rights reserved.
//

#import "PGCocoaDB.h"
#import "ExplorerModel.h"
#import "RecordSet.h"


@implementation ExplorerModel


- (void)createFunctionNodes:(ExplorerNode *)aParent fromSchemaName:(NSString *)schemaName
{
	RecordSet * results;
	ExplorerNode * newNode;
	NSString * functionName;
	int i;
	results = [schema getFunctionNamesFromSchema:schemaName];
	for (i = 0; i < [results count]; i++)
	{
		newNode = [[ExplorerNode alloc] init];
		functionName = [[[[results itemAtIndex: i] fields] itemAtIndex:0] value];
		[newNode setName:functionName];
		[newNode setBaseSchema:schemaName];
		[newNode setExplorerType:@"Function Name"];
		[newNode setParent:aParent];
		[newNode setDisplayColumn2:@""];
		[aParent addChild:newNode];
		//TODO get function info
		
		[newNode release];
	}
}


- (void)createSequenceNodes:(ExplorerNode *)aParent fromSchemaName:(NSString *)schemaName
{
	RecordSet * results;
	ExplorerNode * newNode;
	NSString * sequenceName;
	int i;

	results = [schema getSequenceNamesFromSchema:schemaName];
	for (i = 0; i < [results count]; i++)
	{
		newNode = [[ExplorerNode alloc] init];
		sequenceName = [[[[results itemAtIndex: i] fields] itemAtIndex:0] value];
		[newNode setName:sequenceName];
		[newNode setBaseSchema:schemaName];
		[newNode setExplorerType:@"Sequence Name"];
		[newNode setParent:aParent];
		[newNode setDisplayColumn2:@""];
		[aParent addChild:newNode];
		//TODO get sequence info

		[newNode release];
	}
}


- (void)createColumnNodes:(ExplorerNode *)aParent fromSchemaName:(NSString *)schemaName fromTableName:(NSString *)tableName
{
	RecordSet * results;
	RecordSet * columnInfoSet;
	ExplorerNode * newNode;
	NSString * columnName;
	int i;
	ExplorerNode *titleNode;
	
	titleNode = [[ExplorerNode alloc] init];
	[titleNode setName:@"Columns"];
	[titleNode setExplorerType:@"Column Title"];
	[titleNode setParent:aParent];
	[titleNode setBaseTable:tableName];
	[titleNode setBaseSchema:schemaName];
	[aParent addChild:titleNode];
	[titleNode release];
	
	//NSLog(@"Processing %@ - %@", schemaName, tableName); 
	results = [schema getTableColumnNamesFromSchema:schemaName fromTableName:tableName];
	//NSLog(@"%@", results);
	if (results != nil)
	{
		for (i = 0; i < [results count]; i++)
		{
			//NSLog(@"results count = %d", [results count]);
			newNode = [[ExplorerNode alloc] init];
			columnName = [[[[results itemAtIndex: i] fields] itemAtIndex:0] value];
			columnInfoSet = [schema getTableColumnInfoFromSchema:schemaName fromTableName:tableName fromColumnName:columnName];
			//NSLog(@"%@", columnInfoSet);
			if (columnInfoSet != nil)
			{
				int ii;
				NSMutableString *columnInfoString= [[NSMutableString alloc] init];
				// interate to find NOT NULL and DEFAULT
				for (ii = 0; ii < [[[columnInfoSet itemAtIndex: 0] fields] count]; ii++)
				{
					[columnInfoString appendString:[[[[columnInfoSet itemAtIndex: 0] fields] itemAtIndex:ii] value]];
				}
				//NSLog(@"Processing %@ - %@ - %@ - %@", schemaName, tableName, columnName, columnInfoString); 
				//NSLog(@"results count = %d", [results count]);
				[newNode setName:columnName];
				[newNode setExplorerType:@"Column Name"];
				[newNode setParent:titleNode];
				[newNode setDisplayColumn2:columnInfoString];
				[newNode setBaseTable:tableName];
				[newNode setBaseSchema:schemaName];
				[titleNode addChild:newNode];
				[columnInfoString autorelease];
			}
			[newNode release];
		}
	}
}


- (void)createViewNodes:(ExplorerNode *)aParent fromSchemaName:(NSString *)schemaName
{
	RecordSet * results;
	ExplorerNode * newNode;
	NSString * viewName;
	int i;

	results = [schema getViewNamesFromSchema:schemaName];
	for (i = 0; i < [results count]; i++)
	{
		newNode = [[ExplorerNode alloc] init];
		viewName = [[[[results itemAtIndex: i] fields] itemAtIndex:0] value];
		[newNode setName:viewName];
		[newNode setBaseTable:viewName];
		[newNode setBaseSchema:schemaName];
		[newNode setExplorerType:@"View Name"];
		[newNode setParent:aParent];
		[newNode setDisplayColumn2:@""];
		// do columns
		[self createColumnNodes:newNode fromSchemaName:schemaName fromTableName:viewName];

		// TODO get indexes and other for views?
		[aParent addChild:newNode];

		[newNode release];
	}
}


- (void)createTriggerNodes:(ExplorerNode *)aParent fromSchemaName:(NSString *)schemaName fromTableName:(NSString *)tableName
{
	RecordSet * results;
	ExplorerNode * newNode;
	NSString * triggerName;
	int i;
	ExplorerNode *titleNode;
	
	titleNode = [[ExplorerNode alloc] init];
	[titleNode setName:@"Triggers"];
	[titleNode setExplorerType:@"Trigger Title"];
	[titleNode setParent:aParent];
	[aParent addChild:titleNode];		
	[titleNode release];
	
	results = [schema getTriggerNamesFromSchema:schemaName fromTableName:tableName];
	for (i = 0; i < [results count]; i++)
	{
		newNode = [[ExplorerNode alloc] init];
		triggerName = [[[[results itemAtIndex: i] fields] itemAtIndex:0] value];
		[newNode setName:triggerName];
		[newNode setExplorerType:@"Trigger Name"];
		[newNode setParent:titleNode];
		[newNode setBaseTable:tableName];
		[newNode setBaseSchema:schemaName];
		[newNode setDisplayColumn2:[schema getTriggerSQLFromSchema:schemaName fromTableName:tableName fromTriggerName:triggerName]];
		[titleNode addChild:newNode];

		[newNode release];
	}
}


- (void)createConstraintNodes:(ExplorerNode *)aParent fromSchemaName:(NSString *)schemaName fromTableName:(NSString *)tableName
{
	RecordSet * results;
	ExplorerNode * newNode;
	NSString * constraintName;
	int i;
	ExplorerNode *titleNode;
	
	titleNode = [[ExplorerNode alloc] init];
	[titleNode setName:@"Constraints"];
	[titleNode setExplorerType:@"Constraint Title"];
	[titleNode setParent:aParent];
	[aParent addChild:titleNode];		
	[titleNode release];

	results = [schema getConstraintNamesFromSchema:schemaName fromTableName:tableName];
	for (i = 0; i < [results count]; i++)
	{
		newNode = [[ExplorerNode alloc] init];
		constraintName = [[[[results itemAtIndex: i] fields] itemAtIndex:0] value];
		[newNode setName:constraintName];
		[newNode setExplorerType:@"Constraint Name"];
		[newNode setParent:titleNode];
		[newNode setDisplayColumn2:[schema getConstraintSQLFromSchema:schemaName fromTable:tableName fromConstraint:constraintName pretty:0]];
		[newNode setBaseTable:tableName];
		[newNode setBaseSchema:schemaName];
		[titleNode addChild:newNode];
		//TODO get constraints info?
		
		[newNode release];
	}
}


- (void)createIndexColumnNodes:(ExplorerNode *)aParent fromSchemaName:(NSString *)schemaName fromTableName:(NSString *)tableName fromIndexName:(NSString *)indexName
{
	RecordSet * results;
	ExplorerNode * newNode;
	NSString * colName;
	int i;
		
	results = [schema getIndexColumnNamesFromSchema:schemaName fromTableName:tableName fromIndexName:indexName];
	for (i = 0; i < [results count]; i++)
	{
		newNode = [[ExplorerNode alloc] init];
		colName = [[[[results itemAtIndex: i] fields] itemAtIndex:0] value];
		[newNode setName:colName];
		[newNode setExplorerType:@"Index Column"];
		[newNode setParent:aParent];
		[newNode setBaseTable:tableName];
		[newNode setBaseSchema:schemaName];
		[aParent addChild:newNode];
		
		[newNode release];
	}
}

- (void)createIndexNodes:(ExplorerNode *)aParent fromSchemaName:(NSString *)schemaName fromTableName:(NSString *)tableName
{
	RecordSet * results;
	ExplorerNode * newNode;
	NSString * indexName;
	int i;
	ExplorerNode *titleNode;
	
	titleNode = [[ExplorerNode alloc] init];
	[titleNode setName:@"Indexes"];
	[titleNode setExplorerType:@"Index Title"];
	[titleNode setParent:aParent];
	[aParent addChild:titleNode];	
	[titleNode release];
	
	results = [schema getIndexNamesFromSchema:schemaName fromTableName:tableName];
	for (i = 0; i < [results count]; i++)
	{
		newNode = [[ExplorerNode alloc] init];
		indexName = [[[[results itemAtIndex: i] fields] itemAtIndex:0] value];
		[newNode setName:indexName];
		[newNode setExplorerType:@"Index Name"];
		[newNode setParent:titleNode];
		[newNode setBaseTable:tableName];
		[newNode setBaseSchema:schemaName];
		[newNode setDisplayColumn2:[schema getIndexSQLFromSchema:schemaName fromTableName:tableName fromIndexName:indexName]];
		[titleNode addChild:newNode];

		[self createIndexColumnNodes:newNode fromSchemaName:schemaName fromTableName:tableName fromIndexName:indexName];
		[newNode release];
	}
}


- (void)createTableNodes:(ExplorerNode *)aParent fromSchemaName:(NSString *)schemaName
{
	ExplorerNode * newNode;
	NSString * tableName;
	RecordSet * results;
	int i;
	results = [schema getTableNamesFromSchema:schemaName];
	for (i = 0; i < [results count]; i++)
	{
		// for each table name
		newNode = [[ExplorerNode alloc] init];
		tableName = [[[[results itemAtIndex: i] fields] itemAtIndex:0] value];
		[newNode setName:tableName];
		[newNode setBaseTable:tableName];
		[newNode setBaseSchema:schemaName];
		[newNode setExplorerType:@"Table Name"];
		[newNode setParent:aParent];
		[newNode setDisplayColumn2:@""];
		
		// do columns
		[self createColumnNodes:newNode fromSchemaName:schemaName fromTableName:tableName];
		
		// do triggers
		[self createTriggerNodes:newNode fromSchemaName:schemaName fromTableName:tableName];
		
		// do constraints
		[self createConstraintNodes:newNode fromSchemaName:schemaName fromTableName:tableName];
		
		// do indexes
		[self createIndexNodes:newNode fromSchemaName:schemaName fromTableName:tableName];

		[aParent addChild:newNode];
		[newNode release];
	}
}


- (id)initWithConnectionString:(NSString *) theConnection
{
	[super init];
	ExplorerNode * newNode;
	
	connectionString = theConnection;
	[connectionString retain];
	NSLog(@"ExplorerModel: initWithConnectionString: theConnection");
	
	explorerThreadStatusLock = [[NSLock alloc] init];
	explorerThreadStatus = ExplorerNone;

	showInformationSchema = TRUE;
	showPGCatalog = TRUE;
	showPGToast = FALSE;
	showPGTemps = FALSE;

	// set temporary root node for display
	rootNode = [[ExplorerNode alloc] init];
    [rootNode setName: @"Rebuilding"];
	[rootNode setBaseTable: @"Rebuilding"];
	[rootNode setExplorerType:@"Rebuilding"];
	[rootNode setParent:nil];
	[rootNode setOID:0];
	
	newNode = [[ExplorerNode alloc] init];
	[newNode setName: @"Rebuilding"];
	[newNode setExplorerType:@"Rebuilding"];
	[newNode setParent:rootNode];
	[rootNode addChild: newNode];
	[newNode release];

	return self;
}

// May be run in a separate thread.
- (void)buildSchema:(id)anOutlineView
{
	[self retain]; // Make sure self does not dealloc while thread is running.
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	ExplorerNode * newNode;
	ExplorerNode * newChild;
	RecordSet * results;
	ExplorerNode * realRootNode;

	[schema release];
	schema = [[Schema alloc] initWithConnectionString:connectionString];

	if (schema == nil)
	{
		NSLog(@"Schema init returned error.");
		[self setExplorerThreadStatus:ExplorerError];
		return;
	}
	
	
	[self setExplorerThreadStatus:ExplorerRunning];

	// set database level
    realRootNode = [[ExplorerNode alloc] init];
    [realRootNode setName: [[schema connection] currentDatabase]];
	[realRootNode setBaseTable: @""];
	[realRootNode setExplorerType:@"Database"];
	[realRootNode setParent:nil];
	[realRootNode setOID:0];
	
	// set schema level
	results = [schema getSchemaNames];
	NSString * schemaName;
	int i;
	for (i = 0; i < [results count]; i++)
	{
		schemaName = [[[[results itemAtIndex: i] fields] itemAtIndex:0] value];
		// skip some schemas
		if ([schemaName isCaseInsensitiveLike:@"information_schema"])
		{
			if (!showInformationSchema)
			{
				continue;	//skip this one
			}
		}
		else if ([schemaName isCaseInsensitiveLike:@"pg_catalog"])
		{
			if (!showPGCatalog)
			{
				continue;	//skip this one
			}			
		}
		else if ([schemaName isCaseInsensitiveLike:@"pg_toast"])
		{
			if (!showPGToast)
			{
				continue;	//skip this one
			}
		}
		else if ([schemaName isCaseInsensitiveLike:@"pg_temp*"])
		{
			if (!showPGTemps)
			{
				continue;	//skip this one
			}
		}
		else if ([schemaName isCaseInsensitiveLike:@"public*"])
		{
			if (!showPublic)
			{
				continue;	//skip this one
			}
		}
		
		newNode = [[ExplorerNode alloc] init];
		[newNode setName: schemaName];
		[newNode setExplorerType:@"Schema"];
		[newNode setParent:realRootNode];

		// for each schema add children
		newChild = [[ExplorerNode alloc] init];
		[newChild setName: @"Tables"];
		[newChild setExplorerType:@"Schema Child"];
		[newChild setParent:newNode];
		[newNode addChild: newChild];
		[newChild release];
		[self createTableNodes:newChild fromSchemaName:schemaName];

		newChild = [[ExplorerNode alloc] init];
		[newChild setName: @"Sequences"];
		[newChild setExplorerType:@"Schema Child"];
		[newChild setParent:newNode];
		[newNode addChild: newChild];
		[newChild release];
		[self createSequenceNodes:newChild fromSchemaName:schemaName];
		
		newChild = [[ExplorerNode alloc] init];
		[newChild setName: @"Views"];
		[newChild setExplorerType:@"Schema Child"];
		[newChild setParent:newNode];
		[newNode addChild: newChild];
		[newChild release];
		[self createViewNodes:newChild fromSchemaName:schemaName];
		
		newChild = [[ExplorerNode alloc] init];
		[newChild setName: @"Functions"];
		[newChild setExplorerType:@"Schema Child"];
		[newChild setParent:newNode];
		[newNode addChild: newChild];
		[newChild release];
		[self createFunctionNodes:newChild fromSchemaName:schemaName];
		
		// add to the root node
		[realRootNode addChild: newNode];
		[newNode release];
	}
	[rootNode autorelease];
	rootNode = realRootNode;
	[self setExplorerThreadStatus:ExplorerDone];
	[(NSOutlineView *)anOutlineView reloadData];
	[pool release];
	[self release];
	return;
}

- (void)dealloc
{
	// todo release all ExplorerNodes
	[explorerThreadStatusLock release];

	[rootNode release];
	[schema release];
	[super dealloc];
}

-(void)setSchema:(Schema *)newSchema
{
	[schema release];
	schema = newSchema;
	[schema retain];
}

// accessor methods
- (Schema *)schema
{
	return schema;
}

- (bool)showInformationSchema
{
	return showInformationSchema;
}

- (bool)showPGCatalog
{
	return showPGCatalog;
}

- (bool)showPGToast
{
	return showPGToast;
}

- (bool)showPGTemps
{
	return showPGTemps;
}

- (bool)showPublic
{
	return showPublic;
}

- (enum ExplorerThreadStatus)explorerThreadStatus
{
	enum ExplorerThreadStatus status;
	
	[explorerThreadStatusLock lock];
	status = explorerThreadStatus;
	[explorerThreadStatusLock unlock];
	return status;
}

- (void)setShowInformationSchema:(bool)newValue
{
	showInformationSchema = newValue;
}

- (void)setShowPGCatalog:(bool)newValue
{
	showPGCatalog = newValue;
}

- (void)setShowPGToast:(bool)newValue
{
	showPGToast = newValue;
}

- (void)setShowPGTemps:(bool)newValue
{
	showPGTemps = newValue;
}

- (void)setShowPublic:(bool)newValue
{
	showPublic = newValue;
}

- (void)setExplorerThreadStatus:(enum ExplorerThreadStatus)newValue
{
	[explorerThreadStatusLock lock];
	explorerThreadStatus = newValue;
	[explorerThreadStatusLock unlock];
}

// These methods get called because I am the datasource of the outline view.
- (id)outlineView:(NSOutlineView *)outlineView child:(int)i ofItem:(id)item
{
	UNUSED_PARAMETER(outlineView);
	
	if (item == nil)
	{
		return [rootNode childAtIndex:i];	
	}
	if([self explorerThreadStatus] != ExplorerDone)
	{
		return 0;
	}
	return [item childAtIndex:i];
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	UNUSED_PARAMETER(outlineView);
    
	// Returns YES if the node has children
	if([self explorerThreadStatus] != ExplorerDone)
	{
		return NO;
	}
    return [item expandable];	
}


- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	UNUSED_PARAMETER(outlineView);
    
	if (item == nil) {
        // The root object;
        return [rootNode childrenCount];
    }
	if([self explorerThreadStatus] != ExplorerDone)
	{
		return 0;
	}
    return [item childrenCount];	
}


- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    // Set the identifier of the columns in IB's inspector
    NSString *identifier = [tableColumn identifier];
	UNUSED_PARAMETER(outlineView);
	
    // What is returned depends upon which column it is going to appear.
    if ([identifier isEqual:@"col1"])
	{
		NSRange range = [[item explorerType] rangeOfString:@"Title"];
		if (([[item explorerType] isEqualToString:@"Schema Child"] ) || (range.length != 0))
		{
			NSDictionary *attributes = [[NSDictionary alloc] initWithObjectsAndKeys:[NSColor blueColor], NSForegroundColorAttributeName, nil];
			NSAttributedString *myString = [[[NSAttributedString alloc] initWithString:[item name] attributes: attributes] autorelease];
			[attributes release];
			return myString;
		}		
		else
		{
				return  [item name];
		}
	}
	if ([identifier isEqual:@"col2"])  	
		return [item displayColumn2];
		
	return nil;	
}

- (BOOL)printLog
{
	if([self explorerThreadStatus] == ExplorerDone)
	{
		[rootNode printLog:0];
		return YES;
	}
	NSLog(@"Explorer still Loading.");
	return NO;
}

@end
