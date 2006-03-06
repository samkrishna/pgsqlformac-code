//
//  Schema.m
//  pgCocoaDB
//
//  Created by Neil Tiffin on 2/26/06.
//  Copyright 2006 Performance Champions, Inc. All rights reserved.
//
//	This class provides information about tables, views, triggers,
//	indexes, schemas, columns, and functions in the PostgreSQL database.
//

#import "Schema.h"

@implementation Schema

- initWithConnection:(Connection *) theConnection
{
	NSString *sql;
	RecordSet * results;
	Field * versionField;
	
	self = [super init];
	connection = theConnection;
	[connection retain];
	defaultSchemaName = [[NSString alloc] initWithString: @"public"];
	
	sql = [NSString stringWithFormat:@"%s", "Select version()"];
	results = [connection execQuery:sql];
	versionField = [[[results itemAtIndex:0] fields] itemAtIndex:0];
	pg_version_found = [[NSString alloc] initWithString: [versionField value]];

#if PG_COCOA_DEBUG
	NSLog(pg_version_found);
#endif

	//PostgreSQL 8.1.2 on powerpc-apple-darwin8.5.0, compiled by GCC powerpc-apple-darwin8-gcc-4.0.1 (GCC) 4.0.1 (Apple Computer, Inc. build 5250)
	if ([pg_version_found rangeOfString:@"PostgreSQL 8.1"].location == NSNotFound)
	{
		// TODO not found raise error?

#if PG_COCOA_DEBUG
		NSLog(@"Did not find PostgreSQL version 8");
		NSLog(sql);
		NSLog(pg_version_found);
#endif

	}
	return self;
}


- (void)dealloc
{	
	[connection disconnect];
	[connection release];
	connection = nil;
	
	[defaultSchemaName release];
	defaultSchemaName = nil;
	
	[pg_version_found release];
	pg_version_found = nil;
	
	[super dealloc];
}


-(RecordSet *)getFunctionSourceFromSchema:(NSString *)schemaName functionName: (NSString *) functionName
{
	NSString *sql;
	RecordSet * results;
	
	if (schemaName == nil)
	{
		schemaName = defaultSchemaName;
	}
	
	sql = [NSString stringWithFormat:@"%s'%@''%@'",
		"SELECT routine_definition FROM information_schema.routines \
		WHERE routine_schema = ", schemaName,
		" AND routine_name = ", functionName];

#if PG_COCOA_DEBUG
	NSLog(sql);
#endif

	results = [connection execQuery:sql];
	return results;
}


-(RecordSet *)getFunctionNamesFromSchema:(NSString *)schemaName;
{
	NSString *sql;
	RecordSet * results;
	
	if (schemaName == nil)
	{
		schemaName = defaultSchemaName;
	}
	sql = [NSString stringWithFormat:@"%s'@s'",
		"SELECT routine_name \
		FROM information_schema.routines \
		WHERE routine_schema = ", schemaName];
	
#if PG_COCOA_DEBUG
	NSLog(sql);
#endif
	
	results = [connection execQuery:sql];
	[results autorelease];
	return results;
}


-(RecordSet *)getIndexInfoFromSchema:(NSString *)schemaName tableName:(NSString *) tableName indexName:(NSString *) indexName;
{
	NSString *sql;
	RecordSet * results;
	
	if (schemaName == nil)
	{
		schemaName = defaultSchemaName;
	}
	sql = [NSString stringWithFormat:@"%s%s%s",
		"",
		schemaName,
		""];
	
#if PG_COCOA_DEBUG
	NSLog(sql);
#endif
	
	results = [connection execQuery:sql];
	[results autorelease];
	return results;
}


-(RecordSet *)getIndexNamesFromSchema:(NSString *)schemaName tableName:(NSString *) tableName;
{
	NSString *sql;
	RecordSet * results;
	
	if (schemaName == nil)
	{
		schemaName = defaultSchemaName;
	}
	sql = [NSString stringWithFormat:@"%s%s%s",
		"",
		schemaName,
		""];
	
#if PG_COCOA_DEBUG
	NSLog(sql);
#endif
	
	results = [connection execQuery:sql];
	[results autorelease];
	return results;
}


-(RecordSet *)getObjectDescriptionFromSchema:(NSString *)schemaName objectType:(NSString *)objectType objectName:(NSString *)objectName;
{
	NSString *sql;
	RecordSet * results;
	
	if (schemaName == nil)
	{
		schemaName = defaultSchemaName;
	}
	sql = [NSString stringWithFormat:@"%s%s%s",
		"",
		schemaName,
		""];
	
#if PG_COCOA_DEBUG
	NSLog(sql);
#endif
	
	results = [connection execQuery:sql];
	[results autorelease];
	return results;
}


