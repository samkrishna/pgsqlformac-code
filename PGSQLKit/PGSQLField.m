//
//  PGSQLField.m
//  PGSQLKit
//
//  Created by Andy Satori on 6/7/07.
//  Copyright 2007 Druware Software Designs. All rights reserved.
//

#import "PGSQLField.h"
#include "libpq-fe.h"

@implementation PGSQLField

-(id)initWithResult:(void *)result forColumn:(PGSQLColumn *)forColumn
			  atRow:(int)atRow
{
	[super init];
	
	data = nil;
	
	if (PQgetisnull(result, atRow, [column index]) == 1) {
		return self;
	}
	
	int iLen;
	char *szBuf;
	
	column = forColumn;
	iLen = PQgetlength(result, atRow, [column index]) + 1;	
	
	// this may have to be adjust if the column type is not 0 (eg, it's binary)
	szBuf = PQgetvalue(result, atRow, [column index]);	
	data = nil;
	if (iLen > 0) {
		data = [[NSData alloc] initWithBytes:szBuf length:iLen];
	}

	return self;
}

-(NSString *)asString
{	
	NSString* result = @"";
	if (data != nil)
	{
		int dataLength = [data length];
		if (dataLength > 0)
		{
			// check for null terminator
			char* ptr = (char*)[data bytes];
			char lastChar = ptr[dataLength];
			if (lastChar == '\0')
				dataLength--;
			if (dataLength > 0)
				result = [[[NSString alloc] initWithBytes:[data bytes] length:dataLength encoding:NSMacOSRomanStringEncoding] autorelease];
		}
	}
	return result; 
}

-(NSNumber *)asNumber
{
	if (data != nil) {
		if ([data length] <= 0)
		{
			return nil;
		}
		
		NSNumber *value = [[NSNumber alloc] initWithFloat:
			[[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSMacOSRomanStringEncoding] floatValue]];
		return value;
	}
	return nil;
}

-(long)asLong
{
	if (data != nil) {
		if ([data length] <= 0)
		{
			return nil;
		}
		
		NSString *value = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSMacOSRomanStringEncoding];
		
		return (long)[[NSNumber numberWithFloat:[value floatValue]] longValue];
	}
	return 0; 
}

-(NSDate *)asDate
{
	if (data != nil) {
		if ([data length] <= 0)
		{
			return nil;
		}
		
		NSString *value = [NSString stringWithCString:(char *)[data bytes]
											 encoding:NSMacOSRomanStringEncoding];
		if ([value rangeOfString:@"."].location != NSNotFound)
		{
			value = [NSString stringWithFormat:@"%@ +0000", [value substringToIndex:[value rangeOfString:@"."].location]];
		} else {
			
			value = [NSString stringWithFormat:@"%@ +0000", value];
		}
		NSDate *newDate = [[NSDate alloc] initWithString:value];
		
		return newDate;
	}
	return nil; 	
}

-(NSData *)asData
{
	if (data != nil) {
		if ([data length] <= 0)
		{
			return nil;
		}
		
		return [[[[NSData alloc] initWithData:data] autorelease] retain];
	}
	return nil; 	
}

-(BOOL)asBoolean
{
	if (data != nil) {
		return ([data bytes] == 't');
	}
	return NO;
}


-(BOOL)isNull
{
	return (data == nil);
}

@end;
