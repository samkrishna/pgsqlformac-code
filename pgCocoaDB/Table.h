//
//  Table.h
//  Query Tool
//
//  Created by Andy Satori on Sun Feb 08 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Table : NSObject 
{
	NSString	*schema;
	NSString	*name;
	NSString	*owner;
	BOOL		 hasIndexes;
	BOOL		 hasRules;
	BOOL		 hasTriggers;
}

- (NSString *)schema;
- (void)setSchema:(NSString *)newSchema;

- (NSString *)name;
- (void)setName:(NSString *)newName;

- (NSString *)owner;
- (void)setOwner:(NSString *)newOwner;

- (BOOL)hasIndexes;
- (void)setHasIndexes:(BOOL)newHasIndexes;

- (BOOL)hasRules;
- (void)setHasRules:(BOOL)newHasRules;

- (BOOL)hasTriggers;
- (void)setHasTriggers:(BOOL)newHasTriggers;

@end
