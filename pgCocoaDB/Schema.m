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


-(RecordSet *)getDatabaseNames;
{
	NSString *sql;
	
	sql = [NSString stringWithFormat:@"%s", "SELECT datname FROM pg_catalog.pg_database ORDER BY datname"];
	
#if PG_COCOA_DEBUG
	NSLog(sql);
#endif
	
	return [connection execQuery:sql];
}


-(RecordSet *)getFunctionNamesFromSchema:(NSString *)schemaName;
{
	NSString *sql;
	
	if (schemaName == nil)
	{
		sql = [NSString stringWithFormat:@"%s'@s'",
		"SELECT routine_name \
		FROM information_schema.routines \
		WHERE routine_schema = ", defaultSchemaName];
	}
	else
	{
		sql = [NSString stringWithFormat:@"%s'@s'",
		"SELECT routine_name \
		FROM information_schema.routines \
		WHERE routine_schema = ", schemaName];
	}
	
#if PG_COCOA_DEBUG
	NSLog(sql);
#endif
	
	return [connection execQuery:sql];
}


-(NSString *)getFunctionSQLFromSchema:(NSString *)schemaName fromFunctionName: (NSString *) functionName
{
	NSString * sql;
	RecordSet * results;
	
	if (schemaName == nil)
	{
		sql = [NSString stringWithFormat:@"%s'%@''%@'",
		"SELECT routine_definition FROM information_schema.routines \
		WHERE routine_schema = ", defaultSchemaName,
		" AND routine_name = ", functionName];
	}
	else
	{
		sql = [NSString stringWithFormat:@"%s'%@''%@'",
		"SELECT routine_definition FROM information_schema.routines \
		WHERE routine_schema = ", schemaName,
		" AND routine_name = ", functionName];
	}
	
#if PG_COCOA_DEBUG
	NSLog(sql);
#endif

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
	
	if (schemaName == nil)
	{
		sql = [NSString stringWithFormat:@"SELECT indexdef FROM pg_catalog.pg_indexes \
		WHERE schemaname = '%@' AND tablename = '%@' AND indexname = '%@'", defaultSchemaName, tableName, indexName];
	}
	else
	{
		sql = [NSString stringWithFormat:@"SELECT indexdef FROM pg_catalog.pg_indexes \
		WHERE schemaname = '%@' AND tablename = '%@' AND indexname = '%@'", schemaName, tableName, indexName];
	}
	
#if PG_COCOA_DEBUG
	NSLog(sql);
#endif

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
	
	if (schemaName == nil)
	{
		sql = [NSMutableString stringWithFormat:@"%s'%@'%s'%@'%s","SELECT indexname \
		FROM pg_catalog.pg_indexes WHERE schemaname = ", defaultSchemaName, " AND tablename = ", tableName, " ORDER BY indexname ASC"];
	}
	else
	{
		sql = [NSMutableString stringWithFormat:@"%s'%@'%s'%@'%s","SELECT indexname \
		FROM pg_catalog.pg_indexes WHERE schemaname = ", schemaName, " AND tablename = ", tableName, " ORDER BY indexname ASC"];
	}
	
#if PG_COCOA_DEBUG
	NSLog(sql);
#endif
	
	return [connection execQuery:sql];
}

/*
create or replace function get_tablecomment(text)
returns text as
'
select obj_description(oid, ''pg_class'') from pg_class where relname=$1;
' language 'SQL' ;
comment on function get_tablecomment(text) is 'Get comment from table name';

create or replace function get_funccomment(text, text) 
returns text as
'
select obj_description(oid,''pg_proc'') from pg_proc 
where proname = $1 and oidvectortypes(proargtypes) = $2;
' language 'SQL' ;
comment on function get_funccomment(text, text) is
'Get comment from function name and arguments';


create or replace function get_aggcomment(text, text) 
returns text as
'
select obj_description(oid,''pg_aggregate'') from pg_proc 
where proname = $1 and oidvectortypes(proargtypes) = $2;
' language 'SQL' ;
comment on function get_aggcomment(text, text) is
'Get comment from aggregate name and argument';
 */

