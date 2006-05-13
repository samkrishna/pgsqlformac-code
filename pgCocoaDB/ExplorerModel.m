//
//  ExplorerModel.m
//  pgCocoaDBn
//
//  Created by Neil Tiffin on 3/12/06.
//  Copyright 2006 Performance Champions Inc. All rights reserved.
//

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
		[newNode setExplorerType:@"Sequence Name"];
		[newNode setParent:aParent];
		[newNode setDisplayColumn2:@""];
		[aParent addChild:newNode];
		//TODO get sequence info

		[newNode release];
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
		[newNode setExplorerType:@"View Name"];
		[newNode setParent:aParent];
		[newNode setDisplayColumn2:@""];
		[aParent addChild:newNode];
		//TODO get view info

		[newNode release];
	}
}


- (void)createColumnNodes:(ExplorerNode *)aParent fromSchemaName:(NSString *)schemaName fromTableName:(NSString *)tableName
{
	RecordSet * results;
	RecordSet * columnInfoSet;
	ExplorerNode * newNode;
	NSString * columnName;
	NSString * columnInfoString;
	int i;
	ExplorerNode *titleNode;
	
	titleNode = [[ExplorerNode alloc] init];
	[titleNode setName:@"Columns"];
	[titleNode setExplorerType:@"Column Title"];
	[titleNode setParent:aParent];
	[titleNode setBaseTable:tableName];
	[titleNode setBaseSchema:schemaName];
	[aParent addChild:titleNode];		
	
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
				columnInfoString = [[[[columnInfoSet itemAtIndex: 0] fields] itemAtIndex:0] value];
				//NSLog(@"Processing %@ - %@ - %@ - %@", schemaName, tableName, columnName, columnInfoString); 
				//NSLog(@"results count = %d", [results count]);
				[newNode setName:columnName];
				[newNode setExplorerType:@"Column Name"];
				[newNode setParent:titleNode];
				[newNode setDisplayColumn2:columnInfoString];
				[newNode setBaseTable:tableName];
				[newNode setBaseSchema:schemaName];
				[titleNode addChild:newNode];

				[newNode release];
			}
		}
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
		//[newNode setDisplayColumn2:[schema getTriggerSQLFromSchema:schemaName fromTriggerName:triggerName]];
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

	results = [schema getConstraintNamesFromSchema:schemaName fromTableName:tableName];
	for (i = 0; i < [results count]; i++)
	{
		newNode = [[ExplorerNode alloc] init];
		constraintName = [[[[results itemAtIndex: i] fields] itemAtIndex:0] value];
		[newNode setName:constraintName];
		[newNode setExplorerType:@"Constraint Name"];
		[newNode setParent:titleNode];
		[newNode setDisplayColumn2:@""];
		[newNode setBaseTable:tableName];
		[newNode setBaseSchema:schemaName];
		[titleNode addChild:newNode];
		//TODO get constraints info

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
		//[newNode setDisplayColumn2:[schema getIndexSQLFromSchema:schemaName fromTableName:tableName fromIndexName:indexName]];
		[titleNode addChild:newNode];

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


- (id)initWithConnection:(Connection *) theConnection
{
	[super init];
	
	showInformationSchema = TRUE;
	showPGCatalog = TRUE;
	showPGToast = FALSE;
	showPGTemps = FALSE;
	
	ExplorerNode * newNode;
	ExplorerNode * newChild;
	RecordSet * results;

	schema = [[Schema alloc] initWithConnection:theConnection];
	
	// set database level
    rootNode = [[ExplorerNode alloc] init];
    [rootNode setName: [theConnection currentDatabase]];
	[rootNode setBaseTable: @""];
	[rootNode setExplorerType:@"Database"];
	[rootNode setParent:nil];
	[rootNode setOID:0];
	
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
		
		newNode = [[ExplorerNode alloc] init];
		[newNode setName: schemaName];
		[newNode setExplorerType:@"Schema"];
		[newNode setParent:rootNode];

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
		[rootNode addChild: newNode];
		[newNode release];
	}
	return self;
}

- (void)dealloc
{
	// todo release all ExplorerNodes
	[rootNode release];
	[schema release];
	[super dealloc];
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


// These methods get called because I am the datasource of the outline view.
- (id)outlineView:(NSOutlineView *)outlineView child:(int)i ofItem:(id)item
{
    if (item)
        // Return the child
        return [item childAtIndex:i];
    else 
        // Else return the root
        return [rootNode childAtIndex:i];	
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    // Returns YES if the node has children
    return [item expandable];	
}


- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (item == nil) {
        // The root object;
        return [rootNode childrenCount];
    }
    return [item childrenCount];	
}


- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    // Set the identifier of the columns in IB's inspector
    NSString *identifier = [tableColumn identifier];

    // What is returned depends upon which column it is going to appear.
    if ([identifier isEqual:@"col1"])
        return [item name];
	if ([identifier isEqual:@"col2"])  	
		return [item displayColumn2];
		
	return nil;	
}

- (void)printLog
{
	[rootNode printLog:0];
}

@end
