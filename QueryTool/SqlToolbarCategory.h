//
//  SqlToolbarCategory.h
//  Query Tool for Postgres
//
//  Created by Andy Satori on Wed May 26 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SqlDocument.h"

@interface SqlDocument (SqlToolbarCategory)

- (void)setupToolbar;
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar;
- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem;
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
    itemForItemIdentifier:(NSString *)itemIdentifier
    willBeInsertedIntoToolbar:(BOOL)flag;

@end
