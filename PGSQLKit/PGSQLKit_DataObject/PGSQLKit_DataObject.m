//
//  PGSQLKit_DataObject.m
//  PGSQLKit_DataObject
//
//  Created by Andrew Satori on 1/30/12.
//  Copyright (c) 2012 Druware Software Designs. All rights reserved.
//

#import "PGSQLKit_DataObject.h"
#import "NSData+Base64.h"


@implementation PGSQLKit_DataObject

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
    // create the connectoin
    connection = [[PGSQLConnection alloc] init];
    [connection setServer:@"localhost"];
    [connection setUserName:@"arsatori"];
    [connection setPassword:@""];
    [connection setDatabaseName:@"twj_test"];
    [connection connect];
    
    if (![connection isConnected])
        STFail(@"Unable to connection to server, cannot test data objects without a data server");
    
    [connection retain];
}

- (void)tearDown
{
    // Tear-down code here.
    // release the connectoin
    [connection close];
    [connection release];
    
    [super tearDown];
}

#pragma mark Data Object Tests

- (void)testDataObjectList
{
    // setup the table
    
    NSMutableString *tableCmd = [[NSMutableString alloc] init];
    [tableCmd appendString:@"create table pgdo_test ( "];
    [tableCmd appendString:@"   record_id serial primary key, "];
    [tableCmd appendString:@"   v_char varchar(16) not null "];
    [tableCmd appendString:@")"];
    [connection execCommand:tableCmd];
    [tableCmd release];
    
    // insert a couple of records
    NSMutableString *insertCmd = [[NSMutableString alloc] init];
    [insertCmd appendString:@"insert into pgdo_test (v_char) values ('first test'); "];
    [insertCmd appendString:@"insert into pgdo_test (v_char) values ('second test'); "];
    [connection execCommand:insertCmd];
    [insertCmd release];    

    // create
    
    PGSQLDataObjectList *objList;
    objList = [[PGSQLDataObjectList alloc] initWithConnection:connection 
                                                     forTable:@"pgdo_test" 
                                               withPrimaryKey:@"record_id"];
    
    // do we have 2 records ?
    STAssertTrue([objList count] == 2, @"Count is not the expected 2 records");
    
    // cleanup the table
    tableCmd = [[NSMutableString alloc] init];
    [tableCmd appendString:@"drop table pgdo_test"];
    [connection execCommand:tableCmd];
    [tableCmd release];
}

- (void)testDataObject_abstime
{
    NSNumber *refId;
    NSDate *initialValue = [[NSDate alloc] initWithString:@"2012-01-01 11:15:31 +000"];
    NSDate *updateValue = [[NSDate alloc] initWithString:@"2012-06-06 23:01:01 +000"];
    
    // setup the table
    
    NSMutableString *tableCmd = [[NSMutableString alloc] init];
    [tableCmd appendString:@"create table pgdo_test ( "];
    [tableCmd appendString:@"   record_id serial primary key, "];
    [tableCmd appendString:@"   v_abstime abstime not null "];
    [tableCmd appendString:@")"];
    [connection execCommand:tableCmd];
    [tableCmd release];
    
    // create
    
    PGSQLDataObject *objCreate;
    objCreate = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test" 
                                           withPrimaryKey:@"record_id"];
    
    // set the property
    [objCreate setValue:initialValue forProperty:@"v_abstime"];
    
    // Create -----------------------------------------------------------------
    
    BOOL result = [objCreate save];
    if (result)
    {
        refId  = [[[objCreate refId] copy] retain];
        STAssertTrue([refId longValue] > 0, @"Reference ID is Zero, error: %@", 
                     [objCreate lastError]);
    } else {
        STAssertTrue(result == YES, @"DataObject (v_abstime) Save Failed: %@", 
                     [objCreate lastError]);
        [objCreate release];
        return;
    }
    [objCreate release];
    
    // Read 
    
    PGSQLDataObject *objRead;
    objRead = [[PGSQLDataObject alloc] initWithConnection:connection 
                                               forTable:@"pgdo_test"
                                         withPrimaryKey:@"record_id"
                                                  forId:refId];
    // get the property
    
    STAssertTrue([[objRead valueForProperty:@"v_abstime"] isEqualToDate:initialValue], 
                 @"DataObject (v_abstime) Read Failed");
    
    [objRead release];
    
    // Update 
    
    PGSQLDataObject *objUpdate;
    objUpdate = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"
                                                    forId:refId];
    
    [objUpdate setValue:updateValue forProperty:@"v_abstime"];
    
    STAssertTrue([objUpdate  save], 
                 @"DataObject (v_abstime) Update failed: %@", [objUpdate lastError]);
    [objUpdate release];
    
    // Xml Fetch
    
    PGSQLDataObject *objXmlFetch;
    objXmlFetch = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                   forTable:@"pgdo_test"
                                             withPrimaryKey:@"record_id"
                                                      forId:refId];
    
    NSXMLDocument *xmlDocument = [[NSXMLDocument alloc] initWithRootElement:[objXmlFetch xmlForObject]];
    
    STAssertTrue(([[xmlDocument rootElement] childCount] > 0), 
                 @"DataObject (v_abstime) xmlForObject failed: %@", [objXmlFetch lastError]);
    
    int iFoundChildren = 0;
    for (int i = 0; i < [[xmlDocument rootElement] childCount]; i++)
    {
        NSXMLNode *currentElement = [[xmlDocument rootElement] childAtIndex:i];
        
        if ([[currentElement name] isEqualToString:@"v_abstime"])
        {
            // this is not a string type, so it must be parsed back to an 
            // NSNumber before we can really use it.
            NSDateFormatter* dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
            [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
            [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
            NSDate *currentValue = [dateFormatter dateFromString:[currentElement stringValue]];
            
            STAssertTrue([currentValue isEqualToDate:updateValue], 
                         @"DataObject (v_abstime) xmlForObject Xml value not expected value");
            
            iFoundChildren++;
        }
    }
    STAssertTrue(iFoundChildren >= 1, 
                 @"DataObject (v_abstime) xmlForObject failed to find field in Xml");
    
    [objXmlFetch release];
    
    // Xml Load
    
    PGSQLDataObject *objXmlSet;
    objXmlSet = [[PGSQLDataObject alloc] initWithConnection:connection
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"]; 
    
    STAssertTrue([objXmlSet loadFromXml:[xmlDocument rootElement]], 
                 @"DataObject (v_abstime) loadFromXml Failed: no xml document");
    
    STAssertTrue([[objXmlSet valueForProperty:@"v_abstime"] isEqualToDate:updateValue], 
                 @"DataObject (v_abstime) loadFromXml Failed: value does not match expected");
    
    [objXmlSet setValue:initialValue forProperty:@"v_abstime"];
    
    STAssertTrue([objXmlSet save], 
                 @"DataObject (v_abstime) Save after loadFromXml: %@", [objXmlSet lastError]);
    [objXmlSet release];
    
    // Delete    
    PGSQLDataObject *objDelete;
    objDelete = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"
                                                    forId:refId];
    STAssertTrue([objDelete remove], 
                 @"DataObject Delete failed: %@", [objDelete lastError]);
    [objDelete release];  
    
    // cleanup the table
    tableCmd = [[NSMutableString alloc] init];
    [tableCmd appendString:@"drop table pgdo_test"];
    [connection execCommand:tableCmd];
    [tableCmd release];
}

- (void)testDataObject_bit
{
    NSNumber *refId;
    NSString *initialValue = [[NSString alloc] initWithString:@"01"];
    NSString *updateValue = [[NSString alloc] initWithString:@"10"];
    
    // setup the table
    
    NSMutableString *tableCmd = [[NSMutableString alloc] init];
    [tableCmd appendString:@"create table pgdo_test ( "];
    [tableCmd appendString:@"   record_id serial primary key, "];
    [tableCmd appendString:@"   v_bit bit(2) not null "];
    [tableCmd appendString:@")"];
    [connection execCommand:tableCmd];
    [tableCmd release];
    
    // create
    
    PGSQLDataObject *objCreate;
    objCreate = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test" 
                                           withPrimaryKey:@"record_id"];
    
    // set the property
    [objCreate setValue:initialValue forProperty:@"v_bit"];
    
    // Create -----------------------------------------------------------------
    
    BOOL result = [objCreate save];
    if (result)
    {
        refId  = [[[objCreate refId] copy] retain];
        STAssertTrue([refId longValue] > 0, @"Reference ID is Zero, error: %@", 
                     [objCreate lastError]);
    } else {
        STAssertTrue(result == YES, @"DataObject (v_bit) Save Failed: %@", 
                     [objCreate lastError]);
        [objCreate release];
        return;
    }
    [objCreate release];
    
    // Read 
    
    PGSQLDataObject *objRead;
    objRead = [[PGSQLDataObject alloc] initWithConnection:connection 
                                               forTable:@"pgdo_test"
                                         withPrimaryKey:@"record_id"
                                                  forId:refId];
    // get the property
    
    STAssertTrue([[objRead valueForProperty:@"v_bit"] isEqualToString:initialValue], 
                 @"DataObject (v_bit) Read Failed");
    
    [objRead release];
    
    // Update 
    
    PGSQLDataObject *objUpdate;
    objUpdate = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"
                                                    forId:refId];
    
    [objUpdate setValue:updateValue forProperty:@"v_bit"];
    
    STAssertTrue([objUpdate  save], 
                 @"DataObject (v_bit) Update failed: %@", [objUpdate lastError]);
    [objUpdate release];
    
    // Xml Fetch
    
    PGSQLDataObject *objXmlFetch;
    objXmlFetch = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                   forTable:@"pgdo_test"
                                             withPrimaryKey:@"record_id"
                                                      forId:refId];
    
    NSXMLDocument *xmlDocument = [[NSXMLDocument alloc] initWithRootElement:[objXmlFetch xmlForObject]];
    
    STAssertTrue(([[xmlDocument rootElement] childCount] > 0), 
                 @"DataObject (v_bit) xmlForObject failed: %@", [objXmlFetch lastError]);
    
    int iFoundChildren = 0;
    for (int i = 0; i < [[xmlDocument rootElement] childCount]; i++)
    {
        NSXMLNode *currentElement = [[xmlDocument rootElement] childAtIndex:i];
        
        if ([[currentElement name] isEqualToString:@"v_bit"])
        {
            STAssertTrue([[currentElement stringValue] isEqualToString:updateValue], 
                         @"DataObject (v_bit) xmlForObject Xml value not expected value");
            
            iFoundChildren++;
        }
    }
    STAssertTrue(iFoundChildren >= 1, 
                 @"DataObject (v_bit) xmlForObject failed to find field in Xml");
    
    [objXmlFetch release];
    
    // Xml Load
    
    PGSQLDataObject *objXmlSet;
    objXmlSet = [[PGSQLDataObject alloc] initWithConnection:connection
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"]; 
    
    STAssertTrue([objXmlSet loadFromXml:[xmlDocument rootElement]], 
                 @"DataObject (v_bit) loadFromXml Failed: no xml document");
    
    STAssertTrue([[objXmlSet valueForProperty:@"v_bit"] isEqualToString:updateValue], 
                 @"DataObject (v_bit) loadFromXml Failed: value does not match expected");
    
    [objXmlSet setValue:initialValue forProperty:@"v_bit"];
    
    STAssertTrue([objXmlSet save], 
                 @"DataObject (v_bit) Save after loadFromXml: %@", [objXmlSet lastError]);
    [objXmlSet release];
    
    // Delete    
    PGSQLDataObject *objDelete;
    objDelete = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"
                                                    forId:refId];
    STAssertTrue([objDelete remove], 
                 @"DataObject Delete failed: %@", [objDelete lastError]);
    [objDelete release];  
    
    // cleanup the table
    tableCmd = [[NSMutableString alloc] init];
    [tableCmd appendString:@"drop table pgdo_test"];
    [connection execCommand:tableCmd];
    [tableCmd release];
}

