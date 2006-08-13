//
//  pgCocoaDBSchemaTest.m
//  pgCocoaDB
//
//  Created by Neil Tiffin on 3/4/06.
//  Copyright 2006 Performance Champions, Inc. All rights reserved.
//
//

#import "pgCocoaDBSchemaTest.h"
#import "Record.h"
#import "ExplorerModel.h"

//------------------------------------------------------------------
// Test configuration parameters, Please modify as necessary for
// your environment.

NSString* const PGCocoaTestDatabase = @"pgcocoa_test_database";
NSString* const PGCocoaTestSchema = @"pgcocoa_test_schema";
NSString* const PGCocoaTestUser = @"ntiffin";
NSString* const PGCocoaTestPassword = @"";
NSString* const PGCocoaTestHost = @"localhost";
NSString* const PGCocoaTestPort = @"5432";

// Uncomment the following line to automatically drop and recreate the test database.
//#define DROP_EXISTING_DATABASE 1
// Otherwise you will need to drop the database manually before each test run

// End of configuration parameters
//------------------------------------------------------------------

@implementation pgCocoaDBSchemaTest

static BOOL databaseCreated = NO;

- (void)createDatabase
{
	RecordSet * results;
	NSString* sql;
	
	if (databaseCreated)
	{
		return;
	}

	NSLog(@"Initialize PostgreSQL database.");
	[self raiseAfterFailure];
	
	[conn release];	// does not harm
	conn = [[Connection alloc] init];
		
	// set the connection parameters					
	[conn setUserName:PGCocoaTestUser];
	[conn setPassword:PGCocoaTestPassword];
	[conn setDbName:@"template1"];	
	[conn setHost:PGCocoaTestHost];
	[conn setPort:PGCocoaTestPort];
	
	// perform the connection
	[conn connect];
	STAssertTrue([conn errorDescription] == nil, @"Error connecting to database %@: %@.", [conn dbName], [conn errorDescription]);
	STAssertTrue([conn isConnected], @"Failed to connect to database %@.", [conn dbName]);

	
	// check if test test database exists, error out if it does.
	
	sql = [NSString stringWithFormat:@"%s'%@'", "SELECT datname FROM pg_catalog.pg_database WHERE datname =", PGCocoaTestDatabase];
	results = [conn execQuery:sql];
	STAssertTrue([conn errorDescription] == nil, @"Not able to '%@', %@.", sql, [conn errorDescription]);

	sql = [NSString stringWithFormat:@"CREATE DATABASE %@ WITH ENCODING = 'UTF8' TABLESPACE = pg_default;", PGCocoaTestDatabase];
	if (0 == [results count])
	{
		// test database does not exist
		NSLog(sql);
		[conn execQuery:sql];
		STAssertTrue([conn errorDescription] == nil, @"Not able to '%@', %@.", sql, [conn errorDescription]);
	}
	else
	{
#if DROP_EXISTING_DATABASE
		// if you are not concerned about automatically dropping the test database you can
		// add -DDROP_EXISTING_DATABASE=1 to the OTHER_CFLAGS in project builder
		// or you can uncomment the #define in the configuration area of this file.
		NSString *sql1 = [NSString stringWithFormat:@"%s%@", "DROP DATABASE ", PGCocoaTestDatabase];
		NSLog(sql1);
		[conn execQuery:sql1];
		STAssertTrue([conn errorDescription] == nil, @"Not able to '%@', %@.", sql, [conn errorDescription]);

		NSLog(sql);
		[conn execQuery:sql];
		STAssertTrue([conn errorDescription] == nil, @"Not able to '%@', %@.", sql, [conn errorDescription]);
#else
		STFail(@"Test database exists.");
#endif
	}
	
	[conn disconnect];
	[conn setDbName:PGCocoaTestDatabase];	
	[conn connect];
	STAssertTrue([conn errorDescription] == nil, @"Error connecting to database %@: %@.", [conn dbName], [conn errorDescription]);
	STAssertTrue([conn isConnected], @"Failed to connect to database %@.", [conn dbName]);

	// create test tables, columns, indexes, etc
	sql = [NSString stringWithFormat:@"%s%@ %s", "CREATE SCHEMA ", PGCocoaTestSchema,
	"CREATE TABLE name (\
					   name_id serial PRIMARY KEY,	\
					   weight float DEFAULT 125.3,	\
					   height numeric(10, 3),		\
					   age int DEFAULT 30,			\
					   first varchar(35) NOT NULL,	\
					   last varchar(35) NOT NULL,	\
					   create_time timestamp,	\
					   update_time timestamp)	\
	\
	CREATE TABLE address (\
						  address_id serial PRIMARY KEY,		\
						  name_id integer REFERENCES name (name_id),	\
						  city varchar(20) DEFAULT 'Kansas City',		\
						  state varchar(2)	DEFAULT 'MO',		\
						  zip integer NOT NULL	DEFAULT 64057,	\
						  notes text,				\
						  address varchar(35),		\
						  create_time timestamp,	\
						  update_time timestamp)	\
	\
	CREATE OR REPLACE VIEW address_book AS \
		SELECT	n.first, n.last, a.address	\
		FROM name n, address a				\
		WHERE n.name_id = a.name_id			\
		ORDER by n.last, n.first"];

	[conn execQuery:sql];
	STAssertTrue([conn errorDescription] == nil, @"Error executing SQL: %@. %@", sql, [conn errorDescription]);

	// TODO check if function exists
	sql = [NSString stringWithFormat:@"%s%@.%@.%s", "CREATE or REPLACE FUNCTION ", PGCocoaTestDatabase, PGCocoaTestSchema, "create_time_stamp() RETURNS trigger AS $time_stamp$ \
	BEGIN \
		NEW.create_time := current_timestamp; \
		RETURN NEW; \
	END; \
	$time_stamp$ LANGUAGE plpgsql; "];
	[conn execQuery:sql];
	STAssertTrue([conn errorDescription] == nil, @"Error executing SQL: %@. %@", sql, [conn errorDescription]);

	// TODO check if function exists
	sql = [NSString stringWithFormat:@"%s%@.%@.%s", "CREATE or REPLACE FUNCTION ", PGCocoaTestDatabase, PGCocoaTestSchema,
		"update_time_stamp() RETURNS trigger AS $time_stamp$ \
BEGIN \
	NEW.update_time := current_timestamp; \
	RETURN NEW; \
END; \
$time_stamp$ LANGUAGE plpgsql; "];
	[conn execQuery:sql];
	STAssertTrue([conn errorDescription] == nil, @"Error executing SQL: %@. %@", sql, [conn errorDescription]);
	
	// for testing query tool
	sql = [NSString stringWithFormat:@"%s%@.%@.%s", "CREATE or REPLACE FUNCTION ", PGCocoaTestDatabase, PGCocoaTestSchema,
		"sum_n_product(x int, y int, OUT sum int, OUT prod int) AS $$\nBEGIN\n sum := x + y;\n prod := x * y;\nEND; $$ LANGUAGE plpgsql; "];
	[conn execQuery:sql];
	STAssertTrue([conn errorDescription] == nil, @"Error executing SQL: %@. %@", sql, [conn errorDescription]);
	
	
	sql = [NSString stringWithFormat:@"%s%@.%@.%s%@.%@.%s", "CREATE TRIGGER create_timestamp BEFORE INSERT ON ",
		PGCocoaTestDatabase, PGCocoaTestSchema, "name \
	FOR EACH ROW EXECUTE PROCEDURE ", PGCocoaTestDatabase, PGCocoaTestSchema, "create_time_stamp()"];
	[conn execQuery:sql];
	STAssertTrue([conn errorDescription] == nil, @"Error executing SQL: %@. %@", sql, [conn errorDescription]);

	/*
	sql = [NSString stringWithFormat:@"%s%@.%@.%s%@.%@.%s", "CREATE TRIGGER create_timestamp BEFORE INSERT ON ",
		PGCocoaTestDatabase, PGCocoaTestSchema, "address \
	FOR EACH ROW EXECUTE PROCEDURE ", PGCocoaTestDatabase, PGCocoaTestSchema, "create_time_stamp()"];
	[conn execQuery:sql];
	STAssertTrue([conn errorDescription] == nil, @"Error executing SQL: %@. %@", sql, [conn errorDescription]);
	*/
	
	sql = [NSString stringWithFormat:@"%s%@.%@.%s%@.%@.%s", "CREATE TRIGGER update_timestamp BEFORE UPDATE ON ",
		PGCocoaTestDatabase, PGCocoaTestSchema, "name \
	FOR EACH ROW EXECUTE PROCEDURE ", PGCocoaTestDatabase, PGCocoaTestSchema, "update_time_stamp()"];
	[conn execQuery:sql];
	STAssertTrue([conn errorDescription] == nil, @"Error executing SQL: %@. %@", sql, [conn errorDescription]);
	
	/*
	sql = [NSString stringWithFormat:@"%s%@.%@.%s%@.%@.%s", "CREATE TRIGGER update_timestamp BEFORE UPDATE ON ",
		PGCocoaTestDatabase, PGCocoaTestSchema, "address \
	FOR EACH ROW EXECUTE PROCEDURE ", PGCocoaTestDatabase, PGCocoaTestSchema, "update_time_stamp()"];
	[conn execQuery:sql];
	STAssertTrue([conn errorDescription] == nil, @"Error executing SQL: %@. %@", sql, [conn errorDescription]);
	*/
	
	sql = [NSString stringWithFormat:@"%s%@.%@.%s", "INSERT INTO ",
		PGCocoaTestDatabase, PGCocoaTestSchema, "name (first, last) VALUES ( 'Bennie', 'Hill')"];
	[conn execQuery:sql];
	STAssertTrue([conn errorDescription] == nil, @"Error executing SQL: %@. %@", sql, [conn errorDescription]);
	sql = [NSString stringWithFormat:@"%s%@.%@.%s", "INSERT INTO ",
		PGCocoaTestDatabase, PGCocoaTestSchema, "address (name_id, address, city, state, zip) VALUES ( 1, '14 Upton Hill', 'London', 'UK', 0)"];
	[conn execQuery:sql];
	STAssertTrue([conn errorDescription] == nil, @"Error executing SQL: %@. %@", sql, [conn errorDescription]);
	
	sql = [NSString stringWithFormat:@"%s%@.%@.%s", "INSERT INTO ",
		PGCocoaTestDatabase, PGCocoaTestSchema, "name (first, last) VALUES ( 'Marty', 'Zweig')"];
	[conn execQuery:sql];
	STAssertTrue([conn errorDescription] == nil, @"Error executing SQL: %@. %@", sql, [conn errorDescription]);
	sql = [NSString stringWithFormat:@"%s%@.%@.%s", "INSERT INTO ",
		PGCocoaTestDatabase, PGCocoaTestSchema, "address (name_id, address, city, state, zip) VALUES ( 2, '100 Wall Street', 'New York', 'NY', 10045)"];
	[conn execQuery:sql];
	STAssertTrue([conn errorDescription] == nil, @"Error executing SQL: %@. %@", sql, [conn errorDescription]);
	
	sql = [NSString stringWithFormat:@"%s%@.%@.%s", "INSERT INTO ",
		PGCocoaTestDatabase, PGCocoaTestSchema, "name (first, last) VALUES ( 'Mary', 'Otherwise')"];
	[conn execQuery:sql];
	STAssertTrue([conn errorDescription] == nil, @"Error executing SQL: %@. %@", sql, [conn errorDescription]);
	sql = [NSString stringWithFormat:@"%s%@.%@.%s", "INSERT INTO ",
		PGCocoaTestDatabase, PGCocoaTestSchema, "address (name_id, address) VALUES ( 3, '1050 Main Street')"];
	[conn execQuery:sql];
	STAssertTrue([conn errorDescription] == nil, @"Error executing SQL: %@. %@", sql, [conn errorDescription]);
	
	sql = [NSString stringWithFormat:@"COMMENT ON TABLE %@.address IS 'Multiple Addresses for each name.'",PGCocoaTestSchema];
	[conn execQuery:sql];
	STAssertTrue([conn errorDescription] == nil, @"Error executing SQL: %@. %@", sql, [conn errorDescription]);

	sql = [NSString stringWithFormat:@"COMMENT ON TABLE %@.name IS 'People names only not company names.'",PGCocoaTestSchema];
	[conn execQuery:sql];
	STAssertTrue([conn errorDescription] == nil, @"Error executing SQL: %@. %@", sql, [conn errorDescription]);

	sql = [NSString stringWithFormat:@"COMMENT ON TRIGGER update_timestamp ON %@.name IS 'Keep track of update date and time.'", PGCocoaTestSchema];
	[conn execQuery:sql];
	STAssertTrue([conn errorDescription] == nil, @"Error executing SQL: %@. %@", sql, [conn errorDescription]);
	
	sql = [NSString stringWithFormat:@"COMMENT ON COLUMN %@.name.last IS 'Customers last name.'", PGCocoaTestSchema];
	[conn execQuery:sql];
	STAssertTrue([conn errorDescription] == nil, @"Error executing SQL: %@. %@", sql, [conn errorDescription]);

	sql = [NSString stringWithFormat:@"COMMENT ON COLUMN %@.name.first IS 'Customers first name.'", PGCocoaTestSchema];
	[conn execQuery:sql];
	STAssertTrue([conn errorDescription] == nil, @"Error executing SQL: %@. %@", sql, [conn errorDescription]);

	sql = [NSString stringWithFormat:@"COMMENT ON VIEW %@.address_book IS 'Combined address and name view.'", PGCocoaTestSchema];
	[conn execQuery:sql];
	STAssertTrue([conn errorDescription] == nil, @"Error executing SQL: %@. %@", sql, [conn errorDescription]);

	sql = [NSString stringWithFormat:@"COMMENT ON INDEX %@.address_pkey IS 'Efficient lookup by address.'", PGCocoaTestSchema];
	[conn execQuery:sql];
	STAssertTrue([conn errorDescription] == nil, @"Error executing SQL: %@. %@", sql, [conn errorDescription]);

	sql = [NSString stringWithFormat:@"COMMENT ON INDEX %@.name_pkey IS 'Efficient lookup by name.'", PGCocoaTestSchema];
	[conn execQuery:sql];
	STAssertTrue([conn errorDescription] == nil, @"Error executing SQL: %@. %@", sql, [conn errorDescription]);

	sql = [NSString stringWithFormat:@"COMMENT ON SEQUENCE %@.name_name_id_seq IS 'Keep track of name id numbers.'", PGCocoaTestSchema];
	[conn execQuery:sql];
	STAssertTrue([conn errorDescription] == nil, @"Error executing SQL: %@. %@", sql, [conn errorDescription]);
	
	sql = [NSString stringWithFormat:@"COMMENT ON DATABASE pgcocoa_test_database IS 'The test database comment.'"];
	[conn execQuery:sql];
	STAssertTrue([conn errorDescription] == nil, @"Error executing SQL: %@. %@", sql, [conn errorDescription]);

	sql = [NSString stringWithFormat:@"COMMENT ON SCHEMA pgcocoa_test_schema IS 'The test schema comment.'"];
	[conn execQuery:sql];
	STAssertTrue([conn errorDescription] == nil, @"Error executing SQL: %@. %@", sql, [conn errorDescription]);

	sql = [NSString stringWithFormat:@"COMMENT ON CONSTRAINT name_pkey ON %@.name IS 'Constrain the name to pkey values.'", PGCocoaTestSchema];
	[conn execQuery:sql];
	STAssertTrue([conn errorDescription] == nil, @"Error executing SQL: %@. %@", sql, [conn errorDescription]);

	sql = [NSString stringWithFormat:@"COMMENT ON FUNCTION %@.update_time_stamp () IS 'Timestamp all updates function comment. Uses field update_time.'", PGCocoaTestSchema];
	[conn execQuery:sql];
	STAssertTrue([conn errorDescription] == nil, @"Error executing SQL: %@. %@", sql, [conn errorDescription]);

	[conn disconnect];
	[conn release];
	conn = nil;
	databaseCreated = YES;
}


