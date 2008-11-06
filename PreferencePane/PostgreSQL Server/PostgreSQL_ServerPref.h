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
	IBOutlet NSTextField *testLabel;
	
	IBOutlet NSButton *addServer;
    IBOutlet NSButton *autostartOption;
    IBOutlet NSProgressIndicator *progress;
    IBOutlet NSButton *refresh;
    IBOutlet NSButton *restartService;
    IBOutlet NSTextField *restartServiceLabel;
    IBOutlet NSPopUpButton *servers;
    IBOutlet NSImageView *serviceImage;
    IBOutlet NSPopUpButton *services;
    IBOutlet NSButton *startService;
    IBOutlet NSTextField *startServiceLabel;
    IBOutlet NSTextField *status;
    IBOutlet NSButton *stopService;
    IBOutlet NSTextField *stopServiceLabel;
    IBOutlet NSWindow *window;
	IBOutlet NSProgressIndicator *working;
	
	NSBundle *thisBundle;
	
	AuthorizationRef myAuthorizationRef;

	
	NSString *command;
	NSString *operation;
	
	double updateInterval;
}

- (void) mainViewDidLoad;

- (BOOL)checkPostmasterStatus;
- (void)updateButtonStatus:(BOOL)isRunning;

- (IBAction)onTimedUpdate:(id)sender;

- (IBAction)onRestartService:(id)sender;
- (IBAction)onStartService:(id)sender;
- (IBAction)onStopService:(id)sender;

- (IBAction)launchNetworkConfiguration:(id)sender;

@end