// TODO
-(RecordSet *)getObjectDescriptionFromSchema:(NSString *)schemaName objectType:(NSString *)objectType objectName:(NSString *)objectName;
{
	NSString *sql;
	
	/*
	 SELECT t.typname, d.description
	 FROM pg_catalog.pg_description d, pg_catalog.pg_type t, pg_catalog.pg_database db
	 WHERE (d.objoid = t.oid OR d.objoid = db.oid)
	 */
	
	// TODO defaultSchemaName;
	sql = [NSString stringWithFormat:@"%s%@%s",
		"SELECT objoid, classoid, objsubid, description \
		FROM pg_catalog.pg_description d, pg_catalog.pg_type t, pg_catalog.pg_database db \
		where t.typname = ", objectType,
		" AND (d.objoid = t.oid OR d.objoid = db.oid)"];
	
#if PG_COCOA_DEBUG
	NSLog(sql);
#endif
	
	return [connection execQuery:sql];
}


-(RecordSet *)getSchemaNames;
{
	NSString *sql;
	
	sql = [NSString stringWithFormat:@"%s", "SELECT schema_name FROM information_schema.schemata ORDER BY schema_name"];
	
#if PG_COCOA_DEBUG
	NSLog(sql);
#endif
	
	return [connection execQuery:sql];
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

	if (schemaName == nil)
	{
		sql = [NSString stringWithFormat:sqlFormat, tableName, defaultSchemaName];
	}
	else
	{
		sql = [NSString stringWithFormat:sqlFormat, tableName, schemaName];
	}
	
#if PG_COCOA_DEBUG
	NSLog(sql);
#endif
	
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
	
	if (schemaName == nil)
	{
		sql = [NSString stringWithFormat:sqlFormat, tableName, defaultSchemaName, columnName];
	}
	else
	{
		sql = [NSString stringWithFormat:sqlFormat, tableName, schemaName, columnName];
	}
	
#if PG_COCOA_DEBUG
	NSLog(sql);
#endif
	
	return [connection execQuery:sql];
}


-(RecordSet *)getTableColumnNamesFromSchema:(NSString *)schemaName fromTableName:(NSString *) tableName;
{
	NSString *sql;
	
	if (schemaName == nil)
	{
		sql = [NSString stringWithFormat:@"%s'%@'%s'%@'%s",
		"SELECT column_name FROM information_schema.columns \
		WHERE table_schema = ", defaultSchemaName,
		" AND table_name = ", tableName,
		" ORDER BY ordinal_position ASC"];
	}
	else
	{
		sql = [NSString stringWithFormat:@"%s'%@'%s'%@'%s",
		"SELECT column_name FROM information_schema.columns \
		WHERE table_schema = ", schemaName,
		" AND table_name = ", tableName,
		" ORDER BY ordinal_position ASC"];
	}
	
#if PG_COCOA_DEBUG
	NSLog(sql);
#endif
	
	return [connection execQuery:sql];
}


-(RecordSet *)getTableNamesFromSchema:(NSString *)schemaName;
{
	NSString *sql;

	if (schemaName == nil)
	{
		sql = [NSString stringWithFormat:@"%s'%@'%s",
		"SELECT table_name FROM information_schema.tables WHERE table_schema = ",defaultSchemaName,
		" AND table_type = 'BASE TABLE' ORDER BY table_name ASC"];
	}
	else
	{
		sql = [NSString stringWithFormat:@"%s'%@'%s",
		"SELECT table_name FROM information_schema.tables WHERE table_schema = ",schemaName,
		" AND table_type = 'BASE TABLE' ORDER BY table_name ASC"];
	}
	
#if PG_COCOA_DEBUG
	NSLog(sql);
#endif

	return [connection execQuery:sql];
}


