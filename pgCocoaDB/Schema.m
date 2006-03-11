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
	pgVersionFound = [[NSString alloc] initWithString: [versionField value]];

	//PostgreSQL 8.1.2 on powerpc-apple-darwin8.5.0, compiled by GCC powerpc-apple-darwin8-gcc-4.0.1 (GCC) 4.0.1 (Apple Computer, Inc. build 5250)
	if ([pgVersionFound rangeOfString:@"PostgreSQL 8.1"].location == NSNotFound)
	{
		// TODO not found raise error?

		NSLog(@"Did not find PostgreSQL version 8");
		NSLog(sql);
		NSLog(pgVersionFound);
	}
	return self;
}


- (NSString *)defaultSchemaName;
{
	return defaultSchemaName;
}


- (NSString *)pgVersionFound;
{
	return pgVersionFound;
}


- (void)dealloc
{	
	[connection disconnect];
	[connection release];
	connection = nil;
	
	[defaultSchemaName release];
	defaultSchemaName = nil;
	
	[pgVersionFound release];
	pgVersionFound = nil;
	
	[super dealloc];
}


-(RecordSet *)getNamesFromSchema:(NSString *)schemaName fromType:(NSString *)type;
{
	NSString * sql;
	
	sql = [NSString stringWithFormat:@"SELECT relname \
	FROM pg_catalog.pg_class c, pg_namespace n \
	WHERE n.nspname = '%@' \
	AND c.relnamespace = n.oid \
	AND c.relkind = '%@' ORDER BY c.relname", schemaName, type];
	
	return [connection execQuery:sql];
}


-(RecordSet *)getDatabaseNames;
{
	return [connection execQuery:@"SELECT datname FROM pg_catalog.pg_database ORDER BY datname"];
}


-(RecordSet *)getFunctionNamesFromSchema:(NSString *)schemaName;
{
	NSString *sql;
	NSString *useSchema;
	
	sql = [NSString stringWithFormat:@"%s'@s'",
	"SELECT routine_name \
	FROM information_schema.routines \
	WHERE routine_schema = ", useSchema];
	
	return [connection execQuery:sql];
}


-(NSString *)getFunctionSQLFromSchema:(NSString *)schemaName fromFunctionName: (NSString *) functionName
{
	NSString * sql;
	RecordSet * results;
	
	sql = [NSString stringWithFormat:@"%s'%@''%@'",
	"SELECT routine_definition FROM information_schema.routines \
	WHERE routine_schema = ", schemaName,
	" AND routine_name = ", functionName];

	results = [connection execQuery:sql];
	if ([results count] == 1)
	{
		return [[[[results itemAtIndex: 0] fields] itemAtIndex:0] value];
	}	
	return nil;
}


-(NSString *)getIndexSQLFromSchema:(NSString *)schemaName fromTableName:(NSString *) tableName fromIndexName:(NSString *) indexName;
{
	NSString * sql;
	RecordSet * results;
	
	sql = [NSString stringWithFormat:@"SELECT indexdef FROM pg_catalog.pg_indexes \
	WHERE schemaname = '%@' AND tablename = '%@' AND indexname = '%@'", schemaName, tableName, indexName];

	results = [connection execQuery:sql];
	if ([results count] == 1)
	{
		return [[[[results itemAtIndex: 0] fields] itemAtIndex:0] value];
	}	
	return nil;
}


-(RecordSet *)getIndexNamesFromSchema:(NSString *)schemaName fromTableName:(NSString *) tableName;
{
	NSString *sql;
	
	sql = [NSMutableString stringWithFormat:@"%s'%@'%s'%@'%s","SELECT indexname \
	FROM pg_catalog.pg_indexes WHERE schemaname = ", schemaName, " AND tablename = ", tableName, " ORDER BY indexname ASC"];
	//return [self getNamesFromSchema:schemaName fromType: @"i"];
	
	return [connection execQuery:sql];
}

-(RecordSet *)getSchemaNames;
{
	return [connection execQuery:@"SELECT schema_name FROM information_schema.schemata ORDER BY schema_name"];
}


/*
 to get current values
 select *
 from pgcocoa_test_schema.address_address_id_seq
 */
-(RecordSet *)getSequenceColumnNamesFromSchema:(NSString *)schemaName fromSequence:(NSString *)sequenceName;
{
	NSString * sql;

	sql = [NSString stringWithFormat:@"SELECT attname \
	FROM pg_catalog.pg_class c, pg_catalog.pg_attribute a, pg_namespace n \
	WHERE relkind = 'S'  AND c.oid = a.attrelid AND attnum > 0 AND c.relnamespace = n.oid \
	AND c.relname ='%@' AND n.nspname = '%@'", sequenceName, schemaName];
	
	NSLog(sql);
	return [connection execQuery:sql];
}


