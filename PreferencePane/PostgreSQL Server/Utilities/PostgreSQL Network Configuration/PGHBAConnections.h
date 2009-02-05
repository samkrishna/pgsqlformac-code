//
//  PGHBAConnections.h
//  PostgreSQL Network Configuration
//
//  Created by Andy Satori on 1/8/09.
//  Copyright 2009 Druware Software Designs. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PGHBAConnections : NSObject {
	NSMutableArray *items;
}

- (NSMutableArray *)items;
- (void)setItems:(NSMutableDictionary *)value;

@end
