//
//  Table.m
//  Query Tool
//
//  Created by Andy Satori on Sun Feb 08 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "Table.h"


@implementation Table

-(id)init
{
	[super init];
	NSLog(@"Created Table.h");
	return self;
}

-(void)dealloc
{
	[schema release];
	[name release];
	[owner release];
	[super dealloc];
}

- (NSString *)schema {
    return [[schema retain] autorelease];
}

- (void)setSchema:(NSString *)newSchema {
    if (schema != newSchema) {
        [schema release];
        schema = [newSchema copy];
    }
}

- (NSString *)name {
    return [[name retain] autorelease];
}

- (void)setName:(NSString *)newName {
    if (name != newName) {
        [name release];
        name = [newName copy];
    }
}

- (NSString *)owner {
    return [[owner retain] autorelease];
}

- (void)setOwner:(NSString *)newOwner {
    if (owner != newOwner) {
        [owner release];
        owner = [newOwner copy];
    }
}

- (BOOL)hasIndexes {
    return hasIndexes;
}

- (void)setHasIndexes:(BOOL)newHasIndexes {
	hasIndexes = newHasIndexes;
}

- (BOOL)hasRules {
    return hasRules;
}

- (void)setHasRules:(BOOL)newHasRules {
	hasRules = newHasRules;
}

- (BOOL)hasTriggers {
    return hasTriggers;
}

- (void)setHasTriggers:(BOOL)newHasTriggers {
	hasTriggers = newHasTriggers;
}


@end
