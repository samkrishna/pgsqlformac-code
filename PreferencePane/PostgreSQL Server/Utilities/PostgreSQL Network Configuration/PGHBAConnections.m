//
//  PGHBAConnections.m
//  PostgreSQL Network Configuration
//
//  Created by Andy Satori on 1/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PGHBALocalConnections.h"


@implementation PGHBAConnections

-(id)init
{
	self = [super init];
	
	if (self != nil) {
		// perform custom implementation details (if required)
	
	}
	
    return self;
}

// table view data source methods

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [self count];
}

- (id)tableView:(NSTableView *)aTableView 
	objectValueForTableColumn:(NSTableColumn *)aTableColumn 
			row:(int)rowIndex 
{
    NSString *ident = [aTableColumn identifier];
    NSMutableDictionary *anItem = [self objectAtIndex:rowIndex];
    return [anItem valueForKey:ident];
}

- (void)tableView:(NSTableView *)aTableView 
   setObjectValue:(id)anObject 
   forTableColumn:(NSTableColumn *)aTableColumn 
			  row:(NSInteger)rowIndex
{
	// NSString *ident = [aTableColumn identifier];
    NSMutableDictionary *anItem = [self objectAtIndex:rowIndex];
	
	if ([[aTableColumn identifier] compare:@"isKey"] == NSOrderedSame)
	{
		[anItem setValue:anObject forKey:@"isKey"];			
	}
	
}

@end
