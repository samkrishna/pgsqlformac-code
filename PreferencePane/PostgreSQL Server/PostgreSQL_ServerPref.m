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
	thisBundle = [NSBundle bundleWithIdentifier:@"com.druware.postgresqlformac"];
	
	isLocked = YES;
	
	
	// check for a preferences file
	NSFileManager *fm = [[NSFileManager alloc] init];
	if ([fm fileExistsAtPath:@"/Library/Preferences/com.druware.postgresqlformac.plist"])
	{
		// replace with NSUserDefaults/NSGlobalDomain
		
		
		preferences = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/Library/Preferences/com.druware.postgresqlformac.plist"];
		
		if ([preferences objectForKey:@"startAtBoot"] == nil)
		{
			[preferences setValue:@"YES" forKey:@"startAtBoot"];
		}
		
	} else {
		preferences = [[NSMutableDictionary alloc] init];
		// set the defaults
		[preferences setValue:@"/Library/PostgreSQL8/data" forKey:@"dataPath"];
		[preferences setValue:@"/Library/PostgreSQL8/log/PostgreSQL8.log" forKey:@"logPath"];
		[preferences setValue:@"YES" forKey:@"startAtBoot"];
	}
	[[preferences autorelease] retain];	
	
	if ([[preferences valueForKey:@"startAtBoot"] isEqualToString:@"YES"])
	{
		[autostartOption setState:NSOnState];
	} else {
		[autostartOption setState:NSOffState];		
	}
	
	dataPath = [[NSString alloc] initWithString:[preferences objectForKey:@"dataPath"]];
	
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
	
	[autostartOption setEnabled:!isLocked];
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
	
	[progress startAnimation:sender];
	
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
	[progress stopAnimation:nil];
	
	[pool release];
	[NSThread exit];
	
    return;
}


#pragma mark --
#pragma mark Configuration Management Handlers

- (IBAction)onChangeStartAtBoot:(id)sender
{
	// update the preferences and save them.
	[preferences setValue:@"YES" forKey:@"startAtBoot"];
	if ([autostartOption state] == NSOffState)
	{
		[preferences setValue:@"NO" forKey:@"startAtBoot"];
	} 
	[self savePreferencesFile:nil];
}


- (IBAction)onChangePostgreSQLDataPath:(id)sender
{
	// create the owner.
	PGMChangeDataPath *dialogOwner = [[PGMChangeDataPath alloc] init];
	
	[dialogOwner setCurrentPath:[preferences objectForKey:@"dataPath"]];
	[dialogOwner showModalForWindow:[NSApp mainWindow]];

	[self savePreferencesFile:nil];
	
	// !!!TODO!!!
	// if the data path changes, change it in the preferences, check to see 
	// if initidb is needed, and if it is, call initdb, and restart the database.
	
}

- (IBAction)launchNetworkConfiguration:(id)sender
{
	// create the owner.
	[self fetchConfigFile:@"pg_hba.conf"];	
	
	PGMNetworkConfiguration *dialogOwner = [[PGMNetworkConfiguration alloc] init];
	[dialogOwner showModalForWindow:[NSApp mainWindow]];
	
	
	if ([dialogOwner shouldRestartService])
	{
		[self pushConfigFile:@"pg_hba.conf"];
		[self onReloadService:sender];
	}
	
	// Need to delete the temp file(s)
	[self removeFile:@"/var/tmp/pg_hba.conf.in"];
	[self removeFile:@"/var/tmp/pg_hba.conf.out"];
}

- (IBAction)launchPostgreSQLConfiguration:(id)sender
{
	// create the owner.
	[self fetchConfigFile:@"postgresql.conf"];	
	
	PGMPostgreSQLConfiguration *dialogOwner = [[PGMPostgreSQLConfiguration alloc] init];
	[dialogOwner showModalForWindow:[NSApp mainWindow]];
	
	
	if ([dialogOwner shouldRestartService])
	{
		[self pushConfigFile:@"postgresql.conf"];
		[self onReloadService:sender];
	}
	
	// Need to delete the temp file(s)
	[self removeFile:@"/var/tmp/postgresql.conf.in"];
	[self removeFile:@"/var/tmp/postgresql.conf.out"];
}

#pragma mark --
#pragma mark File Management Routines

-(void)fetchConfigFile:(NSString *)fileName
{
	OSStatus myStatus;
	NSString *pathToHelper = [thisBundle pathForResource:@"StartupHelper" ofType:nil];
	
	const char *myToolPath = [pathToHelper cStringUsingEncoding:NSASCIIStringEncoding]; 
	char *myArguments[5];
	
	NSString *myDataPath = [[NSString alloc] initWithFormat:@"%@/%@", dataPath, fileName];
	NSString *myTempPath = [[NSString alloc] initWithFormat:@"/var/tmp/%@.in", fileName];
	
	myArguments[0] = "/bin/cat";
	myArguments[1] = (char *)[myDataPath cStringUsingEncoding:NSASCIIStringEncoding];
	myArguments[2] = ">";
	myArguments[3] = (char *)[myTempPath cStringUsingEncoding:NSASCIIStringEncoding]; 
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

-(void)pushConfigFile:(NSString *)fileName
{
	OSStatus myStatus;
	NSString *pathToHelper = [thisBundle pathForResource:@"StartupHelper" ofType:nil];
	
	const char *myToolPath = [pathToHelper cStringUsingEncoding:NSASCIIStringEncoding]; 
	char *myArguments[5];
	
	NSString *myDataPath = [[NSString alloc] initWithFormat:@"%@/%@", dataPath, fileName];
	NSString *myTempPath = [[NSString alloc] initWithFormat:@"/var/tmp/%@.out", fileName];
	
	myArguments[0] = "/bin/cat";
	myArguments[1] = (char *)[myTempPath cStringUsingEncoding:NSASCIIStringEncoding]; 
	myArguments[2] = ">";
	myArguments[3] = (char *)[myDataPath cStringUsingEncoding:NSASCIIStringEncoding];
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

-(BOOL)removeFile:(NSString *)filePath
{
	OSStatus myStatus;
	NSString *pathToHelper = [thisBundle pathForResource:@"StartupHelper" ofType:nil];
	
	const char *myToolPath = [pathToHelper cStringUsingEncoding:NSASCIIStringEncoding]; 
	char *myArguments[4];
	
	myArguments[0] = "rm";
	myArguments[1] = "-f";
	myArguments[2] = (char *)[filePath cStringUsingEncoding:NSASCIIStringEncoding];
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
	return YES;
}

-(void)savePreferencesFile:(id)sender
{
	OSStatus myStatus;
	NSString *pathToHelper = [thisBundle pathForResource:@"StartupHelper" ofType:nil];
	const char *myToolPath = [pathToHelper cStringUsingEncoding:NSASCIIStringEncoding]; 
	
	if (![preferences writeToFile:@"/var/tmp/com.druware.postgresqlformac.plist" atomically:YES])
	{
		NSLog(@"Failed to write file");
		return;
	}
	
	char *myArguments[5];
	
	myArguments[0] = "/bin/cat";
	myArguments[1] = "/var/tmp/com.druware.postgresqlformac.plist";
	myArguments[2] = ">";
	myArguments[3] = "/Library/Preferences/com.druware.postgresqlformac.plist";
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
	
	[self removeFile:@"/var/tmp/com.druware.postgresqlformac.plist"];
}

@end
