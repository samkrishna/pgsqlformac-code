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
	}
}


- (void)createColumnNodes:(ExplorerNode *)aParent fromSchemaName:(NSString *)schemaName fromTableName:(NSString *)tableName
{
	RecordSet * results;
	ExplorerNode * newNode;
	NSString * columnName;
	int i;
	results = [schema getTableColumnNamesFromSchema:schemaName fromTableName:tableName];
	for (i = 0; i < [results count]; i++)
	{
		newNode = [[ExplorerNode alloc] init];
		columnName = [[[[results itemAtIndex: i] fields] itemAtIndex:0] value];
		[newNode setName:columnName];
		[newNode setExplorerType:@"Column Name"];
		[newNode setParent:aParent];
		[newNode setDisplayColumn2:@""];
		[aParent addChild:newNode];
		//TODO get column info
	}
}

- (void)createTriggerNodes:(ExplorerNode *)aParent fromSchemaName:(NSString *)schemaName fromTableName:(NSString *)tableName
{
	RecordSet * results;
	ExplorerNode * newNode;
	NSString * triggerName;
	int i;
	results = [schema getTriggerNamesFromSchema:schemaName fromTableName:tableName];
	for (i = 0; i < [results count]; i++)
	{
		newNode = [[ExplorerNode alloc] init];
		triggerName = [[[[results itemAtIndex: i] fields] itemAtIndex:0] value];
		[newNode setName:triggerName];
		[newNode setExplorerType:@"Trigger Name"];
		[newNode setParent:aParent];
		[newNode setDisplayColumn2:@""];
		[aParent addChild:newNode];
		//TODO get trigger info
	}
}

- (void)createConstraintNodes:(ExplorerNode *)aParent fromSchemaName:(NSString *)schemaName fromTableName:(NSString *)tableName
{
	RecordSet * results;
	ExplorerNode * newNode;
	NSString * constraintName;
	int i;
	results = [schema getConstraintNamesFromSchema:schemaName fromTableName:tableName];
	for (i = 0; i < [results count]; i++)
	{
		newNode = [[ExplorerNode alloc] init];
		constraintName = [[[[results itemAtIndex: i] fields] itemAtIndex:0] value];
		[newNode setName:constraintName];
		[newNode setExplorerType:@"Constraint Name"];
		[newNode setParent:aParent];
		[newNode setDisplayColumn2:@""];
		[aParent addChild:newNode];
		//TODO get constraints info
	}
}

- (void)createIndexNodes:(ExplorerNode *)aParent fromSchemaName:(NSString *)schemaName fromTableName:(NSString *)tableName
{
	RecordSet * results;
	ExplorerNode * newNode;
	NSString * indexName;
	int i;
	results = [schema getIndexNamesFromSchema:schemaName fromTableName:tableName];
	for (i = 0; i < [results count]; i++)
	{
		newNode = [[ExplorerNode alloc] init];
		indexName = [[[[results itemAtIndex: i] fields] itemAtIndex:0] value];
		[newNode setName:indexName];
		[newNode setExplorerType:@"Index Name"];
		[newNode setParent:aParent];
		[newNode setDisplayColumn2:@""];
		[aParent addChild:newNode];
		//TODO get Index info
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
	}
}


- (id)initWithConnection:(Connection *) theConnection
{
	[super init];
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
		[self createTableNodes:newChild fromSchemaName:schemaName];

		newChild = [[ExplorerNode alloc] init];
		[newChild setName: @"Sequences"];
		[newChild setExplorerType:@"Schema Child"];
		[newChild setParent:newNode];
		[newNode addChild: newChild];
		[self createSequenceNodes:newChild fromSchemaName:schemaName];
		
		newChild = [[ExplorerNode alloc] init];
		[newChild setName: @"Views"];
		[newChild setExplorerType:@"Schema Child"];
		[newChild setParent:newNode];
		[newNode addChild: newChild];
		[self createViewNodes:newChild fromSchemaName:schemaName];
		
		newChild = [[ExplorerNode alloc] init];
		[newChild setName: @"Functions"];
		[newChild setExplorerType:@"Schema Child"];
		[newChild setParent:newNode];
		[newNode addChild: newChild];
		[self createFunctionNodes:newChild fromSchemaName:schemaName];
		
		// add to the root node
		[rootNode addChild: newNode];
	}
	return self;
}

- (void)dealloc
{
	// todo release all ExplorerNodes
	[super dealloc];
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
