//
//  Fields.m
//
//  Created by Andy Satori on Wed 02/04/04 12:35 AM
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Field.h"
#import "Fields.h"

@implementation Fields

- (id)init
{
    [super init];
    
    items = [[NSMutableArray alloc] init];
    [items retain];
    
    return self;
}

// collection management

- (Field *)addItem
{
    Field *newItem = [[Field alloc] init];
    [newItem retain];
    
    [items addObject: newItem];
    return newItem;    
}

- (void)removeItemAtIndex:(int)index
{
    [items removeObjectAtIndex:index];
}

- (Field *)itemAtIndex:(int)index
{
    return [items objectAtIndex:index];
}

- (int)count
{
    return [items count];
}

- (NSString *)getValueFromName:(NSString *)fieldName
{
	int i;
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

@end
