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

#include <Security/Authorization.h>
#include <Security/AuthorizationTags.h>

    // Note that you have to build the project once to make version.h available.
    // version.h is not (or should not be) in scm because it changes with every build.
#import "version.h"

#include <sys/types.h>
#include <sys/uio.h>
#include <unistd.h>

#pragma mark - Parameter Object 

@interface ExecParameters : NSObject

@property (strong) NSString *command;
@property (strong) NSString *operation;
@property (strong) NSString *option;

@end
@implementation ExecParameters
- (void)dealloc
{
    self.command = nil;
    self.operation = nil;
    self.option = nil;
}
@end

#pragma mark - PostgreSQL_ServerPref Object

@interface PostgreSQL_ServerPref()

    // Weak properties (GUI)
@property (weak, nonatomic) IBOutlet NSButton *autostartOption;
@property (weak, nonatomic) IBOutlet NSProgressIndicator *progress;

@property (weak, nonatomic) IBOutlet NSButton *restartService;
@property (weak, nonatomic) IBOutlet NSTextField *restartServiceLabel;

@property (weak, nonatomic) IBOutlet NSImageView *serviceImage;

@property (weak, nonatomic) IBOutlet NSButton *startService;
@property (weak, nonatomic) IBOutlet NSTextField *startServiceLabel;

@property (weak, nonatomic) IBOutlet NSTextField *status;

@property (weak, nonatomic) IBOutlet NSButton *stopService;
@property (weak, nonatomic) IBOutlet NSTextField *stopServiceLabel;

@property (weak, nonatomic) IBOutlet NSButton *lockToggle;  // On is unlocked.

@property (weak, nonatomic) IBOutlet NSButton *changeDataPath;
@property (weak, nonatomic) IBOutlet NSButton *modifyNetworkConfiguration;
@property (weak, nonatomic) IBOutlet NSButton *modifyPostgreSQLConfiguration;

@property (weak, nonatomic) IBOutlet NSPopUpButton *selectVersion;

@property (weak, nonatomic) IBOutlet NSTextField *debugBuildDateTextLable;

    // Copy Properties
@property AuthorizationFlags myFlags;
@property AuthorizationRef myAuthorizationRef;
@property BOOL isLocked;
@property double updateInterval;

    // Strong Retain Properties
@property (strong, nonatomic) NSArray *postgresqlForMacPgConfigPaths;
@property (strong, nonatomic) NSString *mainPathPgConfigPath;

@property (strong) NSBundle *thisBundle;
@property (strong) NSString *dataPath;
@property (strong) NSMutableDictionary *preferences;
@property (strong) NSUserDefaults *userPrefs;


@end

@implementation PostgreSQL_ServerPref

#pragma mark - Lifecycle Methods

