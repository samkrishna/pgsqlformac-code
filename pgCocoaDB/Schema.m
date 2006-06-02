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
	publicSchemaName = [[NSString alloc] initWithString: @"public"];
	pgCatalogSchemaName = [[NSString alloc] initWithString: @"pg_catalog"];
	informationSchemaName = [[NSString alloc] initWithString: @"information_schema"];
	
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


- (NSString *)publicSchemaName;
{
	return publicSchemaName;
}
- (NSString *)pgCatalogSchemaName;
{
	return pgCatalogSchemaName;
}
- (NSString *)informationSchemaName;
{
	return informationSchemaName;
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
	
	[publicSchemaName release];
	publicSchemaName = nil;
	
	[pgCatalogSchemaName release];
	pgCatalogSchemaName = nil;

	[informationSchemaName release];
	informationSchemaName = nil;

	[pgVersionFound release];
	pgVersionFound = nil;
	
	[super dealloc];
}


-(RecordSet *)getConstraintNamesFromSchema:(NSString *)schemaName fromTableName:(NSString *) tableName
{
	// TODO
	return nil;
}

-(RecordSet *)getNamesFromSchema:(NSString *)schemaName fromType:(NSString *)type;
{
	NSString * sql;
	
	sql = [NSString stringWithFormat:@"SELECT relname \
	FROM pg_catalog.pg_class c, pg_namespace n \
	WHERE n.nspname = '%@' \
	AND c.relnamespace = n.oid \
	AND c.relkind = '%@' ORDER BY c.relname", schemaName, type];
#if PGCOCOA_LOG_SQL
	NSLog(sql);
#endif
	
	return [connection execQuery:sql];
}


-(RecordSet *)getDatabaseNames;
{
	NSString * sql;
	sql = [NSMutableString stringWithString:@"SELECT datname FROM pg_catalog.pg_database ORDER BY datname"];
#if PGCOCOA_LOG_SQL
	NSLog(sql);
#endif
	
	return [connection execQuery:sql];
}


-(RecordSet *)getFunctionNamesFromSchema:(NSString *)schemaName;
{
	NSString *sql;
	
	sql = [NSString stringWithFormat:@"%@'%@'",
	@"SELECT routine_name FROM information_schema.routines WHERE routine_schema = ", schemaName];
#if PGCOCOA_LOG_SQL
	NSLog(sql);
#endif
	
	return [connection execQuery:sql];
}


-(RecordSet *)getIndexNamesFromSchema:(NSString *)schemaName fromTableName:(NSString *) tableName;
{
	NSString *sql;
	
	sql = [NSMutableString stringWithFormat:@"%s'%@'%s'%@'%s","SELECT indexname \
	FROM pg_catalog.pg_indexes WHERE schemaname = ", schemaName, " AND tablename = ", tableName, " ORDER BY indexname ASC"];
	//return [self getNamesFromSchema:schemaName fromType: @"i"];
#if PGCOCOA_LOG_SQL
	NSLog(sql);
#endif
	
	return [connection execQuery:sql];
}

-(RecordSet *)getSchemaNames;
{
	NSString * sql;
	sql = [NSMutableString stringWithString:@"SELECT schema_name FROM information_schema.schemata ORDER BY schema_name"];
#if PGCOCOA_LOG_SQL
	NSLog(sql);
#endif
	
	return [connection execQuery:sql];
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
	
#if PGCOCOA_LOG_SQL
	NSLog(sql);
#endif
	return [connection execQuery:sql];
}


-(RecordSet *)getSequenceNamesFromSchema:(NSString *)schemaName;
{
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
#if PGCOCOA_LOG_SQL
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
	
	sql = [NSString stringWithFormat:sqlFormat, tableName, schemaName, columnName];
#if PGCOCOA_LOG_SQL
	NSLog(sql);
#endif
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
#if PGCOCOA_LOG_SQL
	NSLog(sql);
#endif
	
	return [connection execQuery:sql];
}


-(RecordSet *)getTableNamesFromSchema:(NSString *)schemaName;
{
	return [self getNamesFromSchema:schemaName fromType: @"r"];
}


