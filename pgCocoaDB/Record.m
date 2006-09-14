//
//  Record.m
//  Query Tool
//
//  Created by Andy Satori on Tue Feb 03 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "PGCocoaDB.h"
#import "Record.h"


@implementation Record

- (id)init
{
    [super init];
    
    fields = [[Fields alloc] init];
    
    return self;
}

-(void)dealloc
{
	[fields release];
	
	[super dealloc];
}

- (Fields *)fields 
{
    return fields;
}

- (NSString *)description
{
	return [fields description];
}

@end