- (void)testDataObject_boolean
{
    NSNumber *refId;
    
    // setup the table
    
    NSMutableString *tableCmd = [[NSMutableString alloc] init];
    [tableCmd appendString:@"create table pgdo_test ( "];
    [tableCmd appendString:@"   record_id serial primary key, "];
    [tableCmd appendString:@"   v_boolean boolean not null "];
    [tableCmd appendString:@")"];
    [connection execCommand:tableCmd];
    [tableCmd release];
    
    // create
    
    PGSQLDataObject *objCreate;
    objCreate = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test" 
                                           withPrimaryKey:@"record_id"];
    
    // set the property
    [objCreate setValue:@"yes" forProperty:@"v_boolean"];
    
    // Create -----------------------------------------------------------------
    
    BOOL result = [objCreate save];
    if (result)
    {
        refId  = [[[objCreate refId] copy] retain];
        STAssertTrue([refId longValue] > 0, @"Reference ID is Zero, error: %@", 
                     [objCreate lastError]);
    } else {
        STAssertTrue(result == YES, @"DataObject (v_boolean) Save Failed: %@", 
                     [objCreate lastError]);
        [objCreate release];
        return;
    }
    [objCreate release];
    
    // Read 
    
    PGSQLDataObject *objRead;
    objRead = [[PGSQLDataObject alloc] initWithConnection:connection 
                                               forTable:@"pgdo_test"
                                         withPrimaryKey:@"record_id"
                                                  forId:refId];
    // get the property
    
    STAssertTrue([[objRead valueForProperty:@"v_boolean"] isEqualToString:@"yes"], 
                 @"DataObject (v_boolean) Read Failed");
    
    [objRead release];
    
    // Update 
    
    PGSQLDataObject *objUpdate;
    objUpdate = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"
                                                    forId:refId];
    
    [objUpdate setValue:@"no" forProperty:@"v_boolean"];
    
    STAssertTrue([objUpdate  save], 
                 @"DataObject (v_boolean) Update failed: %@", [objUpdate lastError]);
    [objUpdate release];
    
    // Xml Fetch
    
    PGSQLDataObject *objXmlFetch;
    objXmlFetch = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                   forTable:@"pgdo_test"
                                             withPrimaryKey:@"record_id"
                                                      forId:refId];
    
    NSXMLDocument *xmlDocument = [[NSXMLDocument alloc] initWithRootElement:[objXmlFetch xmlForObject]];
    
    STAssertTrue(([[xmlDocument rootElement] childCount] > 0), 
                 @"DataObject (v_boolean) xmlForObject failed: %@", [objXmlFetch lastError]);
    
    int iFoundChildren = 0;
    for (int i = 0; i < [[xmlDocument rootElement] childCount]; i++)
    {
        NSXMLNode *currentElement = [[xmlDocument rootElement] childAtIndex:i];
        
        if ([[currentElement name] isEqualToString:@"v_boolean"])
        {
            STAssertTrue([[currentElement stringValue] isEqualToString:@"no"], 
                         @"DataObject (v_boolean) xmlForObject Xml value not expected value");
            
            iFoundChildren++;
        }
    }
    STAssertTrue(iFoundChildren >= 1, 
                 @"DataObject (v_boolean) xmlForObject failed to find field in Xml");
    
    [objXmlFetch release];
    
    // Xml Load
    
    PGSQLDataObject *objXmlSet;
    objXmlSet = [[PGSQLDataObject alloc] initWithConnection:connection
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"]; 
    
    STAssertTrue([objXmlSet loadFromXml:[xmlDocument rootElement]], 
                 @"DataObject (v_boolean) loadFromXml Failed: no xml document");
    
    STAssertTrue([[objXmlSet valueForProperty:@"v_boolean"] isEqualToString:@"no"], 
                 @"DataObject (v_boolean) loadFromXml Failed: value does not match expected");
    
    [objXmlSet setValue:@"xml test" forProperty:@"v_boolean"];
    
    STAssertTrue([objXmlSet save], 
                 @"DataObject (v_boolean) Save after loadFromXml: %@", [objXmlSet lastError]);
    [objXmlSet release];
    
    // Delete    
    PGSQLDataObject *objDelete;
    objDelete = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"
                                                    forId:refId];
    STAssertTrue([objDelete remove], 
                 @"DataObject Delete failed: %@", [objDelete lastError]);
    [objDelete release];  
    
    // cleanup the table
    tableCmd = [[NSMutableString alloc] init];
    [tableCmd appendString:@"drop table pgdo_test"];
    [connection execCommand:tableCmd];
    [tableCmd release];
}

- (void)testDataObject_bytea
{
    NSNumber *refId;
    NSURL *initialUrl = [[NSURL alloc] initWithString:@"http://www.postgresqlformac.com/_Media/pgsql_login-2.png"];
    NSURL *updateUrl = [[NSURL alloc] initWithString:@"http://www.postgresqlformac.com/_Media/mockup-query-tool_med.png"];
    NSData *initialValue = [[NSData alloc] initWithContentsOfURL:initialUrl];
    NSData *updateValue = [[NSData alloc] initWithContentsOfURL:updateUrl];
    [initialUrl release];
    [updateUrl release];
    
    // setup the table
    
    NSMutableString *tableCmd = [[NSMutableString alloc] init];
    [tableCmd appendString:@"create table pgdo_test ( "];
    [tableCmd appendString:@"   record_id serial primary key, "];
    [tableCmd appendString:@"   v_bytea bytea not null "];
    [tableCmd appendString:@")"];
    [connection execCommand:tableCmd];
    [tableCmd release];
    
    // create
    
    PGSQLDataObject *objCreate;
    objCreate = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test" 
                                           withPrimaryKey:@"record_id"];
    
    // set the property
    [objCreate setValue:initialValue forProperty:@"v_bytea"];
    
    // Create -----------------------------------------------------------------
    
    BOOL result = [objCreate save];
    if (result)
    {
        refId  = [[[objCreate refId] copy] retain];
        STAssertTrue([refId longValue] > 0, @"Reference ID is Zero, error: %@", 
                     [objCreate lastError]);
    } else {
        STAssertTrue(result == YES, @"DataObject (v_bytea) Save Failed: %@", 
                     [objCreate lastError]);
        [objCreate release];
        return;
    }
    [objCreate release];
    
    // Read 
    
    PGSQLDataObject *objRead;
    objRead = [[PGSQLDataObject alloc] initWithConnection:connection 
                                               forTable:@"pgdo_test"
                                         withPrimaryKey:@"record_id"
                                                  forId:refId];
    // get the property
    
    STAssertTrue([[objRead valueForProperty:@"v_bytea"] isEqualToData:initialValue], 
                 @"DataObject (v_bytea) Read Failed");
    
    [objRead release];
    
    // Update 
    
    PGSQLDataObject *objUpdate;
    objUpdate = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"
                                                    forId:refId];
    
    [objUpdate setValue:updateValue forProperty:@"v_bytea"];
    
    STAssertTrue([objUpdate  save], 
                 @"DataObject (v_bytea) Update failed: %@", [objUpdate lastError]);
    [objUpdate release];
    
    // Xml Fetch
    
    PGSQLDataObject *objXmlFetch;
    objXmlFetch = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                   forTable:@"pgdo_test"
                                             withPrimaryKey:@"record_id"
                                                      forId:refId];
    
    NSXMLDocument *xmlDocument = [[NSXMLDocument alloc] initWithRootElement:[objXmlFetch xmlForObject]];
    NSLog(@"%@", [[xmlDocument rootElement] XMLString]);
    STAssertTrue(([[xmlDocument rootElement] childCount] > 0), 
                 @"DataObject (v_bytea) xmlForObject failed: %@", [objXmlFetch lastError]);
    
    int iFoundChildren = 0;
    for (int i = 0; i < [[xmlDocument rootElement] childCount]; i++)
    {
        NSXMLNode *currentElement = [[xmlDocument rootElement] childAtIndex:i];
        
        if ([[currentElement name] isEqualToString:@"v_bytea"])
        {
            NSString *currentValue = [currentElement stringValue];
            
            NSData* xmlData = [NSData dataFromBase64String:currentValue];
            STAssertTrue([xmlData isEqualToData:updateValue], 
                         @"DataObject (v_bytea) xmlForObject Xml value not expected value");
            
            iFoundChildren++;
        }
    }
    STAssertTrue(iFoundChildren >= 1, 
                 @"DataObject (v_bytea) xmlForObject failed to find field in Xml");
    
    [objXmlFetch release];
    
    // Xml Load
    
    PGSQLDataObject *objXmlSet;
    objXmlSet = [[PGSQLDataObject alloc] initWithConnection:connection
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"]; 
    
    STAssertTrue([objXmlSet loadFromXml:[xmlDocument rootElement]], 
                 @"DataObject (v_bytea) loadFromXml Failed: no xml document");
    
    STAssertTrue([[objXmlSet valueForProperty:@"v_bytea"] isEqualToData:updateValue], 
                 @"DataObject (v_bytea) loadFromXml Failed: value does not match expected");
    
    [objXmlSet setValue:initialValue forProperty:@"v_bytea"];
    
    STAssertTrue([objXmlSet save], 
                 @"DataObject (v_bytea) Save after loadFromXml: %@", [objXmlSet lastError]);
    [objXmlSet release];
    
    // Delete
    
    PGSQLDataObject *objDelete;
    objDelete = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"
                                                    forId:refId];
    STAssertTrue([objDelete remove], 
                 @"DataObject Delete failed: %@", [objDelete lastError]);
    [objDelete release];  
    
    // cleanup the table
    tableCmd = [[NSMutableString alloc] init];
    [tableCmd appendString:@"drop table pgdo_test"];
    [connection execCommand:tableCmd];
    [tableCmd release];
}

- (void)testDataObject_char
{
    NSNumber *refId;
    
    // setup the table
    
    NSMutableString *tableCmd = [[NSMutableString alloc] init];
    [tableCmd appendString:@"create table pgdo_test ( "];
    [tableCmd appendString:@"   record_id serial primary key, "];
    [tableCmd appendString:@"   v_char char(16) not null "];
    [tableCmd appendString:@")"];
    [connection execCommand:tableCmd];
    [tableCmd release];
    
    // create
    
    PGSQLDataObject *objCreate;
    objCreate = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test" 
                                           withPrimaryKey:@"record_id"];
    
    // set the property
    [objCreate setValue:@"unit test" forProperty:@"v_char"];
    
    // Create -----------------------------------------------------------------
    
    BOOL result = [objCreate save];
    if (result)
    {
        refId  = [[[objCreate refId] copy] retain];
        STAssertTrue([refId longValue] > 0, @"Reference ID is Zero, error: %@", 
                     [objCreate lastError]);
    } else {
        STAssertTrue(result == YES, @"DataObject (v_char) Save Failed: %@", 
                     [objCreate lastError]);
        [objCreate release];
        return;
    }
    [objCreate release];
    
    // Read 
    
    PGSQLDataObject *objRead;
    objRead = [[PGSQLDataObject alloc] initWithConnection:connection 
                                               forTable:@"pgdo_test"
                                         withPrimaryKey:@"record_id"
                                                  forId:refId];
    // get the property
    
    STAssertTrue([[objRead valueForProperty:@"v_char"] isEqualToString:@"unit test       "], 
                 @"DataObject (v_char) Read Failed");
    
    [objRead release];
    
    // Update 
    
    PGSQLDataObject *objUpdate;
    objUpdate = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"
                                                    forId:refId];
    
    [objUpdate setValue:@"update test" forProperty:@"v_char"];
    
    STAssertTrue([objUpdate  save], 
                 @"DataObject (v_char) Update failed: %@", [objUpdate lastError]);
    [objUpdate release];
    
    // Xml Fetch
    
    PGSQLDataObject *objXmlFetch;
    objXmlFetch = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                   forTable:@"pgdo_test"
                                             withPrimaryKey:@"record_id"
                                                      forId:refId];
    
    NSXMLDocument *xmlDocument = [[NSXMLDocument alloc] initWithRootElement:[objXmlFetch xmlForObject]];
    
    STAssertTrue(([[xmlDocument rootElement] childCount] > 0), 
                 @"DataObject (v_char) xmlForObject failed: %@", [objXmlFetch lastError]);
    
    int iFoundChildren = 0;
    for (int i = 0; i < [[xmlDocument rootElement] childCount]; i++)
    {
        NSXMLNode *currentElement = [[xmlDocument rootElement] childAtIndex:i];
        
        if ([[currentElement name] isEqualToString:@"v_char"])
        {
            STAssertTrue([[currentElement stringValue] isEqualToString:@"update test     "], 
                         @"DataObject (v_char) xmlForObject Xml value not expected value");
            
            iFoundChildren++;
        }
    }
    STAssertTrue(iFoundChildren >= 1, 
                 @"DataObject (v_char) xmlForObject failed to find field in Xml");
    
    [objXmlFetch release];
    
    // Xml Load
    
    PGSQLDataObject *objXmlSet;
    objXmlSet = [[PGSQLDataObject alloc] initWithConnection:connection
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"]; 
    
    STAssertTrue([objXmlSet loadFromXml:[xmlDocument rootElement]], 
                 @"DataObject (v_char) loadFromXml Failed: no xml document");
    
    STAssertTrue([[objXmlSet valueForProperty:@"v_char"] isEqualToString:@"update test     "], 
                 @"DataObject (v_char) loadFromXml Failed: value does not match expected");
    
    [objXmlSet setValue:@"xml test" forProperty:@"v_char"];
    
    STAssertTrue([objXmlSet save], 
                 @"DataObject (v_char) Save after loadFromXml: %@", [objXmlSet lastError]);
    [objXmlSet release];
    
    // Delete    
    PGSQLDataObject *objDelete;
    objDelete = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"
                                                    forId:refId];
    STAssertTrue([objDelete remove], 
                 @"DataObject Delete failed: %@", [objDelete lastError]);
    [objDelete release];  
    
    // cleanup the table
    tableCmd = [[NSMutableString alloc] init];
    [tableCmd appendString:@"drop table pgdo_test"];
    [connection execCommand:tableCmd];
    [tableCmd release];
}

