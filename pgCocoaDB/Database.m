//
//  Database.m
//  Query Tool
//
//  Created by Andy Satori on Sun Feb 01 2004.
//  Copyright (c) 2004 druware software development. All rights reserved.
//

#import "Database.h"

@implementation Database

- (id)init
{
	self = [super init];
	
	name = [[[[NSString alloc] init] retain] autorelease];
	
	return self;
}

- (NSString *)name 
{
    return [[name retain] autorelease];
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