- (void)setUp
{
	NSLog(@"Starting %@ setUp", [self name]);

	[self raiseAfterFailure];
	[self createDatabase];
	
	conn = [[Connection alloc] init];
	[conn setUserName:PGCocoaTestUser];
	[conn setPassword:PGCocoaTestPassword];
	[conn setDbName:PGCocoaTestDatabase];
	[conn setHost:PGCocoaTestHost];
	[conn setPort:PGCocoaTestPort];
	[conn connect];
	STAssertTrue([conn errorDescription] == nil, @"Error connecting to database %@: %@.", [conn dbName], [conn errorDescription]);
	STAssertTrue([conn isConnected], @"Failed to connect to database %@.", [conn dbName]);

	testSchema = [[Schema alloc] initWithConnection:conn];
	STAssertNotNil(testSchema, @"Failed to init testSchema object.");
}


- (void)tearDown
{
	[testSchema release];
	testSchema = nil;
	
	[conn disconnect];
	[conn release];
	conn = nil;
}


- (void)testTriggerZeroBoundry
{
	RecordSet * results;
	NSString * sql;

	results = [testSchema getTriggerNamesFromSchema:PGCocoaTestSchema fromTableName:@"address"];
	STAssertTrue([results count] == 0, @"Failed to return the correct number of triggers.");
	
	sql = [NSString stringWithFormat:@"%s%@.%@.%s%@.%@.%s", "CREATE TRIGGER create_timestamp BEFORE INSERT ON ",
		PGCocoaTestDatabase, PGCocoaTestSchema, "address \
	FOR EACH ROW EXECUTE PROCEDURE ", PGCocoaTestDatabase, PGCocoaTestSchema, "create_time_stamp()"];
	[conn execQuery:sql];
	STAssertTrue([conn errorDescription] == nil, @"Error executing SQL: %@.", sql);

	results = [testSchema getTriggerNamesFromSchema:PGCocoaTestSchema fromTableName:@"address"];
	STAssertTrue([results count] == 1, @"Failed to return the correct number of triggers.");
}


