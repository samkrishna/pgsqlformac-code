//
//  PGSQLConnectionInfo.m
//  PGSQLKit
//
//  Created by Andy Satori on 4/21/09.
//  Copyright 2009 Druware Software Designs. All rights reserved.
//

#import "PGSQLConnectionInfo.h"
#import "PGSQLConnection.h"
#import "PGSQLRecordset.h"

@implementation PGSQLConnectionInfo

-(id)initWithConnection:(PGSQLConnection *)connection
{
	self = [super init];
	
	pgConnection = connection;
	
	NSMutableString *cmd = [[NSMutableString alloc] init];
	[cmd appendString:@"select current_database() as db, current_user as user, version() as version, current_schema() as schema"]; 
	PGSQLRecordset *rs = (PGSQLRecordset *)[pgConnection open:cmd];
	if (![rs isEOF])
	{
		//userName = [[rs fieldByIndex:1] asString];
		versionString = [[rs fieldByIndex:2] asString];
		//schemaName = [[rs fieldByIndex:3] asString];
	}
	[rs close];
	
	return self;
}


#pragma mark -
#pragma mark Simple Accessors

- (NSString *)versionString
{
	return versionString;
}

@end
