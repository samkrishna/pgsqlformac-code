//
//  SqlMenuCategory.h
//  Query Tool for Postgres
//
//  Created by Andy Satori on Wed May 26 2004.
//  Copyright (c) 2004 druware software designs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SqlDocument.h"
#import "QueryTool.h"

@interface SqlDocument (SqlMenuCategory)

- (BOOL)validateMenuItem:(NSMenuItem *)theItem;

@end
