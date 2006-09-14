//
//  Database.m
//  Query Tool
//
//  Created by Andy Satori on Sun Feb 01 2004.
//  Copyright (c) 2004 druware software development. All rights reserved.
//

#import "PGCocoaDB.h"
#import "Database.h"

@implementation Database

- (id)init
{
	self = [super init];
	
	name = nil;
	
	return self;
}

-(void)dealloc
{
	[name release];
	[super dealloc];
}

- (NSString *)name 
{
    return name;
}

- (void)setName:(NSString *)newName 
{
    if (name != newName) 
	{
        [name release];
        name = [newName copy];
    }
}

@end