-(RecordSet *)getSchemaNames;
{
	NSString *sql;
	RecordSet * results;
	
	sql = [NSString stringWithFormat:@"%s%%s",
		"",
		""];
	
#if PG_COCOA_DEBUG
	NSLog(sql);
#endif
	
	results = [connection execQuery:sql];
	[results autorelease];
	return results;
}


-(RecordSet *)getTableColumnInfoFromSchema:(NSString *)schemaName fromTableName:(NSString *)tableName fromColumnName:(NSString *)columnName;
{
	NSString *sql;
	RecordSet * results;
	
	if (schemaName == nil)
	{
		schemaName = defaultSchemaName;
	}
	sql = [NSString stringWithFormat:@"%s%s%s",
		"",
		schemaName,
		""];
	
#if PG_COCOA_DEBUG
	NSLog(sql);
#endif
	
	results = [connection execQuery:sql];
	[results autorelease];
	return results;
}


-(RecordSet *)getTableColumnNamesFromSchema:(NSString *)schemaName fromTableName:(NSString *) tableName;
{
	NSString *sql;
	RecordSet * results;
	
	if (schemaName == nil)
	{
		schemaName = defaultSchemaName;
	}
	sql = [NSString stringWithFormat:@"%s'%@'%s'%@'%s",
		"SELECT column_name FROM information_schema.columns \
		WHERE table_schema = ", schemaName,
		" AND table_name = ", tableName,
		" ORDER BY column_name ASC"];
	
#if PG_COCOA_DEBUG
	NSLog(sql);
#endif
	
	results = [connection execQuery:sql];
	[results autorelease];
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
		"SELECT table_name FROM information_schema.tables WHERE table_schema = ",schemaName,
		" AND table_type = 'BASE TABLE' ORDER BY table_name ASC"];
	
#if PG_COCOA_DEBUG
	NSLog(sql);
#endif

	results = [connection execQuery:sql];
	[results autorelease];
	return results;
}


-(RecordSet *)getTriggerInfoFromSchema:(NSString *)schemaName
{
	NSString *sql;
	RecordSet * results;
	
	if (schemaName == nil)
	{
		schemaName = defaultSchemaName;
	}
	sql = [NSString stringWithFormat:@"%s%s%s",
		"",
		schemaName,
		""];
	
#if PG_COCOA_DEBUG
	NSLog(sql);
#endif

	results = [connection execQuery:sql];
	[results autorelease];
	return results;
}


-(RecordSet *)getTriggerNamesFromSchema:(NSString *)schemaName fromTableName:(NSString *) tableName
{
	NSString *sql;
	RecordSet * results;
	
	if (schemaName == nil)
	{
		schemaName = defaultSchemaName;
	}
	sql = [NSString stringWithFormat:@"%s'%@'%s'%@'",
		"SELECT trigger_name FROM information_schema.triggers \
		WHERE event_object_schema =", schemaName, 
		" AND event_object_table = ", tableName];
	
#if PG_COCOA_DEBUG
	NSLog(sql);
#endif
	
	results = [connection execQuery:sql];
	[results autorelease];
	return results;
}


-(RecordSet *)getViewColumnInfoFromSchema:(NSString *)schemaName viewName:(NSString *) viewName;
{
	NSString *sql;
	RecordSet * results;

	if (schemaName == nil)
	{
		schemaName = defaultSchemaName;
	}
	sql = [NSString stringWithFormat:@"%s%s%s",
		"",
		schemaName,
		""];
	
#if PG_COCOA_DEBUG
	NSLog(sql);
#endif
	
	results = [connection execQuery:sql];
	[results autorelease];
	return results;
}


-(RecordSet *)getViewNamesFromSchema:(NSString *)schemaName;
{
	NSString *sql;
	RecordSet * results;
	
	if (schemaName == nil)
	{
		schemaName = defaultSchemaName;
	}
	sql = [NSString stringWithFormat:@"%s'%@'%s",
		"SELECT table_name FROM information_schema.tables WHERE table_schema = ", schemaName,
		" AND table_type = 'VIEW' ORDER BY table_name ASC"];
	
#if PG_COCOA_DEBUG
	NSLog(sql);
#endif
	
	results = [connection execQuery:sql];
	[results autorelease];
	return results;
}

@end
