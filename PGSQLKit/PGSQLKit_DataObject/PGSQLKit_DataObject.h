//
//  PGSQLKit_DataObject.h
//  PGSQLKit_DataObject
//
//  Created by Andrew Satori on 1/30/12.
//  Copyright (c) 2012 Druware Software Designs. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <PGSQLKit/PGSQLKit.h>

@interface PGSQLKit_DataObject : XCTestCase
{
    PGSQLConnection *connection;
}

- (void)testDataObjectList;
- (void)testDataObject_abstime;
- (void)testDataObject_bit;
- (void)testDataObject_boolean;
- (void)testDataObject_bytea;
- (void)testDataObject_char;
- (void)testDataObject_date;
- (void)testDataObject_float4;
- (void)testDataObject_float8;
- (void)testDataObject_int2;
- (void)testDataObject_int4;
- (void)testDataObject_int8;
- (void)testDataObject_interval;
- (void)testDataObject_money;
- (void)testDataObject_numeric;
- (void)testDataObject_text;
- (void)testDataObject_time;
- (void)testDataObject_timestamp;
- (void)testDataObject_timetz;
- (void)testDataObject_timestamptz;
- (void)testDataObject_uuid;
- (void)testDataObject_varbit;
- (void)testDataObject_varchar;
// - (void)testDataObject_xml;

@end
