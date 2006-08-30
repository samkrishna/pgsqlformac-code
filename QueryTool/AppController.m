//
//  AppController.m
//  Query Tool for PostgresN
//
//  Created by Neil Tiffin on 8/26/06.
//  Copyright 2006 Performance Champions, Inc.. All rights reserved.
//

#import "AppController.h"
#import "PreferenceController.h"

@implementation AppController

-(IBAction)showPreferencePanel:(id)sender
{
	if(!preferenceController)
	{
		preferenceController = [[PreferenceController alloc] init];
	}
	[[preferenceController window] makeKeyAndOrderFront:self];
}

-(void)dealloc
{
	[preferenceController release];
	[super dealloc];
}
@end