-(NSString *)getTableSQLFromSchema:(NSString *)schemaName fromTableName:(NSString *) tableName
{
	RecordSet *results;
	int i;
	NSMutableString * sqlOutput = [[NSMutableString alloc] init];
	[sqlOutput appendFormat:@"CREATE TABLE %@ ( ", tableName];
	
	/* returns name, type, notnull, default */
	results = [self getTableColumnsInfoFromSchema:schemaName fromTableName:tableName];
	
	for (i = 0; i < [results count]; i++)
	{		
		if (i != 0)
		{
			[sqlOutput appendString:@", "];
		}
		
		/* Attribute name */
		[sqlOutput appendFormat:@"%@", [[[results itemAtIndex: i] fields] getValueFromName:@"name"]];
		
		/* Attribute type */
		[sqlOutput appendFormat:@" %@", [[[results itemAtIndex: i] fields] getValueFromName:@"type"]];
		
		/* if serial then change typename from integer to serial */
		
		/* if serial then change typename from bigint to bigserial */
		
		/* default value */
		[sqlOutput appendFormat:@"%@", [[[results itemAtIndex: i] fields] getValueFromName:@"default"]];
		
		/* null constraint */
		[sqlOutput appendFormat:@"%@", [[[results itemAtIndex: i] fields] getValueFromName:@"notnull"]];
	}
	[sqlOutput appendString:@" );"];
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

#if PG_COCOA_DEBUG
	NSLog(sql);
#endif
	
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
	
	if (schemaName == nil)
	{
		sql = [NSString stringWithFormat:@"%s'%@'%s'%@'",
		"SELECT trigger_name FROM information_schema.triggers \
		WHERE event_object_schema =", defaultSchemaName, 
		" AND event_object_table = ", tableName];
	}
	else
	{
		sql = [NSString stringWithFormat:@"%s'%@'%s'%@'",
		"SELECT trigger_name FROM information_schema.triggers \
		WHERE event_object_schema =", schemaName, 
		" AND event_object_table = ", tableName];
	}
	
#if PG_COCOA_DEBUG
	NSLog(sql);
#endif
	
	return [connection execQuery:sql];
}


-(RecordSet *)getViewColumnInfoFromSchema:(NSString *)schemaName viewName:(NSString *) viewName;
{
	NSString *sql;

	if (schemaName == nil)
	{
		sql = [NSString stringWithFormat:@"%s%@%s",
		"",
		defaultSchemaName,
		""];
	}
	else
	{
		sql = [NSString stringWithFormat:@"%s%@%s",
		"",
		schemaName,
		""];
	}
	
#if PG_COCOA_DEBUG
	NSLog(sql);
#endif
	
	return [connection execQuery:sql];
}


-(RecordSet *)getViewNamesFromSchema:(NSString *)schemaName;
{
	NSString *sql;
	
	if (schemaName == nil)
	{
		sql = [NSString stringWithFormat:@"%s'%@'%s",
		"SELECT table_name FROM information_schema.tables WHERE table_schema = ", defaultSchemaName,
		" AND table_type = 'VIEW' ORDER BY table_name ASC"];
	}
	else
	{
		sql = [NSString stringWithFormat:@"%s'%@'%s",
		"SELECT table_name FROM information_schema.tables WHERE table_schema = ", schemaName,
		" AND table_type = 'VIEW' ORDER BY table_name ASC"];
	}
	
#if PG_COCOA_DEBUG
	NSLog(sql);
#endif
	
	return [connection execQuery:sql];
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
	
	if (schemaName == nil)
	{
		//sql = [NSString stringWithFormat:@"%s'%@.%@'%s%d%s",
		//"select pg_catalog.pg_get_viewdef(", defaultSchemaName, viewName, ", '", pretty, "')"];

		sql = [NSString stringWithFormat:@"%s'%d'%s'%@'%s'%@'%s",
		"select pg_get_viewdef(C.oid, ", pretty, ") \
		from pg_class C, pg_namespace N \
		where N.nspname = ", defaultSchemaName,
		"AND C.relname = ", viewName,
			"AND N.oid = C.relnamespace AND C.relkind = 'v';"];
	}
	else
	{
		//sql = [NSString stringWithFormat:@"%s'%@.%@'%s%d%s",
		//"select pg_catalog.pg_get_viewdef(", schemaName, viewName, ", '", pretty, "')"];
		sql = [NSString stringWithFormat:@"%s'%d'%s'%@'%s'%@'%s",
		"select pg_get_viewdef(C.oid, ", pretty, ") \
		from pg_class C, pg_namespace N \
		where N.nspname = ", schemaName,
		"AND C.relname = ", viewName,
		"AND N.oid = C.relnamespace AND C.relkind = 'v';"];
	}
	
#if PG_COCOA_DEBUG
	NSLog(sql);
#endif
	
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

@end


