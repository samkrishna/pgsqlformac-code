//
//  PGPostgreSQLConfFile.h
//  PostgreSQL Server
//
//  Created by Andy Satori on 2/23/09.
//  Copyright 2009 Druware Software Designs. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PGPostgreSQLConfFile : NSObject {
	NSStringEncoding encoding;
	NSMutableString *rawSourceData;
	
	
	NSMutableArray *allOptions;  // each array contains a line number and the data.
}

-(id)initWithContentsOfFile:(NSString *)file;
-(BOOL)saveToFile:(NSString *)file;

-(BOOL)parseSourceData;

-(NSMutableArray *)allOptions;

-(NSString *)source;
-(void)setSource:(NSString *)value;

@end
