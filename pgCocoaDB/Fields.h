//
//  Fields.h
//
//  Created by Andy Satori on Wed 02/04/04 12:35 AM
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Field.h"
#import "PGCocoaDB.h"

@interface Fields : NSObject 
{
        NSMutableArray *items;
}

- (Field *)addItem;
- (void)removeItemAtIndex:(int)index;
- (Field *)itemAtIndex:(int)index;
- (int)count;
- (NSString *)getValueFromName:(NSString *)fieldName;

@end
