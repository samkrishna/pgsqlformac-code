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

    // Note that you have to build the project once to make version.h available.
    // version.h is not (or should not be) in scm because it changes with every build.
#import "version.h"

#include <sys/types.h>
#include <sys/uio.h>
#include <unistd.h>


@interface PostgreSQL_ServerPref()

@property (weak) IBOutlet NSTextField *debugBuildDateTextLable;

@property (strong, nonatomic) NSArray *postgresqlForMacPgConfigPaths;
@property (strong, nonatomic) NSString *mainPathPgConfigPath;

@end

@implementation PostgreSQL_ServerPref

    // call using [PostgreSQL_ServerPref debugErrorBreakInCode:@""];
    // will cause the debugger to breakpoint
+ (void)debugErrorBreakInCode:(NSString *)errorString
{
#ifdef DEBUG
    [NSException raise:@"Debug Error" format:@"%@", errorString];
#else
    return;
#endif
}

- (void) searchUsingPGConfig
{
        // Search for postgresql using the results from pg_config using 'pg_config --bindir'
}

- (void) checkForAvailableVersions
{
        // get alternate version list
        // get current version --
        // /Library/PostgreSQL8/bin/psql --version |  grep psql | awk -F" " '{print $3}'
        // alternate versions
        // /Library/PostgreSQL8/versions
	
        //NSString *file;
    
    NSFileManager *defaultFM = [NSFileManager defaultManager];
    NSError *error;
	
    self.postgresqlForMacPgConfigPaths = [defaultFM contentsOfDirectoryAtPath:@"/Library/PostgreSQL/versions/" error:&error];
	for (NSString *directory in self.postgresqlForMacPgConfigPaths)
	{
		NSLog(@"%@", directory);
	}
}

- (void) mainViewDidLoad
{
	// Check the current Status and change to display accordingly.
	updateInterval = 0.5;
	thisBundle = [NSBundle bundleWithIdentifier:@"com.druware.postgresqlformac"];
	
	isLocked = YES;
	
        // Update the build date text field if necessary.
    [self.debugBuildDateTextLable setEditable:NO];
    [self.debugBuildDateTextLable setSelectable:YES];
    [self.debugBuildDateTextLable setHidden:YES];

#ifdef DEBUG
#ifdef BUILD_TIMESTAMP
    NSString *debugString = [NSString stringWithFormat:@"Debug Build: %@", BUILD_TIMESTAMP];
    [self.debugBuildDateTextLable setStringValue:debugString];
    [self.debugBuildDateTextLable setHidden:NO];
#endif
#endif
    
    [self checkForAvailableVersions];

        // check for a preferences file
	NSFileManager *fm = [[NSFileManager alloc] init];
	if ([fm fileExistsAtPath:DRUWARE_PREF_FILE_NSSTRING])
	{
		// replace with NSUserDefaults/NSGlobalDomain
		
		preferences = [[NSMutableDictionary alloc] initWithContentsOfFile:DRUWARE_PREF_FILE_NSSTRING];
		
		if (preferences[PREF_KEY_DATA_PATH] == nil)
		{
			[preferences setValue:@"/Library/PostgreSQL/data" forKey:PREF_KEY_DATA_PATH];
		}
		if (preferences[PREF_KEY_LOG_PATH] == nil)
		{
			[preferences setValue:@"/Library/PostgreSQL/log/PostgreSQL.log" forKey:PREF_KEY_LOG_PATH];
		}
		if (preferences[PREF_KEY_START_AT_BOOT] == nil)
		{
			[preferences setValue:@"YES" forKey:PREF_KEY_START_AT_BOOT];
		}
		if (preferences[PREF_KEY_PORT_NUMBER] == nil)
		{
			[preferences setValue:@"5432" forKey:PREF_KEY_PORT_NUMBER];
		}
		if (preferences[PREF_KEY_BIN_PATH] == nil)
		{
			[preferences setValue:@"/Library/PostgreSQL/bin" forKey:PREF_KEY_BIN_PATH];
		}
		
	} else {
        
            // create the initial defaults
		preferences = [[NSMutableDictionary alloc] init];
		[preferences setValue:@"/Library/PostgreSQL/data" forKey:PREF_KEY_DATA_PATH];
		[preferences setValue:@"/Library/PostgreSQL/log/PostgreSQL.log" forKey:PREF_KEY_LOG_PATH];
		[preferences setValue:@"YES" forKey:PREF_KEY_START_AT_BOOT];
		[preferences setValue:@"5432" forKey:PREF_KEY_PORT_NUMBER];
		[preferences setValue:@"/Library/PostgreSQL/bin" forKey:PREF_KEY_BIN_PATH];
	}
	
	if ([[preferences valueForKey:PREF_KEY_START_AT_BOOT] isEqualToString:@"YES"])
	{
		[autostartOption setState:NSOnState];
	} else {
		[autostartOption setState:NSOffState];		
	}
	
	dataPath = [[NSString alloc] initWithString:preferences[PREF_KEY_DATA_PATH]];
    
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
	
	AuthorizationItem myItems = {kAuthorizationRightExecute, [pathToHelper length], (char *)[pathToHelper cStringUsingEncoding:NSMacOSRomanStringEncoding], 0};
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
        [self savePreferencesFile:nil];    // for the time being make sure we always have saved the pref file so it can be used by PGMChangeDataPath.
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
	NSString *serverProcessName = @"postgres";
	NSString *serverProcessNameAlt = @"postmaster";
	NSArray *processes = [AGProcess allProcesses];
	int i;
	for (i = 0; i < [processes count]; i++)
	{
		AGProcess *process = (AGProcess *)processes[i];	
		if ([process command] != nil) 
		{
			if ([[process command] isEqual:serverProcessName])
			{
				return YES;
			}
			if ([[process command] isEqual:serverProcessNameAlt])
			{
				return YES;
			}
		}
	}
	return NO;
}

