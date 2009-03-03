//
//  PGMChangeDataPath.h
//  PostgreSQL Server
//
//  Created by Andy Satori on 2/16/09.
//  Copyright 2009 Druware Software Designs. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PGMChangeDataPath : NSObject {
	IBOutlet NSTextField *dataFilePath;
	IBOutlet NSPanel *thisPanel;
	
	NSString *currentPath;
	
	NSWindow *parentWindow;
}

- (void)showModalForWindow:(NSWindow *)window;

- (void)setCurrentPath:(NSString *)value;

- (IBAction)onBrowseForFolder:(id)sender;
- (IBAction)onSetDataPath:(id)sender;
- (IBAction)onCancelSetDataPath:(id)sender;

@end