//
//  Fields.m
//
//  Created by Andy Satori on Wed 02/04/04 12:35 AM
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PGCocoaDB.h"
#import "Field.h"
#import "Fields.h"

@implementation Fields

- (id)init
{
    [super init];
    items = [[NSMutableArray alloc] init];
    
    return self;
}

-(void)dealloc
{
	[items removeAllObjects];
	[items release];
	
	[super dealloc];
}

// collection management

- (Field *)addItem
{
    Field *newItem = [[Field alloc] init];
    
    [items addObject: newItem];
	[newItem release];
    return newItem;    
}

- (void)removeItemAtIndex:(int)anIndex
{
    [items removeObjectAtIndex:anIndex];
}

- (Field *)itemAtIndex:(int)anIndex
{
    return [items objectAtIndex:anIndex];
}

- (int)count
{
    return [items count];
}

- (NSString *)getValueFromName:(NSString *)fieldName
{
	unsigned int i;
	for (i = 0; i < [items count]; i++)
	{
		if ([fieldName compare:[[items objectAtIndex:i] name]] == NSOrderedSame)
		{
			return [[items objectAtIndex:i] value];
		}
	}
	return nil;
}

// table view data source methods

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [items count];
}

- (id)tableView:(NSTableView *)aTableView 
    objectValueForTableColumn:(NSTableColumn *)aTableColumn 
    row:(int)rowIndex 
{
    NSString *ident = [aTableColumn identifier];
    Field *anItem = [items objectAtIndex:rowIndex];
    return [anItem valueForKey:ident];
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
