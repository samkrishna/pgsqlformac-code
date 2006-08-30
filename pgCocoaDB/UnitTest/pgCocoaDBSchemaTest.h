//
//  pgCocoaDBSchemaTest.h
//  pgCocoaDB
//
//  Created by Neil Tiffin on 3/4/06.
//  Copyright 2006 Performance Champions, Inc. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "Connection.h"
#import "Schema.h"
#import "PGCocoaDB.h"

@interface pgCocoaDBSchemaTest : SenTestCase {
	Connection * conn;
	Schema * testSchema;
}

- (void) createDatabase;

@end