- (void)dealloc
{
    self.postgresqlForMacPgConfigPaths = nil;
    self.mainPathPgConfigPath = nil;
    
    self.thisBundle = nil;
    self.dataPath = nil;
    self.preferences = nil;
    self.userPrefs = nil;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

#pragma mark - Misc Methods

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

#pragma mark - NSPreferencePane Methods

- (void) mainViewDidLoad
{
	// Check the current Status and change to display accordingly.
    // Currently on my MacBookPro Intel Core i7, 2.66 GHz the update check consumes about 200ms.
    // 0.8 gives 25% duty cycle.  TODO change from polling to event.
    // Potentially use pg_isready?
	self.updateInterval = 0.8;
	
    self.thisBundle = [NSBundle bundleWithIdentifier:@"com.druware.postgresqlformac"];
	NSParameterAssert(self.thisBundle != nil);
    
	self.isLocked = YES;
	   
        // Find out what we know
    [self checkForAvailableVersions];
    
        // Get make Preferences
    self.preferences = [self getPreferencesFromFile];
	NSParameterAssert(self.preferences != nil);
    
        // Update GUI

        // Update the debug build date text field.
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

	if ([[self.preferences valueForKey:PREF_KEY_START_AT_BOOT] isEqualToString:PREF_START_AT_BOOT_DEFAULT])
	{
		[self.autostartOption setState:NSOnState];
	} else {
		[self.autostartOption setState:NSOffState];
	}
	
	self.dataPath = [[NSString alloc] initWithString:self.preferences[PREF_KEY_DATA_PATH]];
    
    [self onTimedUpdate:nil];
}

#pragma mark - Lock Management Handlers

- (BOOL)unlockPane
{
	OSStatus myStatus;
    self.myFlags = kAuthorizationFlagDefaults;
	
    NSString *pathToHelper = [self.thisBundle pathForResource:@"StartupHelper" ofType:nil];
	
        // myAuthorizationItem.AuthorizationString = "@
    myStatus = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment,
								   self.myFlags, &_myAuthorizationRef);
    if (myStatus != errAuthorizationSuccess)
		return NO;
	
	AuthorizationItem myItems = {kAuthorizationRightExecute, [pathToHelper length], (char *)[pathToHelper cStringUsingEncoding:NSMacOSRomanStringEncoding], 0};
	AuthorizationRights myRights = {1, &myItems};
	
	self.myFlags =  kAuthorizationFlagDefaults |
    kAuthorizationFlagInteractionAllowed |
	kAuthorizationFlagPreAuthorize |
	kAuthorizationFlagExtendRights;
		
        // this pops the dialog.  If the above AuthItemRIghts includes more than one item, then it will auth all or none.
	myStatus = AuthorizationCopyRights (self.myAuthorizationRef, &myRights,
										kAuthorizationEmptyEnvironment, self.myFlags, NULL ); // this pops the dialog
	
	if (myStatus == errAuthorizationSuccess)
	{
		self.isLocked = NO;
        [self savePreferencesFile:self.preferences];    // TODO for the time being make sure we
                                                        // always have saved the pref file so it can be used by PGMChangeDataPath.
		[self.lockToggle setState:NSOnState];
		return YES;
	}
    
    [self.lockToggle setState:NSOffState];
	self.isLocked = YES;
	return NO;
}

- (BOOL)lockPane
{
	if (!self.isLocked)
	{
		AuthorizationFree (self.myAuthorizationRef, kAuthorizationFlagDefaults);
		self.isLocked = YES;
		[self.lockToggle setState:NSOffState];
		return YES;
	}
    [self.lockToggle setState:NSOnState];
    self.isLocked = NO;
	return NO;
}

- (IBAction)toggleLock:(id)sender
{
	if (self.isLocked)
	{
		[self unlockPane];
	} else {
		[self lockPane];
	}

	[self.autostartOption setEnabled:!self.isLocked];
	[self.modifyNetworkConfiguration setEnabled:!self.isLocked];
	[self.modifyPostgreSQLConfiguration setEnabled:!self.isLocked];
	
	return;
}

#pragma mark - Status Update Handlers

- (void)updateButtonStatus:(BOOL)isRunning
{	
	[self.startService setEnabled:(!isRunning)];
	[self.startServiceLabel setEnabled:(!isRunning)];
	
	[self.stopService setEnabled:isRunning];
	[self.stopServiceLabel setEnabled:isRunning];
	
	[self.restartService setEnabled:isRunning];
	[self.restartServiceLabel setEnabled:isRunning];
	
	if (isRunning)
	{
		// set the image to running
		NSString *imagePath = [self.thisBundle pathForResource:@"xserve-running" ofType:@"png"];
		NSImage *image = [[NSImage alloc] initWithContentsOfFile:imagePath];
		[self.serviceImage setImage:image];
		[self.status setStringValue:@"Current Status: Running"];
		
	} else {
		// set the image to stopped
		NSString *imagePath = [self.thisBundle pathForResource:@"xserve-stopped" ofType:@"png"];
		NSImage *image = [[NSImage alloc] initWithContentsOfFile:imagePath];
		[self.serviceImage setImage:image];
		[self.status setStringValue:@"Current Status: Down"];
	}

	if ((self.isLocked) || (isRunning))
    {
        [self.changeDataPath setEnabled:NO];
    } else {
        [self.changeDataPath setEnabled:YES];
    }
	return;
}

