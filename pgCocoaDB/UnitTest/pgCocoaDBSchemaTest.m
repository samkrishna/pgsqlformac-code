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

//------------------------------------------------------------------
// Test configuration parameters, Please modify as necessary for
// your environment.

NSString* const PGCocoaTestDatabase = @"pgcocoa_test_database";
NSString* const PGCocoaTestSchema = @"pgcocoa_test_schema";
NSString* const PGCocoaTestUser = @"ntiffin";
NSString* const PGCocoaTestPassword = @"";
NSString* const PGCocoaTestHost = @"localhost";
NSString* const PGCocoaTestPort = @"5432";

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
	
	[conn disconnect];
	
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

	if (0 == [results count])
	{
		// test database does not exist
		sql = [NSString stringWithFormat:@"%s%@", "CREATE DATABASE ", PGCocoaTestDatabase];
		NSLog(sql);
		[conn execQuery:sql];
		STAssertTrue([conn errorDescription] == nil, @"Not able to '%@', %@.", sql, [conn errorDescription]);
	}
	else
	{
#if NEIL_TEST
		// if you are not concerned about automatically dropping the test database you can remove this "#if"
		// or you can add -DNEIL_TEST to the OTHER_CFLAGS in project builder
		sql = [NSString stringWithFormat:@"%s%@", "DROP DATABASE ", PGCocoaTestDatabase];
		NSLog(sql);
		[conn execQuery:sql];
		STAssertTrue([conn errorDescription] == nil, @"Not able to '%@', %@.", sql, [conn errorDescription]);

		sql = [NSString stringWithFormat:@"%s%@", "CREATE DATABASE ", PGCocoaTestDatabase];
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
					   weight float DEFAULT 125.3,			\
					   age int DEFAULT 30,					\
					   first varchar(35) NOT NULL,		\
					   last varchar(35) NOT NULL,		\
					   create_time timestamp,	\
					   update_time timestamp)	\
	\
	CREATE TABLE address (\
						  address_id serial PRIMARY KEY,		\
						  name_id integer REFERENCES name (name_id),	\
						  city varchar(20) DEFAULT 'Kansas City',		\
						  state varchar(2)	DEFAULT 'MO',	\
						  zip integer NOT NULL	DEFAULT 64057, \
						  notes text,			\
						  address varchar(35),	\
						  create_time timestamp,	\
						  update_time timestamp)	\
	\
	CREATE VIEW address_book AS \
		SELECT	n.first, n.last, a.address	\
		FROM name n, address a				\
		WHERE n.name_id = a.name_id		\
		ORDER by n.last, n.first"];

	[conn execQuery:sql];
	STAssertTrue([conn errorDescription] == nil, @"Error executing SQL: %@.", sql);

	// TODO check if function exists
	sql = [NSString stringWithFormat:@"%s%@.%@.%s", "CREATE or REPLACE FUNCTION ", PGCocoaTestDatabase, PGCocoaTestSchema, "create_time_stamp() RETURNS trigger AS $time_stamp$ \
	BEGIN \
		NEW.create_time := current_timestamp; \
		RETURN NEW; \
	END; \
	$time_stamp$ LANGUAGE plpgsql; "];
	[conn execQuery:sql];
	STAssertTrue([conn errorDescription] == nil, @"Error executing SQL: %@.", sql);

	// TODO check if function exists
	sql = [NSString stringWithFormat:@"%s%@.%@.%s", "CREATE or REPLACE FUNCTION ", PGCocoaTestDatabase, PGCocoaTestSchema, "update_time_stamp() RETURNS trigger AS $time_stamp$ \
	BEGIN \
		NEW.update_time := current_timestamp; \
		RETURN NEW; \
	END; \
	$time_stamp$ LANGUAGE plpgsql; "];
	[conn execQuery:sql];
	STAssertTrue([conn errorDescription] == nil, @"Error executing SQL: %@.", sql);
	
	sql = [NSString stringWithFormat:@"%s%@.%@.%s%@.%@.%s", "CREATE TRIGGER create_timestamp BEFORE INSERT ON ",
		PGCocoaTestDatabase, PGCocoaTestSchema, "name \
	FOR EACH ROW EXECUTE PROCEDURE ", PGCocoaTestDatabase, PGCocoaTestSchema, "create_time_stamp()"];
	[conn execQuery:sql];
	STAssertTrue([conn errorDescription] == nil, @"Error executing SQL: %@.", sql);

	/*
	sql = [NSString stringWithFormat:@"%s%@.%@.%s%@.%@.%s", "CREATE TRIGGER create_timestamp BEFORE INSERT ON ",
		PGCocoaTestDatabase, PGCocoaTestSchema, "address \
	FOR EACH ROW EXECUTE PROCEDURE ", PGCocoaTestDatabase, PGCocoaTestSchema, "create_time_stamp()"];
	[conn execQuery:sql];
	STAssertTrue([conn errorDescription] == nil, @"Error executing SQL: %@.", sql);
	*/
	
	sql = [NSString stringWithFormat:@"%s%@.%@.%s%@.%@.%s", "CREATE TRIGGER update_timestamp BEFORE UPDATE ON ",
		PGCocoaTestDatabase, PGCocoaTestSchema, "name \
	FOR EACH ROW EXECUTE PROCEDURE ", PGCocoaTestDatabase, PGCocoaTestSchema, "update_time_stamp()"];
	[conn execQuery:sql];
	STAssertTrue([conn errorDescription] == nil, @"Error executing SQL: %@.", sql);
	
	/*
	sql = [NSString stringWithFormat:@"%s%@.%@.%s%@.%@.%s", "CREATE TRIGGER update_timestamp BEFORE UPDATE ON ",
		PGCocoaTestDatabase, PGCocoaTestSchema, "address \
	FOR EACH ROW EXECUTE PROCEDURE ", PGCocoaTestDatabase, PGCocoaTestSchema, "update_time_stamp()"];
	[conn execQuery:sql];
	STAssertTrue([conn errorDescription] == nil, @"Error executing SQL: %@.", sql);
	*/
	
	sql = [NSString stringWithFormat:@"%s%@.%@.%s", "INSERT INTO ",
		PGCocoaTestDatabase, PGCocoaTestSchema, "name (first, last) VALUES ( 'Bennie', 'Hill')"];
	[conn execQuery:sql];
	STAssertTrue([conn errorDescription] == nil, @"Error executing SQL: %@.", sql);
	sql = [NSString stringWithFormat:@"%s%@.%@.%s", "INSERT INTO ",
		PGCocoaTestDatabase, PGCocoaTestSchema, "address (name_id, address, city, state, zip) VALUES ( 1, '14 Upton Hill', 'London', 'UK', 0)"];
	[conn execQuery:sql];
	STAssertTrue([conn errorDescription] == nil, @"Error executing SQL: %@.", sql);
	
	sql = [NSString stringWithFormat:@"%s%@.%@.%s", "INSERT INTO ",
		PGCocoaTestDatabase, PGCocoaTestSchema, "name (first, last) VALUES ( 'Marty', 'Zweig')"];
	[conn execQuery:sql];
	STAssertTrue([conn errorDescription] == nil, @"Error executing SQL: %@.", sql);
	sql = [NSString stringWithFormat:@"%s%@.%@.%s", "INSERT INTO ",
		PGCocoaTestDatabase, PGCocoaTestSchema, "address (name_id, address, city, state, zip) VALUES ( 2, '100 Wall Street', 'New York', 'NY', 10045)"];
	[conn execQuery:sql];
	STAssertTrue([conn errorDescription] == nil, @"Error executing SQL: %@.", sql);
	
	sql = [NSString stringWithFormat:@"%s%@.%@.%s", "INSERT INTO ",
		PGCocoaTestDatabase, PGCocoaTestSchema, "name (first, last) VALUES ( 'Mary', 'Otherwise')"];
	[conn execQuery:sql];
	STAssertTrue([conn errorDescription] == nil, @"Error executing SQL: %@.", sql);
	sql = [NSString stringWithFormat:@"%s%@.%@.%s", "INSERT INTO ",
		PGCocoaTestDatabase, PGCocoaTestSchema, "address (name_id, address) VALUES ( 3, '1050 Main Street')"];
	[conn execQuery:sql];
	STAssertTrue([conn errorDescription] == nil, @"Error executing SQL: %@.", sql);
	
	databaseCreated = YES;
}


