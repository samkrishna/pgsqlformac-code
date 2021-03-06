//
//  ExplorerNode.m
//  pgCocoaDBn
//
//  Created by Neil Tiffin on 3/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "PGCocoaDB.h"
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
	[children removeAllObjects];	
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
	return [name string];
}

-(NSAttributedString *) attributedName
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

-(NSString *) baseSchema
{
	return baseSchema;
}

-(NSColor *) nameColor
{
	return nameColor;
}

-(UInt32)oid;
{
	return oid;
}

-(void)setName:(NSString *)s
{
	[name release];
	name = [[NSAttributedString alloc] initWithString:s];
}

-(void)setNameColor:(NSColor *)s
{
	[s retain];
	[nameColor release];
	nameColor = s;
}

-(void)setBaseTable:(NSString *)s
{
	[s retain];
	[baseTable release];
	baseTable = s;
}

-(void)setExplorerType:(NSString *)s
{
	[s retain];
	[explorerType release];
	explorerType = s;
}

-(void)setDisplayColumn2:(NSString *)s;
{
	[s retain];
	[displayColumn2 release];
	displayColumn2 = s;
}

-(void)setComment:(NSString *)s;
{
	[s retain];
	[comment release];
	comment = s;
}

-(void)setBaseSchema:(NSString *)s;
{
	[s retain];
	[baseSchema release];
	baseSchema = s;
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
	if (displayColumn2)
	{
		NSLog(@"%@%@ %@", spaces, name, displayColumn2);
	}
	else
	{
		NSLog(@"%@%@", spaces, name);
	}
	for (i = 0; i < [children count]; i++)
	{
		[[children objectAtIndex:i] printLog:indent+2 ];
	}
	[spaces release];
}


@end
