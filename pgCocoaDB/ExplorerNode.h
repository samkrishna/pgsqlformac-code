//
//  ExplorerNode.h
//  pgCocoaDB
//
//  Created by Neil Tiffin on 3/12/06.
//  Copyright 2006 Performance Champions, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PGCocoaDB.h"

@interface ExplorerNode : NSObject {
	NSMutableArray * children;
	ExplorerNode * parent;
	NSAttributedString * name;	// name of this node displayed in column 1
								//    of the outline view
	NSString * baseTable;		// pg_catalog table where the oid resides
	UInt32	oid;				// oid entry in the baseTable
	NSString * explorerType;	// i.e. table, index, sequence etc.
	NSString * displayColumn2;	// info to display in column 2 of the outline view
								//	  content depends on explorerType
	NSString * comment;			// From postgresql comments database
								//    for display as a tool tip
	NSString *baseSchema;
}

	// Accessor methods
-(NSString *)name;
//-(NSAttributedString *) attributedName;
-(NSString *)baseTable;
-(NSString *)explorerType;
-(NSString *)displayColumn2;
-(NSString *)comment;
-(NSString *)baseSchema;
-(UInt32)oid;

-(void)setName:(NSString *)s;
-(void)setNameColor:(NSColor *)s;
-(void)setBaseTable:(NSString *)s;
-(void)setExplorerType:(NSString *)s;
-(void)setDisplayColumn2:(NSString *)s;
-(void)setComment:(NSString *)s;
-(void)setBaseSchema:(NSString *)s;
-(void)setOID:(UInt32)o;

	// Accessors for the parent node
- (ExplorerNode *)parent;
- (void)setParent:(ExplorerNode *)n;

	// Accessors for the children
- (void)addChild:(ExplorerNode *)n;
- (int)childrenCount;
- (ExplorerNode *)childAtIndex:(int)i;

	// Other properties
- (BOOL)expandable;

- (void)printLog:(unsigned int)indent;

@end
