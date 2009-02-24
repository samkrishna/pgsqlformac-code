//
//  PGMPostgreSQLConfiguration.h
//  PostgreSQL Server
//
//  Created by Andy Satori on 2/19/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PGMPostgreSQLConfiguration : NSObject {
	
	IBOutlet NSPanel *thisPanel;
	
	NSWindow *parentWindow;
}

- (void)showModalForWindow:(NSWindow *)window;

- (IBAction)onBrowseForFolder:(id)sender;
- (IBAction)onOK:(id)sender;
- (IBAction)onCancel:(id)sender;

@end