- (void)testDataObject_date
{
    NSNumber *refId;
    NSDate *initialValue = [[NSDate alloc] initWithString:@"2012-01-01 00:00:00 +000"];
    NSDate *updateValue = [[NSDate alloc] initWithString:@"2012-06-06 00:00:00 +000"];
    
    // setup the table
    
    NSMutableString *tableCmd = [[NSMutableString alloc] init];
    [tableCmd appendString:@"create table pgdo_test ( "];
    [tableCmd appendString:@"   record_id serial primary key, "];
    [tableCmd appendString:@"   v_date date not null "];
    [tableCmd appendString:@")"];
    [connection execCommand:tableCmd];
    [tableCmd release];
    
    // create
    
    PGSQLDataObject *objCreate;
    objCreate = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test" 
                                           withPrimaryKey:@"record_id"];
    
    // set the property
    [objCreate setValue:initialValue forProperty:@"v_date"];
    
    // Create -----------------------------------------------------------------
    
    BOOL result = [objCreate save];
    if (result)
    {
        refId  = [[[objCreate refId] copy] retain];
        STAssertTrue([refId longValue] > 0, @"Reference ID is Zero, error: %@", 
                     [objCreate lastError]);
    } else {
        STAssertTrue(result == YES, @"DataObject (v_date) Save Failed: %@", 
                     [objCreate lastError]);
        [objCreate release];
        return;
    }
    [objCreate release];
    
    // Read 
    
    PGSQLDataObject *objRead;
    objRead = [[PGSQLDataObject alloc] initWithConnection:connection 
                                               forTable:@"pgdo_test"
                                         withPrimaryKey:@"record_id"
                                                  forId:refId];
    // get the property
    
    STAssertTrue([[objRead valueForProperty:@"v_date"] isEqualToDate:initialValue], 
                 @"DataObject (v_date) Read Failed");
    
    [objRead release];
    
    // Update 
    
    PGSQLDataObject *objUpdate;
    objUpdate = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"
                                                    forId:refId];
    
    [objUpdate setValue:updateValue forProperty:@"v_date"];
    
    STAssertTrue([objUpdate  save], 
                 @"DataObject (v_date) Update failed: %@", [objUpdate lastError]);
    [objUpdate release];
    
    // Xml Fetch
    
    PGSQLDataObject *objXmlFetch;
    objXmlFetch = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                   forTable:@"pgdo_test"
                                             withPrimaryKey:@"record_id"
                                                      forId:refId];
    
    NSXMLDocument *xmlDocument = [[NSXMLDocument alloc] initWithRootElement:[objXmlFetch xmlForObject]];
    
    STAssertTrue(([[xmlDocument rootElement] childCount] > 0), 
                 @"DataObject (v_date) xmlForObject failed: %@", [objXmlFetch lastError]);
    
    int iFoundChildren = 0;
    for (int i = 0; i < [[xmlDocument rootElement] childCount]; i++)
    {
        NSXMLNode *currentElement = [[xmlDocument rootElement] childAtIndex:i];
        
        if ([[currentElement name] isEqualToString:@"v_date"])
        {
            // this is not a string type, so it must be parsed back to an 
            // NSNumber before we can really use it.
            NSDateFormatter* dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
            [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
            [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
            NSDate *currentValue = [dateFormatter dateFromString:[currentElement stringValue]];
            
            STAssertTrue([currentValue isEqualToDate:updateValue], 
                         @"DataObject (v_date) xmlForObject Xml value not expected value");
            
            iFoundChildren++;
        }
    }
    STAssertTrue(iFoundChildren >= 1, 
                 @"DataObject (v_date) xmlForObject failed to find field in Xml");
    
    [objXmlFetch release];
    
    // Xml Load
    
    PGSQLDataObject *objXmlSet;
    objXmlSet = [[PGSQLDataObject alloc] initWithConnection:connection
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"]; 
    
    STAssertTrue([objXmlSet loadFromXml:[xmlDocument rootElement]], 
                 @"DataObject (v_date) loadFromXml Failed: no xml document");
    
    STAssertTrue([[objXmlSet valueForProperty:@"v_date"] isEqualToDate:updateValue], 
                 @"DataObject (v_date) loadFromXml Failed: value does not match expected");
    
    [objXmlSet setValue:initialValue forProperty:@"v_date"];
    
    STAssertTrue([objXmlSet save], 
                 @"DataObject (v_date) Save after loadFromXml: %@", [objXmlSet lastError]);
    [objXmlSet release];
    
    // Delete    
    PGSQLDataObject *objDelete;
    objDelete = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"
                                                    forId:refId];
    STAssertTrue([objDelete remove], 
                 @"DataObject Delete failed: %@", [objDelete lastError]);
    [objDelete release];  
    
    // cleanup the table
    tableCmd = [[NSMutableString alloc] init];
    [tableCmd appendString:@"drop table pgdo_test"];
    [connection execCommand:tableCmd];
    [tableCmd release];
}

- (void)testDataObject_float4
{
    NSNumber *refId;
    NSNumber *initialValue = [[NSNumber alloc] initWithFloat:101.105];
    NSNumber *updateValue = [[NSNumber alloc] initWithFloat:501.011];
    
    // setup the table
    
    NSMutableString *tableCmd = [[NSMutableString alloc] init];
    [tableCmd appendString:@"create table pgdo_test ( "];
    [tableCmd appendString:@"   record_id serial primary key, "];
    [tableCmd appendString:@"   v_float4 float4 not null "];
    [tableCmd appendString:@")"];
    [connection execCommand:tableCmd];
    [tableCmd release];
    
    // create
    
    PGSQLDataObject *objCreate;
    objCreate = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test" 
                                           withPrimaryKey:@"record_id"];
    
    // set the property
    [objCreate setValue:initialValue forProperty:@"v_float4"];
    
    // Create -----------------------------------------------------------------
    
    BOOL result = [objCreate save];
    if (result)
    {
        refId  = [[[objCreate refId] copy] retain];
        STAssertTrue([refId longValue] > 0, @"Reference ID is Zero, error: %@", 
                     [objCreate lastError]);
    } else {
        STAssertTrue(result == YES, @"DataObject (v_float4) Save Failed: %@", 
                     [objCreate lastError]);
        [objCreate release];
        return;
    }
    [objCreate release];
    
    // Read 
    
    PGSQLDataObject *objRead;
    objRead = [[PGSQLDataObject alloc] initWithConnection:connection 
                                               forTable:@"pgdo_test"
                                         withPrimaryKey:@"record_id"
                                                  forId:refId];
    // get the property
    
    STAssertTrue([[objRead valueForProperty:@"v_float4"] isEqualToNumber:initialValue], 
                 @"DataObject (v_bit) Read Failed");
    
    [objRead release];
    
    // Update 
    
    PGSQLDataObject *objUpdate;
    objUpdate = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"
                                                    forId:refId];
    
    [objUpdate setValue:updateValue forProperty:@"v_float4"];
    
    STAssertTrue([objUpdate  save], 
                 @"DataObject (v_float4) Update failed: %@", [objUpdate lastError]);
    [objUpdate release];
    
    // Xml Fetch
    
    PGSQLDataObject *objXmlFetch;
    objXmlFetch = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                   forTable:@"pgdo_test"
                                             withPrimaryKey:@"record_id"
                                                      forId:refId];
    
    NSXMLDocument *xmlDocument = [[NSXMLDocument alloc] initWithRootElement:[objXmlFetch xmlForObject]];
    
    STAssertTrue(([[xmlDocument rootElement] childCount] > 0), 
                 @"DataObject (v_float4) xmlForObject failed: %@", [objXmlFetch lastError]);
    
    int iFoundChildren = 0;
    for (int i = 0; i < [[xmlDocument rootElement] childCount]; i++)
    {
        NSXMLNode *currentElement = [[xmlDocument rootElement] childAtIndex:i];
        
        if ([[currentElement name] isEqualToString:@"v_float4"])
        {
            // this is not a string type, so it must be parsed back to an 
            // NSNumber before we can really use it.
            NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
            [f setNumberStyle:NSNumberFormatterDecimalStyle];
            NSNumber *currentValue = [f numberFromString:[currentElement stringValue]];
            [f release];
            
            STAssertTrue([currentValue floatValue] == [updateValue floatValue], 
                         @"DataObject (v_float4) xmlForObject Xml value not expected value");
            
            iFoundChildren++;
        }
    }
    STAssertTrue(iFoundChildren >= 1, 
                 @"DataObject (v_float4) xmlForObject failed to find field in Xml");
    
    [objXmlFetch release];
    
    // Xml Load
    
    PGSQLDataObject *objXmlSet;
    objXmlSet = [[PGSQLDataObject alloc] initWithConnection:connection
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"]; 
    
    STAssertTrue([objXmlSet loadFromXml:[xmlDocument rootElement]], 
                 @"DataObject (v_float4) loadFromXml Failed: no xml document");
    
    STAssertTrue([[objXmlSet valueForProperty:@"v_float4"] floatValue] == [updateValue floatValue], 
                 @"DataObject (v_float4) loadFromXml Failed: value does not match expected");
    
    [objXmlSet setValue:initialValue forProperty:@"v_float4"];
    
    STAssertTrue([objXmlSet save], 
                 @"DataObject (v_float4) Save after loadFromXml: %@", [objXmlSet lastError]);
    [objXmlSet release];
    
    // Delete    
    PGSQLDataObject *objDelete;
    objDelete = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"
                                                    forId:refId];
    STAssertTrue([objDelete remove], 
                 @"DataObject Delete failed: %@", [objDelete lastError]);
    [objDelete release];  
    
    // cleanup the table
    tableCmd = [[NSMutableString alloc] init];
    [tableCmd appendString:@"drop table pgdo_test"];
    [connection execCommand:tableCmd];
    [tableCmd release];
}

