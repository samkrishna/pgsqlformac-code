//
//  ExplorerNode.m
//  pgCocoaDBn
//
//  Created by Neil Tiffin on 3/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "ExplorerNode.h"


@implementation ExplorerNode

-(id)init
{
	[super init];
	
	children = [[NSMutableArray alloc] init];
	
	return self;
}

-(void)dealloc
{
	/* TODO release each child first */
	[children release];
	children = nil;
	
	[name release];
	name = nil;
	
	[baseTable release];
	baseTable = nil;
	
	[explorerType release];
	explorerType = nil;
	
	[displayColumn2 release];
	displayColumn2 = nil;
	
	[super dealloc];
}


-(NSString *) name
{
	return name;
}


-(NSString *) baseTable
{
	return baseTable;
}


-(NSString *) explorerType
{
	return explorerType;
}


-(NSString *) displayColumn2
{
	return displayColumn2;
}

-(NSString *) comment
{
	return comment;
}


-(UInt32)oid;
{
	return oid;
}

-(void)setName:(NSString *)s
{
	[name release];
	name = s;
	[name retain];
}

-(void)setBaseTable:(NSString *)s;
{
	[baseTable release];
	baseTable = s;
	[baseTable retain];
}

-(void)setExplorerType:(NSString *)s;
{
	[explorerType release];
	explorerType = s;
	[explorerType retain];
}

-(void)setDisplayColumn2:(NSString *)s;
{
	[displayColumn2 release];
	displayColumn2 = s;
	[displayColumn2 retain];
}

-(void)setComment:(NSString *)s;
{
	[comment release];
	comment = s;
	[comment retain];
}

-(void)setOID:(UInt32)o;
{
	oid = o;
}

// Accessors for the parent node
- (ExplorerNode *)parent
{
	return parent;
}

- (void)setParent:(ExplorerNode *)n
{
	//weak reference
	parent = n;
}

	// Accessors for the children
- (void)addChild:(ExplorerNode *)n
{
	[n setParent:self];
    [children addObject:n];	
}

- (int)childrenCount
{
	return [children count];
}

- (ExplorerNode *)childAtIndex:(int)i
{
    return [children objectAtIndex:i];
}

	// Other properties
- (BOOL)expandable
{
	return ([children count] > 0);
}

- (void)printLog:(unsigned int)indent
{
	unsigned int i;
	NSMutableString * spaces = [[NSMutableString alloc] init];
	for (i = 0; i < indent; i++)
	{
		[spaces appendString:@" "];
	}
	NSLog(@"%@%@", spaces, name);
	for (i = 0; i < [children count]; i++)
	{
		[[children objectAtIndex:i] printLog:indent+2 ];
	}
	[spaces release];
}


@end