- (void)testTriggerWith2
{
	RecordSet * results;

	results = [testSchema getTriggerNamesFromSchema:PGCocoaTestSchema fromTableName:@"name"];
	STAssertTrue([results count] == 2, @"Failed to return the correct number of triggers.");
}


- (void)testTables
{
	RecordSet * results;
		
	results = [testSchema getTableNamesFromSchema:PGCocoaTestSchema];
	STAssertTrue([results count] == 2, @"Failed to return the correct number of tables.");

	results = [testSchema getTableNamesFromSchema:nil];
	STAssertTrue([results count] == 0, @"Failed to return 0 number of tables in the public schema.");
}


- (void)testFunctions
{
	RecordSet * results;
	
	// TODO
}


- (void)testViews
{
	RecordSet * results;
		
	results = [testSchema getViewNamesFromSchema:PGCocoaTestSchema];
	STAssertTrue([results count] == 1, @"Failed to return the correct number of views.");
	
	results = [testSchema getViewNamesFromSchema:nil];
	STAssertTrue([results count] == 0, @"Failed to return 0 number of views in the public schema.");
}


- (void)testAddressColumns
{
	RecordSet * results;
		
	results = [testSchema getTableColumnNamesFromSchema:PGCocoaTestSchema fromTableName:@"address"];
	STAssertTrue([results count] == 9, @"Failed to return the correct number of columns from table 'address'.");

	int i;
	NSNumber *aFoundCount = [NSNumber numberWithInt:0];
	NSString* aColumnName;
	NSNumber *newValue;
	NSArray * columnCount = [NSArray arrayWithObjects: aFoundCount, aFoundCount, aFoundCount, aFoundCount, aFoundCount, aFoundCount, aFoundCount, aFoundCount, aFoundCount, nil];
	NSArray * columnNames = [NSArray arrayWithObjects: @"address_id", @"name_id", @"city", @"state", @"zip", @"notes", @"address", @"create_time", @"update_time", nil];
	NSMutableDictionary * columnLookup = [[NSMutableDictionary alloc] initWithObjects:columnCount forKeys:columnNames];
	
	for (i = 0; i < [results count]; i++)
	{
		aColumnName = [[[[results itemAtIndex: i] fields] itemAtIndex:0] value];
		aFoundCount = [columnLookup objectForKey: aColumnName];
		if (aFoundCount != nil)
		{
			newValue =  [NSNumber numberWithInt:[aFoundCount intValue]+1];
			[columnLookup setObject:newValue forKey:aColumnName];
		}
		else
		{
			STFail(@"Found extra column name (%@) in table 'name'.", aColumnName);
		}
	}
	
	NSLog(@"Checking columns in table 'address':");
	NSEnumerator *enumerator = [columnLookup keyEnumerator];
	while ((aColumnName = [enumerator nextObject])) {
		aFoundCount = [columnLookup objectForKey: aColumnName];
		NSLog(@"    %@ count = %d.", aColumnName, [aFoundCount intValue]);
		STAssertTrue([aFoundCount intValue] == 1, @"Problem finding column name (%@) in table 'address'.", aColumnName);
	}
	
	[columnLookup release];
	columnLookup = nil;
}


