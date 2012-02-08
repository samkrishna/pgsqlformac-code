//
//  PGSQLKit_Tests.m
//  PGSQLKit_Tests
//
//  Created by Andrew Satori on 1/30/12.
//  Copyright (c) 2012 Druware Software Development. All rights reserved.
//

#import "PGSQLKit_Tests.h"

@implementation PGSQLKit_Tests

- (void)setUp
{
    [super setUp];
    

}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testConnection
{
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
    
    // release the connectoin
    [connection close];
    [connection release];
}

@end