-(RecordSet *)getSequenceNamesFromSchema:(NSString *)schemaName;
{
	if (schemaName == nil)
	{
		return [self getNamesFromSchema:defaultSchemaName fromType: @"S"];
	}
	return [self getNamesFromSchema:schemaName fromType: @"S"];
}


/*
 SELECT a.attname as "name", format_type(a.atttypid, a.atttypmod) AS "type",
 CASE 
	WHEN a.attnotnull = TRUE THEN 'NOT NULL'
	else ' '
 END as "notnull", 
 CASE
	WHEN a.atthasdef = '1'  THEN 'DEFAULT '  || cast(pg_catalog.pg_get_expr(d.adbin, attrelid) AS varchar(100))
	ELSE ' '
 END as "default"
 FROM ((pg_class c FULL OUTER JOIN pg_attribute a ON a.attrelid = c.oid)
	   FULL OUTER JOIN pg_namespace n ON n.oid = c.relnamespace) 
	LEFT OUTER JOIN pg_attrdef d ON d.adrelid = c.oid AND d.adnum = a.attnum
 WHERE c.relname = 'name'
 AND n.nspname = 'pgcocoa_test_schema'
 AND a.attnum > 0
 AND a.attisdropped  = FALSE
 ORDER BY a.attnum
 */


/* returns name, type, notnull, default */
-(RecordSet *)getTableColumnsInfoFromSchema:(NSString *)schemaName fromTableName:(NSString *)tableName;
{
	NSString *sql;
	NSString *sqlFormat;
	
	sqlFormat = @"SELECT a.attname as \"name\", format_type(a.atttypid, a.atttypmod) AS \"type\", \
		CASE \
			WHEN a.attnotnull = TRUE THEN ' NOT NULL' \
			ELSE NULL \
		END as \"notnull\", \
		CASE \
			WHEN a.atthasdef = '1'  THEN ' DEFAULT '  || cast(pg_catalog.pg_get_expr(d.adbin, attrelid) AS varchar(100)) \
			ELSE NULL \
		END as \"default\" \
		FROM ((pg_class c FULL OUTER JOIN pg_attribute a ON a.attrelid = c.oid) \
			FULL OUTER JOIN pg_namespace n ON n.oid = c.relnamespace)  \
			LEFT OUTER JOIN pg_attrdef d ON d.adrelid = c.oid AND d.adnum = a.attnum \
		WHERE c.relname = '%@' \
		AND n.nspname = '%@' \
		AND a.attnum > 0 \
		AND a.attisdropped = FALSE \
		ORDER BY a.attnum";

	sql = [NSString stringWithFormat:sqlFormat, tableName, schemaName];
	return [connection execQuery:sql];
}


/* returns type, notnull, default */
-(RecordSet *)getTableColumnInfoFromSchema:(NSString *)schemaName fromTableName:(NSString *)tableName fromColumnName:(NSString *)columnName;
{
	NSString *sql;
	NSString *sqlFormat;
	
	sqlFormat = @"SELECT format_type(a.atttypid, a.atttypmod) AS \"type\", \
	CASE \
		WHEN a.attnotnull = TRUE THEN ' NOT NULL' \
		ELSE NULL \
	END as \"notnull\", \
	CASE \
		WHEN a.atthasdef = '1'  THEN ' DEFAULT '  || cast(pg_catalog.pg_get_expr(d.adbin, attrelid) AS varchar(100)) \
		ELSE NULL \
	END as \"default\" \
	FROM ((pg_class c FULL OUTER JOIN pg_attribute a ON a.attrelid = c.oid) \
		FULL OUTER JOIN pg_namespace n ON n.oid = c.relnamespace)  \
		LEFT OUTER JOIN pg_attrdef d ON d.adrelid = c.oid AND d.adnum = a.attnum \
	WHERE c.relname = '%@' \
	AND n.nspname = '%@' \
	AND a.attname = '%@' \
	AND a.attnum > 0 \
	AND a.attisdropped = FALSE \
	ORDER BY a.attnum";
	
	sql = [NSString stringWithFormat:sqlFormat, tableName, schemaName, columnName];
	return [connection execQuery:sql];
}


-(RecordSet *)getTableColumnNamesFromSchema:(NSString *)schemaName fromTableName:(NSString *) tableName;
{
	NSString *sql;

	sql = [NSString stringWithFormat:@"%s'%@'%s'%@'%s",
	"SELECT column_name FROM information_schema.columns \
	WHERE table_schema = ", schemaName,
	" AND table_name = ", tableName,
	" ORDER BY ordinal_position ASC"];

	return [connection execQuery:sql];
}