- (void)testDataObject_float8
{
    NSNumber *refId;
    NSNumber *initialValue = [[NSNumber alloc] initWithFloat:101.105];
    NSNumber *updateValue = [[NSNumber alloc] initWithFloat:501.011];
    
    // setup the table
    
    NSMutableString *tableCmd = [[NSMutableString alloc] init];
    [tableCmd appendString:@"create table pgdo_test ( "];
    [tableCmd appendString:@"   record_id serial primary key, "];
    [tableCmd appendString:@"   v_float8 float8 not null "];
    [tableCmd appendString:@")"];
    [connection execCommand:tableCmd];
    [tableCmd release];
    
    // create
    
    PGSQLDataObject *objCreate;
    objCreate = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test" 
                                           withPrimaryKey:@"record_id"];
    
    // set the property
    [objCreate setValue:initialValue forProperty:@"v_float8"];
    
    // Create -----------------------------------------------------------------
    
    BOOL result = [objCreate save];
    if (result)
    {
        refId  = [[[objCreate refId] copy] retain];
        STAssertTrue([refId longValue] > 0, @"Reference ID is Zero, error: %@", 
                     [objCreate lastError]);
    } else {
        STAssertTrue(result == YES, @"DataObject (v_float8) Save Failed: %@", 
                     [objCreate lastError]);
        [objCreate release];
        return;
    }
    [objCreate release];
    
    // Read 
    
    PGSQLDataObject *objRead;
    objRead = [[PGSQLDataObject alloc] initWithConnection:connection 
                                               forTable:@"pgdo_test"
                                         withPrimaryKey:@"record_id"
                                                  forId:refId];
    // get the property
    
    STAssertTrue([[objRead valueForProperty:@"v_float8"] isEqualToNumber:initialValue], 
                 @"DataObject (v_bit) Read Failed");
    
    [objRead release];
    
    // Update 
    
    PGSQLDataObject *objUpdate;
    objUpdate = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"
                                                    forId:refId];
    
    [objUpdate setValue:updateValue forProperty:@"v_float8"];
    
    STAssertTrue([objUpdate  save], 
                 @"DataObject (v_float8) Update failed: %@", [objUpdate lastError]);
    [objUpdate release];
    
    // Xml Fetch
    
    PGSQLDataObject *objXmlFetch;
    objXmlFetch = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                   forTable:@"pgdo_test"
                                             withPrimaryKey:@"record_id"
                                                      forId:refId];
    
    NSXMLDocument *xmlDocument = [[NSXMLDocument alloc] initWithRootElement:[objXmlFetch xmlForObject]];
    
    STAssertTrue(([[xmlDocument rootElement] childCount] > 0), 
                 @"DataObject (v_float8) xmlForObject failed: %@", [objXmlFetch lastError]);
    
    int iFoundChildren = 0;
    for (int i = 0; i < [[xmlDocument rootElement] childCount]; i++)
    {
        NSXMLNode *currentElement = [[xmlDocument rootElement] childAtIndex:i];
        
        if ([[currentElement name] isEqualToString:@"v_float8"])
        {
            // this is not a string type, so it must be parsed back to an 
            // NSNumber before we can really use it.
            NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
            [f setNumberStyle:NSNumberFormatterDecimalStyle];
            NSNumber *currentValue = [f numberFromString:[currentElement stringValue]];
            [f release];
            
            STAssertTrue([currentValue floatValue] == [updateValue floatValue], 
                         @"DataObject (v_float8) xmlForObject Xml value not expected value");
            
            iFoundChildren++;
        }
    }
    STAssertTrue(iFoundChildren >= 1, 
                 @"DataObject (v_float8) xmlForObject failed to find field in Xml");
    
    [objXmlFetch release];
    
    // Xml Load
    
    PGSQLDataObject *objXmlSet;
    objXmlSet = [[PGSQLDataObject alloc] initWithConnection:connection
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"]; 
    
    STAssertTrue([objXmlSet loadFromXml:[xmlDocument rootElement]], 
                 @"DataObject (v_float8) loadFromXml Failed: no xml document");
    
    STAssertTrue([[objXmlSet valueForProperty:@"v_float8"] floatValue] == [updateValue floatValue], 
                 @"DataObject (v_float8) loadFromXml Failed: value does not match expected");
    
    [objXmlSet setValue:initialValue forProperty:@"v_float8"];
    
    STAssertTrue([objXmlSet save], 
                 @"DataObject (v_float8) Save after loadFromXml: %@", [objXmlSet lastError]);
    [objXmlSet release];
    
    // Delete    
    PGSQLDataObject *objDelete;
    objDelete = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"
                                                    forId:refId];
    STAssertTrue([objDelete remove], 
                 @"DataObject Delete failed: %@", [objDelete lastError]);
    [objDelete release];  
    
    // cleanup the table
    tableCmd = [[NSMutableString alloc] init];
    [tableCmd appendString:@"drop table pgdo_test"];
    [connection execCommand:tableCmd];
    [tableCmd release];
}

- (void)testDataObject_int2
{
    NSNumber *refId;
    NSNumber *initialValue = [[NSNumber alloc] initWithInt:256];
    NSNumber *updateValue = [[NSNumber alloc] initWithFloat:512];
    
    // setup the table
    
    NSMutableString *tableCmd = [[NSMutableString alloc] init];
    [tableCmd appendString:@"create table pgdo_test ( "];
    [tableCmd appendString:@"   record_id serial primary key, "];
    [tableCmd appendString:@"   v_int2 int2 not null "];
    [tableCmd appendString:@")"];
    [connection execCommand:tableCmd];
    [tableCmd release];
    
    // create
    
    PGSQLDataObject *objCreate;
    objCreate = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test" 
                                           withPrimaryKey:@"record_id"];
    
    // set the property
    [objCreate setValue:initialValue forProperty:@"v_int2"];
    
    // Create -----------------------------------------------------------------
    
    BOOL result = [objCreate save];
    if (result)
    {
        refId  = [[[objCreate refId] copy] retain];
        STAssertTrue([refId longValue] > 0, @"Reference ID is Zero, error: %@", 
                     [objCreate lastError]);
    } else {
        STAssertTrue(result == YES, @"DataObject (v_int2) Save Failed: %@", 
                     [objCreate lastError]);
        [objCreate release];
        return;
    }
    [objCreate release];
    
    // Read 
    
    PGSQLDataObject *objRead;
    objRead = [[PGSQLDataObject alloc] initWithConnection:connection 
                                               forTable:@"pgdo_test"
                                         withPrimaryKey:@"record_id"
                                                  forId:refId];
    // get the property
    
    STAssertTrue([[objRead valueForProperty:@"v_int2"] isEqualToNumber:initialValue], 
                 @"DataObject (v_int2) Read Failed");
    
    [objRead release];
    
    // Update 
    
    PGSQLDataObject *objUpdate;
    objUpdate = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"
                                                    forId:refId];
    
    [objUpdate setValue:updateValue forProperty:@"v_int2"];
    
    STAssertTrue([objUpdate  save], 
                 @"DataObject (v_int2) Update failed: %@", [objUpdate lastError]);
    [objUpdate release];
    
    // Xml Fetch
    
    PGSQLDataObject *objXmlFetch;
    objXmlFetch = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                   forTable:@"pgdo_test"
                                             withPrimaryKey:@"record_id"
                                                      forId:refId];
    
    NSXMLDocument *xmlDocument = [[NSXMLDocument alloc] initWithRootElement:[objXmlFetch xmlForObject]];
    
    STAssertTrue(([[xmlDocument rootElement] childCount] > 0), 
                 @"DataObject (v_int2) xmlForObject failed: %@", [objXmlFetch lastError]);
    
    int iFoundChildren = 0;
    for (int i = 0; i < [[xmlDocument rootElement] childCount]; i++)
    {
        NSXMLNode *currentElement = [[xmlDocument rootElement] childAtIndex:i];
        
        if ([[currentElement name] isEqualToString:@"v_int2"])
        {
            // this is not a string type, so it must be parsed back to an 
            // NSNumber before we can really use it.
            NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
            [f setNumberStyle:NSNumberFormatterDecimalStyle];
            NSNumber *currentValue = [f numberFromString:[currentElement stringValue]];
            [f release];
            
            STAssertTrue([currentValue intValue] == [updateValue intValue], 
                         @"DataObject (v_int2) xmlForObject Xml value not expected value");
            
            iFoundChildren++;
        }
    }
    STAssertTrue(iFoundChildren >= 1, 
                 @"DataObject (v_int2) xmlForObject failed to find field in Xml");
    
    [objXmlFetch release];
    
    // Xml Load
    
    PGSQLDataObject *objXmlSet;
    objXmlSet = [[PGSQLDataObject alloc] initWithConnection:connection
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"]; 
    
    STAssertTrue([objXmlSet loadFromXml:[xmlDocument rootElement]], 
                 @"DataObject (v_int2) loadFromXml Failed: no xml document");
    
    STAssertTrue([[objXmlSet valueForProperty:@"v_int2"] intValue] == [updateValue intValue], 
                 @"DataObject (v_int2) loadFromXml Failed: value does not match expected");
    
    [objXmlSet setValue:initialValue forProperty:@"v_int2"];
    
    STAssertTrue([objXmlSet save], 
                 @"DataObject (v_int2) Save after loadFromXml: %@", [objXmlSet lastError]);
    [objXmlSet release];
    
    // Delete    
    PGSQLDataObject *objDelete;
    objDelete = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"
                                                    forId:refId];
    STAssertTrue([objDelete remove], 
                 @"DataObject Delete failed: %@", [objDelete lastError]);
    [objDelete release];  
    
    // cleanup the table
    tableCmd = [[NSMutableString alloc] init];
    [tableCmd appendString:@"drop table pgdo_test"];
    [connection execCommand:tableCmd];
    [tableCmd release];
}

- (void)testDataObject_int4
{
    NSNumber *refId;
    NSNumber *initialValue = [[NSNumber alloc] initWithInt:256];
    NSNumber *updateValue = [[NSNumber alloc] initWithFloat:512];
    
    // setup the table
    
    NSMutableString *tableCmd = [[NSMutableString alloc] init];
    [tableCmd appendString:@"create table pgdo_test ( "];
    [tableCmd appendString:@"   record_id serial primary key, "];
    [tableCmd appendString:@"   v_int4 int4 not null "];
    [tableCmd appendString:@")"];
    [connection execCommand:tableCmd];
    [tableCmd release];
    
    // create
    
    PGSQLDataObject *objCreate;
    objCreate = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test" 
                                           withPrimaryKey:@"record_id"];
    
    // set the property
    [objCreate setValue:initialValue forProperty:@"v_int4"];
    
    // Create -----------------------------------------------------------------
    
    BOOL result = [objCreate save];
    if (result)
    {
        refId  = [[[objCreate refId] copy] retain];
        STAssertTrue([refId longValue] > 0, @"Reference ID is Zero, error: %@", 
                     [objCreate lastError]);
    } else {
        STAssertTrue(result == YES, @"DataObject (v_int4) Save Failed: %@", 
                     [objCreate lastError]);
        [objCreate release];
        return;
    }
    [objCreate release];
    
    // Read 
    
    PGSQLDataObject *objRead;
    objRead = [[PGSQLDataObject alloc] initWithConnection:connection 
                                               forTable:@"pgdo_test"
                                         withPrimaryKey:@"record_id"
                                                  forId:refId];
    // get the property
    
    STAssertTrue([[objRead valueForProperty:@"v_int4"] isEqualToNumber:initialValue], 
                 @"DataObject (v_bit) Read Failed");
    
    [objRead release];
    
    // Update 
    
    PGSQLDataObject *objUpdate;
    objUpdate = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"
                                                    forId:refId];
    
    [objUpdate setValue:updateValue forProperty:@"v_int4"];
    
    STAssertTrue([objUpdate  save], 
                 @"DataObject (v_int4) Update failed: %@", [objUpdate lastError]);
    [objUpdate release];
    
    // Xml Fetch
    
    PGSQLDataObject *objXmlFetch;
    objXmlFetch = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                   forTable:@"pgdo_test"
                                             withPrimaryKey:@"record_id"
                                                      forId:refId];
    
    NSXMLDocument *xmlDocument = [[NSXMLDocument alloc] initWithRootElement:[objXmlFetch xmlForObject]];
    
    STAssertTrue(([[xmlDocument rootElement] childCount] > 0), 
                 @"DataObject (v_int4) xmlForObject failed: %@", [objXmlFetch lastError]);
    
    int iFoundChildren = 0;
    for (int i = 0; i < [[xmlDocument rootElement] childCount]; i++)
    {
        NSXMLNode *currentElement = [[xmlDocument rootElement] childAtIndex:i];
        
        if ([[currentElement name] isEqualToString:@"v_int4"])
        {
            // this is not a string type, so it must be parsed back to an 
            // NSNumber before we can really use it.
            NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
            [f setNumberStyle:NSNumberFormatterDecimalStyle];
            NSNumber *currentValue = [f numberFromString:[currentElement stringValue]];
            [f release];
            
            STAssertTrue([currentValue intValue] == [updateValue intValue], 
                         @"DataObject (v_int4) xmlForObject Xml value not expected value");
            
            iFoundChildren++;
        }
    }
    STAssertTrue(iFoundChildren >= 1, 
                 @"DataObject (v_int4) xmlForObject failed to find field in Xml");
    
    [objXmlFetch release];
    
    // Xml Load
    
    PGSQLDataObject *objXmlSet;
    objXmlSet = [[PGSQLDataObject alloc] initWithConnection:connection
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"]; 
    
    STAssertTrue([objXmlSet loadFromXml:[xmlDocument rootElement]], 
                 @"DataObject (v_int4) loadFromXml Failed: no xml document");
    
    STAssertTrue([[objXmlSet valueForProperty:@"v_int4"] intValue] == [updateValue intValue], 
                 @"DataObject (v_int4) loadFromXml Failed: value does not match expected");
    
    [objXmlSet setValue:initialValue forProperty:@"v_int4"];
    
    STAssertTrue([objXmlSet save], 
                 @"DataObject (v_int4) Save after loadFromXml: %@", [objXmlSet lastError]);
    [objXmlSet release];
    
    // Delete    
    PGSQLDataObject *objDelete;
    objDelete = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"
                                                    forId:refId];
    STAssertTrue([objDelete remove], 
                 @"DataObject Delete failed: %@", [objDelete lastError]);
    [objDelete release];  
    
    // cleanup the table
    tableCmd = [[NSMutableString alloc] init];
    [tableCmd appendString:@"drop table pgdo_test"];
    [connection execCommand:tableCmd];
    [tableCmd release];
}

