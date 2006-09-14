//
//  RecordSet.m
//
//  Created by Andy Satori on Mon 02/02/04 12:36 PM
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PGCocoaDB.h"
#import "RecordSet.h"

@implementation RecordSet

- (id)init
{
    [super init];
    items = [[NSMutableArray alloc] init];
    
    return self;
}

-(void) dealloc
{
	[items removeAllObjects];
	[items release];
	
	[super dealloc];
}

// collection management

- (Record *)addItem
{
    Record *newItem = [[Record alloc] init];

    [items addObject:newItem];
	[newItem release];
    return newItem;    
}

- (void)removeItemAtIndex:(int)anIndex
{
    [items removeObjectAtIndex:anIndex];
}

- (Record *)itemAtIndex:(int)anIndex
{
    return [items objectAtIndex:anIndex];
}

- (int)count
{
    return [items count];
}

- (NSString *)description
{
	unsigned int i;
	NSMutableString * text;
	text = [[[NSMutableString alloc] init] autorelease];
	
	for (i = 0; i < [items count]; i++)
	{
		[text appendString:[[items objectAtIndex:i] description]];
		[text appendString:@"\n"];
	}
	return text;
}


@end
