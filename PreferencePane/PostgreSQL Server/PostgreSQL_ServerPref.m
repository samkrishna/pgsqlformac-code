//
//  PostgreSQL_ServerPref.m
//  PostgreSQL Server
//
//  Created by Andy Satori on 8/8/08.
//  Copyright (c) 2008 Druware Software Designs. All rights reserved.
//

#import "PostgreSQL_ServerPref.h"
#import "AGProcess.h"
#import "PGMChangeDataPath.h"
#import "PGMNetworkConfiguration.h"
#import "PGMPostgreSQLConfiguration.h"

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
	
	preferences = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/Library/Preferences/com.druware.postgresqlformac.plist"];
	[[preferences autorelease] retain];
	
	[self onTimedUpdate:nil];
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
	
	[changeDataPath setEnabled:!isLocked];
	[modifyNetworkConfiguration setEnabled:!isLocked];
	[modifyPostgreSQLConfiguration setEnabled:!isLocked];
	
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
	if (option != nil)
	{
		[option release];
		option = nil;
	}
	
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
	
	if (option != nil)
	{
		[option release];
		option = nil;
	}
	
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
	
	if (option != nil)
	{
		[option release];
		option = nil;
	}
	
	[working startAnimation:sender];
	
	[NSThread detachNewThreadSelector:@selector(execStartupWithRights) toTarget:self withObject:operation];	
	
    return;	
}

- (IBAction)onReloadService:(id)sender
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
	
	if (option != nil)
	{
		[option release];
		option = nil;
	}
 	option = [[NSString alloc] initWithString:@"RELOAD"];
	
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
	if (option != nil)	
	{
		myArguments[2] = (char *)[option cString];;
	} else {
		myArguments[2] = "MANUAL";
	}
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

- (IBAction)onChangePostgreSQLDataPath:(id)sender
{
	// create the owner.
	PGMChangeDataPath *dialogOwner = [[PGMChangeDataPath alloc] init];
	
	[dialogOwner setCurrentPath:[preferences objectForKey:@"dataPath"]];
	[dialogOwner showModalForWindow:[NSApp mainWindow]];

	// !!!TODO!!!
	// if the data path changes, change it in the preferences, check to see 
	// if initidb is needed, and if it is, call initdb, and restart the database.
	
}

- (IBAction)launchNetworkConfiguration:(id)sender
{
	// create the owner.
	[self fetchHBAConfiguration:sender];
	
	PGMNetworkConfiguration *dialogOwner = [[PGMNetworkConfiguration alloc] init];
	[dialogOwner showModalForWindow:[NSApp mainWindow]];
	
	
	if ([dialogOwner shouldRestartService])
	{
		[self pushHBAConfiguration:sender];
		[self onReloadService:sender];
	}
	
	// Need to delete the temp file(s)
	[self removeTempHBAFiles:nil];
	
}

- (IBAction)launchPostgreSQLConfiguration:(id)sender
{
	// create the owner.
	[self fetchPGConfiguration:sender];
	
	PGMPostgreSQLConfiguration *dialogOwner = [[PGMPostgreSQLConfiguration alloc] init];
	[dialogOwner showModalForWindow:[NSApp mainWindow]];
	
	
	if ([dialogOwner shouldRestartService])
	{
		[self pushPGConfiguration:sender];
		[self onReloadService:sender];
	}
	
	// Need to delete the temp file(s)
	[self removeTempPGFiles:nil];
	
}

#pragma mark --
#pragma mark File Management Routines

-(IBAction)fetchHBAConfiguration:(id)sender
{
	OSStatus myStatus;
	NSString *pathToHelper = [thisBundle pathForResource:@"StartupHelper" ofType:nil];

	const char *myToolPath = [pathToHelper cStringUsingEncoding:NSASCIIStringEncoding]; 
	char *myArguments[5];
	
	myArguments[0] = "/bin/cat";
	myArguments[1] = "/Library/PostgreSQL8/data/pg_hba.conf";
	myArguments[2] = ">";
	myArguments[3] = "/var/tmp/pg_hba.conf.in";
	myArguments[4] = NULL;
	
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

-(IBAction)pushHBAConfiguration:(id)sender
{
	OSStatus myStatus;
	NSString *pathToHelper = [thisBundle pathForResource:@"StartupHelper" ofType:nil];
	
	const char *myToolPath = [pathToHelper cStringUsingEncoding:NSASCIIStringEncoding]; 
	char *myArguments[5];
	
	myArguments[0] = "/bin/cat";
	myArguments[1] = "/var/tmp/pg_hba.conf.out";
	myArguments[2] = ">";
	myArguments[3] = "/Library/PostgreSQL8/data/pg_hba.conf";
	myArguments[4] = NULL;
	
	NSLog(@"pushing configuration");
	
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

-(IBAction)removeTempHBAFiles:(id)sender
{
	OSStatus myStatus;
	NSString *pathToHelper = [thisBundle pathForResource:@"StartupHelper" ofType:nil];
	
	const char *myToolPath = [pathToHelper cStringUsingEncoding:NSASCIIStringEncoding]; 
	char *myArguments[4];
	
	myArguments[0] = "rm";
	myArguments[1] = "-f";
	myArguments[2] = "/var/tmp/pg_hba.conf.in";
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
	
	myArguments[0] = "rm";
	myArguments[1] = "-f";
	myArguments[2] = "/var/tmp/pg_hba.conf.out";
	myArguments[3] = NULL;	
	
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

-(IBAction)fetchPGConfiguration:(id)sender
{
	OSStatus myStatus;
	NSString *pathToHelper = [thisBundle pathForResource:@"StartupHelper" ofType:nil];
	
	const char *myToolPath = [pathToHelper cStringUsingEncoding:NSASCIIStringEncoding]; 
	char *myArguments[5];
	
	myArguments[0] = "/bin/cat";
	myArguments[1] = "/Library/PostgreSQL8/data/postgresql.conf";
	myArguments[2] = ">";
	myArguments[3] = "/var/tmp/postgresql.conf.in";
	myArguments[4] = NULL;
	
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

-(IBAction)pushPGConfiguration:(id)sender
{
	OSStatus myStatus;
	NSString *pathToHelper = [thisBundle pathForResource:@"StartupHelper" ofType:nil];
	
	const char *myToolPath = [pathToHelper cStringUsingEncoding:NSASCIIStringEncoding]; 
	char *myArguments[5];
	
	myArguments[0] = "/bin/cat";
	myArguments[1] = "/var/tmp/postgresql.conf.out";
	myArguments[2] = ">";
	myArguments[3] = "/Library/PostgreSQL8/data/postgresql.conf";
	myArguments[4] = NULL;
	
	NSLog(@"pushing configuration");
	
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

-(IBAction)removeTempPGFiles:(id)sender
{
	OSStatus myStatus;
	NSString *pathToHelper = [thisBundle pathForResource:@"StartupHelper" ofType:nil];
	
	const char *myToolPath = [pathToHelper cStringUsingEncoding:NSASCIIStringEncoding]; 
	char *myArguments[4];
	
	myArguments[0] = "rm";
	myArguments[1] = "-f";
	myArguments[2] = "/var/tmp/postgresql.conf.in";
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
	
	myArguments[0] = "rm";
	myArguments[1] = "-f";
	myArguments[2] = "/var/tmp/postgresql.conf.out";
	myArguments[3] = NULL;	
	
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


@end