- (void)testDataObject_int8
{
    NSNumber *refId;
    NSNumber *initialValue = [[NSNumber alloc] initWithLong:32768];
    NSNumber *updateValue = [[NSNumber alloc] initWithLong:65538];
    
    // setup the table
    
    NSMutableString *tableCmd = [[NSMutableString alloc] init];
    [tableCmd appendString:@"create table pgdo_test ( "];
    [tableCmd appendString:@"   record_id serial primary key, "];
    [tableCmd appendString:@"   v_int8 int8 not null "];
    [tableCmd appendString:@")"];
    [connection execCommand:tableCmd];
    [tableCmd release];
    
    // create
    
    PGSQLDataObject *objCreate;
    objCreate = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test" 
                                           withPrimaryKey:@"record_id"];
    
    // set the property
    [objCreate setValue:initialValue forProperty:@"v_int8"];
    
    // Create -----------------------------------------------------------------
    
    BOOL result = [objCreate save];
    if (result)
    {
        refId  = [[[objCreate refId] copy] retain];
        STAssertTrue([refId longValue] > 0, @"Reference ID is Zero, error: %@", 
                     [objCreate lastError]);
    } else {
        STAssertTrue(result == YES, @"DataObject (v_int8) Save Failed: %@", 
                     [objCreate lastError]);
        [objCreate release];
        return;
    }
    [objCreate release];
    
    // Read 
    
    PGSQLDataObject *objRead;
    objRead = [[PGSQLDataObject alloc] initWithConnection:connection 
                                               forTable:@"pgdo_test"
                                         withPrimaryKey:@"record_id"
                                                  forId:refId];
    // get the property
    
    STAssertTrue([[objRead valueForProperty:@"v_int8"] isEqualToNumber:initialValue], 
                 @"DataObject (v_bit) Read Failed");
    
    [objRead release];
    
    // Update 
    
    PGSQLDataObject *objUpdate;
    objUpdate = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"
                                                    forId:refId];
    
    [objUpdate setValue:updateValue forProperty:@"v_int8"];
    
    STAssertTrue([objUpdate  save], 
                 @"DataObject (v_int8) Update failed: %@", [objUpdate lastError]);
    [objUpdate release];
    
    // Xml Fetch
    
    PGSQLDataObject *objXmlFetch;
    objXmlFetch = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                   forTable:@"pgdo_test"
                                             withPrimaryKey:@"record_id"
                                                      forId:refId];
    
    NSXMLDocument *xmlDocument = [[NSXMLDocument alloc] initWithRootElement:[objXmlFetch xmlForObject]];
    
    STAssertTrue(([[xmlDocument rootElement] childCount] > 0), 
                 @"DataObject (v_int8) xmlForObject failed: %@", [objXmlFetch lastError]);
    
    int iFoundChildren = 0;
    for (int i = 0; i < [[xmlDocument rootElement] childCount]; i++)
    {
        NSXMLNode *currentElement = [[xmlDocument rootElement] childAtIndex:i];
        
        if ([[currentElement name] isEqualToString:@"v_int8"])
        {
            // this is not a string type, so it must be parsed back to an 
            // NSNumber before we can really use it.
            NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
            [f setNumberStyle:NSNumberFormatterDecimalStyle];
            NSNumber *currentValue = [f numberFromString:[currentElement stringValue]];
            [f release];
            
            STAssertTrue([currentValue longValue] == [updateValue longValue], 
                         @"DataObject (v_int8) xmlForObject Xml value not expected value");
            
            iFoundChildren++;
        }
    }
    STAssertTrue(iFoundChildren >= 1, 
                 @"DataObject (v_int8) xmlForObject failed to find field in Xml");
    
    [objXmlFetch release];
    
    // Xml Load
    
    PGSQLDataObject *objXmlSet;
    objXmlSet = [[PGSQLDataObject alloc] initWithConnection:connection
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"]; 
    
    STAssertTrue([objXmlSet loadFromXml:[xmlDocument rootElement]], 
                 @"DataObject (v_int8) loadFromXml Failed: no xml document");
    
    STAssertTrue([[objXmlSet valueForProperty:@"v_int8"] longValue] == [updateValue longValue], 
                 @"DataObject (v_int8) loadFromXml Failed: value does not match expected");
    
    [objXmlSet setValue:initialValue forProperty:@"v_int8"];
    
    STAssertTrue([objXmlSet save], 
                 @"DataObject (v_int8) Save after loadFromXml: %@", [objXmlSet lastError]);
    [objXmlSet release];
    
    // Delete    
    PGSQLDataObject *objDelete;
    objDelete = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"
                                                    forId:refId];
    STAssertTrue([objDelete remove], 
                 @"DataObject Delete failed: %@", [objDelete lastError]);
    [objDelete release];  
    
    // cleanup the table
    tableCmd = [[NSMutableString alloc] init];
    [tableCmd appendString:@"drop table pgdo_test"];
    [connection execCommand:tableCmd];
    [tableCmd release];
}

- (void)testDataObject_money
{
    NSNumber *refId;
    NSNumber *initialValue = [[NSNumber alloc] initWithFloat:101.15];
    NSNumber *updateValue = [[NSNumber alloc] initWithFloat:501.11];
    
    // setup the table
    
    NSMutableString *tableCmd = [[NSMutableString alloc] init];
    [tableCmd appendString:@"create table pgdo_test ( "];
    [tableCmd appendString:@"   record_id serial primary key, "];
    [tableCmd appendString:@"   v_money money not null "];
    [tableCmd appendString:@")"];
    [connection execCommand:tableCmd];
    [tableCmd release];
    
    // create
    
    PGSQLDataObject *objCreate;
    objCreate = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test" 
                                           withPrimaryKey:@"record_id"];
    
    // set the property
    [objCreate setValue:initialValue forProperty:@"v_money"];
    
    // Create -----------------------------------------------------------------
    
    BOOL result = [objCreate save];
    if (result)
    {
        refId  = [[[objCreate refId] copy] retain];
        STAssertTrue([refId longValue] > 0, @"Reference ID is Zero, error: %@", 
                     [objCreate lastError]);
    } else {
        STAssertTrue(result == YES, @"DataObject (v_money) Save Failed: %@", 
                     [objCreate lastError]);
        [objCreate release];
        return;
    }
    [objCreate release];
    
    // Read 
    
    PGSQLDataObject *objRead;
    objRead = [[PGSQLDataObject alloc] initWithConnection:connection 
                                               forTable:@"pgdo_test"
                                         withPrimaryKey:@"record_id"
                                                  forId:refId];
    // get the property
    
    STAssertTrue([[objRead valueForProperty:@"v_money"] floatValue] == 
                 [initialValue floatValue], 
                 @"DataObject (v_money) Read Failed");
    
    [objRead release];
    
    // Update 
    
    PGSQLDataObject *objUpdate;
    objUpdate = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"
                                                    forId:refId];
    
    [objUpdate setValue:updateValue forProperty:@"v_money"];
    
    STAssertTrue([objUpdate  save], 
                 @"DataObject (v_money) Update failed: %@", [objUpdate lastError]);
    [objUpdate release];
    
    // Xml Fetch
    
    PGSQLDataObject *objXmlFetch;
    objXmlFetch = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                   forTable:@"pgdo_test"
                                             withPrimaryKey:@"record_id"
                                                      forId:refId];
    
    NSXMLDocument *xmlDocument = [[NSXMLDocument alloc] initWithRootElement:[objXmlFetch xmlForObject]];
    
    STAssertTrue(([[xmlDocument rootElement] childCount] > 0), 
                 @"DataObject (v_money) xmlForObject failed: %@", [objXmlFetch lastError]);
    
    int iFoundChildren = 0;
    for (int i = 0; i < [[xmlDocument rootElement] childCount]; i++)
    {
        NSXMLNode *currentElement = [[xmlDocument rootElement] childAtIndex:i];
        
        if ([[currentElement name] isEqualToString:@"v_money"])
        {
            // this is not a string type, so it must be parsed back to an 
            // NSNumber before we can really use it.
            NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
            [f setNumberStyle:NSNumberFormatterDecimalStyle];
            NSNumber *currentValue = [f numberFromString:[currentElement stringValue]];
            [f release];
            
            STAssertTrue([currentValue floatValue] == [updateValue floatValue], 
                         @"DataObject (v_money) xmlForObject Xml value not expected value");
            
            iFoundChildren++;
        }
    }
    STAssertTrue(iFoundChildren >= 1, 
                 @"DataObject (v_money) xmlForObject failed to find field in Xml");
    
    [objXmlFetch release];
    
    // Xml Load
    
    PGSQLDataObject *objXmlSet;
    objXmlSet = [[PGSQLDataObject alloc] initWithConnection:connection
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"]; 
    
    STAssertTrue([objXmlSet loadFromXml:[xmlDocument rootElement]], 
                 @"DataObject (v_money) loadFromXml Failed: no xml document");
    
    STAssertTrue([[objXmlSet valueForProperty:@"v_money"] floatValue] == [updateValue floatValue], 
                 @"DataObject (v_money) loadFromXml Failed: value does not match expected");
    
    [objXmlSet setValue:initialValue forProperty:@"v_money"];
    
    STAssertTrue([objXmlSet save], 
                 @"DataObject (v_money) Save after loadFromXml: %@", [objXmlSet lastError]);
    [objXmlSet release];
    
    // Delete    
    PGSQLDataObject *objDelete;
    objDelete = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"
                                                    forId:refId];
    STAssertTrue([objDelete remove], 
                 @"DataObject Delete failed: %@", [objDelete lastError]);
    [objDelete release];  
    
    // cleanup the table
    tableCmd = [[NSMutableString alloc] init];
    [tableCmd appendString:@"drop table pgdo_test"];
    [connection execCommand:tableCmd];
    [tableCmd release];
}

