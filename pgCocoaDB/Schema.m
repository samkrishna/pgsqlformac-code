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

bool parsePGArray(const char *atext, char ***itemarray, int *nitems);

@implementation Schema

- initWithConnection:(Connection *) theConnection
{
	NSString *sql;
	RecordSet * results;
	Field * versionField;
	
	[super init];
	[connection release];
	connection = theConnection;
	[connection retain];
	publicSchemaName = [[NSString alloc] initWithString: @"public"];
	pgCatalogSchemaName = [[NSString alloc] initWithString: @"pg_catalog"];
	informationSchemaName = [[NSString alloc] initWithString: @"information_schema"];
	
	sql = [NSString stringWithFormat:@"%s", "Select version()"];
	results = [connection execQueryNoLog:sql];
	versionField = [[[results itemAtIndex:0] fields] itemAtIndex:0];
	pgVersionFound = [[NSString alloc] initWithString: [versionField value]];

	// TODO add user default to bypass versions check
	//PostgreSQL 8.1.2 on powerpc-apple-darwin8.5.0, compiled by GCC powerpc-apple-darwin8-gcc-4.0.1 (GCC) 4.0.1 (Apple Computer, Inc. build 5250)
	if ([pgVersionFound rangeOfString:@"PostgreSQL 8.1"].location == NSNotFound)
	{
		// TODO not found raise error?

		NSLog(@"Did not find PostgreSQL version 8.1: %@", pgVersionFound);
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

/*
select n.nspname, c.conname, t.relname, c.contype
from pg_constraint c, pg_namespace n, pg_class t
where c.connamespace = n.oid
AND t.oid = c.conrelid;
*/
-(RecordSet *)getConstraintNamesFromSchema:(NSString *)schemaName fromTableName:(NSString *) tableName
{
	NSString * sql;

	sql = [NSString stringWithFormat:@"SELECT c.conname \
	FROM pg_constraint c, pg_namespace n, pg_class t \
	WHERE n.nspname = '%@' AND t.relname = '%@' AND n.oid = c.connamespace AND t.oid = c.conrelid;", schemaName, tableName ];

#if PGCOCOA_LOG_SQL
	NSLog(sql);
#endif

	return [connection execQueryLogInfoLogSQL:sql];;
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
	
	return [connection execQueryNoLog:sql];
}


-(RecordSet *)getDatabaseNames;
{
	NSString * sql;
	sql = [NSMutableString stringWithString:@"SELECT datname FROM pg_catalog.pg_database ORDER BY datname"];
#if PGCOCOA_LOG_SQL
	NSLog(sql);
#endif
	
	return [connection execQueryNoLog:sql];
}


-(RecordSet *)getFunctionNamesFromSchema:(NSString *)schemaName;
{
	NSString *sql;
	
	sql = [NSString stringWithFormat:@"%@'%@'",
	@"SELECT routine_name FROM information_schema.routines WHERE routine_schema = ", schemaName];
#if PGCOCOA_LOG_SQL
	NSLog(sql);
#endif
	
	return [connection execQueryNoLog:sql];
}

-(int)getIndexCountFromSchema:(NSString *)schemaName fromTableName:(NSString *) tableName;
{
	NSString *sql;
	
	sql = [NSString stringWithFormat:@"SELECT count(*) FROM pg_catalog.pg_indexes WHERE schemaname = '%@' AND tablename = '%@'", schemaName, tableName];
#if PGCOCOA_LOG_SQL
	NSLog(sql);
#endif
	RecordSet * results = [connection execQueryNoLog:sql];
	
	return [[[[[results itemAtIndex: 0] fields] itemAtIndex:0] value] intValue];
}

-(RecordSet *)getIndexNamesFromSchema:(NSString *)schemaName fromTableName:(NSString *) tableName;
{
	NSString *sql;
	
	sql = [NSString stringWithFormat:@"%s'%@'%s'%@'%s","SELECT indexname \
	FROM pg_catalog.pg_indexes WHERE schemaname = ", schemaName, " AND tablename = ", tableName, " ORDER BY indexname ASC"];
	//return [self getNamesFromSchema:schemaName fromType: @"i"];
#if PGCOCOA_LOG_SQL
	NSLog(sql);
#endif
	
	return [connection execQueryNoLog:sql];
}

-(RecordSet *)getSchemaNames;
{
	NSString * sql;
	sql = [NSString stringWithString:@"SELECT schema_name FROM information_schema.schemata ORDER BY schema_name"];
#if PGCOCOA_LOG_SQL
	NSLog(sql);
#endif
	
	return [connection execQueryNoLog:sql];
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
	return [connection execQueryNoLog:sql];
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
	return [connection execQueryNoLog:sql];
}


/* returns type, notnull, default */
-(RecordSet *)getTableColumnInfoFromSchema:(NSString *)schemaName fromTableName:(NSString *)tableName fromColumnName:(NSString *)columnName;
{
	NSString *sql;
	NSString *sqlFormat;
	
	sqlFormat = @"SELECT format_type(a.atttypid, a.atttypmod) AS \"type\", \
	CASE \
		WHEN a.attnotnull = TRUE THEN ' NOT NULL '  \
		ELSE ' '  \
	END as \"notnull\", \
	CASE \
		WHEN a.atthasdef = TRUE  THEN 'DEFAULT '  || cast(pg_catalog.pg_get_expr(d.adbin, attrelid) AS varchar(200)) \
		ELSE ' ' \
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
	return [connection execQueryNoLog:sql];
}

//select indexname from pg_indexes where schemaname = 'public' AND tablename = 'file_monitor_names';
//SELECT attname FROM pg_catalog.pg_attribute, pg_catalog.pg_class
//where pg_attribute.attrelid = pg_class.oid
//AND relname LIKE 'file_monitor_names_file_set_name_key';

-(RecordSet *)getIndexColumnNamesFromSchema:(NSString *)schemaName fromTableName:(NSString *)tableName fromIndexName:(NSString *)indexName
{
	NSString *sql;
	sql = [NSString stringWithFormat:@"SELECT attname \
	FROM pg_index x \
	JOIN pg_class c ON c.oid = x.indrelid \
	JOIN pg_class i ON i.oid = x.indexrelid \
	JOIN pg_attribute a ON a. attrelid = i.oid \
	JOIN pg_namespace n ON n.oid = c.relnamespace \
	WHERE c.relkind = 'r'::\"char\" AND i.relkind = 'i'::\"char\" \
	AND c.relname = '%@' \
	AND n.nspname = '%@' \
	AND i.relname = '%@'", tableName, schemaName, indexName];
#if PGCOCOA_LOG_SQL
	NSLog(sql);
#endif
		
	return [connection execQueryNoLog:sql];
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
	
	return [connection execQueryNoLog:sql];
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
	
	return [connection execQueryNoLog:sql];
}


-(RecordSet *)getViewNamesFromSchema:(NSString *)schemaName;
{
	return [self getNamesFromSchema:schemaName fromType: @"v"];
}

//-----------------------------------------------------------------------------------------
// generate SQL

/*
select pg_get_constraintdef(c.oid, false)
from pg_constraint c, pg_namespace n, pg_class t
where c.connamespace = n.oid
AND t.oid = c.conrelid;
*/
-(NSString *)getConstraintSQLFromSchema:(NSString *)schemaName fromTable:(NSString *)tableName fromConstraint:(NSString *)constraintName pretty:(int)pretty;
{
	NSString *sql;
	RecordSet * results;
	
	// TODO pretty print?
	sql = [NSString stringWithFormat:@"SELECT pg_get_constraintdef(c.oid, false) \
	FROM pg_constraint c, pg_namespace n, pg_class t \
	WHERE n.nspname = '%@' AND t.relname = '%@' AND c.conname = '%@' AND n.oid = c.connamespace AND t.oid = c.conrelid;", schemaName, tableName, constraintName ];

#if PGCOCOA_LOG_SQL
	NSLog(sql);
#endif
	
	results = [connection execQueryNoLog:sql];
	if ([results count] == 1)
	{
		sql = [[NSString alloc] initWithFormat:@"%@\n", [[[[results itemAtIndex: 0] fields] itemAtIndex:0] value]];
		[sql autorelease];
		return sql;
	}
	return nil;
}


-(NSString *)getFunctionSQLFromSchema:(NSString *)schemaName fromFunctionName: (NSString *) functionName pretty:(int)pretty
{
	NSString * sql;
	int numberOfArgs;
	RecordSet * results;
	RecordSet * results1;
	char **allargtypes = NULL;
	char **argmodes = NULL;
	char **argnames = NULL;
	int argtypes_nitems = 0;
	int argmodes_nitems = 0;
	int argnames_nitems = 0;
	char buffer[1024];
	
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
	results = [connection execQueryNoLog:sql];
	
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
	NSLog(@"args: %@", [[[results itemAtIndex: 0] fields] getValueFromName: @"proallargtypes"]);
	NSLog(@"args: %@", [[[results itemAtIndex: 0] fields] getValueFromName: @"proargmodes"]);
	NSLog(@"args: %@", [[[results itemAtIndex: 0] fields] getValueFromName: @"proargnames"]);
	/*
	 2006-06-17 16:41:42.405 Query Tool for Postgres[28356] args: {23,23,23,23}
	 2006-06-17 16:41:42.405 Query Tool for Postgres[28356] args: {i,i,o,o}
	 2006-06-17 16:41:42.405 Query Tool for Postgres[28356] args: {x,y,sum,prod}
	 2006-06-17 16:41:42.406 Query Tool for Postgres[28356] args: 2
	*/
	numberOfArgs = [[[[results itemAtIndex: 0] fields] getValueFromName: @"pronargs"] intValue];
	
	[[[[results itemAtIndex: 0] fields] getValueFromName: @"proallargtypes"] getCString:buffer maxLength:1024 encoding:NSASCIIStringEncoding];
	if (!parsePGArray( buffer, &allargtypes, &argtypes_nitems))
	{
		if (allargtypes)
			free(allargtypes);
		allargtypes = NULL;
	}
	
	[[[[results itemAtIndex: 0] fields] getValueFromName: @"proargmodes"] getCString:buffer maxLength:1024 encoding:NSASCIIStringEncoding];
	if (!parsePGArray( buffer, &argmodes, &argmodes_nitems))
	{
		if (argmodes)
			free(argmodes);
		argmodes = NULL;
	}
	
	[[[[results itemAtIndex: 0] fields] getValueFromName: @"proargnames"] getCString:buffer maxLength:1024 encoding:NSASCIIStringEncoding];
	if (!parsePGArray( buffer, &argnames, &argnames_nitems))
	{
		if (argnames)
			free(argnames);
		argnames = NULL;
	}

	if (argnames_nitems != 0)
	{
		int i;
		[sqlOutput appendString:@"("];
		for (i = 0; i< argnames_nitems; i++)
		{	
			char * argmode;
			if (argmodes)
			{
				switch (argmodes[i][0])
				{
					case 'i':
						argmode = "IN";
						break;
					case 'o':
						argmode = "OUT ";
						break;
					case 'b':
						argmode = "INOUT ";
						break;
					default:
						NSLog(@"WARNING: bogus value in proargmodes array");
						argmode = "";
						break;
				}
			}
				else
					argmode = "";
			
			if (i != 0)
			{
				[sqlOutput appendString:@", "];
			}
			sql = [NSString stringWithFormat:@"SELECT pg_catalog.format_type('%s'::pg_catalog.oid, NULL)", allargtypes[i]];
			results1 = [connection execQueryNoLog:sql];
			if ([results1 count] != 1)
			{
				NSLog(@"getFunctionSQLFromSchema: Returned too many functions for type conversion.");
				return nil;
			}
			[sqlOutput appendFormat:@"%s %s %@", argmode, argnames[i], [[[[results1 itemAtIndex: 0] fields] itemAtIndex:0] value]];
		}
		[sqlOutput appendString:@") "];
	}
	[sqlOutput appendString:@" AS $$\n"];
	[sqlOutput appendString:[[[results itemAtIndex: 0] fields] getValueFromName:@"prosrc"]];
	[sqlOutput appendString:@"$$"];
	[sqlOutput appendFormat:@" LANGUAGE %@;", [[[results itemAtIndex: 0] fields] getValueFromName:@"lanname"]];
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
	
	results = [connection execQueryNoLog:sql];
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
	
	results = [connection execQueryNoLog:sql];
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
	NSMutableString * sqlOutput = [[[NSMutableString alloc] init] autorelease];
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
	return sqlOutput;
}

/*
 select pg_get_triggerdef(tr.oid)
 from pg_trigger tr, pg_namespace n, pg_class ta
 where ta.relnamespace = n.oid
 AND ta.oid = tr.tgrelid;
 */

-(NSString *)getTriggerSQLFromSchema:(NSString *)schemaName fromTableName:(NSString*)tableName fromTriggerName:(NSString *)triggerName
{
	NSString * sql;
	RecordSet * results;
	
	// TODO handle schema
	sql = [NSString stringWithFormat:@"SELECT pg_get_triggerdef(tr.oid) \
	FROM pg_trigger tr, pg_namespace n, pg_class ta \
	WHERE n.nspname = '%@' AND ta.relname = '%@' AND tr.tgname = '%@' AND n.oid = ta.relnamespace AND ta.oid = tr.tgrelid;", schemaName, tableName, triggerName ];
#if PGCOCOA_LOG_SQL
	NSLog(sql);
#endif
	
	results = [connection execQueryNoLog:sql];
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
	
	results = [connection execQueryNoLog:sql];
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
	results = [connection execQueryNoLog:sql];
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
	results = [connection execQueryNoLog:sql];
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
	results = [connection execQueryNoLog:sql];
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
	results = [connection execQueryNoLog:sql];
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
	results = [connection execQueryNoLog:sql];
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
	results = [connection execQueryNoLog:sql];
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
	results = [connection execQueryNoLog:sql];
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
	results = [connection execQueryNoLog:sql];
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
	results = [connection execQueryNoLog:sql];
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
	results = [connection execQueryNoLog:sql];
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

	return [connection execQueryNoLog:sql];
}

/*
 * The following code is from
 *  http://developer.postgresql.org/cvsweb.cgi/pgsql/src/bin/pg_dump/dumputils.c?rev=1.30;content-type=text%2Fx-cvsweb-markup
 */

/*-------------------------------------------------------------------------
*
* Utility routines for SQL dumping
*	Basically this is stuff that is useful in both pg_dump and pg_dumpall.
*
*
* Portions Copyright (c) 1996-2006, PostgreSQL Global Development Group
* Portions Copyright (c) 1994, Regents of the University of California
*
* $PostgreSQL: pgsql/src/bin/pg_dump/dumputils.c,v 1.30 2006/06/01 00:15:36 tgl Exp $
*
*-------------------------------------------------------------------------
*/

/*
 * Deconstruct the text representation of a 1-dimensional Postgres array
 * into individual items.
 *
 * On success, returns true and sets *itemarray and *nitems to describe
 * an array of individual strings.	On parse failure, returns false;
 * *itemarray may exist or be NULL.
 *
 * NOTE: free'ing itemarray is sufficient to deallocate the working storage.
 */
bool
parsePGArray(const char *atext, char ***itemarray, int *nitems)
{
	int			inputlen;
	char	  **items;
	char	   *strings;
	int			curitem;
	
	/*
	 * We expect input in the form of "{item,item,item}" where any item is
	 * either raw data, or surrounded by double quotes (in which case embedded
														* characters including backslashes and quotes are backslashed).
	 *
	 * We build the result as an array of pointers followed by the actual
	 * string data, all in one malloc block for convenience of deallocation.
	 * The worst-case storage need is not more than one pointer and one
	 * character for each input character (consider "{,,,,,,,,,,}").
	 */
	*itemarray = NULL;
	*nitems = 0;
	inputlen = strlen(atext);
	if (inputlen < 2 || atext[0] != '{' || atext[inputlen - 1] != '}')
		return false;			/* bad input */
	items = (char **) malloc(inputlen * (sizeof(char *) + sizeof(char)));
	if (items == NULL)
		return false;			/* out of memory */
	*itemarray = items;
	strings = (char *) (items + inputlen);
	
	atext++;					/* advance over initial '{' */
	curitem = 0;
	while (*atext != '}')
	{
		if (*atext == '\0')
			return false;		/* premature end of string */
		items[curitem] = strings;
		while (*atext != '}' && *atext != ',')
		{
			if (*atext == '\0')
				return false;	/* premature end of string */
			if (*atext != '"')
				*strings++ = *atext++;	/* copy unquoted data */
			else
			{
				/* process quoted substring */
				atext++;
				while (*atext != '"')
				{
					if (*atext == '\0')
						return false;	/* premature end of string */
					if (*atext == '\\')
					{
						atext++;
						if (*atext == '\0')
							return false;		/* premature end of string */
					}
					*strings++ = *atext++;		/* copy quoted data */
				}
				atext++;
			}
		}
		*strings++ = '\0';
		if (*atext == ',')
			atext++;
		curitem++;
	}
	if (atext[1] != '\0')
		return false;			/* bogus syntax (embedded '}') */
	*nitems = curitem;
	return true;
}


@end

