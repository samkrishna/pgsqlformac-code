//
//  SqlToolbarCategory.m
//  Query Tool for Postgres
//
//  Created by Andy Satori on Wed May 26 2004.
//  Copyright (c) 2004 druware software designs. All rights reserved.
//

#import "SqlToolbarCategory.h"

@implementation SqlDocument (SqlToolbarCategory)

- (void)setupToolbar
{
    NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"sqlToolbar"];
    [toolbar setDelegate:self];
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];
    [window setToolbar:[toolbar autorelease]];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
    itemForItemIdentifier:(NSString *)itemIdentifier
    willBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    
    if ( [itemIdentifier isEqualToString:@"Connect"] ) {
        [item setLabel:@"Connect"];
        [item setPaletteLabel:[item label]];
        [item setImage:[NSImage imageNamed:@"connect_32"]];
        [item setTarget:self];
        [item setAction:@selector(onConnect:)];
    }
	
    if ( [itemIdentifier isEqualToString:@"Disconnect"] ) {
        [item setLabel:@"Disconnect"];
        [item setPaletteLabel:[item label]];
        [item setImage:[NSImage imageNamed:@"disconnect_32"]];
        [item setTarget:self];
        [item setAction:@selector(onDisconnect:)];
    }
	
    if ( [itemIdentifier isEqualToString:@"Execute"] ) {
        [item setLabel:@"Execute"];
        [item setPaletteLabel:[item label]];
        [item setImage:[NSImage imageNamed:@"run_script_32"]];
        [item setTarget:self];
        [item setAction:@selector(onExecuteQuery:)];
    }
	
	if ( [itemIdentifier isEqualToString:@"SelectDB"] ) {
		NSRect fRect = [dbListView frame];
        [item setLabel:@"Select Database:"];
        [item setPaletteLabel:[item label]];
        [item setView:dbListView];
		[item setMinSize:fRect.size];
		[item setMaxSize:fRect.size];
    }
		
	return [item autorelease];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:@"Connect", @"Disconnect", @"Execute",
									 @"SelectDB",
	                                 NSToolbarSpaceItemIdentifier,
                                     NSToolbarFlexibleSpaceItemIdentifier,
                                     NSToolbarCustomizeToolbarItemIdentifier, nil];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:
        @"Connect", @"Disconnect", @"Execute", @"SelectDB",
        NSToolbarFlexibleSpaceItemIdentifier, 
        NSToolbarCustomizeToolbarItemIdentifier, nil];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
	// onConnect
    if ( [theItem action] == @selector(onConnect:) )
	{
        return (![conn isConnected]);
	}
	
	if ( [theItem action] == @selector(onDisconnect:) )
	{
        return ([conn isConnected]);
	}
	
    if ( [theItem action] == @selector(onExecuteQuery:) )
	{
        return ([conn isConnected]);
	}	
	
	//if ( [[theItem itemIdentifier] isEqualToString:@"SelectDB"] )
	//{
    //    return ([conn isConnected]);
	//}
		
	return YES;
}

@end