-(RecordSet *)getTableNamesFromSchema:(NSString *)schemaName;
{
	if (schemaName == nil)
	{
		return [self getNamesFromSchema:defaultSchemaName fromType: @"r"];
	}
	return [self getNamesFromSchema:schemaName fromType: @"r"];
}


-(NSString *)getTableSQLFromSchema:(NSString *)schemaName fromTableName:(NSString *) tableName pretty:(int)pretty
{
	RecordSet *results;
	int i;
	NSMutableString * sqlOutput = [[NSMutableString alloc] init];
	[sqlOutput appendFormat:@"CREATE TABLE %@.%@ ( ", schemaName, tableName];
	if (pretty) [sqlOutput appendString:@"\n"];
	
	/* returns name, type, notnull, default */
	results = [self getTableColumnsInfoFromSchema:schemaName fromTableName:tableName];
	
	for (i = 0; i < [results count]; i++)
	{		
		if (i != 0)
		{
			if (pretty)
			{
				[sqlOutput appendString:@",\n"];
			}
			else
			{
				[sqlOutput appendString:@", "];				
			}
		}
		if (pretty) [sqlOutput appendString:@"    "];
		
		/* Attribute name */
		[sqlOutput appendFormat:@"%@", [[[results itemAtIndex: i] fields] getValueFromName:@"name"]];
		
		/* Attribute type */
		[sqlOutput appendFormat:@" %@", [[[results itemAtIndex: i] fields] getValueFromName:@"type"]];
		
		
		/* default value */
		/* TODO handle serial */
		/* if serial then change typename from integer to serial */
		/* if serial then change typename from bigint to bigserial */
		[sqlOutput appendFormat:@"%@", [[[results itemAtIndex: i] fields] getValueFromName:@"default"]];
		
		/* TODO check for foreign key  or primary key values */
		/* null constraint */
		[sqlOutput appendFormat:@"%@", [[[results itemAtIndex: i] fields] getValueFromName:@"notnull"]];
		

	}
	if (pretty)
	{
		[sqlOutput appendString:@"\n);"];
	}
	else
	{
		[sqlOutput appendString:@" );"];
	}
	[sqlOutput autorelease];
	return sqlOutput;
}


-(NSString *)getTriggerSQLFromSchema:(NSString *)schemaName fromTriggerName:(NSString *)triggerName
{
	NSString * sql;
	RecordSet * results;
	
	// TODO handle schema
	sql = [NSString stringWithFormat:@"%s%@%s",
	"SELECT pg_catalog.pg_get_triggerdef(t.oid) \
	FROM pg_catalog.pg_trigger t				\
	WHERE t.tgname = ", triggerName];

	results = [connection execQuery:sql];
	if ([results count] == 1)
	{
		return [[[[results itemAtIndex: 0] fields] itemAtIndex:0] value];
	}
	return nil;
}


-(RecordSet *)getTriggerNamesFromSchema:(NSString *)schemaName fromTableName:(NSString *) tableName
{
	NSString *sql;
	
	sql = [NSString stringWithFormat:@"%s'%@'%s'%@'",
	"SELECT trigger_name FROM information_schema.triggers \
	WHERE event_object_schema =", schemaName, 
	" AND event_object_table = ", tableName];
	
	return [connection execQuery:sql];
}


-(RecordSet *)getViewNamesFromSchema:(NSString *)schemaName;
{
	if (schemaName == nil)
	{
		return [self getNamesFromSchema:defaultSchemaName fromType: @"v"];
	}
	return [self getNamesFromSchema:schemaName fromType: @"v"];
}


/*
 SELECT definition
 FROM pg_catalog.pg_views
 WHERE viewname = 'name_of_view'
 
 CREATE VIEW pg_views AS \
 SELECT \
 N.nspname AS schemaname, \
 C.relname AS viewname, \
 pg_get_userbyid(C.relowner) AS viewowner, \
 pg_get_viewdef(C.oid) AS definition \
 FROM pg_class C LEFT JOIN pg_namespace N ON (N.oid = C.relnamespace) \
 WHERE C.relkind = 'v';
 */
