//
//  RegistrationDialog.h
//  PostgreSQL Query Action
//
//  Created by Andy Satori on 11/10/07.
//  Copyright 2007 Druware Software Designs. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>


@interface RegistrationDialog : NSObject {
	IBOutlet NSWindow *regPanel;

    IBOutlet NSTextField *emailAddress;
    IBOutlet NSTextField *ownerName;
    IBOutlet NSTextField *purchaseDate;
    IBOutlet NSTextView *serialKey;
	IBOutlet NSTextField *product;
	IBOutlet NSTextField *version;
	IBOutlet NSTextField *purchaseConfirmationCode;
	IBOutlet NSTextField *validatedCode;
	
    IBOutlet NSButton *next;
	IBOutlet NSButton *cancel;
	
	IBOutlet WebView *registrationPageView;
	
	NSWindow *parentWindow;
}

- (void)beginModalDialogForWindow:(NSWindow *)parent;

- (IBAction)onCancel:(id)sender;
- (IBAction)onNext:(id)sender;

@end

