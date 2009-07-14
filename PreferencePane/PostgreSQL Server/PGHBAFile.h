//
//  PGHBAFile.h
//  PostgreSQL Network Configuration
//
//  Created by Andy Satori on 11/13/08.
//  Copyright 2008 Druware Software Designs. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PGHBAConnections.h"


@interface PGHBAFile : NSObject {
	NSStringEncoding encoding;
	NSMutableString *rawSourceData;
	
	long groupLocalOrigin;
	long groupIPv4Origin;
	long groupIPv6Origin;
	
	NSMutableArray *comments;  // each array contains a line number and the data.
	PGHBAConnections *allConnections;
}

-(id)initWithContentsOfFile:(NSString *)file;
-(BOOL)saveToFile:(NSString *)file;

-(BOOL)parseSourceData;
-(BOOL)generateSourceData;

-(PGHBAConnections *)allConnections;

-(NSString *)source;
-(void)setSource:(NSString *)value;

@end
