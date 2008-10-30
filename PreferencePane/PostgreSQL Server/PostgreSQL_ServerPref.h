//
//  PostgreSQL_ServerPref.h
//  PostgreSQL Server
//
//  Created by Andy Satori on 8/8/08.
//  Copyright (c) 2008 Druware Software Designs. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>


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
	
	NSString *command;
	NSString *operation;
}

- (void) mainViewDidLoad;

- (BOOL)checkPostmasterStatus;
- (void)updateButtonStatus:(BOOL)isRunning;

- (IBAction)onStartService:(id)sender;

- (IBAction)launchNetworkConfiguration:(id)sender;

@end
