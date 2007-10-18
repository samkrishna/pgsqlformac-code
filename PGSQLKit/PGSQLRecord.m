//
//  PGSQLRecord.m
//  PGSQLKit
//
//  Created by Andy Satori on 6/7/07.
//  Copyright 2007 Druware Software Designs. All rights reserved.
//

#import "PGSQLRecord.h"
#include "libpq-fe.h"

@implementation PGSQLRecord


-(id)initWithResult:(void *)result atRow:(long)atRow columns:(NSArray *)columncache
{
	[super init];

	pgResult = result;
	columns = columncache;
	rowNumber = atRow;
	
	return self;
}

-(PGSQLField *)fieldByName:(NSString *)fieldName
{
	// find the field index from the columns.
	int x = 0;
	PGSQLColumn *column;
	
	for (x = 0; x < [columns count]; x++)
	{
		if ([[[columns objectAtIndex:x] name] caseInsensitiveCompare:fieldName] == NSOrderedSame)
		{
			column = [columns objectAtIndex:x];
			break;
		}
	}
	
	PGSQLField *result = [[PGSQLField alloc] initWithResult:pgResult forColumn:column
														   atRow:rowNumber];
	return [[result retain] autorelease];
}

-(PGSQLField *)fieldByIndex:(long)fieldIndex
{
	// find the field index from the columns.
	PGSQLField *result = [[PGSQLField alloc] initWithResult:pgResult forColumn:[columns objectAtIndex:fieldIndex]
													  atRow:rowNumber];

	return [[result retain] autorelease];
}

-(long)rowNumber
{
	return rowNumber;
}

@end