- (void)testDataObject_numeric
{
    NSNumber *refId;
    NSNumber *initialValue = [[NSNumber alloc] initWithFloat:101.105];
    NSNumber *updateValue = [[NSNumber alloc] initWithFloat:501.011];
    
    // setup the table
    
    NSMutableString *tableCmd = [[NSMutableString alloc] init];
    [tableCmd appendString:@"create table pgdo_test ( "];
    [tableCmd appendString:@"   record_id serial primary key, "];
    [tableCmd appendString:@"   v_numeric numeric not null "];
    [tableCmd appendString:@")"];
    [connection execCommand:tableCmd];
    [tableCmd release];
    
    // create
    
    PGSQLDataObject *objCreate;
    objCreate = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test" 
                                           withPrimaryKey:@"record_id"];
    
    // set the property
    [objCreate setValue:initialValue forProperty:@"v_numeric"];
    
    // Create -----------------------------------------------------------------
    
    BOOL result = [objCreate save];
    if (result)
    {
        refId  = [[[objCreate refId] copy] retain];
        STAssertTrue([refId longValue] > 0, @"Reference ID is Zero, error: %@", 
                     [objCreate lastError]);
    } else {
        STAssertTrue(result == YES, @"DataObject (v_numeric) Save Failed: %@", 
                     [objCreate lastError]);
        [objCreate release];
        return;
    }
    [objCreate release];
    
    // Read 
    
    PGSQLDataObject *objRead;
    objRead = [[PGSQLDataObject alloc] initWithConnection:connection 
                                               forTable:@"pgdo_test"
                                         withPrimaryKey:@"record_id"
                                                  forId:refId];
    // get the property
    
    STAssertTrue([[objRead valueForProperty:@"v_numeric"] isEqualToNumber:initialValue], 
                 @"DataObject (v_numeric) Read Failed");
    
    [objRead release];
    
    // Update 
    
    PGSQLDataObject *objUpdate;
    objUpdate = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"
                                                    forId:refId];
    
    [objUpdate setValue:updateValue forProperty:@"v_numeric"];
    
    STAssertTrue([objUpdate  save], 
                 @"DataObject (v_numeric) Update failed: %@", [objUpdate lastError]);
    [objUpdate release];
    
    // Xml Fetch
    
    PGSQLDataObject *objXmlFetch;
    objXmlFetch = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                   forTable:@"pgdo_test"
                                             withPrimaryKey:@"record_id"
                                                      forId:refId];
    
    NSXMLDocument *xmlDocument = [[NSXMLDocument alloc] initWithRootElement:[objXmlFetch xmlForObject]];
    
    STAssertTrue(([[xmlDocument rootElement] childCount] > 0), 
                 @"DataObject (v_numeric) xmlForObject failed: %@", [objXmlFetch lastError]);
    
    int iFoundChildren = 0;
    for (int i = 0; i < [[xmlDocument rootElement] childCount]; i++)
    {
        NSXMLNode *currentElement = [[xmlDocument rootElement] childAtIndex:i];
        
        if ([[currentElement name] isEqualToString:@"v_numeric"])
        {
            // this is not a string type, so it must be parsed back to an 
            // NSNumber before we can really use it.
            NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
            [f setNumberStyle:NSNumberFormatterDecimalStyle];
            NSNumber *currentValue = [f numberFromString:[currentElement stringValue]];
            [f release];
            
            STAssertTrue([currentValue floatValue] == [updateValue floatValue], 
                         @"DataObject (v_numeric) xmlForObject Xml value not expected value");
            
            iFoundChildren++;
        }
    }
    STAssertTrue(iFoundChildren >= 1, 
                 @"DataObject (v_numeric) xmlForObject failed to find field in Xml");
    
    [objXmlFetch release];
    
    // Xml Load
    
    PGSQLDataObject *objXmlSet;
    objXmlSet = [[PGSQLDataObject alloc] initWithConnection:connection
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"]; 
    
    STAssertTrue([objXmlSet loadFromXml:[xmlDocument rootElement]], 
                 @"DataObject (v_numeric) loadFromXml Failed: no xml document");
    
    STAssertTrue([[objXmlSet valueForProperty:@"v_numeric"] floatValue] == [updateValue floatValue], 
                 @"DataObject (v_numeric) loadFromXml Failed: value does not match expected");
    
    [objXmlSet setValue:initialValue forProperty:@"v_numeric"];
    
    STAssertTrue([objXmlSet save], 
                 @"DataObject (v_numeric) Save after loadFromXml: %@", [objXmlSet lastError]);
    [objXmlSet release];
    
    // Delete    
    PGSQLDataObject *objDelete;
    objDelete = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"
                                                    forId:refId];
    STAssertTrue([objDelete remove], 
                 @"DataObject Delete failed: %@", [objDelete lastError]);
    [objDelete release];  
    
    // cleanup the table
    tableCmd = [[NSMutableString alloc] init];
    [tableCmd appendString:@"drop table pgdo_test"];
    [connection execCommand:tableCmd];
    [tableCmd release];
}

- (void)testDataObject_text
{
    NSNumber *refId;
    
    // setup the table
    
    NSMutableString *tableCmd = [[NSMutableString alloc] init];
    [tableCmd appendString:@"create table pgdo_test ( "];
    [tableCmd appendString:@"   record_id serial primary key, "];
    [tableCmd appendString:@"   v_text text not null "];
    [tableCmd appendString:@")"];
    [connection execCommand:tableCmd];
    [tableCmd release];
    
    // create
    
    PGSQLDataObject *objCreate;
    objCreate = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test" 
                                           withPrimaryKey:@"record_id"];
    
    // set the property
    [objCreate setValue:@"unit test" forProperty:@"v_text"];
    
    // Create -----------------------------------------------------------------
    
    BOOL result = [objCreate save];
    if (result)
    {
        refId  = [[[objCreate refId] copy] retain];
        STAssertTrue([refId longValue] > 0, @"Reference ID is Zero, error: %@", 
                     [objCreate lastError]);
    } else {
        STAssertTrue(result == YES, @"DataObject (v_text) Save Failed: %@", 
                     [objCreate lastError]);
        [objCreate release];
        return;
    }
    [objCreate release];
    
    // Read 
    
    PGSQLDataObject *objRead;
    objRead = [[PGSQLDataObject alloc] initWithConnection:connection 
                                               forTable:@"pgdo_test"
                                         withPrimaryKey:@"record_id"
                                                  forId:refId];
    // get the property
    
    STAssertTrue([[objRead valueForProperty:@"v_text"] isEqualToString:@"unit test"], 
                 @"DataObject (v_text) Read Failed");
    
    [objRead release];
    
    // Update 
    
    PGSQLDataObject *objUpdate;
    objUpdate = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"
                                                    forId:refId];
    
    [objUpdate setValue:@"update test" forProperty:@"v_text"];
    
    STAssertTrue([objUpdate  save], 
                 @"DataObject (v_text) Update failed: %@", [objUpdate lastError]);
    [objUpdate release];
    
    // Xml Fetch
    
    PGSQLDataObject *objXmlFetch;
    objXmlFetch = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                   forTable:@"pgdo_test"
                                             withPrimaryKey:@"record_id"
                                                      forId:refId];
    
    NSXMLDocument *xmlDocument = [[NSXMLDocument alloc] initWithRootElement:[objXmlFetch xmlForObject]];
    
    STAssertTrue(([[xmlDocument rootElement] childCount] > 0), 
                 @"DataObject (v_text) xmlForObject failed: %@", [objXmlFetch lastError]);
    
    int iFoundChildren = 0;
    for (int i = 0; i < [[xmlDocument rootElement] childCount]; i++)
    {
        NSXMLNode *currentElement = [[xmlDocument rootElement] childAtIndex:i];
        
        if ([[currentElement name] isEqualToString:@"v_text"])
        {
            STAssertTrue([[currentElement stringValue] isEqualToString:@"update test"], 
                         @"DataObject (v_text) xmlForObject Xml value not expected value");
            
            iFoundChildren++;
        }
    }
    STAssertTrue(iFoundChildren >= 1, 
                 @"DataObject (v_text) xmlForObject failed to find field in Xml");
    
    [objXmlFetch release];
    
    // Xml Load
    
    PGSQLDataObject *objXmlSet;
    objXmlSet = [[PGSQLDataObject alloc] initWithConnection:connection
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"]; 
    
    STAssertTrue([objXmlSet loadFromXml:[xmlDocument rootElement]], 
                 @"DataObject (v_text) loadFromXml Failed: no xml document");
    
    STAssertTrue([[objXmlSet valueForProperty:@"v_text"] isEqualToString:@"update test"], 
                 @"DataObject (v_text) loadFromXml Failed: value does not match expected");
    
    [objXmlSet setValue:@"xml test" forProperty:@"v_text"];
    
    STAssertTrue([objXmlSet save], 
                 @"DataObject (v_text) Save after loadFromXml: %@", [objXmlSet lastError]);
    [objXmlSet release];
    
    // Delete
    
    PGSQLDataObject *objDelete;
    objDelete = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"
                                                    forId:refId];
    STAssertTrue([objDelete remove], 
                 @"DataObject Delete failed: %@", [objDelete lastError]);
    [objDelete release];  
    
    // cleanup the table
    tableCmd = [[NSMutableString alloc] init];
    [tableCmd appendString:@"drop table pgdo_test"];
    [connection execCommand:tableCmd];
    [tableCmd release];
}

- (void)testDataObject_time
{
    NSNumber *refId;
    NSDate *initialValue = [[NSDate alloc] initWithString:@"1970-01-01 08:24:13 +000"];
    NSDate *updateValue = [[NSDate alloc] initWithString:@"1970-01-01 17:02:54 +000"];
    
    // setup the table
    
    NSMutableString *tableCmd = [[NSMutableString alloc] init];
    [tableCmd appendString:@"create table pgdo_test ( "];
    [tableCmd appendString:@"   record_id serial primary key, "];
    [tableCmd appendString:@"   v_time date not null "];
    [tableCmd appendString:@")"];
    [connection execCommand:tableCmd];
    [tableCmd release];
    
    // create
    
    PGSQLDataObject *objCreate;
    objCreate = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test" 
                                           withPrimaryKey:@"record_id"];
    
    // set the property
    [objCreate setValue:initialValue forProperty:@"v_time"];
    
    // Create -----------------------------------------------------------------
    
    BOOL result = [objCreate save];
    if (result)
    {
        refId  = [[[objCreate refId] copy] retain];
        STAssertTrue([refId longValue] > 0, @"Reference ID is Zero, error: %@", 
                     [objCreate lastError]);
    } else {
        STAssertTrue(result == YES, @"DataObject (v_time) Save Failed: %@", 
                     [objCreate lastError]);
        [objCreate release];
        return;
    }
    [objCreate release];
    
    // Read 
    
    PGSQLDataObject *objRead;
    objRead = [[PGSQLDataObject alloc] initWithConnection:connection 
                                               forTable:@"pgdo_test"
                                         withPrimaryKey:@"record_id"
                                                  forId:refId];
    // get the property
    
    STAssertTrue([[objRead valueForProperty:@"v_time"] isEqualToDate:initialValue], 
                 @"DataObject (v_time) Read Failed");
    
    [objRead release];
    
    // Update 
    
    PGSQLDataObject *objUpdate;
    objUpdate = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"
                                                    forId:refId];
    
    [objUpdate setValue:updateValue forProperty:@"v_time"];
    
    STAssertTrue([objUpdate  save], 
                 @"DataObject (v_time) Update failed: %@", [objUpdate lastError]);
    [objUpdate release];
    
    // Xml Fetch
    
    PGSQLDataObject *objXmlFetch;
    objXmlFetch = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                   forTable:@"pgdo_test"
                                             withPrimaryKey:@"record_id"
                                                      forId:refId];
    
    NSXMLDocument *xmlDocument = [[NSXMLDocument alloc] initWithRootElement:[objXmlFetch xmlForObject]];
    
    STAssertTrue(([[xmlDocument rootElement] childCount] > 0), 
                 @"DataObject (v_time) xmlForObject failed: %@", [objXmlFetch lastError]);
    
    int iFoundChildren = 0;
    for (int i = 0; i < [[xmlDocument rootElement] childCount]; i++)
    {
        NSXMLNode *currentElement = [[xmlDocument rootElement] childAtIndex:i];
        
        if ([[currentElement name] isEqualToString:@"v_time"])
        {
            // this is not a string type, so it must be parsed back to an 
            // NSNumber before we can really use it.
            NSDateFormatter* dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
            [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
            [dateFormatter setDateFormat:@"HH:mm:ss"];
            NSDate *currentValue = [dateFormatter dateFromString:[currentElement stringValue]];
            
            STAssertTrue([currentValue isEqualToDate:updateValue], 
                         @"DataObject (v_time) xmlForObject Xml value not expected value");
            
            iFoundChildren++;
        }
    }
    STAssertTrue(iFoundChildren >= 1, 
                 @"DataObject (v_time) xmlForObject failed to find field in Xml");
    
    [objXmlFetch release];
    
    // Xml Load
    
    PGSQLDataObject *objXmlSet;
    objXmlSet = [[PGSQLDataObject alloc] initWithConnection:connection
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"]; 
    
    STAssertTrue([objXmlSet loadFromXml:[xmlDocument rootElement]], 
                 @"DataObject (v_time) loadFromXml Failed: no xml document");
    
    STAssertTrue([[objXmlSet valueForProperty:@"v_time"] isEqualToDate:updateValue], 
                 @"DataObject (v_time) loadFromXml Failed: value does not match expected");
    
    [objXmlSet setValue:initialValue forProperty:@"v_time"];
    
    STAssertTrue([objXmlSet save], 
                 @"DataObject (v_time) Save after loadFromXml: %@", [objXmlSet lastError]);
    [objXmlSet release];
    
    // Delete    
    PGSQLDataObject *objDelete;
    objDelete = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"
                                                    forId:refId];
    STAssertTrue([objDelete remove], 
                 @"DataObject Delete failed: %@", [objDelete lastError]);
    [objDelete release];  
    
    // cleanup the table
    tableCmd = [[NSMutableString alloc] init];
    [tableCmd appendString:@"drop table pgdo_test"];
    [connection execCommand:tableCmd];
    [tableCmd release];
}

