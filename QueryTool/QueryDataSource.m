//
//  QueryDataSource.m
//
//  Created by Andy Satori on Sun 02/08/04 05:38 PM
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QueryDataSource.h"
#import "QueryTool.h"

@implementation QueryDataSource

- (id)init
{
    [super init];
    items = [[NSMutableArray alloc] init];
    
    return self;
}

// collection management

- (NSMutableDictionary *)addItem
{
    NSMutableDictionary *newItem = [[NSMutableDictionary alloc] init];
    
    [items addObject: newItem];
    return newItem;    
}

- (void)removeItemAtIndex:(int)index
{
    [items removeObjectAtIndex:index];
}

- (NSMutableDictionary *)itemAtIndex:(int)index
{
    return [items objectAtIndex:index];
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
