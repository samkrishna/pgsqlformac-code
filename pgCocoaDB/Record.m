//
//  Record.m
//  Query Tool
//
//  Created by Andy Satori on Tue Feb 03 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "Record.h"


@implementation Record

- (id)init
{
    [super init];
    
    fields = [[[[Fields alloc] init] retain] autorelease];
    
    return self;
}

- (Fields *)fields 
{
    return [[fields retain] autorelease];
}

- (NSString *)description
{
	return [fields description];
}

@end
