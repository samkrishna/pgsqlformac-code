//
//  Schema.m
//  pgCocoaDB
//
//  Created by Neil Tiffin on 2/26/06.
//  Copyright 2006 Performance Champions, Inc. All rights reserved.
//

#import "Schema.h"


@implementation Schema

- initWithConnection:(Connection *) theConnection
{
	self = [super init];
	connection = theConnection;
	[connection retain];
	defaultSchemaName = [[[NSString alloc] initWithString: @"public"] retain];
	
	return self;
}


-(RecordSet *)getFunctionInfoFromSchema:(NSString *)schemaName functionName: (NSString *) functionName
{
	NSString *sql;
	RecordSet * results;
	
	sql = [NSString stringWithFormat:@"%s%s%s",
		"",
		schemaName,
		""];

	results = [connection execQuery:sql];
	[[results retain] autorelease];
	return results;
}


-(RecordSet *)getFunctionNamesFromSchema:(NSString *)schemaName;
{
	NSString *sql;
	RecordSet * results;
	
	sql = [NSString stringWithFormat:@"%s%s%s",
		"",
		schemaName,
		""];

	results = [connection execQuery:sql];
	[[results retain] autorelease];
	return results;
}


-(RecordSet *)getIndexInfoFromSchema:(NSString *)schemaName tableName:(NSString *) tableName indexName:(NSString *) indexName;
{
	NSString *sql;
	RecordSet * results;
	
	sql = [NSString stringWithFormat:@"%s%s%s",
		"",
		schemaName,
		""];

	results = [connection execQuery:sql];
	[[results retain] autorelease];
	return results;
}


-(RecordSet *)getIndexNamesFromSchema:(NSString *)schemaName tableName:(NSString *) tableName;
{
	NSString *sql;
	RecordSet * results;
	
	sql = [NSString stringWithFormat:@"%s%s%s",
		"",
		schemaName,
		""];

	results = [connection execQuery:sql];
	[[results retain] autorelease];
	return results;
}


-(RecordSet *)getObjectDescriptionFromSchema:(NSString *)schemaName objectType:(NSString *)objectType objectName:(NSString *)objectName;
{
	NSString *sql;
	RecordSet * results;
	
	sql = [NSString stringWithFormat:@"%s%s%s",
		"",
		schemaName,
		""];

	results = [connection execQuery:sql];
	[[results retain] autorelease];
	return results;
}


-(RecordSet *)getSchemaNames;
{
	NSString *sql;
	RecordSet * results;
	
	sql = [NSString stringWithFormat:@"%s%%s",
		"",
		""];

	results = [connection execQuery:sql];
	[[results retain] autorelease];
	return results;
}


-(RecordSet *)getTableColumnInfoFromSchema:(NSString *)schemaName tableName:(NSString *) tableName;
{
	NSString *sql;
	RecordSet * results;
	
	sql = [NSString stringWithFormat:@"%s%s%s",
		"",
		schemaName,
		""];

	results = [connection execQuery:sql];
	[[results retain] autorelease];
	return results;
}


-(RecordSet *)getTableNamesFromSchema:(NSString *)schemaName;
{
	NSString *sql;
	RecordSet * results;
	if (schemaName == nil)
	{
		schemaName = defaultSchemaName;
	}
	sql = [NSString stringWithFormat:@"%s'%@'%s",
		"SELECT table_name FROM information_schema.tables WHERE table_schema = ",
		schemaName,
		" AND table_type = 'BASE TABLE' ORDER BY table_name ASC"];
	results = [connection execQuery:sql];
	[results autorelease];
	return results;
}


-(RecordSet *)getViewColumnInfoFromSchema:(NSString *)schemaName viewName:(NSString *) viewName;
{
	NSString *sql;
	RecordSet * results;

	sql = [NSString stringWithFormat:@"%s%s%s",
		"",
		schemaName,
		""];
	
	results = [connection execQuery:sql];
	[[results retain] autorelease];
	return results;
}


-(RecordSet *)getViewNamesFromSchema:(NSString *)schemaName;
{
	NSString *sql;
	RecordSet * results;
	
	sql = [NSString stringWithFormat:@"%s'%@'%s",
		"SELECT table_name FROM information_schema.tables WHERE table_schema = ",
		schemaName,
		" AND table_type = 'VIEW' ORDER BY table_name ASC"];
	
	results = [connection execQuery:sql];
	[results autorelease];
	return results;
}



@end