- (void)setUp
{
	[self raiseAfterFailure];

	NSLog(@"Execute setUp");
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
	STAssertNotNil(testSchema, @"Failed to init Schema object.");
}


- (void)tearDown
{
	NSLog(@"Execute TearDown");

	[testSchema release];
	testSchema = nil;
	
	[conn disconnect];
	[conn release];
	conn = nil;
}


- (void)testTriggerZeroBoundry
{
	[self createDatabase];
	
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

	[self createDatabase];

	results = [testSchema getTriggerNamesFromSchema:PGCocoaTestSchema fromTableName:@"name"];
	STAssertTrue([results count] == 2, @"Failed to return the correct number of triggers.");
}


- (void)testTables
{
	RecordSet * results;

	[self createDatabase];
		
	results = [testSchema getTableNamesFromSchema:PGCocoaTestSchema];
	STAssertTrue([results count] == 2, @"Failed to return the correct number of tables.");

	results = [testSchema getTableNamesFromSchema:nil];
	STAssertTrue([results count] == 0, @"Failed to return 0 number of tables in the public schema.");
}


- (void)testFunctions
{
	RecordSet * results;

	[self createDatabase];
}

- (void)testViews
{
	RecordSet * results;

	[self createDatabase];
		
	results = [testSchema getViewNamesFromSchema:PGCocoaTestSchema];
	STAssertTrue([results count] == 1, @"Failed to return the correct number of views.");
	
	results = [testSchema getViewNamesFromSchema:nil];
	STAssertTrue([results count] == 0, @"Failed to return 0 number of views in the public schema.");
}

- (void)testAddressColumns
{
	RecordSet * results;

	[self createDatabase];
		
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

- (void)testNameColumns
{
	RecordSet * results;
	
	[self createDatabase];
		
	results = [testSchema getTableColumnNamesFromSchema:PGCocoaTestSchema fromTableName:@"name"];
	STAssertTrue([results count] == 7, @"Failed to return the correct number of columns from table 'name'.");
	
	int i;
	NSNumber *aFoundCount = [NSNumber numberWithInt:0];
	NSString* aColumnName;
	NSNumber *newValue;
	NSArray * columnCount = [NSArray arrayWithObjects: aFoundCount, aFoundCount, aFoundCount, aFoundCount, aFoundCount, aFoundCount, aFoundCount, nil];
	NSArray * columnNames = [NSArray arrayWithObjects: @"name_id", @"weight", @"age", @"first", @"last", @"create_time", @"update_time", nil];
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


@end