- (void)checkForProblems
{
	// check for the postgres user
	
	// check for the presence of data in the DATA path
	
	// check for the presence of a file in the LOG path
	
	// check permissions on the DATA path
	
	// check permissions on the LOG file
	
	return;
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
		command = nil;
	}
 	command = @"/Library/StartupItems/PostgreSQL/PostgreSQL";
	
	if (operation != nil)
	{
		operation = nil;
	}
 	operation = @"restart";
	if (option != nil)
	{
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
		command = nil;
	}
 	command = @"/Library/StartupItems/PostgreSQL/PostgreSQL";
	
	if (operation != nil)
	{
		operation = nil;
	}
 	operation = @"start";
	
	if (option != nil)
	{
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
		command = nil;
	}
 	command = @"/Library/StartupItems/PostgreSQL/PostgreSQL";
	
	if (operation != nil)
	{
		operation = nil;
	}
 	operation = @"stop";
	
	if (option != nil)
	{
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
		command = nil;
	}
 	command = @"/Library/StartupItems/PostgreSQL/PostgreSQL";
	
	if (operation != nil)
	{
		operation = nil;
	}
 	operation = @"restart";
	
	if (option != nil)
	{
		option = nil;
	}
 	option = @"RELOAD";
	
	[NSThread detachNewThreadSelector:@selector(execStartupWithRights) toTarget:self withObject:operation];	
    return;	
}

