//
//  RecordSet.h
//
//  Created by Andy Satori on Mon 02/02/04 12:36 PM
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Record.h"

@interface RecordSet : NSObject 
{
	NSMutableArray *items;
}

- (Record *)addItem;
- (void)removeItemAtIndex:(int)index;
- (Record *)itemAtIndex:(int)index;
- (int)count;

@end
