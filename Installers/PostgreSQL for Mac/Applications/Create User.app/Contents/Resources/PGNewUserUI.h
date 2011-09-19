//
//  PGNewUserUI.h
//  Create User
//
//  Created by Andy Satori on 2/21/05.
//  Copyright 2005 Druware Software Designs. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <PGSQLKit/PGSQLKit.h>

@interface PGNewUserUI : NSObject 
{
    IBOutlet NSButton *back;
    IBOutlet NSButton *next;
    IBOutlet NSSecureTextField *password;
    IBOutlet NSTextField *port;
    IBOutlet NSTextView *resultOutput;
    IBOutlet NSProgressIndicator *resultStatus;
    IBOutlet NSTextField *server;
    IBOutlet NSTextField *user;
    IBOutlet NSWindow *window;
    IBOutlet NSTabView *tabs;

    IBOutlet NSTextField *newLogin;
    IBOutlet NSTextField *newUID;
    IBOutlet NSTextField *newPassword;
    IBOutlet NSTextField *newConfPassword;
    IBOutlet NSTextField *newExpirationDate;
    IBOutlet NSPopUpButton *groups;
	IBOutlet NSButton *allowCreateDB;
	IBOutlet NSButton *allowCreateUser;
	IBOutlet NSButton *versionSevenFeaturesOnly;
	
	PGSQLConnection *_conn;
}
- (IBAction)onBack:(id)sender;
- (IBAction)onCancel:(id)sender;
- (IBAction)onNext:(id)sender;


- (void)createUser;

@end
