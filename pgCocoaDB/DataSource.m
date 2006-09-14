//
//  DataSource.m
//
//  Created by Andy Satori on Sun 02/08/04 05:38 PM
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PGCocoaDB.h"
#import "DataSource.h"

@implementation DataSource

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

- (NSMutableDictionary *)addItem
{
    NSMutableDictionary *newItem = [[NSMutableDictionary alloc] init];
    
    [items addObject: newItem];
	[newItem release];
    return newItem;    
}

- (void)removeItemAtIndex:(int)anIndex
{
    [items removeObjectAtIndex:anIndex];
}

- (NSMutableDictionary *)itemAtIndex:(int)anIndex
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
    NSMutableDictionary *anItem = [items objectAtIndex:rowIndex];
    return [anItem valueForKey:ident];
}

@end