- (void)testTableNameColumns
{
	RecordSet * results;
			
	results = [testSchema getTableColumnNamesFromSchema:PGCocoaTestSchema fromTableName:@"name"];
	STAssertTrue([results count] == 8, @"Failed to return the correct number of columns from table 'name'.");
	
	int i;
	NSNumber *aFoundCount = [NSNumber numberWithInt:0];
	NSString* aColumnName;
	NSNumber *newValue;
	NSArray * columnCount = [NSArray arrayWithObjects: aFoundCount, aFoundCount, aFoundCount, aFoundCount, aFoundCount, aFoundCount, aFoundCount, aFoundCount, nil];
	NSArray * columnNames = [NSArray arrayWithObjects: @"name_id", @"weight", @"height", @"age", @"first", @"last", @"create_time", @"update_time", nil];
	NSMutableDictionary * columnLookup = [[NSMutableDictionary alloc] initWithObjects:columnCount forKeys:columnNames];
	
	for (i = 0; i < [results count]; i++)
	{
		aColumnName = [[[[results itemAtIndex: i] fields] itemAtIndex:0] value];
		aFoundCount = [columnLookup objectForKey: aColumnName];
		if (aFoundCount != nil)
		{
			newValue =  [NSNumber numberWithInt:[aFoundCount intValue]+1];
			[columnLookup setObject:newValue forKey:aColumnName];
		}
		else
		{
			STFail(@"Found extra column name (%@) in table 'name'.", aColumnName);
		}
	}
	
	NSLog(@"Checking columns in table 'name':");
	NSEnumerator *enumerator = [columnLookup keyEnumerator];
	while ((aColumnName = [enumerator nextObject])) {
		aFoundCount = [columnLookup objectForKey: aColumnName];
		NSLog(@"    %@ count = %d.", aColumnName, [aFoundCount intValue]);
		STAssertTrue([aFoundCount intValue] == 1, @"Problem finding column name (%@) in table 'name'.", aColumnName);
	}
	
	[columnLookup release];
	columnLookup = nil;
}


