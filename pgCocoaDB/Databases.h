//
//  Databases.h
//
//  Created by Andy Satori on Thu 01/29/04 10:53 PM
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Database.h"

@interface Databases : NSObject 
{
	NSMutableArray *items;
}

- (Database *)addItem;
- (void)removeItemAtIndex:(int)index;
- (Database *)itemAtIndex:(int)index;
- (int)count;

@end
