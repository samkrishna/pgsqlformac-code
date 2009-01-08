//
//  PGHBAFile.h
//  PostgreSQL Network Configuration
//
//  Created by Andy Satori on 11/13/08.
//  Copyright 2008 Druware Software Designs. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PGHBAFile : NSObject {
	NSStringEncoding encoding;
	NSMutableString *rawSourceData;
	
	NSMutableArray *comments;  // each array contains a line number and the data.
	NSMutableArray *localConnections;
	NSMutableArray *ipv4Connections;
	NSMutableArray *ipv6Connections;	
}

-(id)initWithContentsOfFile:(NSString *)file;
-(BOOL)saveToFile:(NSString *)file;

-(BOOL)parseSourceData;

-(NSString *)source;
-(void)setSource:(NSString *)value;

@end
