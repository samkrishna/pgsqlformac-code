//
//  Field.m
//  Query Tool
//
//  Created by Andy Satori on Wed Feb 04 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "Field.h"


@implementation Field

- (id)init
{
    [super init];
    
    name = [[[[NSString alloc] init] retain] autorelease];
    value = [[[[NSString alloc] init] retain] autorelease];
    
    return self;
}


- (NSString *)name {
    return [[name retain] autorelease];
}

- (void)setName:(NSString *)newName {
    if (name != newName) {
        [name release];
        name = [newName copy];
    }
}

- (NSString *)value {
    return [[value retain] autorelease];
}

- (void)setValue:(NSString *)newValue {
    if (value != newValue) {
        [value release];
        value = [newValue copy];
    }
}



@end
