//
//  PGHBAFile.m
//  PostgreSQL Network Configuration
//
//  Created by Andy Satori on 11/13/08.
//  Copyright 2008 Druware Software Designs. All rights reserved.
//

#import "PGHBAFile.h"


@implementation PGHBAFile

-(id)initWithContentsOfFile:(NSString *)file
{
    self = [super init];
	
	if (self != nil) {
		rawSourceData = nil;
		comments = [[[[NSMutableArray alloc] init] autorelease] retain];
		allConnections = [[[[PGHBAConnections alloc] init] autorelease] retain];
		
		NSError *readError = nil;
		rawSourceData = [[NSMutableString alloc] initWithContentsOfFile:file 
														   usedEncoding:&encoding 
																  error:&readError];
		if (readError != nil)
		{
			NSLog(@"Error Reading File: %@", rawSourceData); 
			return nil;
		}
		[[rawSourceData retain] autorelease];
		
		// parse the raw data into the data elements
		[self parseSourceData];						  
	}
	
    return self;
}


-(BOOL)saveToFile:(NSString *)file
{
	// make sure to rebuild the file from the lists if needed
	
	NSError *readError = nil;
	if (![rawSourceData writeToFile:file atomically:YES encoding:encoding error:&readError])
	{
		if (readError != nil)
		{
			NSLog(@"Error Reading File: %@", rawSourceData); 
			return NO;
		}
	}
	
	return YES;
}

-(BOOL)parseSourceData
{
	NSArray *lines = [rawSourceData componentsSeparatedByString:@"\n"];
	int x;
	for (x = 0; x < [lines count]; x++)
	{
		NSString *line = [lines objectAtIndex:x];
		NSRange rangeOfComment = [line rangeOfString:@"#"];
		
		// if there is a # at the beginning, it's a comment.
		NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
		NSNumber *lineNumber = [[NSNumber alloc] initWithInteger:x];
		[dict setObject:lineNumber forKey:@"Line#"];
		
		if (rangeOfComment.location == 0)
		{
			[dict setObject:line forKey:@"Comment"];
			[comments addObject:dict];
		} else if ([line length] == 0) {
			[dict setObject:line forKey:@"Comment"];
			[comments addObject:dict];
		} else {
			// parse the line
			NSArray *tempElements = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
			NSMutableArray *elements = [[NSMutableArray alloc] init];
			
			int i;
			for (i = 0; i < [tempElements count]; i++)
			{
				NSString *element = [tempElements objectAtIndex:i];
				if ([element length] > 0)
				{
					[elements addObject:element];
				}
			}
			
			// determine the record type and add it to the correct array.
			if ([[elements objectAtIndex:0] caseInsensitiveCompare:@"local"] == NSOrderedSame)
			{
				[dict setObject:@"Local" forKey:@"group"];				
				[dict setObject:[elements objectAtIndex:0] forKey:@"type"];
				[dict setObject:[elements objectAtIndex:1] forKey:@"database"];
				[dict setObject:[elements objectAtIndex:2] forKey:@"user"];
				[dict setObject:[elements objectAtIndex:3] forKey:@"method"];
				if ([elements count] > 4)
					[dict setObject:[elements objectAtIndex:4] forKey:@"option"];
			} else {
				NSRange rangeOfColon = [[elements objectAtIndex:3] rangeOfString:@":"];

				[dict setObject:[elements objectAtIndex:0] forKey:@"type"];
				[dict setObject:[elements objectAtIndex:1] forKey:@"database"];
				[dict setObject:[elements objectAtIndex:2] forKey:@"user"];
				[dict setObject:[elements objectAtIndex:3] forKey:@"address"];
				[dict setObject:[elements objectAtIndex:4] forKey:@"method"];
				
				if ([elements count] > 5)
					[dict setObject:[elements objectAtIndex:5] forKey:@"option"];
				
				// determine if element index 3 is an ipv4 or ipv6 address.
				if (rangeOfColon.location == NSNotFound)
				{
					[dict setObject:@"IPv4" forKey:@"group"];				
				} else {
					[dict setObject:@"IPv6" forKey:@"group"];				
				}
			}
			[[allConnections items] addObject:dict];
		}
	}
	
	return YES;
}

-(PGHBAConnections *)allConnections
{
	return allConnections;
}

-(NSString *)source {
	return rawSourceData;
}

-(void)setSource:(NSString *)value
{
	if (rawSourceData != nil)
	{
		[rawSourceData release];
		rawSourceData = nil;
	}
	
	rawSourceData = [[NSString alloc] initWithString:value];
	[[rawSourceData retain] autorelease];
	
	[self parseSourceData];
}

@end