- (void)testDatabase
{
	RecordSet * results;
	NSString* aDatabaseName;
	int i;
		
	results = [testSchema getDatabaseNames];
	bool found = NO;
	NSLog(@"Found databases:");
	for (i = 0; i < [results count]; i++)
	{
		aDatabaseName = [[[[results itemAtIndex: i] fields] itemAtIndex:0] value];
		if ([PGCocoaTestDatabase compare:aDatabaseName] == NSOrderedSame)
		{
			found = YES;
			NSLog(@" ** %@", aDatabaseName);
		}
		else
		{
			NSLog(@"    %@", aDatabaseName);
		}
	}
	STAssertTrue(found == YES, @"Error finding database: %@.", PGCocoaTestDatabase);
}


- (void)testSchema
{
	RecordSet * results;
	
	[self createDatabase];
	
	results = [testSchema getSchemaNames];
	int i;
	NSNumber *aFoundCount = [NSNumber numberWithInt:0];
	NSString* aSchemaName;
	NSNumber *newValue;
	NSArray * columnCount = [NSArray arrayWithObjects: aFoundCount, aFoundCount, aFoundCount, aFoundCount, aFoundCount, nil];
	NSArray * columnNames = [NSArray arrayWithObjects: @"pg_catalog", @"pg_toast", @"public", @"information_schema", PGCocoaTestSchema, nil];
	NSMutableDictionary * columnLookup = [[NSMutableDictionary alloc] initWithObjects:columnCount forKeys:columnNames];
	
	for (i = 0; i < [results count]; i++)
	{
		aSchemaName = [[[[results itemAtIndex: i] fields] itemAtIndex:0] value];
		aFoundCount = [columnLookup objectForKey: aSchemaName];
		if (aFoundCount != nil)
		{
			newValue =  [NSNumber numberWithInt:[aFoundCount intValue]+1];
			[columnLookup setObject:newValue forKey:aSchemaName];
		}
		else
		{
			NSLog(@"Found extra schema name (%@).", aSchemaName);
		}
	}
	NSLog(@"Checking schemas:");
	NSEnumerator *enumerator = [columnLookup keyEnumerator];
	while ((aSchemaName = [enumerator nextObject])) {
		aFoundCount = [columnLookup objectForKey: aSchemaName];
		NSLog(@"    %@ count = %d.", aSchemaName, [aFoundCount intValue]);
		STAssertTrue([aFoundCount intValue] == 1, @"Problem finding Schema name (%@).", aSchemaName);
	}
	[columnLookup release];
	columnLookup = nil;
}


- (void)testIndexNames
{
	int i, ii;
	RecordSet * tables;
	RecordSet * indexes;
	NSString * aTableName;
	NSMutableArray *tableNamesArray = [[NSMutableArray alloc] init];
	
	[self createDatabase];

	tables = [testSchema getTableNamesFromSchema:PGCocoaTestSchema];
	for (i = 0; i < [tables count]; i++)
	{
		aTableName = [[[[tables itemAtIndex: i] fields] itemAtIndex:0] value];
		[tableNamesArray addObject:aTableName];
		NSLog(@"Found table: %@", aTableName);
	}
	
	NSNumber *aFoundCount = [NSNumber numberWithInt:0];
	NSString* anIndexName;
	NSNumber *newValue;
	NSArray * foundCount = [NSArray arrayWithObjects: aFoundCount, aFoundCount, nil];
	NSArray * indexNames = [NSArray arrayWithObjects: @"address_pkey", @"name_pkey", nil];
	NSMutableDictionary * indexLookup = [[NSMutableDictionary alloc] initWithObjects:foundCount forKeys:indexNames];

	for (i = 0; i < [tableNamesArray count]; i++)
	{
		indexes = [testSchema getIndexNamesFromSchema:PGCocoaTestSchema fromTableName:[tableNamesArray objectAtIndex:i]];
		NSLog(@"For table %@, found %d indexes.", [tableNamesArray objectAtIndex:i], [indexes count]);
		for (ii = 0; ii < [indexes count]; ii++)
		{
			anIndexName = [[[[indexes itemAtIndex: ii] fields] itemAtIndex:0] value];
			aFoundCount = [indexLookup objectForKey: anIndexName];
			if (aFoundCount != nil)
			{
				newValue =  [NSNumber numberWithInt:[aFoundCount intValue]+1];
				[indexLookup setObject:newValue forKey:anIndexName];
			}
			else
			{
				STFail(@"Found extra index name (%@) for table (%@).", anIndexName, [tableNamesArray objectAtIndex:i]);
			}
		}
	}

	NSLog(@"Checking indexes:");
	NSEnumerator *enumerator = [indexLookup keyEnumerator];
	while ((anIndexName = [enumerator nextObject]))
	{
		aFoundCount = [indexLookup objectForKey: anIndexName];
		NSLog(@"    %@ count = %d.", anIndexName, [aFoundCount intValue]);
		STAssertTrue([aFoundCount intValue] == 1, @"Problem finding index name (%@) with count (%d).", anIndexName, [aFoundCount intValue]);
	}
	
	[tableNamesArray release];
	tableNamesArray = nil;
	
	[indexLookup release];
	indexLookup = nil;
}


