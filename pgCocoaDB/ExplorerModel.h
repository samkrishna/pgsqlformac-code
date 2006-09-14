//
//  ExplorerModel.h
//  pgCocoaDB
//
//  Created by Neil Tiffin on 3/12/06.
//  Copyright 2006 Performance Champions, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "ExplorerNode.h"
#import "Connection.h"
#import "Schema.h"

enum ThreadStatus { None, Running, Done, Error };

@interface ExplorerModel : NSObject
{
	ExplorerNode * rootNode;
	NSString * connectionString;
	//Connection *connection;
	Schema * schema;
	bool showInformationSchema;
	bool showPGCatalog;
	bool showPGToast;
	bool showPGTemps;
	bool showPublic;
	
	NSLock *explorerThreadStatusLock;
	enum ThreadStatus explorerThreadStatus; 
}

- (id)initWithConnectionString:(NSString *)theConnection;
- (void)buildSchema:(id)anObject;

- (void)setSchema:(Schema *)newSchema;
- (Schema *)schema;
- (bool)showInformationSchema;
- (bool)showPGCatalog;
- (bool)showPGToast;
- (bool)showPGTemps;
- (bool)showPublic;
- (enum ThreadStatus)explorerThreadStatus;

- (void)setShowInformationSchema:(bool)newValue;
- (void)setShowPGCatalog:(bool)newValue;
- (void)setShowPGToast:(bool)newValue;
- (void)setShowPGTemps:(bool)newValue;
- (void)setShowPublic:(bool)newValue;
- (void)setExplorerThreadStatus:(enum ThreadStatus)newValue;

	// These methods get called because I am the datasource of the outline view.
- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item;
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item;
- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item;
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item;

- (BOOL)printLog;

@end