- (void)testDataObject_timestamp
{
    NSNumber *refId;
    NSDate *initialValue = [[NSDate alloc] initWithString:@"2012-01-01 11:15:31 +000"];
    NSDate *updateValue = [[NSDate alloc] initWithString:@"2012-06-06 23:01:01 +000"];
    
    // setup the table
    
    NSMutableString *tableCmd = [[NSMutableString alloc] init];
    [tableCmd appendString:@"create table pgdo_test ( "];
    [tableCmd appendString:@"   record_id serial primary key, "];
    [tableCmd appendString:@"   v_timestamp timestamp not null "];
    [tableCmd appendString:@")"];
    [connection execCommand:tableCmd];
    [tableCmd release];
    
    // create
    
    PGSQLDataObject *objCreate;
    objCreate = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test" 
                                           withPrimaryKey:@"record_id"];
    
    // set the property
    [objCreate setValue:initialValue forProperty:@"v_timestamp"];
    
    // Create -----------------------------------------------------------------
    
    BOOL result = [objCreate save];
    if (result)
    {
        refId  = [[[objCreate refId] copy] retain];
        STAssertTrue([refId longValue] > 0, @"Reference ID is Zero, error: %@", 
                     [objCreate lastError]);
    } else {
        STAssertTrue(result == YES, @"DataObject (v_timestamp) Save Failed: %@", 
                     [objCreate lastError]);
        [objCreate release];
        return;
    }
    [objCreate release];
    
    // Read 
    
    PGSQLDataObject *objRead;
    objRead = [[PGSQLDataObject alloc] initWithConnection:connection 
                                               forTable:@"pgdo_test"
                                         withPrimaryKey:@"record_id"
                                                  forId:refId];
    // get the property
    
    STAssertTrue([[objRead valueForProperty:@"v_timestamp"] isEqualToDate:initialValue], 
                 @"DataObject (v_timestamp) Read Failed");
    
    [objRead release];
    
    // Update 
    
    PGSQLDataObject *objUpdate;
    objUpdate = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"
                                                    forId:refId];
    
    [objUpdate setValue:updateValue forProperty:@"v_timestamp"];
    
    STAssertTrue([objUpdate  save], 
                 @"DataObject (v_timestamp) Update failed: %@", [objUpdate lastError]);
    [objUpdate release];
    
    // Xml Fetch
    
    PGSQLDataObject *objXmlFetch;
    objXmlFetch = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                   forTable:@"pgdo_test"
                                             withPrimaryKey:@"record_id"
                                                      forId:refId];
    
    NSXMLDocument *xmlDocument = [[NSXMLDocument alloc] initWithRootElement:[objXmlFetch xmlForObject]];
    
    STAssertTrue(([[xmlDocument rootElement] childCount] > 0), 
                 @"DataObject (v_timestamp) xmlForObject failed: %@", [objXmlFetch lastError]);
    
    int iFoundChildren = 0;
    for (int i = 0; i < [[xmlDocument rootElement] childCount]; i++)
    {
        NSXMLNode *currentElement = [[xmlDocument rootElement] childAtIndex:i];
        
        if ([[currentElement name] isEqualToString:@"v_timestamp"])
        {
            // this is not a string type, so it must be parsed back to an 
            // NSNumber before we can really use it.
            NSDateFormatter* dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
            [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
            [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
            NSDate *currentValue = [dateFormatter dateFromString:[currentElement stringValue]];
            
            STAssertTrue([currentValue isEqualToDate:updateValue], 
                         @"DataObject (v_timestamp) xmlForObject Xml value not expected value");
            
            iFoundChildren++;
        }
    }
    STAssertTrue(iFoundChildren >= 1, 
                 @"DataObject (v_timestamp) xmlForObject failed to find field in Xml");
    
    [objXmlFetch release];
    
    // Xml Load
    
    PGSQLDataObject *objXmlSet;
    objXmlSet = [[PGSQLDataObject alloc] initWithConnection:connection
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"]; 
    
    STAssertTrue([objXmlSet loadFromXml:[xmlDocument rootElement]], 
                 @"DataObject (v_timestamp) loadFromXml Failed: no xml document");
    
    STAssertTrue([[objXmlSet valueForProperty:@"v_timestamp"] isEqualToDate:updateValue], 
                 @"DataObject (v_timestamp) loadFromXml Failed: value does not match expected");
    
    [objXmlSet setValue:initialValue forProperty:@"v_timestamp"];
    
    STAssertTrue([objXmlSet save], 
                 @"DataObject (v_timestamp) Save after loadFromXml: %@", [objXmlSet lastError]);
    [objXmlSet release];
    
    // Delete    
    PGSQLDataObject *objDelete;
    objDelete = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"
                                                    forId:refId];
    STAssertTrue([objDelete remove], 
                 @"DataObject Delete failed: %@", [objDelete lastError]);
    [objDelete release];  
    
    // cleanup the table
    tableCmd = [[NSMutableString alloc] init];
    [tableCmd appendString:@"drop table pgdo_test"];
    [connection execCommand:tableCmd];
    [tableCmd release];
}

- (void)testDataObject_timestamptz
{
    NSNumber *refId;
    
    NSDate *initialValue = [[NSDate alloc] initWithString:@"2012-01-01 11:15:31 +000"];
    NSDate *updateValue = [[NSDate alloc] initWithString:@"2012-06-06 23:01:01 +000"];
    
    // setup the table
    
    NSMutableString *tableCmd = [[NSMutableString alloc] init];
    [tableCmd appendString:@"create table pgdo_test ( "];
    [tableCmd appendString:@"   record_id serial primary key, "];
    [tableCmd appendString:@"   v_timestamptz timestamptz not null "];
    [tableCmd appendString:@")"];
    [connection execCommand:tableCmd];
    [tableCmd release];
    
    // create
    
    PGSQLDataObject *objCreate;
    objCreate = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test" 
                                           withPrimaryKey:@"record_id"];
    
    // set the property
    [objCreate setValue:initialValue forProperty:@"v_timestamptz"];
    
    // Create -----------------------------------------------------------------
    
    BOOL result = [objCreate save];
    if (result)
    {
        refId  = [[[objCreate refId] copy] retain];
        STAssertTrue([refId longValue] > 0, @"Reference ID is Zero, error: %@", 
                     [objCreate lastError]);
    } else {
        STAssertTrue(result == YES, @"DataObject (v_timestamptz) Save Failed: %@", 
                     [objCreate lastError]);
        [objCreate release];
        return;
    }
    [objCreate release];
    
    // Read 
    
    PGSQLDataObject *objRead;
    objRead = [[PGSQLDataObject alloc] initWithConnection:connection 
                                               forTable:@"pgdo_test"
                                         withPrimaryKey:@"record_id"
                                                  forId:refId];
    // get the property
    
    STAssertTrue([[objRead valueForProperty:@"v_timestamptz"] isEqualToDate:initialValue], 
                 @"DataObject (v_timestamptz) Read Failed");
    
    [objRead release];
    
    // Update 
    
    PGSQLDataObject *objUpdate;
    objUpdate = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"
                                                    forId:refId];
    
    [objUpdate setValue:updateValue forProperty:@"v_timestamptz"];
    
    STAssertTrue([objUpdate  save], 
                 @"DataObject (v_timestamptz) Update failed: %@", [objUpdate lastError]);
    [objUpdate release];
    
    // Xml Fetch
    
    PGSQLDataObject *objXmlFetch;
    objXmlFetch = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                   forTable:@"pgdo_test"
                                             withPrimaryKey:@"record_id"
                                                      forId:refId];
    
    NSXMLDocument *xmlDocument = [[NSXMLDocument alloc] initWithRootElement:[objXmlFetch xmlForObject]];
    
    STAssertTrue(([[xmlDocument rootElement] childCount] > 0), 
                 @"DataObject (v_timestamptz) xmlForObject failed: %@", [objXmlFetch lastError]);
    
    int iFoundChildren = 0;
    for (int i = 0; i < [[xmlDocument rootElement] childCount]; i++)
    {
        NSXMLNode *currentElement = [[xmlDocument rootElement] childAtIndex:i];
        
        if ([[currentElement name] isEqualToString:@"v_timestamptz"])
        {
            // this is not a string type, so it must be parsed back to an 
            // NSNumber before we can really use it.
            NSDateFormatter* dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
            [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
            [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
            NSDate *currentValue = [dateFormatter dateFromString:[currentElement stringValue]];
            
            STAssertTrue([currentValue isEqualToDate:updateValue], 
                         @"DataObject (v_timestamptz) xmlForObject Xml value not expected value");
            
            iFoundChildren++;
        }
    }
    STAssertTrue(iFoundChildren >= 1, 
                 @"DataObject (v_timestamptz) xmlForObject failed to find field in Xml");
    
    [objXmlFetch release];
    
    // Xml Load
    
    PGSQLDataObject *objXmlSet;
    objXmlSet = [[PGSQLDataObject alloc] initWithConnection:connection
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"]; 
    
    STAssertTrue([objXmlSet loadFromXml:[xmlDocument rootElement]], 
                 @"DataObject (v_timestamptz) loadFromXml Failed: no xml document");
    
    STAssertTrue([[objXmlSet valueForProperty:@"v_timestamptz"] isEqualToDate:updateValue], 
                 @"DataObject (v_timestamptz) loadFromXml Failed: value does not match expected");
    
    [objXmlSet setValue:initialValue forProperty:@"v_timestamptz"];
    
    STAssertTrue([objXmlSet save], 
                 @"DataObject (v_timestamptz) Save after loadFromXml: %@", [objXmlSet lastError]);
    [objXmlSet release];
    
    // Delete    
    PGSQLDataObject *objDelete;
    objDelete = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"
                                                    forId:refId];
    STAssertTrue([objDelete remove], 
                 @"DataObject Delete failed: %@", [objDelete lastError]);
    [objDelete release];  
    
    // cleanup the table
    tableCmd = [[NSMutableString alloc] init];
    [tableCmd appendString:@"drop table pgdo_test"];
    [connection execCommand:tableCmd];
    [tableCmd release];
}

- (void)testDataObject_uuid
{
    NSNumber *refId;
    
    // setup the table
    
    NSMutableString *tableCmd = [[NSMutableString alloc] init];
    [tableCmd appendString:@"create table pgdo_test ( "];
    [tableCmd appendString:@"   record_id serial primary key, "];
    [tableCmd appendString:@"   v_uuid uuid not null "];
    [tableCmd appendString:@")"];
    [connection execCommand:tableCmd];
    [tableCmd release];
    
    // create
    
    PGSQLDataObject *objCreate;
    objCreate = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test" 
                                           withPrimaryKey:@"record_id"];
    
    // set the property
    [objCreate setValue:@"{ABC62ED3-A7A2-4F15-B1C5-179826C2E0BB}" forProperty:@"v_uuid"];
    
    // Create -----------------------------------------------------------------
    
    BOOL result = [objCreate save];
    if (result)
    {
        refId  = [[[objCreate refId] copy] retain];
        STAssertTrue([refId longValue] > 0, @"Reference ID is Zero, error: %@", 
                     [objCreate lastError]);
    } else {
        STAssertTrue(result == YES, @"DataObject (v_uuid) Save Failed: %@", 
                     [objCreate lastError]);
        [objCreate release];
        return;
    }
    [objCreate release];
    
    // Read 
    
    PGSQLDataObject *objRead;
    objRead = [[PGSQLDataObject alloc] initWithConnection:connection 
                                               forTable:@"pgdo_test"
                                         withPrimaryKey:@"record_id"
                                                  forId:refId];
    // get the property
    
    STAssertTrue([[objRead valueForProperty:@"v_uuid"] isEqualToString:@"abc62ed3-a7a2-4f15-b1c5-179826c2e0bb"], 
                 @"DataObject (v_uuid) Read Failed");
    
    [objRead release];
    
    // Update 
    
    PGSQLDataObject *objUpdate;
    objUpdate = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"
                                                    forId:refId];
    
    [objUpdate setValue:@"{5E70283C-D420-4E67-939C-4032C8EBC702}" forProperty:@"v_uuid"];
    
    STAssertTrue([objUpdate  save], 
                 @"DataObject (v_uuid) Update failed: %@", [objUpdate lastError]);
    [objUpdate release];
    
    // Xml Fetch
    
    PGSQLDataObject *objXmlFetch;
    objXmlFetch = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                   forTable:@"pgdo_test"
                                             withPrimaryKey:@"record_id"
                                                      forId:refId];
    
    NSXMLDocument *xmlDocument = [[NSXMLDocument alloc] initWithRootElement:[objXmlFetch xmlForObject]];
    
    STAssertTrue(([[xmlDocument rootElement] childCount] > 0), 
                 @"DataObject (v_uuid) xmlForObject failed: %@", [objXmlFetch lastError]);
    
    int iFoundChildren = 0;
    for (int i = 0; i < [[xmlDocument rootElement] childCount]; i++)
    {
        NSXMLNode *currentElement = [[xmlDocument rootElement] childAtIndex:i];
        
        if ([[currentElement name] isEqualToString:@"v_uuid"])
        {
            STAssertTrue([[currentElement stringValue] isEqualToString:@"5e70283c-d420-4e67-939c-4032c8ebc702"], 
                         @"DataObject (v_uuid) xmlForObject Xml value not expected value");
            
            iFoundChildren++;
        }
    }
    STAssertTrue(iFoundChildren >= 1, 
                 @"DataObject (v_uuid) xmlForObject failed to find field in Xml");
    
    [objXmlFetch release];
    
    // Xml Load
    
    PGSQLDataObject *objXmlSet;
    objXmlSet = [[PGSQLDataObject alloc] initWithConnection:connection
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"]; 
    
    STAssertTrue([objXmlSet loadFromXml:[xmlDocument rootElement]], 
                 @"DataObject (v_uuid) loadFromXml Failed: no xml document");
    
    STAssertTrue([[objXmlSet valueForProperty:@"v_uuid"] isEqualToString:@"5e70283c-d420-4e67-939c-4032c8ebc702"], 
                 @"DataObject (v_uuid) loadFromXml Failed: value does not match expected");
    
    [objXmlSet setValue:@"{5E70283C-D420-4E67-939C-4032C8EBC702}" forProperty:@"v_uuid"];
    
    STAssertTrue([objXmlSet save], 
                 @"DataObject (v_uuid) Save after loadFromXml: %@", [objXmlSet lastError]);
    [objXmlSet release];
    
    // Delete
    
    PGSQLDataObject *objDelete;
    objDelete = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"
                                                    forId:refId];
    STAssertTrue([objDelete remove], 
                 @"DataObject Delete failed: %@", [objDelete lastError]);
    [objDelete release];  
    
    // cleanup the table
    tableCmd = [[NSMutableString alloc] init];
    [tableCmd appendString:@"drop table pgdo_test"];
    [connection execCommand:tableCmd];
    [tableCmd release];
}