- (void)testIndexInfo
{
	NSString * correctIndexSQLName = [[NSString alloc] initWithFormat:@"CREATE UNIQUE INDEX name_pkey ON %@.name USING btree (name_id)", PGCocoaTestSchema];
	NSString * correctIndexSQLAddress = [[NSString alloc] initWithFormat:@"CREATE UNIQUE INDEX address_pkey ON %@.address USING btree (address_id)", PGCocoaTestSchema];
	NSString * indexSQL;
	
	[self createDatabase];

	indexSQL = [testSchema getIndexSQLFromSchema:PGCocoaTestSchema fromTableName:@"name" fromIndexName:@"name_pkey"];
	STAssertTrue(indexSQL != nil, @"Problem finding index info for table (name) and index name (name_pkey).");
	
	if ([correctIndexSQLName compare:indexSQL] != NSOrderedSame)
	{
		//NSLog(indexSQL);
		//NSLog(correctIndexSQLName);
		STFail(@"Index info for table (name) and index name (name_pkey) does not match\n%@\n%2.", correctIndexSQLName, indexSQL);		
	}

	indexSQL = [testSchema getIndexSQLFromSchema:PGCocoaTestSchema fromTableName:@"address" fromIndexName:@"address_pkey"];
	STAssertTrue(indexSQL != nil, @"Problem finding index info for table (address) and index name (address_pkey).");
	
	if ([correctIndexSQLAddress compare:indexSQL] != NSOrderedSame)
	{
		//NSLog(indexSQL);
		//NSLog(correctIndexSQLAddress);
		STFail(@"Index info for table (address) and index name (address_pkey) does not match\n%@\n%2.", correctIndexSQLAddress, indexSQL);		
	}
	
	[correctIndexSQLName release];
	correctIndexSQLName = nil;
	
	[correctIndexSQLAddress release];
	correctIndexSQLAddress = nil;
}


/*
 correct result
 CREATE OR REPLACE VIEW address_book AS SELECT n."first", n."last", a.address FROM pgcocoa_test_schem
 a.name n, pgcocoa_test_schema.address a WHERE (n.name_id = a.name_id) ORDER BY n."last", n."first";
 */
- (void)testViewSQL
{
	NSString *theSQL;
	
	[self createDatabase];
	
	theSQL = [testSchema getViewSQLFromSchema:PGCocoaTestSchema fromView:@"address_book" pretty:0];
	STAssertTrue(theSQL != nil, @"Did not return SQL.");
	STAssertTrue([theSQL length] == 199, @"SQL not correct length.");
	
	NSLog(theSQL);
}


- (void)testTableNameSQL
{
	NSString *theSQL;
	
	[self createDatabase];
	
	theSQL = [testSchema getTableSQLFromSchema:PGCocoaTestSchema fromTableName:@"name" pretty:1];
	STAssertTrue(theSQL != nil, @"Did not return SQL.");
	NSLog(theSQL);

	theSQL = [testSchema getTableSQLFromSchema:PGCocoaTestSchema fromTableName:@"name" pretty:0];
	STAssertTrue(theSQL != nil, @"Did not return SQL.");
	NSLog(theSQL);
}


- (void)testTableAddressSQL
{
	NSString *theSQL;
	
	[self createDatabase];
	
	theSQL = [testSchema getTableSQLFromSchema:PGCocoaTestSchema fromTableName:@"address" pretty:1];
	STAssertTrue(theSQL != nil, @"Did not return SQL.");
	NSLog(theSQL);
	
	theSQL = [testSchema getTableSQLFromSchema:PGCocoaTestSchema fromTableName:@"address" pretty:0];
	STAssertTrue(theSQL != nil, @"Did not return SQL.");
	NSLog(theSQL);
	
}


