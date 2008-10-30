//
//  PostgreSQL_ServerPref.m
//  PostgreSQL Server
//
//  Created by Andy Satori on 8/8/08.
//  Copyright (c) 2008 Druware Software Designs. All rights reserved.
//

#import "PostgreSQL_ServerPref.h"
#import "AGProcess.h"

#include <Security/Authorization.h>
#include <Security/AuthorizationTags.h>

@implementation PostgreSQL_ServerPref

- (void) mainViewDidLoad
{
	// Check the current Status and change to display accordingly.
	[self updateButtonStatus:[self checkPostmasterStatus]];
}

- (void)updateButtonStatus:(BOOL)isRunning
{	
	NSBundle *bundleApp = [NSBundle bundleWithIdentifier:@"com.druware.postgresqlserverpreferences"];
	
	[startService setEnabled:(!isRunning)];
	[startServiceLabel setEnabled:(!isRunning)];
	
	[stopService setEnabled:isRunning];
	[stopServiceLabel setEnabled:isRunning];
	
	[restartService setEnabled:isRunning];
	[restartServiceLabel setEnabled:isRunning];
	
	if (isRunning)
	{
		// set the image to running
		NSString *imagePath = [bundleApp pathForResource:@"xserve-running" ofType:@"png"];
		NSImage *image = [[NSImage alloc] initWithContentsOfFile:imagePath];
		[serviceImage setImage:image];
		[status setStringValue:@"Current Status: Running"];
		
	} else {
		// set the image to stopped
		NSString *imagePath = [bundleApp pathForResource:@"xserve-stopped" ofType:@"png"];
		NSImage *image = [[NSImage alloc] initWithContentsOfFile:imagePath];
		[serviceImage setImage:image];
		[status setStringValue:@"Current Status: Down"];
	}
	
	return;
}

- (BOOL)checkPostmasterStatus
{
	// check the current run state of postmaster
	NSString *serverProcessName = [[NSString alloc] initWithString:@"postgres"];
	NSString *serverProcessNameAlt = [[NSString alloc] initWithString:@"postmaster"];
	NSArray *processes = [AGProcess allProcesses];
	int i;
	for (i = 0; i < [processes count]; i++)
	{
		AGProcess *process = (AGProcess *)[processes objectAtIndex:i];		
		if ([[process command] isEqual:serverProcessName])
		{
			return YES;
		}
		if ([[process command] isEqual:serverProcessNameAlt])
		{
			return YES;
		}
	}
	return NO;
}


- (void)execWithRights
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
    OSStatus myStatus;
    AuthorizationFlags myFlags = kAuthorizationFlagDefaults;
    AuthorizationRef myAuthorizationRef;
	
    NSBundle *bundleApp = [NSBundle mainBundle];
    NSString *pathToHelper = [bundleApp pathForResource:@"StartupHelper" ofType:nil];
	
	// myAuthorizationItem.AuthorizationString = "@
    myStatus = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, 
								   myFlags, &myAuthorizationRef);				
    if (myStatus != errAuthorizationSuccess) 
		return;
	
    do 
    {
		AuthorizationItem myItems = {kAuthorizationRightExecute, [pathToHelper length], [pathToHelper cString], 0};
		AuthorizationRights myRights = {1, &myItems};
		
		myFlags =  kAuthorizationFlagDefaults |          
		kAuthorizationFlagInteractionAllowed |
		kAuthorizationFlagPreAuthorize |
		kAuthorizationFlagExtendRights;         
		myStatus = AuthorizationCopyRights (myAuthorizationRef, &myRights, 
											kAuthorizationEmptyEnvironment, myFlags, NULL );
		
        if (myStatus == errAuthorizationSuccess) 
		{
			const char *myToolPath = [pathToHelper cString]; 
			char *myArguments[4];
			
			myArguments[0] = [command cString];
			myArguments[1] = [operation cString];
			myArguments[2] = "MANUAL";
			myArguments[3] = NULL;
			
			FILE *myCommunicationsPipe = NULL;
			char myReadBuffer[128];
			
			myFlags = kAuthorizationFlagDefaults;			
			myStatus = AuthorizationExecuteWithPrivileges(myAuthorizationRef, 
														  myToolPath, myFlags, myArguments, &myCommunicationsPipe);      
			
			if (myStatus == errAuthorizationSuccess)
				for(;;)
				{
					int bytesRead = read (fileno (myCommunicationsPipe),
										  myReadBuffer, sizeof (myReadBuffer));
					if (bytesRead < 1) break;
					NSLog(@"%s", myReadBuffer);
				}			
		}
    } while (0);
	
    AuthorizationFree (myAuthorizationRef, kAuthorizationFlagDefaults);                
	
    if (myStatus) NSLog(@"Status: %i\n", myStatus);
	
	sleep(3);
	
	// update the buttons
	BOOL isRunning = [self checkPostmasterStatus];
	[self updateButtonStatus:isRunning];
	[working stopAnimation:nil];
	
	[pool release];
	[NSThread exit];
	
    return;
}

- (IBAction)onStartService:(id)sender
{
	return;
}

- (IBAction)launchNetworkConfiguration:(id)sender
{
	return;
}

@end
