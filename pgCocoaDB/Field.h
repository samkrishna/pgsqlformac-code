//
//  Field.h
//  Query Tool
//
//  Created by Andy Satori on Wed Feb 04 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Field : NSObject 
{
	NSString *name;
	NSString *value;
}
- (NSString *)name;
- (void)setName:(NSString *)newName;

- (NSString *)value;
- (void)setValue:(NSString *)newValue;

@end
