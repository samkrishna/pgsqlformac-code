//
//  Database.h
//  Query Tool
//
//  Created by Andy Satori on Sun Feb 01 2004.
//  Copyright (c) 2004 Druware Software Designs. All rights reserved.
//
 
#import <Foundation/Foundation.h>

@interface Database : NSObject 
{
	NSString	*name;
}

- (NSString *)name;
- (void)setName:(NSString *)newName;

@end
