//
//  PostgreSQL_ServerPref.h
//  PostgreSQL Server
//
//  Created by Andy Satori on 8/8/08.
//  Copyright (c) 2008 Druware Software Designs. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>
#import <Cocoa/Cocoa.h>

#include <Security/Authorization.h>
#include <Security/AuthorizationTags.h>

@interface PostgreSQL_ServerPref : NSPreferencePane 
{
    IBOutlet NSButton *autostartOption;
    IBOutlet NSProgressIndicator *progress;

    IBOutlet NSButton *restartService;
    IBOutlet NSTextField *restartServiceLabel;

    IBOutlet NSImageView *serviceImage;

    IBOutlet NSButton *startService;
    IBOutlet NSTextField *startServiceLabel;
    
	IBOutlet NSTextField *status;
    
	IBOutlet NSButton *stopService;
    IBOutlet NSTextField *stopServiceLabel;
    	
	IBOutlet NSButton *lockToggle;
	
	IBOutlet NSButton *changeDataPath;
	IBOutlet NSButton *modifyNetworkConfiguration;
	IBOutlet NSButton *modifyPostgreSQLConfiguration;
	
	NSBundle *thisBundle;
	
	AuthorizationFlags myFlags;
	AuthorizationRef myAuthorizationRef;

	NSString *command;
	NSString *operation;
	NSString *option;
	
	NSString *dataPath;
	
	NSMutableDictionary *preferences;
	NSUserDefaults *userPrefs;
	
	BOOL isLocked;
	
	double updateInterval;
}

- (void) mainViewDidLoad;

- (BOOL)unlockPane;
- (BOOL)lockPane;
- (IBAction)toggleLock:(id)sender;

- (BOOL)checkPostmasterStatus;
- (void)updateButtonStatus:(BOOL)isRunning;
- (void)checkForProblems;

- (IBAction)onTimedUpdate:(id)sender;

- (IBAction)onRestartService:(id)sender;
- (IBAction)onStartService:(id)sender;
- (IBAction)onStopService:(id)sender;
- (IBAction)onReloadService:(id)sender;

- (IBAction)onChangeStartAtBoot:(id)sender;
- (IBAction)onChangePostgreSQLDataPath:(id)sender;
- (IBAction)launchNetworkConfiguration:(id)sender;
- (IBAction)launchPostgreSQLConfiguration:(id)sender;

- (void)savePreferencesFile:(id)sender;

- (void)fetchConfigFile:(NSString *)fileName;
- (void)pushConfigFile:(NSString *)fileName;
- (BOOL)removeFile:(NSString *)filePath;



@end
