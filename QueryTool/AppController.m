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

-(id)init
{
	[super init];
	//NSLog(@"AppController init");
	preferenceController = [[PreferenceController alloc] init];
	[preferenceController createApplicationDefaultPreferences];
	return self;
}

-(IBAction)showPreferencePanel:(id)sender
{
	UNUSED_PARAMETER(sender);
	
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