- (BOOL)checkPostmasterStatus
{
	// check the current run state of postmaster
	NSString *serverProcessName = @"postgres";
	NSString *serverProcessNameAlt = @"postmaster";
	NSArray *processes = [AGProcess allProcesses];
	for (AGProcess *process in processes)
	{
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
    DEBUG_LOG_METHOD
	// check for the postgres user
	
	// check for the presence of data in the DATA path
	
	// check for the presence of a file in the LOG path
	
	// check permissions on the DATA path
	
	// check permissions on the LOG file
	
	return;
}

- (IBAction)onTimedUpdate:(id)sender
{
        //DEBUG_LOG_METHOD
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL result = [self checkPostmasterStatus];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateButtonStatus:result];
                //DEBUG_LOG_METHOD
        });
    });
	[self performSelector:@selector(onTimedUpdate:) withObject:self afterDelay:self.updateInterval];
}

#pragma mark - Service Management Handlers

- (IBAction)onRestartService:(id)sender
{
	// if locked, need to unlock before calling exec
	if (self.isLocked)
	{
		[self toggleLock:sender];
	}
	
	if (self.isLocked)
	{
		return;
	}
	
    ExecParameters *execParameters = [[ExecParameters alloc] init];
    
 	execParameters.command = @"/Library/StartupItems/PostgreSQL/PostgreSQL";
 	execParameters.operation = @"restart";
    execParameters.option = nil;
	
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self execStartupWithRights:execParameters];
    });
	
    return;	
}

- (IBAction)onStartService:(id)sender
{
	// if locked, need to unlock before calling exec
	if (self.isLocked)
	{
		[self toggleLock:sender];
	}
	
	if (self.isLocked)
	{
		return;
	}
	
    ExecParameters *execParameters = [[ExecParameters alloc] init];
 	execParameters.command = @"/Library/StartupItems/PostgreSQL/PostgreSQL";
 	execParameters.operation = @"start";
    execParameters.option = nil;
	
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self execStartupWithRights:execParameters];
    });

    return;
}

- (IBAction)onStopService:(id)sender
{	
	// if locked, need to unlock before calling exec
	if (self.isLocked)
	{
		[self toggleLock:sender];
	}
	
	if (self.isLocked)
	{
		return;
	}
	
    ExecParameters *execParameters = [[ExecParameters alloc] init];
 	execParameters.command = @"/Library/StartupItems/PostgreSQL/PostgreSQL";
 	execParameters.operation = @"stop";
    execParameters.option = nil;
	
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self execStartupWithRights:execParameters];
    });
	
    return;	
}

- (IBAction)onReloadService:(id)sender
{
	// if locked, need to unlock before calling exec
	if (self.isLocked)
	{
		[self toggleLock:sender];
	}
	
	if (self.isLocked)
	{
		return;
	}
	
    ExecParameters *execParameters = [[ExecParameters alloc] init];
 	execParameters.command = @"/Library/StartupItems/PostgreSQL/PostgreSQL";
 	execParameters.operation = @"restart";
 	execParameters.option = @"RELOAD";
	
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self execStartupWithRights:execParameters];
    });
    return;
}