- (void)testViewAddressBookColumns
{
	RecordSet * results;
	NSString * view_name = @"address_book";
	
	[self createDatabase];
	
	results = [testSchema getTableColumnNamesFromSchema:PGCocoaTestSchema fromTableName:view_name];
	STAssertTrue([results count] == 3, @"Failed to return the correct number of columns from table '%@'.", view_name);
	
	int i;
	NSNumber *aFoundCount = [NSNumber numberWithInt:0];
	NSString* aColumnName;
	NSNumber *newValue;
	NSArray * columnCount = [NSArray arrayWithObjects: aFoundCount, aFoundCount, aFoundCount, nil];
	NSArray * columnNames = [NSArray arrayWithObjects: @"first", @"last", @"address", nil];
	NSMutableDictionary * columnLookup = [[NSMutableDictionary alloc] initWithObjects:columnCount forKeys:columnNames];
	
	for (i = 0; i < [results count]; i++)
	{
		aColumnName = [[[[results itemAtIndex: i] fields] itemAtIndex:0] value];
		aFoundCount = [columnLookup objectForKey: aColumnName];
		if (aFoundCount != nil)
		{
			newValue =  [NSNumber numberWithInt:[aFoundCount intValue]+1];
			[columnLookup setObject:newValue forKey:aColumnName];
		}
		else
		{
			STFail(@"Found extra column name (%@) in table %@.", aColumnName, view_name);
		}
	}
	
	NSLog(@"Checking columns in table %@:", view_name);
	NSEnumerator *enumerator = [columnLookup keyEnumerator];
	while ((aColumnName = [enumerator nextObject])) {
		aFoundCount = [columnLookup objectForKey: aColumnName];
		NSLog(@"    %@ count = %d.", aColumnName, [aFoundCount intValue]);
		STAssertTrue([aFoundCount intValue] == 1, @"Problem finding column name (%@) in table %@.", aColumnName, view_name);
	}
	
	[columnLookup release];
	columnLookup = nil;
}

/*
2006-03-09 09:50:08.986 otest[8324]    address_address_id_seq
2006-03-09 09:50:08.986 otest[8324]    name_name_id_seq
*/

- (void)testSequenceNames
{
	RecordSet * results;
	int i;
	
	[self createDatabase];

	results = [testSchema getSequenceNamesFromSchema:PGCocoaTestSchema];
	STAssertTrue([results count] == 2, @"Failed to return the correct number of sequences.");

	NSNumber *aFoundCount = [NSNumber numberWithInt:0];
	NSString* aSequenceName;
	NSNumber *newValue;
	NSArray * sequenceCount = [NSArray arrayWithObjects: aFoundCount, aFoundCount, nil];
	NSArray * sequenceNames = [NSArray arrayWithObjects: @"address_address_id_seq", @"name_name_id_seq", nil];
	NSMutableDictionary * SequenceLookup = [[NSMutableDictionary alloc] initWithObjects:sequenceCount forKeys:sequenceNames];
	
	for (i = 0; i < [results count]; i++)
	{
		aSequenceName = [[[[results itemAtIndex: i] fields] itemAtIndex:0] value];
		aFoundCount = [SequenceLookup objectForKey: aSequenceName];
		if (aFoundCount != nil)
		{
			newValue =  [NSNumber numberWithInt:[aFoundCount intValue]+1];
			[SequenceLookup setObject:newValue forKey:aSequenceName];
		}
		else
		{
			STFail(@"Found extra sequence name (%@).", aSequenceName);
		}
	}
	
	NSLog(@"Checking sequences:");
	NSEnumerator *enumerator = [SequenceLookup keyEnumerator];
	while ((aSequenceName = [enumerator nextObject])) {
		aFoundCount = [SequenceLookup objectForKey: aSequenceName];
		NSLog(@"    %@ count = %d.", aSequenceName, [aFoundCount intValue]);
		STAssertTrue([aFoundCount intValue] == 1, @"Problem finding sequence name (%@).", aSequenceName);
	}
}


- (void)testSequenceColumnNames
 {
	 RecordSet * results;
	 int i;
	 
	 [self createDatabase];

	 results = [testSchema getSequenceColumnNamesFromSchema:PGCocoaTestSchema fromSequence:@"name_name_id_seq"];
	 NSLog(@"Sequence Column Names = %d", [results count]);
	 STAssertTrue([results count] == 9, @"Failed to return the correct number of sequence column names.");
	 
	 NSNumber *aFoundCount = [NSNumber numberWithInt:0];
	 NSString* aSequenceName;
	 NSNumber *newValue;
	 NSArray * sequenceCount = [NSArray arrayWithObjects: aFoundCount, aFoundCount, aFoundCount,aFoundCount,aFoundCount,aFoundCount,aFoundCount,aFoundCount,aFoundCount,nil];
	 NSArray * sequenceNames = [NSArray arrayWithObjects: @"sequence_name", @"last_value", @"increment_by", @"max_value",@"min_value",@"cache_value",@"log_cnt",@"is_cycled",@"is_called",nil];
	 NSMutableDictionary * SequenceLookup = [[NSMutableDictionary alloc] initWithObjects:sequenceCount forKeys:sequenceNames];
	 
	 for (i = 0; i < [results count]; i++)
	 {
		 aSequenceName = [[[[results itemAtIndex: i] fields] itemAtIndex:0] value];
		 aFoundCount = [SequenceLookup objectForKey: aSequenceName];
		 if (aFoundCount != nil)
		 {
			 newValue =  [NSNumber numberWithInt:[aFoundCount intValue]+1];
			 [SequenceLookup setObject:newValue forKey:aSequenceName];
		 }
		 else
		 {
			 STFail(@"Found extra sequence column name (%@).", aSequenceName);
		 }
	 }
	 
	 NSLog(@"Checking sequences:");
	 NSEnumerator *enumerator = [SequenceLookup keyEnumerator];
	 while ((aSequenceName = [enumerator nextObject])) {
		 aFoundCount = [SequenceLookup objectForKey: aSequenceName];
		 NSLog(@"    %@ count = %d.", aSequenceName, [aFoundCount intValue]);
		 STAssertTrue([aFoundCount intValue] == 1, @"Problem finding sequence column name (%@).", aSequenceName);
	 }
 }

- (void)testTriggerComment
{
	NSString * comment;
	
	comment = [testSchema getTriggerCommentFromSchema:PGCocoaTestSchema fromTableName:@"name" fromTriggerName:@"update_timestamp"];	
	STAssertTrue(comment != nil, @"Trigger NULL comment.");
	if ([comment compare:@"Keep track of update date and time."] != NSOrderedSame)
	{
		STFail(@"Trigger wrong comment (%@).", comment);
	}
}

