//
//  PostgreSQL_ServerPref.m
//  PostgreSQL Server
//
//  Created by Andy Satori on 8/8/08.
//  Copyright (c) 2008 Druware Software Designs. All rights reserved.
//

#import "PostgreSQL_ServerPref.h"
#import "AGProcess.h"

#include <sys/types.h>
#include <sys/uio.h>
#include <unistd.h>



@implementation PostgreSQL_ServerPref

- (void) mainViewDidLoad
{
	// Check the current Status and change to display accordingly.
	updateInterval = 0.5;
	thisBundle = [NSBundle bundleWithIdentifier:@"com.druware.postgresqlserverpreferences"];
	
	isLocked = YES;
	
	[self performSelector:@selector(onTimedUpdate:) withObject:self afterDelay:0.1];
}

#pragma mark --
#pragma mark Lock Management Handlers

- (BOOL)unlockPane
{
	OSStatus myStatus;
    myFlags = kAuthorizationFlagDefaults;
	
    NSString *pathToHelper = [thisBundle pathForResource:@"StartupHelper" ofType:nil];
	
	// myAuthorizationItem.AuthorizationString = "@
    myStatus = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, 
								   myFlags, &myAuthorizationRef);				
    if (myStatus != errAuthorizationSuccess) 
		return NO;
	
	AuthorizationItem myItems = {kAuthorizationRightExecute, [pathToHelper length], (char *)[pathToHelper cString], 0};
	AuthorizationRights myRights = {1, &myItems};
	
	myFlags =  kAuthorizationFlagDefaults |          
	kAuthorizationFlagInteractionAllowed |
	kAuthorizationFlagPreAuthorize |
	kAuthorizationFlagExtendRights;      
	
	
	// this pops the dialog.  If the above AuthItemRIghts includes more than one item, then it will auth all or none.  
	myStatus = AuthorizationCopyRights (myAuthorizationRef, &myRights, 
										kAuthorizationEmptyEnvironment, myFlags, NULL ); // this pops the dialog
	
	if (myStatus == errAuthorizationSuccess) 
	{
		isLocked = NO;
		return YES;
	}
	
	
	isLocked = YES;		
	return NO;
}

- (BOOL)lockPane
{
	if (!isLocked) 
	{
		AuthorizationFree (myAuthorizationRef, kAuthorizationFlagDefaults); 
		isLocked = YES;
		return YES;
	}
	
	return NO;
}

- (IBAction)toggleLock:(id)sender
{
	NSLog(@"got isLocked");
	if (isLocked) 
	{
		[self unlockPane];
	} else {
		[self lockPane];
	}
	
	if (isLocked)
	{
		[lockToggle setState:NSOffState];
	}
	
	return;
}


#pragma mark --
#pragma mark Status Update Handlers

- (void)updateButtonStatus:(BOOL)isRunning
{	
	[startService setEnabled:(!isRunning)];
	[startServiceLabel setEnabled:(!isRunning)];
	
	[stopService setEnabled:isRunning];
	[stopServiceLabel setEnabled:isRunning];
	
	[restartService setEnabled:isRunning];
	[restartServiceLabel setEnabled:isRunning];
	
	if (isRunning)
	{
		// set the image to running
		NSString *imagePath = [thisBundle pathForResource:@"xserve-running" ofType:@"png"];
		NSImage *image = [[NSImage alloc] initWithContentsOfFile:imagePath];
		[serviceImage setImage:image];
		[status setStringValue:@"Current Status: Running"];
		
	} else {
		// set the image to stopped
		NSString *imagePath = [thisBundle pathForResource:@"xserve-stopped" ofType:@"png"];
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

- (IBAction)onTimedUpdate:(id)sender
{
	[self updateButtonStatus:[self checkPostmasterStatus]];
	[self performSelector:@selector(onTimedUpdate:) withObject:self afterDelay:updateInterval];
}

#pragma mark --
#pragma mark Service Management Handlers

- (IBAction)onRestartService:(id)sender
{
	// if locked, need to unlock before calling exec
	if (isLocked) 
	{
		[self toggleLock:sender];
	}
	
	if (isLocked)
	{
		return;
	}
	
	if (command != nil) 
	{
		[command release];
		command = nil;
	}
 	command = [[NSString alloc] initWithString:@"/Library/StartupItems/PostgreSQL/PostgreSQL"];
	
	if (operation != nil)
	{
		[operation release];
		operation = nil;
	}
 	operation = [[NSString alloc] initWithString:@"restart"];
	
	[NSThread detachNewThreadSelector:@selector(execStartupWithRights) toTarget:self withObject:operation];	
	
    return;	
}

- (IBAction)onStartService:(id)sender
{
	// if locked, need to unlock before calling exec
	if (isLocked) 
	{
		[self toggleLock:sender];
	}
	
	if (isLocked)
	{
		return;
	}
	
	if (command != nil) 
	{
		[command release];
		command = nil;
	}
 	command = [[NSString alloc] initWithString:@"/Library/StartupItems/PostgreSQL/PostgreSQL"];
	
	if (operation != nil)
	{
		[operation release];
		operation = nil;
	}
 	operation = [[NSString alloc] initWithString:@"start"];
	
	[NSThread detachNewThreadSelector:@selector(execStartupWithRights) toTarget:self withObject:operation];	
    return;	
}

- (IBAction)onStopService:(id)sender
{	
	// if locked, need to unlock before calling exec
	if (isLocked) 
	{
		[self toggleLock:sender];
	}
	
	if (isLocked)
	{
		return;
	}
	
	if (command != nil) 
	{
		[command release];
		command = nil;
	}
 	command = [[NSString alloc] initWithString:@"/Library/StartupItems/PostgreSQL/PostgreSQL"];
	
	if (operation != nil)
	{
		[operation release];
		operation = nil;
	}
 	operation = [[NSString alloc] initWithString:@"stop"];
	
	[working startAnimation:sender];
	
	[NSThread detachNewThreadSelector:@selector(execStartupWithRights) toTarget:self withObject:operation];	
	
    return;	
}

- (void)execStartupWithRights
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
    OSStatus myStatus;
    
	NSString *pathToHelper = [thisBundle pathForResource:@"StartupHelper" ofType:nil];

	const char *myToolPath = [pathToHelper cString]; 
	char *myArguments[4];
	
	myArguments[0] = (char *)[command cString];
	myArguments[1] = (char *)[operation cString];
	myArguments[2] = "MANUAL";
	myArguments[3] = NULL;
	
	FILE *myCommunicationsPipe = NULL;
	
	myFlags = kAuthorizationFlagDefaults;			
	myStatus = AuthorizationExecuteWithPrivileges(myAuthorizationRef, 
												  myToolPath, myFlags, myArguments, &myCommunicationsPipe);      
	
	if (myStatus == errAuthorizationSuccess)
		for(;;)
		{
			
			char myReadBuffer[4096];
			
			int bytesRead = read(fileno(myCommunicationsPipe),
								 myReadBuffer, sizeof(myReadBuffer));
			if (bytesRead < 1) break;
		} 
	
	// update the buttons
	[working stopAnimation:nil];
	
	[pool release];
	[NSThread exit];
	
    return;
}


#pragma mark --
#pragma mark Configuration Management Handlers

- (IBAction)launchNetworkConfiguration:(id)sender
{
	return;
}




@end