- (void)execStartupWithRights:(ExecParameters *)execParameters
{
    NSParameterAssert(execParameters != nil);
    
    OSStatus myStatus;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progress startAnimation:nil];
    });
    
    NSString *pathToHelper = [self.thisBundle pathForResource:@"StartupHelper" ofType:nil];
    NSParameterAssert(pathToHelper != nil);
    
    const char *myToolPath = [pathToHelper cStringUsingEncoding:NSMacOSRomanStringEncoding];
    char *myArguments[4];
    
    myArguments[0] = (char *)[execParameters.command cStringUsingEncoding:NSMacOSRomanStringEncoding];
    myArguments[1] = (char *)[execParameters.operation cStringUsingEncoding:NSMacOSRomanStringEncoding];
    if (execParameters.option != nil)
    {
        myArguments[2] = (char *)[execParameters.option cStringUsingEncoding:NSMacOSRomanStringEncoding];
    } else {
        myArguments[2] = "MANUAL";
    }
    myArguments[3] = NULL;
    
    FILE *myCommunicationsPipe = NULL;
    
    self.myFlags = kAuthorizationFlagDefaults;
    myStatus = AuthorizationExecuteWithPrivileges(self.myAuthorizationRef,
                                                  myToolPath, self.myFlags, myArguments, &myCommunicationsPipe);
    
    if (myStatus == errAuthorizationSuccess)
    {
        for(;;)
        {
            char myReadBuffer[4096];
            
            int bytesRead = read(fileno(myCommunicationsPipe), myReadBuffer, sizeof(myReadBuffer));
            if (bytesRead < 1) break;
#ifdef DEBUG
            else {
                myReadBuffer[bytesRead] = 0;
                NSLog(@"Buffer: %s", (char *)&myReadBuffer);
            }
#endif
        }
    } else {
        NSLog(@"Authorization Services Failure: %d", myStatus);
            //[Debug debugErrorBreakInCode:@""];
    }
    
        // update the buttons
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progress stopAnimation:nil];
    });
}

#pragma mark - Configuration Management Handlers

- (IBAction)onChangeStartAtBoot:(id)sender
{
	// update the preferences and save them.
	[self.preferences setValue:PREF_START_AT_BOOT_DEFAULT forKey:PREF_KEY_START_AT_BOOT];
	if ([self.autostartOption state] == NSOffState)
	{
		[self.preferences setValue:@"NO" forKey:PREF_KEY_START_AT_BOOT];
	} 
	[self savePreferencesFile:self.preferences];
}

