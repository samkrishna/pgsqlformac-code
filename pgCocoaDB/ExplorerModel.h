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
#import "PGCocoaDB.h"


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
	unsigned int explorerThreadStatus;	// 0 = not inited, 1 = running, 2 = error, 3 = done, 
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
- (unsigned int)explorerThreadStatus;

- (void)setShowInformationSchema:(bool)newValue;
- (void)setShowPGCatalog:(bool)newValue;
- (void)setShowPGToast:(bool)newValue;
- (void)setShowPGTemps:(bool)newValue;
- (void)setShowPublic:(bool)newValue;
- (void)setExplorerThreadStatus:(unsigned int)newValue;

	// These methods get called because I am the datasource of the outline view.
- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item;
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item;
- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item;
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item;

- (void)printLog;

@end
