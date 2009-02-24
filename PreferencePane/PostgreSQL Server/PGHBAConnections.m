//
//  PGHBAConnections.m
//  PostgreSQL Network Configuration
//
//  Created by Andy Satori on 1/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PGHBAConnections.h"


@implementation PGHBAConnections

-(id)init
{
	self = [super init];
	
	if (self != nil) {
		// perform custom implementation details (if required)
		items = [[NSMutableArray alloc] init];
		[[items autorelease] retain];
	}
	
    return self;
}

- (NSMutableArray *)items
{
	return items;
}

- (void)setItems:(NSMutableDictionary *)value
{
	if (items != value)
	{
		[items release];
		items = [[NSMutableArray alloc] initWithArray:(id)value];
		[[items autorelease] retain];
	}
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

- (void)tableView:(NSTableView *)aTableView 
   setObjectValue:(id)anObject 
   forTableColumn:(NSTableColumn *)aTableColumn 
			  row:(int)rowIndex
{
	// NSString *ident = [aTableColumn identifier];
    NSMutableDictionary *anItem = [items objectAtIndex:rowIndex];
	
	if ([[aTableColumn identifier] compare:@"isKey"] == NSOrderedSame)
	{
		[anItem setValue:anObject forKey:@"isKey"];			
	}
	
}

@end
