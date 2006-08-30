//
//  SqlDocument.h
//  Query Tool
//
//  Created by Andy Satori on Thu Jan 29 2004.
//  Copyright (c) 2004 Druware Software Designs. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "DataSource.h"
#import "Connection.h"
#import "ExplorerModel.h"
#import "MyOutlineView.h"
#import "MyResultsView.h"
#import "QueryTool.h"

@class PreferenceController;

@interface SqlDocument : NSDocument
{
	// query window
	IBOutlet NSWindow		*window;
	IBOutlet NSTextView		*query;
	IBOutlet NSTextView		*rawOutput;
	IBOutlet MyResultsView	*dataOutput;
	IBOutlet NSTabView		*tabs;
	IBOutlet NSProgressIndicator *working;
	IBOutlet NSTextField	*status;
	
	//connect dialog
	IBOutlet NSPanel		*panelConnect;
	IBOutlet NSTextField	*userName;
	IBOutlet NSTextField	*password;
	IBOutlet NSTextField	*databaseName;
	IBOutlet NSComboBox		*host;
	IBOutlet NSComboBox		*port;
	IBOutlet NSPopUpButton	*dbName;
	
	// toolbar items
	IBOutlet NSView			*dbListView;
	IBOutlet NSPopUpButton  *dbList;
	
	// SQL Log Panel
	IBOutlet NSPanel		*sqlLogPanel;
	IBOutlet NSTextView		*sqlLogPanelTextView;
	
	// outline schema view
	IBOutlet MyOutlineView *schemaView;  // ref to the schema outline view object

	ExplorerModel *explorer;   // ref to schema outline view data source
	
	// Non-Gui
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
- (IBAction)onShowSQLLog:(id)sender;
- (IBAction)onShowPostgreSQLHTML:(id)sender;
- (IBAction)onShowSQLHTML:(id)sender;

// set view fonts
- (IBAction)setSchemaViewFont:(id)sender;
- (IBAction)setDataOutputViewFont:(id)sender;
- (IBAction)setSQLLogViewFont:(id)sender;

// Respond to dynamic menus in the object browser.
// Tables
- (void)onSelectSelectTableMenuItem:(id)sender;
- (void)onSelectCreateTableMenuItem:(id)sender;
- (void)onSelectCreateBakTableMenuItem:(id)sender;
- (void)onSelectAlterTableRenameMenuItem:(id)sender;
- (void)onSelectVacuumTableMenuItem:(id)sender;
- (void)onSelectTruncateTableMenuItem:(id)sender;
- (void)onSelectDropTableMenuItem:(id)sender;

// Columns
- (void)onSelectColSelectMenuItem:(id)sender;
- (void)onSelectColsMenuItem:(id)sender;
- (void)onSelectCreateIndexOnColsMenuItem:(id)sender;
- (void)onSelectCreateUniqIndexOnColsMenuItem:(id)sender;
- (void)onSelectAlterAddColMenuItem:(id)sender;
- (void)onSelectAlterRenameColMenuItem:(id)sender;
- (void)onSelectCreateTabColsMenuItem:(id)sender;
- (void)onSelectDropColMenuItem:(id)sender;
- (void)onSelectAlterTabAlterColMenuItem:(id)sender;

// Views
- (void)onSelectCreateViewMenuItem:(id)sender;
- (void)onSelectCreateViewTemplateMenuItem:(id)sender;
- (void)onSelectDropViewMenuItem:(id)sender;

// Functions
- (void)onSelectCreateFunctionMenuItem:(id)sender;
- (void)onSelectCreateFunctionTemplateMenuItem:(id)sender;
- (void)onSelectDropFunctionMenuItem:(id)sender;

// Indexes
- (BOOL)isValueKeyword:(NSString *)value;
- (void)setAttributesForWord:(NSRange)rangeOfCurrentWord;
- (void)colorRange:(NSRange)rangeToColor;

@end
