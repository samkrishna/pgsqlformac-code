//
//  RecordSet.m
//
//  Created by Andy Satori on Mon 02/02/04 12:36 PM
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RecordSet.h"

@implementation RecordSet

- (id)init
{
    [super init];
    
    items = [[NSMutableArray alloc] init];
    [items retain];
    
    return self;
}

// collection management

- (Record *)addItem
{
    Record *newItem = [[Record alloc] init];
    [newItem retain];
    
    [items addObject:newItem];
    return newItem;    
}

- (void)removeItemAtIndex:(int)index
{
    [items removeObjectAtIndex:index];
}

- (Record *)itemAtIndex:(int)index
{
    return [items objectAtIndex:index];
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
