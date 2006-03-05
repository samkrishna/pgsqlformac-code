//
//  pgCocoaDBSchemaTest.m
//  pgCocoaDB
//
//  Created by Neil Tiffin on 3/4/06.
//  Copyright 2006 Performance Champions, Inc. All rights reserved.
//
//

#import "pgCocoaDBSchemaTest.h"
#import "Schema.h"
#import "Connection.h"

// Test configuration parameters, Please modify as necessary for your environment
NSString* const PGCocoaTestDatabase = @"pgcocoa_test_database";
NSString* const PGCocoaTestSchema = @"pgcocoa_test_schema";
NSString* const PGCocoaTestUser = @"ntiffin";
NSString* const PGCocoaTestPassword = @"";
NSString* const PGCocoaTestHost = @"localhost";
NSString* const PGCocoaTestPort = @"5432";

// End of configuration parameters
//------------------------------------------------------------------


@implementation pgCocoaDBSchemaTest

- (void)setUp
{
	Connection * conn;
	RecordSet * results;
	NSString* sql;
	
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

	sql = [NSString stringWithFormat:@"%s%@.%@.%s%@.%@.%s", "CREATE TRIGGER create_timestamp BEFORE INSERT ON ",
		PGCocoaTestDatabase, PGCocoaTestSchema, "address \
	FOR EACH ROW EXECUTE PROCEDURE ", PGCocoaTestDatabase, PGCocoaTestSchema, "create_time_stamp()"];
	[conn execQuery:sql];
	STAssertTrue([conn errorDescription] == nil, @"Error executing SQL: %@.", sql);
	
	sql = [NSString stringWithFormat:@"%s%@.%@.%s%@.%@.%s", "CREATE TRIGGER update_timestamp BEFORE UPDATE ON ",
		PGCocoaTestDatabase, PGCocoaTestSchema, "name \
	FOR EACH ROW EXECUTE PROCEDURE ", PGCocoaTestDatabase, PGCocoaTestSchema, "update_time_stamp()"];
	[conn execQuery:sql];
	STAssertTrue([conn errorDescription] == nil, @"Error executing SQL: %@.", sql);
	
	sql = [NSString stringWithFormat:@"%s%@.%@.%s%@.%@.%s", "CREATE TRIGGER update_timestamp BEFORE UPDATE ON ",
		PGCocoaTestDatabase, PGCocoaTestSchema, "address \
	FOR EACH ROW EXECUTE PROCEDURE ", PGCocoaTestDatabase, PGCocoaTestSchema, "update_time_stamp()"];
	[conn execQuery:sql];
	STAssertTrue([conn errorDescription] == nil, @"Error executing SQL: %@.", sql);

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
	
	
	[conn disconnect];
}


- (void)testConnection
{
	Connection * conn;

	conn = [[Connection alloc] init];
	
	// set the connection parameters					
	[conn setUserName:PGCocoaTestUser];
	[conn setPassword:PGCocoaTestPassword];
	[conn setDbName:PGCocoaTestDatabase];	
	[conn setHost:PGCocoaTestHost];
	[conn setPort:PGCocoaTestPort];
	
	// perform the connection
	[conn connect];
	STAssertTrue([conn errorDescription] == nil, @"Error connecting to database %@: %@.", [conn dbName], [conn errorDescription]);
	STAssertTrue([conn isConnected], @"Failed to connect to database %@.", [conn dbName]);

	// start tests
	RecordSet * results;
	NSString * sql;
	Schema * testSchema = [[Schema alloc] initWithConnection:conn];
	NSLog(@"Schema inited.");
	
	STAssertNotNil(testSchema, @"Failed to init Schema object.");
	
	
	
	
	[testSchema release];
	
	NSLog(@"Connection Failed");
	[conn release];
}

@end