- (void)testTableComment
{
	NSString * comment;
	
	comment = [testSchema getTableCommentFromSchema:PGCocoaTestSchema fromTableName:@"name"];	
	STAssertTrue(comment != nil, @"Table NULL comment.");
	if ([comment compare:@"People names only not company names."] != NSOrderedSame)
	{
		STFail(@"Table wrong comment (%@).", comment);
	}
	
	comment = [testSchema getTableCommentFromSchema:PGCocoaTestSchema fromTableName:@"address"];
	STAssertTrue(comment != nil, @"Table NULL comment.");
	if ([comment compare:@"Multiple Addresses for each name."] != NSOrderedSame)
	{
		STFail(@"Table wrong comment (%@).", comment);
	}
	
}

- (void)testColumnComment
{
	NSString * comment;
	comment = [testSchema getColumnCommentFromSchema:PGCocoaTestSchema fromTableName:@"name" fromColumnName:@"first"];	
	STAssertTrue(comment != nil, @"Column has NULL comment.");
	if ([comment compare:@"Customers first name."] != NSOrderedSame)
	{
		STFail(@"Column first name wrong comment (%@).", comment);
	}
	comment = [testSchema getColumnCommentFromSchema:PGCocoaTestSchema fromTableName:@"name" fromColumnName:@"last"];	
	STAssertTrue(comment != nil, @"Column has NULL comment.");
	if ([comment compare:@"Customers last name."] != NSOrderedSame)
	{
		STFail(@"Column last name wrong comment (%@).", comment);
	}
}


- (void)testViewComment
{
	NSString * comment;
	
	comment = [testSchema getViewCommentFromSchema:PGCocoaTestSchema fromViewName:@"address_book"];	
	STAssertTrue(comment != nil, @"View has NULL comment.");
	if ([comment compare:@"Combined address and name view."] != NSOrderedSame)
	{
		STFail(@"View wrong comment (%@).", comment);
	}
}


- (void)testIndexComment
{
	NSString * comment;
	
	comment = [testSchema getIndexCommentFromSchema:PGCocoaTestSchema fromIndexName:@"address_pkey"];	
	STAssertTrue(comment != nil, @"Index has NULL comment.");
	if ([comment compare:@"Efficient lookup by address."] != NSOrderedSame)
	{
		STFail(@"Index wrong comment (%@).", comment);
	}
	else
	{
		NSLog(comment);
	}
}


- (void)testSequenceComment
{
	NSString * comment;
	
	comment = [testSchema getSequenceCommentFromSchema:PGCocoaTestSchema fromSequenceName:@"name_name_id_seq"];	
	STAssertTrue(comment != nil, @"Sequence has NULL comment.");
	if ([comment compare:@"Keep track of name id numbers."] != NSOrderedSame)
	{
		STFail(@"Sequence wrong comment (%@).", comment);
	}
	else
	{
		NSLog(comment);
	}	
}

-(void)testDatabaseComment
{
	NSString * comment;
	
	comment = [testSchema getDatabaseComment:@"pgcocoa_test_database"];	
	STAssertTrue(comment != nil, @"Database has NULL comment.");
	if ([comment compare:@"The test database comment."] != NSOrderedSame)
	{
		STFail(@"Database wrong comment (%@).", comment);
	}
	else
	{
		NSLog(comment);
	}	
}

-(void)testSchemaComment
{
	NSString * comment;
	
	comment = [testSchema getSchemaComment:@"pgcocoa_test_schema"];	
	STAssertTrue(comment != nil, @"Schema has NULL comment.");
	if ([comment compare:@"The test schema comment."] != NSOrderedSame)
	{
		STFail(@"Schema wrong comment (%@).", comment);
	}
	else
	{
		NSLog(comment);
	}		
}

-(void)testConstraintComment
{
	NSString * comment;
	
	comment = [testSchema getConstraintCommentFromSchema:PGCocoaTestSchema fromConstraintName:@"name_pkey"];	
	STAssertTrue(comment != nil, @"Constraint has NULL comment.");
	if ([comment compare:@"Constrain the name to pkey values."] != NSOrderedSame)
	{
		STFail(@"Constraint wrong comment (%@).", comment);
	}
	else
	{
		NSLog(comment);
	}
}

-(void)testFunctionComment
{
	NSString * comment;
	
	comment = [testSchema getFunctionCommentFromSchema:PGCocoaTestSchema fromFunctionName:@"update_time_stamp"];	
	STAssertTrue(comment != nil, @"Function has NULL comment.");
	if ([comment compare:@"Timestamp all updates function comment. Uses field update_time."] != NSOrderedSame)
	{
		STFail(@"Function wrong comment (%@).", comment);
	}
	else
	{
		NSLog(comment);
	}
}

-(void)testExplorer
{
	ExplorerModel *explorer = [[ExplorerModel alloc] initWithConnection:conn];
	[explorer buildSchema];
	
	[explorer printLog];
	[explorer autorelease];
}

-(void)testLocks
{
	unsigned int i;
	RecordSet * results;
	NSString* aColumnName;
	NSString* aColumnValue;
		
	results = [testSchema getLocks];
	
	for (i = 0; i < [results count]; i++)
	{
		/*
		aColumnName = [[[[results itemAtIndex: i] fields] itemAtIndex:0] value];
		aColumnValue =[[[[results itemAtIndex: i] fields] itemAtIndex:0] value];
		 */
	}	
}

@end

