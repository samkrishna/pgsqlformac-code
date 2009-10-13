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
	self = [super init];
	
	if (self)
	{
		data = nil;
	
		if (PQgetisnull(result, atRow, [forColumn index]) != 1)
		{		
			char* szBuf = nil;
			
			column = [forColumn retain];
			int iLen = PQgetlength(result, atRow, [column index]) + 1;	
			
			// this may have to be adjust if the column type is not 0 (eg, it's binary)
			szBuf = PQgetvalue(result, atRow, [column index]);
			if (iLen > 0)
				data = [[NSData alloc] initWithBytes:szBuf length:iLen];
		}
	}

	return self;
}

- (void)dealloc
{
	[data release];
	[column release];
	[super dealloc];
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
			char lastChar = ptr[dataLength - 1];
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
		NSString *temp = [[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSMacOSRomanStringEncoding] autorelease];
		NSNumber *value = [[[NSNumber alloc] initWithFloat:[temp floatValue]] autorelease];
		return value;
	}
	return nil;
}

-(long)asLong
{
	if (data != nil) {
		if ([data length] <= 0)
		{
			return 0;
		}
		
		NSString *value = [[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSMacOSRomanStringEncoding] autorelease];
		
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
		NSDate *newDate = [[[NSDate alloc] initWithString:value] autorelease];
		
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
		
		return [[[NSData alloc] initWithData:data] autorelease];
	}
	return nil; 	
}

-(BOOL)asBoolean
{
	BOOL result = NO;
	if (data != nil)
	{
		char charResult = *(char*)[data bytes];
		result = (charResult == 't');
	}
	return result;
}

-(BOOL)isNull
{
	return (data == nil);
}

@end;
