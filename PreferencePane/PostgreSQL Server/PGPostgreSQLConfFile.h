//
//  PGPostgreSQLConfFile.h
//  PostgreSQL Server
//
//  Created by Andy Satori on 2/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PGPostgreSQLConfFile : NSObject {
	NSStringEncoding encoding;
	NSMutableString *rawSourceData;
	
	NSMutableArray *comments;  // each array contains a line number and the data.
	NSMutableDictionary *allOptions;
}

-(id)initWithContentsOfFile:(NSString *)file;
-(BOOL)saveToFile:(NSString *)file;

-(BOOL)parseSourceData;

-(NSMutableDictionary *)allOptions;

-(NSString *)source;
-(void)setSource:(NSString *)value;

@end
