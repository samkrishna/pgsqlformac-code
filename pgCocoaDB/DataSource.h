//
//  DataSource.h
//
//  Created by Andy Satori on Sun 02/08/04 05:38 PM
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PGCocoaDB.h"

@interface DataSource : NSObject 
{
        NSMutableArray *items;
}

- (NSMutableDictionary *)addItem;
- (void)removeItemAtIndex:(int)index;
- (NSMutableDictionary *)itemAtIndex:(int)index;
- (int)count;

@end