- (void)testDataObject_varbit
{
    NSNumber *refId;
    NSString *initialValue = [[NSString alloc] initWithString:@"01"];
    NSString *updateValue = [[NSString alloc] initWithString:@"1010"];
    
    // setup the table
    
    NSMutableString *tableCmd = [[NSMutableString alloc] init];
    [tableCmd appendString:@"create table pgdo_test ( "];
    [tableCmd appendString:@"   record_id serial primary key, "];
    [tableCmd appendString:@"   v_varbit varbit(4) not null "];
    [tableCmd appendString:@")"];
    [connection execCommand:tableCmd];
    [tableCmd release];
    
    // create
    
    PGSQLDataObject *objCreate;
    objCreate = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test" 
                                           withPrimaryKey:@"record_id"];
    
    // set the property
    [objCreate setValue:initialValue forProperty:@"v_varbit"];
    
    // Create -----------------------------------------------------------------
    
    BOOL result = [objCreate save];
    if (result)
    {
        refId  = [[[objCreate refId] copy] retain];
        STAssertTrue([refId longValue] > 0, @"Reference ID is Zero, error: %@", 
                     [objCreate lastError]);
    } else {
        STAssertTrue(result == YES, @"DataObject (v_varbit) Save Failed: %@", 
                     [objCreate lastError]);
        [objCreate release];
        return;
    }
    [objCreate release];
    
    // Read 
    
    PGSQLDataObject *objRead;
    objRead = [[PGSQLDataObject alloc] initWithConnection:connection 
                                               forTable:@"pgdo_test"
                                         withPrimaryKey:@"record_id"
                                                  forId:refId];
    // get the property
    
    STAssertTrue([[objRead valueForProperty:@"v_varbit"] isEqualToString:initialValue], 
                 @"DataObject (v_varbit) Read Failed");
    
    [objRead release];
    
    // Update 
    
    PGSQLDataObject *objUpdate;
    objUpdate = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"
                                                    forId:refId];
    
    [objUpdate setValue:updateValue forProperty:@"v_varbit"];
    
    STAssertTrue([objUpdate  save], 
                 @"DataObject (v_varbit) Update failed: %@", [objUpdate lastError]);
    [objUpdate release];
    
    // Xml Fetch
    
    PGSQLDataObject *objXmlFetch;
    objXmlFetch = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                   forTable:@"pgdo_test"
                                             withPrimaryKey:@"record_id"
                                                      forId:refId];
    
    NSXMLDocument *xmlDocument = [[NSXMLDocument alloc] initWithRootElement:[objXmlFetch xmlForObject]];
    
    STAssertTrue(([[xmlDocument rootElement] childCount] > 0), 
                 @"DataObject (v_varbit) xmlForObject failed: %@", [objXmlFetch lastError]);
    
    int iFoundChildren = 0;
    for (int i = 0; i < [[xmlDocument rootElement] childCount]; i++)
    {
        NSXMLNode *currentElement = [[xmlDocument rootElement] childAtIndex:i];
        
        if ([[currentElement name] isEqualToString:@"v_varbit"])
        {
            STAssertTrue([[currentElement stringValue] isEqualToString:updateValue], 
                         @"DataObject (v_varbit) xmlForObject Xml value not expected value");
            
            iFoundChildren++;
        }
    }
    STAssertTrue(iFoundChildren >= 1, 
                 @"DataObject (v_varbit) xmlForObject failed to find field in Xml");
    
    [objXmlFetch release];
    
    // Xml Load
    
    PGSQLDataObject *objXmlSet;
    objXmlSet = [[PGSQLDataObject alloc] initWithConnection:connection
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"]; 
    
    STAssertTrue([objXmlSet loadFromXml:[xmlDocument rootElement]], 
                 @"DataObject (v_varbit) loadFromXml Failed: no xml document");
    
    STAssertTrue([[objXmlSet valueForProperty:@"v_varbit"] isEqualToString:updateValue], 
                 @"DataObject (v_varbit) loadFromXml Failed: value does not match expected");
    
    [objXmlSet setValue:initialValue forProperty:@"v_varbit"];
    
    STAssertTrue([objXmlSet save], 
                 @"DataObject (v_varbit) Save after loadFromXml: %@", [objXmlSet lastError]);
    [objXmlSet release];
    
    // Delete    
    PGSQLDataObject *objDelete;
    objDelete = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"
                                                    forId:refId];
    STAssertTrue([objDelete remove], 
                 @"DataObject Delete failed: %@", [objDelete lastError]);
    [objDelete release];  
    
    // cleanup the table
    tableCmd = [[NSMutableString alloc] init];
    [tableCmd appendString:@"drop table pgdo_test"];
    [connection execCommand:tableCmd];
    [tableCmd release];
}

- (void)testDataObject_varchar
{
    NSNumber *refId;
    
    // setup the table
    
    NSMutableString *tableCmd = [[NSMutableString alloc] init];
    [tableCmd appendString:@"create table pgdo_test ( "];
    [tableCmd appendString:@"   record_id serial primary key, "];
    [tableCmd appendString:@"   v_varchar varchar(64) not null "];
    [tableCmd appendString:@")"];
    [connection execCommand:tableCmd];
    [tableCmd release];
    
    // create
    
    PGSQLDataObject *objCreate;
    objCreate = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test" 
                                           withPrimaryKey:@"record_id"];
    
    // set the property
    [objCreate setValue:@"unit test" forProperty:@"v_varchar"];
    
    // Create -----------------------------------------------------------------
    
    BOOL result = [objCreate save];
    if (result)
    {
        refId  = [[[objCreate refId] copy] retain];
        STAssertTrue([refId longValue] > 0, @"Reference ID is Zero, error: %@", 
                     [objCreate lastError]);
    } else {
        STAssertTrue(result == YES, @"DataObject (v_varchar) Save Failed: %@", 
                     [objCreate lastError]);
        [objCreate release];
        return;
    }
    [objCreate release];
    
    // Read 
    
    PGSQLDataObject *objRead;
    objRead = [[PGSQLDataObject alloc] initWithConnection:connection 
                                               forTable:@"pgdo_test"
                                         withPrimaryKey:@"record_id"
                                                  forId:refId];
    // get the property
    
    STAssertTrue([[objRead valueForProperty:@"v_varchar"] isEqualToString:@"unit test"], 
                 @"DataObject (v_varchar) Read Failed");
    
    [objRead release];
    
    // Update 
    
    PGSQLDataObject *objUpdate;
    objUpdate = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"
                                                    forId:refId];
    
    [objUpdate setValue:@"update test" forProperty:@"v_varchar"];
    
    STAssertTrue([objUpdate  save], 
                 @"DataObject (v_varchar) Update failed: %@", [objUpdate lastError]);
    [objUpdate release];
    
    // Xml Fetch
    
    PGSQLDataObject *objXmlFetch;
    objXmlFetch = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                   forTable:@"pgdo_test"
                                             withPrimaryKey:@"record_id"
                                                      forId:refId];
    
    NSXMLDocument *xmlDocument = [[NSXMLDocument alloc] initWithRootElement:[objXmlFetch xmlForObject]];
    
    STAssertTrue(([[xmlDocument rootElement] childCount] > 0), 
                 @"DataObject (v_varchar) xmlForObject failed: %@", [objXmlFetch lastError]);
    
    int iFoundChildren = 0;
    for (int i = 0; i < [[xmlDocument rootElement] childCount]; i++)
    {
        NSXMLNode *currentElement = [[xmlDocument rootElement] childAtIndex:i];
        
        if ([[currentElement name] isEqualToString:@"v_varchar"])
        {
            STAssertTrue([[currentElement stringValue] isEqualToString:@"update test"], 
                         @"DataObject (v_varchar) xmlForObject Xml value not expected value");
            
            iFoundChildren++;
        }
    }
    STAssertTrue(iFoundChildren >= 1, 
                 @"DataObject (v_varchar) xmlForObject failed to find field in Xml");
    
    [objXmlFetch release];
    
    // Xml Load
    
    PGSQLDataObject *objXmlSet;
    objXmlSet = [[PGSQLDataObject alloc] initWithConnection:connection
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"]; 
    
    STAssertTrue([objXmlSet loadFromXml:[xmlDocument rootElement]], 
                 @"DataObject (v_varchar) loadFromXml Failed: no xml document");
    
    STAssertTrue([[objXmlSet valueForProperty:@"v_varchar"] isEqualToString:@"update test"], 
                 @"DataObject (v_varchar) loadFromXml Failed: value does not match expected");
    
    [objXmlSet setValue:@"xml test" forProperty:@"v_varchar"];
    
    STAssertTrue([objXmlSet save], 
                 @"DataObject (v_varchar) Save after loadFromXml: %@", [objXmlSet lastError]);
    [objXmlSet release];
    
    // Delete
    
    PGSQLDataObject *objDelete;
    objDelete = [[PGSQLDataObject alloc] initWithConnection:connection 
                                                 forTable:@"pgdo_test"
                                           withPrimaryKey:@"record_id"
                                                    forId:refId];
    STAssertTrue([objDelete remove], 
                 @"DataObject Delete failed: %@", [objDelete lastError]);
    [objDelete release];  
    
    // cleanup the table
    tableCmd = [[NSMutableString alloc] init];
    [tableCmd appendString:@"drop table pgdo_test"];
    [connection execCommand:tableCmd];
    [tableCmd release];
}

@end
