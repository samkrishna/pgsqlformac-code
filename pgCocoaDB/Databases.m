//
//  Databases.m
//
//  Created by Andy Satori on Thu 01/29/04 10:53 PM
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PGCocoaDB.h"
#import "Database.h"
#import "Databases.h"

@implementation Databases

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

- (Database *)addItem
{
    Database *newItem = [[Database alloc] init];
    
    [items addObject: newItem];
	[newItem release];
    return newItem;    
}

- (void)removeItemAtIndex:(int)anIndex
{
    [items removeObjectAtIndex:anIndex];
}

- (Database *)itemAtIndex:(int)anIndex
{
    return [items objectAtIndex:anIndex];
}

- (int)count
{
    return [items count];
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
    Database *anItem = [items objectAtIndex:rowIndex];
    return [anItem valueForKey:ident];
}

@end