-(NSString *)getViewSQLFromSchema:(NSString *)schemaName fromView:(NSString *)viewName pretty:(int)pretty;
{
	NSString *sql;
	RecordSet * results;
	
	//sql = [NSString stringWithFormat:@"%s'%@.%@'%s%d%s",
	//"select pg_catalog.pg_get_viewdef(", schemaName, viewName, ", '", pretty, "')"];
	sql = [NSString stringWithFormat:@"%s'%d'%s'%@'%s'%@'%s",
	"select pg_get_viewdef(C.oid, ", pretty, ") \
	from pg_class C, pg_namespace N \
	where N.nspname = ", schemaName,
	"AND C.relname = ", viewName,
	"AND N.oid = C.relnamespace AND C.relkind = 'v';"];
	
	results = [connection execQuery:sql];
	if ([results count] == 1)
	{
		if (pretty)
		{
			sql = [[NSString alloc] initWithFormat:@"CREATE OR REPLACE VIEW %@ AS \n %@", viewName, [[[[results itemAtIndex: 0] fields] itemAtIndex:0] value]];
		}
		else
		{
			sql = [[NSString alloc] initWithFormat:@"CREATE OR REPLACE VIEW %@ AS %@", viewName, [[[[results itemAtIndex: 0] fields] itemAtIndex:0] value]];
		}
		[sql autorelease];
		return sql;
	}
	return nil;
}

// Process Comments
-(NSString *)getColumnCommentFromSchema:(NSString *)schemaName fromTableName:(NSString *)tableName fromColumnName:(NSString *) columnName;
{
	
	return nil;
}


-(NSString *)getIndexCommentFromSchema:(NSString *)schemaName fromIndexName:(NSString *)indexName;
{
	NSString *sql;
	RecordSet *results;
	
	sql = [NSString stringWithFormat:@"select obj_description(t.oid,'pg_class') from pg_catalog.pg_class c, pg_catalog.pg_namespace n\
	where tgrelid = c.oid AND c.relkind = 'i' AND c.relname = '%@' AND c.relnamespace = n.oid AND n.nspname = '%@'", indexName, schemaName];
	NSLog(sql);
	results = [connection execQuery:sql];
	if ([results count] == 1)
	{
		return [[[[results itemAtIndex: 0] fields] itemAtIndex:0] value];
	}
	return nil;
}


-(NSString *)getTableCommentFromSchema:(NSString *)schemaName fromTableName:(NSString *)tableName;
{
	NSString *sql;
	RecordSet *results;
	
	sql = [NSString stringWithFormat:@"select obj_description(t.oid,'pg_class') from pg_catalog.pg_class c, pg_catalog.pg_namespace n\
	where tgrelid = c.oid AND c.relkind = 'r' AND c.relname = '%@' AND c.relnamespace = n.oid AND n.nspname = '%@'", tableName, schemaName];
	NSLog(sql);
	results = [connection execQuery:sql];
	if ([results count] == 1)
	{
		return [[[[results itemAtIndex: 0] fields] itemAtIndex:0] value];
	}
	return nil;
}


// TODO
-(NSString *)getObjectCommentFromSchema:(NSString *)schemaName objectType:(NSString *)objectType objectName:(NSString *)objectName;
{
	NSString *oidLookupTable;
		
	if (([objectType compare:@"table"] == NSOrderedSame)
		|| ([objectType compare:@"column"] == NSOrderedSame)
		|| ([objectType compare:@"index"] == NSOrderedSame)
		|| ([objectType compare:@"sequence"] == NSOrderedSame)
		|| ([objectType compare:@"View"] == NSOrderedSame))
	{
		oidLookupTable = @"pg_class";
	}
	else if ([objectType compare:@"aggregate"] == NSOrderedSame)
	{
		oidLookupTable = @"pg_aggregate";
	}
	else if ([objectType compare:@"constraint"] == NSOrderedSame)
	{
		oidLookupTable = @"pg_constraint";
	}
	else if ([objectType compare:@"database"] == NSOrderedSame)
	{
		oidLookupTable = @"pg_database";
	}
	else if ([objectType compare:@"function"] == NSOrderedSame)
	{
		oidLookupTable = @"pg_proc";
	}
	else if ([objectType compare:@"rule"] == NSOrderedSame)
	{
		oidLookupTable = @"pg_rewrite";
	}
	else if ([objectType compare:@"schema"] == NSOrderedSame)
	{
		oidLookupTable = @"pg_namespace";
	}
	
	return nil;
}


-(NSString *)getTriggerCommentFromSchema:(NSString *)schemaName fromTableName:(NSString *)tableName fromTriggerName:(NSString *)triggerName;
{
	NSString *sql;
	RecordSet *results;
	
	sql = [NSString stringWithFormat:@"select obj_description(t.oid,'pg_trigger') from pg_catalog.pg_trigger t, pg_catalog.pg_class c, pg_catalog.pg_namespace n\
	where tgname = '%@' AND tgrelid = c.oid AND c.relname = '%@' AND c.relnamespace = n.oid AND n.nspname = '%@'", triggerName, tableName, schemaName];
	NSLog(sql);
	results = [connection execQuery:sql];
	if ([results count] == 1)
	{
		return [[[[results itemAtIndex: 0] fields] itemAtIndex:0] value];
	}
	return nil;
}


@end