- (IBAction)onChangePostgreSQLDataPath:(id)sender
{
        // create the owner.
	PGMChangeDataPath *dialogOwner = [[PGMChangeDataPath alloc]
                                      initWithSaveCallback:^(NSMutableDictionary *pref){
                                          self.preferences = pref;
                                          [self savePreferencesFile:pref];
                                              // !!!TODO!!!
                                              // if the data path changes, change it in the preferences, check to see
                                              // if initidb is needed, and if it is, call initdb, and restart the database.
                                      }
                                      cancelCallback:nil];
	
	[dialogOwner showModalForWindow:[NSApp mainWindow]];
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

#pragma mark - File Management Routines

-(void)fetchConfigFile:(NSString *)fileName
{
	OSStatus myStatus;
	NSString *pathToHelper = [self.thisBundle pathForResource:@"StartupHelper" ofType:nil];
	
	const char *myToolPath = [pathToHelper cStringUsingEncoding:NSASCIIStringEncoding]; 
	char *myArguments[5];
	
	NSString *myDataPath = [[NSString alloc] initWithFormat:@"%@/%@", self.dataPath, fileName];
	NSString *myTempPath = [[NSString alloc] initWithFormat:@"/var/tmp/%@.in", fileName];
	
	myArguments[0] = "/bin/cat";
	myArguments[1] = (char *)[myDataPath cStringUsingEncoding:NSASCIIStringEncoding];
	myArguments[2] = ">";
	myArguments[3] = (char *)[myTempPath cStringUsingEncoding:NSASCIIStringEncoding]; 
	myArguments[4] = NULL;
	
	FILE *myCommunicationsPipe = NULL;
	char myReadBuffer[128];
	
	self.myFlags = kAuthorizationFlagDefaults;
	myStatus = AuthorizationExecuteWithPrivileges(self.myAuthorizationRef,
												  myToolPath, self.myFlags, myArguments, &myCommunicationsPipe);
	
	if (myStatus == errAuthorizationSuccess)
    {
		for(;;)
		{
			int bytesRead = read (fileno (myCommunicationsPipe), myReadBuffer, sizeof (myReadBuffer));
			if (bytesRead < 1) break;
#ifdef DEBUG
            else {
                myReadBuffer[bytesRead] = 0;
                NSLog(@"Buffer: %s", (char *)&myReadBuffer);
            }
#endif
		}
    } else {
        NSLog(@"Authorization Services Failure: %d", myStatus);
        [Debug debugErrorBreakInCode:@""];
    }
}

-(void)pushConfigFile:(NSString *)fileName
{
	OSStatus myStatus;
	NSString *pathToHelper = [self.thisBundle pathForResource:@"StartupHelper" ofType:nil];
	
	const char *myToolPath = [pathToHelper cStringUsingEncoding:NSASCIIStringEncoding]; 
	char *myArguments[5];
	
	NSString *myDataPath = [[NSString alloc] initWithFormat:@"%@/%@", self.dataPath, fileName];
	NSString *myTempPath = [[NSString alloc] initWithFormat:@"/var/tmp/%@.out", fileName];
	
	myArguments[0] = "/bin/cat";
	myArguments[1] = (char *)[myTempPath cStringUsingEncoding:NSASCIIStringEncoding]; 
	myArguments[2] = ">";
	myArguments[3] = (char *)[myDataPath cStringUsingEncoding:NSASCIIStringEncoding];
	myArguments[4] = NULL;
	
	FILE *myCommunicationsPipe = NULL;
	char myReadBuffer[128];
	
	self.myFlags = kAuthorizationFlagDefaults;
	myStatus = AuthorizationExecuteWithPrivileges(self.myAuthorizationRef,
												  myToolPath, self.myFlags, myArguments, &myCommunicationsPipe);
	
	if (myStatus == errAuthorizationSuccess)
    {
		for(;;)
		{
			int bytesRead = read (fileno (myCommunicationsPipe), myReadBuffer, sizeof (myReadBuffer));
			if (bytesRead < 1) break;
#ifdef DEBUG
            else {
                myReadBuffer[bytesRead] = 0;
                NSLog(@"Buffer: %s", (char *)&myReadBuffer);
            }
#endif
		}
    } else {
        NSLog(@"Authorization Services Failure: %d", myStatus);
        [Debug debugErrorBreakInCode:@""];
    }
}

-(BOOL)removeFile:(NSString *)filePath
{
	OSStatus myStatus;
	NSString *pathToHelper = [self.thisBundle pathForResource:@"StartupHelper" ofType:nil];
	
	const char *myToolPath = [pathToHelper cStringUsingEncoding:NSASCIIStringEncoding]; 
	char *myArguments[4];
	
	myArguments[0] = "rm";
	myArguments[1] = "-f";
	myArguments[2] = (char *)[filePath cStringUsingEncoding:NSASCIIStringEncoding];
	myArguments[3] = NULL;
	
	FILE *myCommunicationsPipe = NULL;
	char myReadBuffer[128];
	
	self.myFlags = kAuthorizationFlagDefaults;
	myStatus = AuthorizationExecuteWithPrivileges(self.myAuthorizationRef,
												  myToolPath, self.myFlags, myArguments, &myCommunicationsPipe);
	
	if (myStatus == errAuthorizationSuccess)
    {
		for(;;)
		{
			int bytesRead = read (fileno (myCommunicationsPipe), myReadBuffer, sizeof (myReadBuffer));
			if (bytesRead < 1) break;
#ifdef DEBUG
            else {
                myReadBuffer[bytesRead] = 0;
                NSLog(@"Buffer: %s", (char *)&myReadBuffer);
            }
#endif
		}
    } else {
        NSLog(@"Authorization Services Failure: %d", myStatus);
        [Debug debugErrorBreakInCode:@""];
    }
	return YES;
}

#pragma mark - Preferences Get & Save


- (NSMutableDictionary *)getPreferencesFromFile
{
    DEBUG_LOG_METHOD
    NSMutableDictionary *localPref = nil;
	NSFileManager *fm = [[NSFileManager alloc] init];
	if ([fm fileExistsAtPath:DRUWARE_PREF_FILE_NSSTRING])
	{
            // replace with NSUserDefaults/NSGlobalDomain
		localPref = [[NSMutableDictionary alloc] initWithContentsOfFile:DRUWARE_PREF_FILE_NSSTRING];
	} else {
            // create the initial defaults
		localPref = [[NSMutableDictionary alloc] init];
    }
    
    NSParameterAssert(localPref != nil);
    NSLog(@"%@\n%@", DRUWARE_PREF_FILE_NSSTRING, localPref);
    
        // set the default prefs if not already set.
    if (localPref[PREF_KEY_DATA_PATH] == nil)
    {
        [localPref setValue:PREF_DATA_PATH_DEFAULT forKey:PREF_KEY_DATA_PATH];
    }
    if (localPref[PREF_KEY_LOG_PATH] == nil)
    {
        [localPref setValue:[PREF_LOG_PATH_DEFAULT stringByAppendingPathComponent:PREF_LOG_FILE_NAME_DEFAULT] forKey:PREF_KEY_LOG_PATH];
    }
    if (localPref[PREF_KEY_START_AT_BOOT] == nil)
    {
        [localPref setValue:PREF_START_AT_BOOT_DEFAULT forKey:PREF_KEY_START_AT_BOOT];
    }
    if (localPref[PREF_KEY_PORT_NUMBER] == nil)
    {
        [localPref setValue:PREF_PORT_NUMBER_DEFAULT forKey:PREF_KEY_PORT_NUMBER];
    }
    if (localPref[PREF_KEY_BIN_PATH] == nil)
    {
        [localPref setValue:PREF_BIN_PATH_DEFAULT forKey:PREF_KEY_BIN_PATH];
    }
    
    return localPref;
}

-(void)savePreferencesFile:(NSMutableDictionary *)savePreferences
{
    DEBUG_LOG_METHOD
	OSStatus myStatus;
	NSString *pathToHelper = [self.thisBundle pathForResource:@"StartupHelper" ofType:nil];
	const char *myToolPath = [pathToHelper cStringUsingEncoding:NSASCIIStringEncoding];
	char *myArguments[5];
    
    for (NSString *key in savePreferences)
    {
        NSMutableString *defaultStr = [NSMutableString stringWithFormat:@" \"%@\" '%@'", key, savePreferences[key]];
        
        myArguments[0] = "/usr/bin/defaults write " DRUWARE_PREF_FILE_CSTRING;
        myArguments[1] = (char *)[defaultStr cStringUsingEncoding:NSUTF8StringEncoding];
        myArguments[2] = NULL;
        myArguments[3] = NULL;
        myArguments[4] = NULL;
        
#ifdef DEBUG
        NSLog(@"Writing Preferences\n%s%s", myArguments[0], myArguments[1]);
#endif
        FILE *myCommunicationsPipe = NULL;
        char myReadBuffer[128];
        
        self.myFlags = kAuthorizationFlagDefaults;
        myStatus = AuthorizationExecuteWithPrivileges(self.myAuthorizationRef,
                                                      myToolPath, self.myFlags, myArguments, &myCommunicationsPipe);
        
        if (myStatus == errAuthorizationSuccess)
        {
            for(;;)
            {
                int bytesRead = read (fileno (myCommunicationsPipe), myReadBuffer, sizeof (myReadBuffer));
                if (bytesRead < 1) break;
#ifdef DEBUG
                else {
                    myReadBuffer[bytesRead] = 0;
                    NSLog(@"Buffer: %s", (char *)&myReadBuffer);
                }
#endif
            }
        } else {
            NSLog(@"Authorization Services Failure: %d", myStatus);
            [Debug debugErrorBreakInCode:@""];
        }
    }
}

@end
