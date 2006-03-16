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

@interface ExplorerModel : NSObject
{
	ExplorerNode * rootNode;
	Connection * connection;
	Schema * schema;
}

- (id)initWithConnection:(Connection *) aConnection;

	// These methods get called because I am the datasource of the outline view.
- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item;
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item;
- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item;
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item;

- (void)printLog;

@end
