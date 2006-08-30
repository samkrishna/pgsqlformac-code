//
//  MyResultsView.h
//  Query Tool for PostgresN
//
//  Created by Neil Tiffin on 7/16/06.
//  Copyright 2006 Performance Champions, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QueryTool.h"

@interface MyResultsView : NSTableView {

	NSFont *currentFont;
}

- (void)changeFont:(id)sender;
- (NSFont *)currentFont;
- (void)setCurrentFont:(NSFont *)theFont;

@end
