//
//  SqlMenuCategory.m
//  Query Tool for Postgres
//
//  Created by Andy Satori on Wed May 26 2004.
//  Copyright (c) 2004 druware software designs. All rights reserved.
//

#import "SqlMenuCategory.h"

@implementation SqlDocument (SqlMenuCategory)


- (BOOL)validateMenuItem:(NSMenuItem *)theItem
{
	// onExecuteQuery
    if ( [theItem action] == @selector(onExecuteQuery:) )
	{
        return ([conn isConnected]);
	}

	// onConnect
    if ( [theItem action] == @selector(onConnect:) )
	{
        return (![conn isConnected]);
	}
	
	// onDisconnect
    if ( [theItem action] == @selector(onDisconnect:) )
	{
        return ([conn isConnected]);
	}
	
	return YES;
}

@end