- (void)execStartupWithRights
{
	@autoreleasepool {
        
        OSStatus myStatus;
        
        NSString *pathToHelper = [thisBundle pathForResource:@"StartupHelper" ofType:nil];
        
        const char *myToolPath = [pathToHelper cStringUsingEncoding:NSMacOSRomanStringEncoding];
        char *myArguments[4];
        
        myArguments[0] = (char *)[command cStringUsingEncoding:NSMacOSRomanStringEncoding];
        myArguments[1] = (char *)[operation cStringUsingEncoding:NSMacOSRomanStringEncoding];
        if (option != nil)
        {
            myArguments[2] = (char *)[option cStringUsingEncoding:NSMacOSRomanStringEncoding];
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
                    //NSLog(@"Buffer: %s", &myReadBuffer);
                if (bytesRead < 1) break;
            } 
        
            // update the buttons
        [progress stopAnimation:nil];
        
	}
	[NSThread exit];
	
    return;
}


#pragma mark --
#pragma mark Configuration Management Handlers

- (IBAction)onChangeStartAtBoot:(id)sender
{
	// update the preferences and save them.
	[preferences setValue:@"YES" forKey:PREF_KEY_START_AT_BOOT];
	if ([autostartOption state] == NSOffState)
	{
		[preferences setValue:@"NO" forKey:PREF_KEY_START_AT_BOOT];
	} 
	[self savePreferencesFile:nil];
}


- (IBAction)onChangePostgreSQLDataPath:(id)sender
{
	// create the owner.
	PGMChangeDataPath *dialogOwner = [[PGMChangeDataPath alloc] init];
	
	[dialogOwner setCurrentPath:preferences[PREF_KEY_DATA_PATH]];
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
    {
		for(;;)
		{
			int bytesRead = read (fileno (myCommunicationsPipe),
								  myReadBuffer, sizeof (myReadBuffer));
			if (bytesRead < 1) break;
			NSLog(@"%s", myReadBuffer);
		}
    } else {
        NSLog(@"Authorization Services Failure: %d", myStatus);
        [PostgreSQL_ServerPref debugErrorBreakInCode:@""];
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
    {
		for(;;)
		{
			int bytesRead = read (fileno (myCommunicationsPipe),
								  myReadBuffer, sizeof (myReadBuffer));
			if (bytesRead < 1) break;
			NSLog(@"%s", myReadBuffer);
		}
    } else {
        NSLog(@"Authorization Services Failure: %d", myStatus);
        [PostgreSQL_ServerPref debugErrorBreakInCode:@""];
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
    {
		for(;;)
		{
			int bytesRead = read (fileno (myCommunicationsPipe),
								  myReadBuffer, sizeof (myReadBuffer));
			if (bytesRead < 1) break;
			NSLog(@"%s", myReadBuffer);
		}
    } else {
        NSLog(@"Authorization Services Failure: %d", myStatus);
        [PostgreSQL_ServerPref debugErrorBreakInCode:@""];
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
        [PostgreSQL_ServerPref debugErrorBreakInCode:@""];
		return;
	}
	
	char *myArguments[5];
	
	myArguments[0] = "/bin/cat";
	myArguments[1] = "/var/tmp/com.druware.postgresqlformac.plist";
	myArguments[2] = ">";
	myArguments[3] = DRUWARE_PREF_FILE_CSTRING;
	myArguments[4] = NULL;
	
	NSLog(@"pushing configuration");
	
	FILE *myCommunicationsPipe = NULL;
	char myReadBuffer[128];
	
	myFlags = kAuthorizationFlagDefaults;			
	myStatus = AuthorizationExecuteWithPrivileges(myAuthorizationRef, 
												  myToolPath, myFlags, myArguments, &myCommunicationsPipe);      
	
	if (myStatus == errAuthorizationSuccess)
    {
		for(;;)
		{
			int bytesRead = read (fileno (myCommunicationsPipe),
								  myReadBuffer, sizeof (myReadBuffer));
			if (bytesRead < 1) break;
			NSLog(@"%s", myReadBuffer);
		}
	} else {
        NSLog(@"Authorization Services Failure: %d", myStatus);
        [PostgreSQL_ServerPref debugErrorBreakInCode:@""];
    }
	[self removeFile:@"/var/tmp/com.druware.postgresqlformac.plist"];
}

@end
