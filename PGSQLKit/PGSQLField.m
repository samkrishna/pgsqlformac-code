/*          file: PGSQLField.m
 *   description: Encapsulate a single data field in the result set of a PGSQL
 *                command.  As a convenience, the field object does offers some
 *                internal tools for converting the data into Foundation native
 *                classes, like NSString, NSNumber, NSDate and NSData.
 *
 * License *********************************************************************
 *
 * Copyright (c) 2007-2011, Andy 'Dru' Satori @ Druware Software Designs 
 * All rights reserved.
 *
 * Redistribution and use in source or binary forms, with or without
 *  modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions in source or binary form must reproduce the above
 *    copyright notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the distribution.
 * 2. Neither the name of the Druware Software Designs nor the names of its
 *    contributors may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 *******************************************************************************
 *
 * history:
 *   see method headers for detailed history of changes
 *
 ******************************************************************************/

#import "PGSQLField.h"
#include "libpq-fe.h"

@implementation PGSQLField

/* init
 *   description
 *     override the default NSObject init method to prevent a bare init for the
 *     data object. Throws an exception if called.
 *   arguments
 *     none
 *   returns
 *     none
 *   history
 *     who   date    change
 *     --- -------- ----------------------------------------------------------- 
 ******************************************************************************/
- (id)init
{
	NSException* myException = [NSException
								exceptionWithName:@"InvalidInitCalled"
								reason:@"Init cannot be called without a parameter, use initWithResult: instead"
								userInfo:nil];
	@throw myException;
    
    return nil;
}

-(id)initWithResult:(void *)result forColumn:(PGSQLColumn *)forColumn
			  atRow:(int)atRow
{
	self = [super init];
	
	if (self)
	{
		data = nil;
		
		// this will default to NSUTF8StringEncoding with PG9
		defaultEncoding = NSUTF8StringEncoding;

		if (PQgetisnull(result, atRow, [forColumn index]) != 1)
		{		
			char* szBuf = nil;
			
			column = [forColumn retain];
			
			int format = PQfformat(result, [column index]);
			
			int iLen = PQgetlength(result, atRow, [column index]);			// Binary
			if (format == 0)
			{
				iLen = PQgetlength(result, atRow, [column index]) + 1;		// Text
			}
			
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
				result = [[[NSString alloc] initWithBytes:[data bytes] length:dataLength encoding:defaultEncoding] autorelease];
		}
	}
	return result; 
}

-(NSString *)asString:(NSStringEncoding)encoding
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
					result = [[[NSString alloc] initWithBytes:[data bytes] length:dataLength encoding:encoding] autorelease];
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
		NSString *temp = [[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding] autorelease];
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
		
		NSString *value = [[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding] autorelease];
		
		return (long)[[NSNumber numberWithFloat:[value floatValue]] longValue];
	}
	return 0; 
}


-(short)asShort
{
	if (data != nil) {
		if ([data length] <= 0)
		{
			return 0;
		}
		
		NSString *value = [[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding] autorelease];
		
		return (short)[[NSNumber numberWithFloat:[value floatValue]] shortValue];
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
											 encoding:NSUTF8StringEncoding];
        // in the case of an abstime, this value will include a GMT offset in 
        // the form -/+#, this will need to be adjusted accordingly to convert 
        // to an NSDate
        
        // a postgresql date/time returns in the format(s):
        //   abstime      YYYY-MM-DD HH:mm:SS(-/+)##(:##)
        //   timestamp    YYYY-MM-DD HH:mm:SS.microsecond
        //   date         YYYY-MM-DD
        //   time                    HH:mm:SS.microsecond
        //   timestamptz  YYYY-MM-DD HH:mm:SS.microsecond(-/+))##(:##)
        //   timetz                  HH:mm:SS.microsecond(-/+))##(:##)
        // ISO DEFAULT: http://www.w3.org/TR/NOTE-datetime
        
        // based upon the above, it makes sense to parse the data into a 
        // format that can be processed by NSDate and it the NSDate formatter.
                    
        // it is worth noting that PostgreSQL can output dates in several 
        // formats and as such this should account for each:
        // http://www.postgresql.org/docs/8.0/static/datatype-datetime.html
        

        NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeZone:[NSTimeZone defaultTimeZone]];
        
        // need to determine which output style we have:
        //  ISO         ISO 8601/SQL standard	1997-12-17 07:37:16-08      
        //  SQL         traditional style       12/17/1997 07:37:16.00 PST
        //  POSTGRES	original style          Wed Dec 17 07:37:16 1997 PST
        //  German      regional style          17.12.1997 07:37:16.00 PST
        
        switch ([column type])
        {
            case 702:   // abstime (date and time)
                [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ssZ"];
                break;

            case 1082:  // date  
                [dateFormatter setDateFormat:@"yyyy-MM-dd"];
                break;
                
            case 1083:  // time
                [dateFormatter setDateFormat:@"HH:mm:ss.s"];
                break;
                
            case 1114:  // timestamp
                [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.s"];
                break;
                
            case 1184:  // timestamptz
                [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.sZ"];
                break;
                
            case 1266:  // timetz
                [dateFormatter setDateFormat:@"HH:mm:ss.sZ"];
                break;
                
            default:
                break;
        }
        [dateFormatter autorelease];
        return [dateFormatter dateFromString:value];
	}
	return nil; 	
}

-(NSDate *)asDateWithGMTOffset:(NSString *)gmtOffset
{
	if (data != nil) {
		if ([data length] <= 0)
		{
			return nil;
		}
		
		NSString *value = [NSString stringWithCString:(char *)[data bytes]
											 encoding:NSUTF8StringEncoding];
		if ([value rangeOfString:@"."].location != NSNotFound)
		{
			value = [NSString stringWithFormat:@"%@ %@", 
					 [value substringToIndex:[value rangeOfString:@"."].location],
					 gmtOffset];
		} else {
			
			value = [NSString stringWithFormat:@"%@ %@", value, gmtOffset];
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

-(NSStringEncoding)defaultEncoding
{
	return defaultEncoding;
}

-(void)setDefaultEncoding:(NSStringEncoding)value
{
    if (defaultEncoding != value) {
        defaultEncoding = value;
    }	
	
}

@end;
