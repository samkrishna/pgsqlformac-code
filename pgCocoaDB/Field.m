//
//  Field.m
//  Query Tool
//
//  Created by Andy Satori on Wed Feb 04 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "PGCocoaDB.h"
#import "Field.h"


@implementation Field

- (id)init
{
    [super init];
    
    name = nil;
    value = nil;
    
    return self;
}

-(void)dealloc
{
	[name release];
	[value release];
		
	[super dealloc];
}


- (NSString *)name {
    return name;
}

- (void)setName:(NSString *)newName {
    if (name != newName) {
        [name release];
        name = newName;
		[name retain];
    }
}

- (NSString *)value {
    return value;
}

- (void)setValue:(NSString *)newValue {
    if (value != newValue) {
        [value release];
        value = newValue;
		[value retain];
    }
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"'%@' '%@'", name, value];
}

- (NSString *)format
{
	return format;
}

- (void)setFormat:(NSString *)newValue;
{
	[format release];
	format = newValue;
	[format retain];
}
@end
