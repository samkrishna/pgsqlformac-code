//
//  menuCategory.m
//  Service Manager
//
//  Created by Andy Satori on Thu Jan 29 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "menuCategory.h"


@implementation SQLServiceManager (MenuDelegateCategory)


- (BOOL)validateMenuItem:(NSMenuItem *)theItem
{
	BOOL isRunning = [self checkPostmasterStatus];
	
    if ( [theItem action] == @selector(onStartService:) )
        return (!isRunning);
    if ( [theItem action] == @selector(onStopService:) )
        return (isRunning);
	
    if ( [theItem action] == @selector(onRestartService:) )
        return (isRunning);
		
	return NO;
}

@end