-(RecordSet *)getTriggerNamesFromSchema:(NSString *)schemaName fromTableName:(NSString *) tableName
{
	NSString *sql;
	
	sql = [NSString stringWithFormat:@"%s'%@'%s'%@'",
	"SELECT trigger_name FROM information_schema.triggers \
	WHERE event_object_schema =", schemaName, 
	" AND event_object_table = ", tableName];
#if PGCOCOA_LOG_SQL
	NSLog(sql);
#endif
	
	return [connection execQuery:sql];
}


-(RecordSet *)getViewNamesFromSchema:(NSString *)schemaName;
{
	return [self getNamesFromSchema:schemaName fromType: @"v"];
}

//-----------------------------------------------------------------------------------------
// generate SQL

-(NSString *)getFunctionSQLFromSchema:(NSString *)schemaName fromFunctionName: (NSString *) functionName pretty:(int)pretty
{
	NSString * sql;
	RecordSet * results;
	NSMutableString * sqlOutput = [[[NSMutableString alloc] init] autorelease];
	/*
	sql = [NSString stringWithFormat:@"%@'%@'%@'%@'",
		@"SELECT routine_definition FROM information_schema.routines WHERE routine_schema = ", schemaName, @" AND routine_name = ", functionName];
	 
	 SELECT proname, proretset, prosrc, probin, pronargs, proallargtypes, proargmodes, proargnames,
	 (SELECT typname from pg_catalog.pg_type WHERE oid = prorettype) as rettype,
	 provolatile, proisstrict, prosecdef,
	 (SELECT lanname FROM pg_catalog.pg_language WHERE oid = prolang) as lanname 
	 FROM pg_catalog.pg_proc
	 */
	
	sql = [NSString stringWithFormat:@"SELECT p.proname, p.proretset, p.prosrc, p.probin, p.pronargs, p.proallargtypes, p.proargmodes, p.proargnames, \
	p.provolatile, p.proisstrict, p.prosecdef, (SELECT lanname FROM pg_catalog.pg_language l WHERE l.oid = p.prolang) as lanname, \
	(SELECT typname from pg_catalog.pg_type WHERE oid = p.prorettype) as rettype \
	FROM pg_catalog.pg_proc p, pg_catalog.pg_namespace n \
	WHERE n.oid = p.pronamespace AND p.proname = '%@' AND n.nspname = '%@'", functionName, schemaName];
#if PGCOCOA_LOG_SQL
	NSLog(sql);
#endif
	results = [connection execQuery:sql];
	
	if ([results count] != 1)
	{
		NSLog(@"getFunctionSQLFromSchema: Returned too many functions.");
		return nil;
	}

	// check for binary or source
	if ([[[[results itemAtIndex: 0] fields] getValueFromName: @"probin"] compare:@"-"] != NSOrderedSame)
	{
		NSLog(@"getFunctionSQLFromSchema: Can not handle binary functions.");
		return nil;
	}
		
	if ([[[[results itemAtIndex: 0] fields] getValueFromName: @"prosrc"] compare:@"-"] == NSOrderedSame)
	{
		NSLog(@"getFunctionSQLFromSchema: No source to return.");
		return nil;
	}
	//TODO implement pretty
	
	[sqlOutput appendFormat:@"CREATE or REPLACE FUNCTION %@.%@ ", schemaName, functionName];
	//TODO get return values and parameters

	[sqlOutput appendString:@" AS $$ "];
	[sqlOutput appendString:[[[results itemAtIndex: 0] fields] getValueFromName:@"prosrc"];
	[sqlOutput appendString:@"$$ "];
	//TODO language & ;
		
	return sqlOutput;
}


-(NSString *)getIndexSQLFromSchema:(NSString *)schemaName fromTableName:(NSString *) tableName fromIndexName:(NSString *) indexName;
{
	NSString * sql;
	RecordSet * results;
	
	sql = [NSString stringWithFormat:@"SELECT indexdef FROM pg_catalog.pg_indexes \
	WHERE schemaname = '%@' AND tablename = '%@' AND indexname = '%@'", schemaName, tableName, indexName];
#if PGCOCOA_LOG_SQL
	NSLog(sql);
#endif
	
	results = [connection execQuery:sql];
	if ([results count] == 1)
	{
		return [[[[results itemAtIndex: 0] fields] itemAtIndex:0] value];
	}	
	return nil;
}


-(NSString *)getRuleSQLFromSchema:(NSString *)schemaName fromRuleName:(NSString *)ruleName pretty:(int)pretty
{
	NSString * sql;
	RecordSet * results;
	
	// TODO handle schema
	sql = [NSString stringWithFormat:@"%s%@%s",
		"SELECT pg_catalog.pg_get_ruledef(t.oid) \
	FROM pg_catalog.pg_rewrite rw \
	WHERE rw.rulename = ", ruleName];
#if PGCOCOA_LOG_SQL
	NSLog(sql);
#endif
	
	results = [connection execQuery:sql];
	if ([results count] == 1)
	{
		return [[[[results itemAtIndex: 0] fields] itemAtIndex:0] value];
	}
	return nil;
}


-(NSString *)getTableSQLFromSchema:(NSString *)schemaName fromTableName:(NSString *) tableName pretty:(int)pretty
{
	RecordSet *results;
	int i;
	NSMutableString * sqlOutput = [[NSMutableString alloc] init];
	[sqlOutput appendFormat:@"CREATE TABLE %@.%@ ( ", schemaName, tableName];
	if (pretty)
	{
		[sqlOutput appendString:@"\n"];
	}
	/* returns name, type, notnull, default */
	results = [self getTableColumnsInfoFromSchema:schemaName fromTableName:tableName];
	//NSLog(@"get table sql return count: %d", [results count]);
	//NSLog(@"Column results:%@", [results description]);
	//NSLog(@"Connection currentDatabase: %@", [connection currentDatabase]);
	//NSLog(@"Connection dbName: %@", [connection dbName]);
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
		if (pretty)
		{
			[sqlOutput appendString:@"    "];
		}
		/* Attribute name */
		[sqlOutput appendFormat:@"%@", [[[results itemAtIndex: i] fields] getValueFromName:@"name"]];
		/* Attribute type */
		[sqlOutput appendFormat:@" %@", [[[results itemAtIndex: i] fields] getValueFromName:@"type"]];
		
		/* default value */
		/* TODO handle serial */
		/* if serial then change typename from integer to serial */
		/* if serial then change typename from bigint to bigserial */
		if ([[[[results itemAtIndex: i] fields] getValueFromName:@"default"] compare:@""] != NSOrderedSame)
		{
			[sqlOutput appendFormat:@" %@", [[[results itemAtIndex: i] fields] getValueFromName:@"default"]];
		}
		/* TODO check for foreign key  or primary key values */
		/* null constraint */
		if ([[[[results itemAtIndex: i] fields] getValueFromName:@"notnull"] compare:@""] != NSOrderedSame)
		{
			[sqlOutput appendFormat:@" %@", [[[results itemAtIndex: i] fields] getValueFromName:@"notnull"]];
		}
		
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
#if PGCOCOA_LOG_SQL
	NSLog(sql);
#endif
	
	results = [connection execQuery:sql];
	if ([results count] == 1)
	{
		return [[[[results itemAtIndex: 0] fields] itemAtIndex:0] value];
	}
	return nil;
}


-(NSString *)getViewSQLFromSchema:(NSString *)schemaName fromView:(NSString *)viewName pretty:(int)pretty;
{
	NSString *sql;
	RecordSet * results;
	
	sql = [NSString stringWithFormat:@"%s'%d'%s'%@'%s'%@'%s",
	"SELECT pg_get_viewdef(C.oid, ", pretty, ") \
	FROM pg_class C, pg_namespace N \
	WHERE N.nspname = ", schemaName,
	"AND C.relname = ", viewName,
	"AND N.oid = C.relnamespace AND C.relkind = 'v';"];
#if PGCOCOA_LOG_SQL
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

//-----------------------------------------------------------------------------------------
// Process Comments
// TODO Remaining comments functions to implment
/*
	domain pg_type
	operator pg_operator
	type pg_type
 
	if ([objectType compare:@"aggregate"] == NSOrderedSame)
	{
		oidLookupTable = @"pg_aggregate";
	}
	else if ([objectType compare:@"rule"] == NSOrderedSame)
	{
		oidLookupTable = @"pg_rewrite";
	}
*/


-(NSString *)getColumnCommentFromSchema:(NSString *)schemaName fromTableName:(NSString *)tableName fromColumnName:(NSString *) columnName;
{
	NSString *sql;
	RecordSet *results;
	
	sql = [NSString stringWithFormat:@"SELECT col_description(c.oid, a.attnum) \
	FROM pg_catalog.pg_class c, pg_catalog.pg_namespace n, pg_catalog.pg_attribute a\
	where c.relkind = 'r' AND c.relname = '%@' AND c.relnamespace = n.oid AND n.nspname = '%@' \
	AND a.attrelid = c.oid AND a.attname = '%@'", tableName, schemaName, columnName];
#if PGCOCOA_LOG_SQL
	NSLog(sql);
#endif
	results = [connection execQuery:sql];
	if ([results count] == 1)
	{
		return [[[[results itemAtIndex: 0] fields] itemAtIndex:0] value];
	}
	return nil;
}


-(NSString *)getConstraintCommentFromSchema:(NSString *)schemaName fromConstraintName:(NSString *)constraintName;
{
	NSString *sql;
	RecordSet *results;
	
	sql = [NSString stringWithFormat:@"SELECT obj_description(c.oid,'pg_constraint') \
	FROM pg_catalog.pg_namespace n, pg_catalog.pg_constraint c \
	WHERE n.nspname = '%@' AND n.oid = c.connamespace AND c.conname = '%@'", schemaName, constraintName];
#if PGCOCOA_LOG_SQL
	NSLog(sql);
#endif
	results = [connection execQuery:sql];
	if ([results count] == 1)
	{
		return [[[[results itemAtIndex: 0] fields] itemAtIndex:0] value];
	}
	return nil;
}


-(NSString *)getDatabaseComment:(NSString *)databaseName;
{
	NSString *sql;
	RecordSet *results;
	
	sql = [NSString stringWithFormat:@"SELECT obj_description(d.oid,'pg_database') FROM pg_catalog.pg_database d \
	WHERE d.datname = '%@'", databaseName];
#if PGCOCOA_LOG_SQL
	NSLog(sql);
#endif
	results = [connection execQuery:sql];
	if ([results count] == 1)
	{
		return [[[[results itemAtIndex: 0] fields] itemAtIndex:0] value];
	}
	return nil;
}


-(NSString *)getFunctionCommentFromSchema:(NSString *)schemaName fromFunctionName:(NSString *)functionName;
{
	NSString *sql;
	RecordSet *results;
	
	/* FIXME currently does not work for overloaded functions, need to check function arguments */
	sql = [NSString stringWithFormat:@"SELECT obj_description(p.oid,'pg_proc') \
	FROM pg_catalog.pg_namespace n, pg_catalog.pg_proc p \
	WHERE n.nspname = '%@' AND n.oid = p.pronamespace AND p.proname = '%@'", schemaName, functionName];
#if PGCOCOA_LOG_SQL
	NSLog(sql);
#endif
	results = [connection execQuery:sql];
	if ([results count] == 1)
	{
		return [[[[results itemAtIndex: 0] fields] itemAtIndex:0] value];
	}
	return nil;
}


-(NSString *)getIndexCommentFromSchema:(NSString *)schemaName fromIndexName:(NSString *)indexName;
{
	NSString *sql;
	RecordSet *results;
	
	sql = [NSString stringWithFormat:@"SELECT obj_description(c.oid,'pg_class') FROM pg_catalog.pg_class c, pg_catalog.pg_namespace n\
	WHERE c.relkind = 'i' AND c.relname = '%@' AND c.relnamespace = n.oid AND n.nspname = '%@'", indexName, schemaName];
#if PGCOCOA_LOG_SQL
	NSLog(sql);
#endif
	results = [connection execQuery:sql];
	if ([results count] == 1)
	{
		return [[[[results itemAtIndex: 0] fields] itemAtIndex:0] value];
	}
	return nil;
}


-(NSString *)getSchemaComment:(NSString *)schemaName;
{
	NSString *sql;
	RecordSet *results;
	
	sql = [NSString stringWithFormat:@"SELECT obj_description(n.oid,'pg_namespace') FROM pg_catalog.pg_namespace n \
	WHERE n.nspname = '%@'", schemaName];
#if PGCOCOA_LOG_SQL
	NSLog(sql);
#endif
	results = [connection execQuery:sql];
	if ([results count] == 1)
	{
		return [[[[results itemAtIndex: 0] fields] itemAtIndex:0] value];
	}
	return nil;
}


-(NSString *)getSequenceCommentFromSchema:(NSString *)schemaName fromSequenceName:(NSString *)sequenceName;
{
	NSString *sql;
	RecordSet *results;
	
	sql = [NSString stringWithFormat:@"SELECT obj_description(c.oid,'pg_class') FROM pg_catalog.pg_class c, pg_catalog.pg_namespace n\
	WHERE c.relkind = 'S' AND c.relname = '%@' AND c.relnamespace = n.oid AND n.nspname = '%@'", sequenceName, schemaName];
#if PGCOCOA_LOG_SQL
	NSLog(sql);
#endif
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
	
	sql = [NSString stringWithFormat:@"SELECT obj_description(c.oid,'pg_class') FROM pg_catalog.pg_class c, pg_catalog.pg_namespace n\
	WHERE c.relkind = 'r' AND c.relname = '%@' AND c.relnamespace = n.oid AND n.nspname = '%@'", tableName, schemaName];
#if PGCOCOA_LOG_SQL
	NSLog(sql);
#endif
	results = [connection execQuery:sql];
	if ([results count] == 1)
	{
		return [[[[results itemAtIndex: 0] fields] itemAtIndex:0] value];
	}
	return nil;
}


-(NSString *)getTriggerCommentFromSchema:(NSString *)schemaName fromTableName:(NSString *)tableName fromTriggerName:(NSString *)triggerName;
{
	NSString *sql;
	RecordSet *results;
	
	sql = [NSString stringWithFormat:@"SELECT obj_description(t.oid,'pg_trigger') \
	FROM pg_catalog.pg_trigger t, pg_catalog.pg_class c, pg_catalog.pg_namespace n\
	WHERE tgname = '%@' AND tgrelid = c.oid AND c.relname = '%@' AND c.relnamespace = n.oid \
	AND n.nspname = '%@'", triggerName, tableName, schemaName];
#if PGCOCOA_LOG_SQL
	NSLog(sql);
#endif
	results = [connection execQuery:sql];
	if ([results count] == 1)
	{
		return [[[[results itemAtIndex: 0] fields] itemAtIndex:0] value];
	}
	return nil;
}


-(NSString *)getViewCommentFromSchema:(NSString *)schemaName fromViewName:(NSString *)viewName;
{
	NSString *sql;
	RecordSet *results;
	
	sql = [NSString stringWithFormat:@"SELECT obj_description(c.oid,'pg_class') FROM pg_catalog.pg_class c, pg_catalog.pg_namespace n\
	WHERE c.relkind = 'v' AND c.relname = '%@' AND c.relnamespace = n.oid AND n.nspname = '%@'", viewName, schemaName];
#if PGCOCOA_LOG_SQL
	NSLog(sql);
#endif
	results = [connection execQuery:sql];
	if ([results count] == 1)
	{
		return [[[[results itemAtIndex: 0] fields] itemAtIndex:0] value];
	}
	return nil;
}

-(RecordSet *)getLocks;
{
	NSString *sql;
	
	sql = [NSString stringWithString:@"SELECT dbu.usename as locker, l.mode as locktype,\
	pg_stat_get_backend_pid(S.backendid) as pid,\
	db.datname||'.'||n.nspname||'.'||r.relname as relation, l.mode,\
	substring(pg_stat_get_backend_activity(S.backendid ), 0, 30) as query\
	FROM pg_user dbu,\
	(SELECT pg_stat_get_backend_idset() AS backendid) AS S,\
	pg_database db, pg_locks l, pg_class r, pg_namespace n\
	WHERE db.oid = pg_stat_get_backend_dbid(S.backendid)\
	AND dbu.usesysid = pg_stat_get_backend_userid(S.backendid)\
	AND l.pid = pg_stat_get_backend_pid(S.backendid)\
	AND l.relation = r.oid\
	AND l.database = db.oid\
	AND r.relnamespace = n.oid\
	AND l.granted\
	ORDER BY db.datname, n.nspname, r.relname, l.mode"];
	
#if PGCOCOA_LOG_SQL
	NSLog(sql);
#endif

	return [connection execQuery:sql];
}



@end

