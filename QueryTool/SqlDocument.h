//
//  SqlDocument.h
//  Query Tool
//
//  Created by Andy Satori on Thu Jan 29 2004.
//  Copyright (c) 2004 Druware Software Designs. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "DataSource.h"
#import "pgCocoaDB/Connection.h"

@interface SqlDocument : NSDocument
{
	// query window
	IBOutlet NSWindow		*window;
	IBOutlet NSTextView		*query;
	IBOutlet NSTextView		*rawOutput;
	IBOutlet NSTableView	*dataOutput;
	IBOutlet NSTabView		*tabs;
	IBOutlet NSProgressIndicator *working;
	IBOutlet NSTextField	*status;
	
	//connect dialog
	IBOutlet NSPanel		*panelConnect;
	IBOutlet NSTextField	*userName;
	IBOutlet NSTextField	*password;
	IBOutlet NSComboBox		*host;
	IBOutlet NSComboBox		*port;
	IBOutlet NSPopUpButton	*dbName;
	
	// toolbar items
	IBOutlet NSView			*dbListView;
	IBOutlet NSPopUpButton  *dbList;
	
	
	NSString				*fileContent;
	NSData					*fileData;
	Connection				*conn;
	DataSource				*dataSource;
	
	int						 currentEditorRow;
	int						 currentEditorCol;
	
	bool					 hasTriedToConnect;

	// syntax elements
	NSArray *keywords;
	NSArray *operators;
	NSArray *beginComment;
	NSArray *endComment;
	NSArray *beginLiteral;
	NSArray *endLiteral;
}

- (IBAction)onExecuteQuery:(id)sender;
- (IBAction)onConnect:(id)sender;
- (IBAction)onConnectOK:(id)sender;
- (IBAction)onConnectCancel:(id)sender;
- (IBAction)onDisconnect:(id)sender;
- (IBAction)onSetDatabase:(id)sender;


- (BOOL)isValueKeyword:(NSString *)value;
- (void)setAttributesForWord:(NSRange)rangeOfCurrentWord;
- (void)colorRange:(NSRange)rangeToColor;

@end
