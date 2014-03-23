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
        comments = [[NSMutableArray alloc] init];
        allConnections = [[PGHBAConnections alloc] init];
        
		NSError *readError = nil;
		rawSourceData = [[NSMutableString alloc] initWithContentsOfFile:file 
														   usedEncoding:&encoding 
																  error:&readError];
		if (readError != nil)
		{
			NSLog(@"Error Reading File: %@", rawSourceData); 
			return nil;
		}
		
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
	groupLocalOrigin = 0;
	groupIPv4Origin = 0;
	groupIPv6Origin = 0;
    
    // clear the arrays first
    if ([comments count] > 0)
    {
        [comments removeAllObjects];
    }
    
    if ([[allConnections items] count] > 0)
    {
        [[allConnections items]  removeAllObjects];
    }
	
	NSArray *lines = [rawSourceData componentsSeparatedByString:@"\n"];
	int x;
	for (x = 0; x < [lines count]; x++)
	{
		NSString *line = lines[x];
		NSRange rangeOfComment = [line rangeOfString:@"#"];
		
		// if there is a # at the beginning, it's a comment.
		NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
		NSNumber *lineNumber = @(x);
		dict[@"Line#"] = lineNumber;
		
		if (rangeOfComment.location == 0)
		{
			dict[@"Comment"] = line;
			[comments addObject:dict];
		} else if ([line length] == 0) {
			dict[@"Comment"] = line;
			[comments addObject:dict];
		} else {
			// parse the line
			NSArray *tempElements = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
			NSMutableArray *elements = [[NSMutableArray alloc] init];
			
			int i;
			for (i = 0; i < [tempElements count]; i++)
			{
                NSString *element = tempElements[i];
                if ([element length] > 0)
                {
                    [elements addObject:element];
                }
			}
			
			// determine the record type and add it to the correct array.
			if ([elements[0] caseInsensitiveCompare:@"local"] == NSOrderedSame)
			{
                if (groupLocalOrigin == 0) { groupLocalOrigin = x; }
                dict[@"group"] = @"Local";				
                dict[@"type"] = elements[0];
                dict[@"database"] = elements[1];
                dict[@"user"] = elements[2];
                dict[@"method"] = elements[3];
                dict[@"address"] = @"";
                dict[@"option"] = @"";
                if ([elements count] > 4)
                    dict[@"option"] = elements[4];
				
			} else {
                NSRange rangeOfColon = [elements[3] rangeOfString:@":"];
                
                dict[@"type"] = elements[0];
                dict[@"database"] = elements[1];
                dict[@"user"] = elements[2];
                dict[@"address"] = elements[3];
                dict[@"method"] = elements[4];
                dict[@"option"] = @"";
                if ([elements count] > 5)
                    dict[@"option"] = elements[5];
                
                // determine if element index 3 is an ipv4 or ipv6 address.
                if (rangeOfColon.location == NSNotFound)
                {
                    if (groupIPv4Origin == 0) { groupIPv4Origin = x; }
                    dict[@"group"] = @"IPv4";				
                } else {
                    if (groupIPv6Origin == 0) { groupIPv6Origin = x; }
                    dict[@"group"] = @"IPv6";				
                }
			}
			[[allConnections items] addObject:dict];
		}
	}
	
	return YES;
}

-(int)getMaxLineNumber
{
    int maxLineNum = 0;
	int x;
    
	// find the max line number so we know how many lines to write
    for (x = 0; x < [comments count]; x++)
	{
        if ([comments[x][@"Line#"] intValue] > maxLineNum)
            maxLineNum = [comments[x][@"Line#"] intValue];
	}
    
    for (x = 0; x < [[allConnections items] count]; x++)
	{
        if ([[allConnections items][x][@"Line#"] intValue] > maxLineNum)
            maxLineNum = [[allConnections items][x][@"Line#"] intValue];
	}
    
    return maxLineNum;
}

-(int)getMaxLineNumberForGroup:(NSString *)group
{
    int maxLineNum = 0;
	int x;
    
	// find the max line number so we know how many lines to write
    for (x = 0; x < [[allConnections items] count]; x++)
	{
        if ([[allConnections items][x][@"group"] isEqualToString:group] == NSOrderedSame)
            if ([[allConnections items][x][@"Line#"] intValue] > maxLineNum)
                maxLineNum = [[allConnections items][x][@"Line#"] intValue];
	}
    
    return maxLineNum;
}

-(void)incrementLineNumbersFromNumber:(int)startingWith
{
	int x;
    
    NSLog(@"Incrementing Comment Line#'s from %d", startingWith);
    
	// find the max line number so we know how many lines to write
    for (x = 0; x < [comments count]; x++)
	{
        if ([comments[x][@"Line#"] intValue] >= startingWith)
            [comments[x] setValue:@([comments[x][@"Line#"] intValue] + 1) forKey:@"Line#"];
	}
    
    NSLog(@"Incrementing Connection Line#'s from %d", startingWith);

    for (x = 0; x < [[allConnections items] count]; x++)
	{
        if ([[allConnections items][x][@"Line#"] intValue] >= startingWith)
            [[allConnections items][x] setValue:@([[allConnections items][x][@"Line#"] intValue] + 1) forKey:@"Line#"];
	}
}

-(void)decrementLineNumbersFromNumber:(int)startingWith
{
	int x;
    
    NSLog(@"Incrementing Comment Line#'s from %d", startingWith);
    
	// find the max line number so we know how many lines to write
    for (x = 0; x < [comments count]; x++)
	{
        if ([comments[x][@"Line#"] intValue] >= startingWith)
            [comments[x] setValue:@([comments[x][@"Line#"] intValue] - 1) forKey:@"Line#"];
	}
    
    NSLog(@"Incrementing Connection Line#'s from %d", startingWith);
    
    for (x = 0; x < [[allConnections items] count]; x++)
	{
        if ([[allConnections items][x][@"Line#"] intValue] >= startingWith)
            [[allConnections items][x] setValue:@([[allConnections items][x][@"Line#"] intValue] - 1) forKey:@"Line#"];
	}
}


-(BOOL)generateSourceData
{
	NSMutableString *newSource = [[NSMutableString alloc] init];
	
    // write the lines to newSource from comments until groupLocalOrigin
	// then loop the connections for all locals
	// rinse and repeat for IPv4 and IPv6
	
	int lineNum = 0;
	int maxLineNum = [self getMaxLineNumber];
    int x;
    
    // find the current line number object and write it to the file

	for (lineNum = 0; lineNum <= maxLineNum; lineNum++)
    {
        BOOL found = NO;
        for (x = 0; x < [comments count]; x++)
        {
            if ([comments[x][@"Line#"] intValue] == lineNum)
            {
                [newSource appendFormat:@"%@\n", comments[x][@"Comment"]];
                found = YES;
                break;
            }
        }
        
        if (!found)
        {
            for (x = 0; x < [[allConnections items] count]; x++)
            {
                if ([[allConnections items][x][@"Line#"] intValue] == lineNum)
                {
                    // type database postgres 127.0.0.1/32 trust option
                    [newSource appendFormat:@"%@ \t %@ \t %@ \t %@ \t %@ \t %@ \n",
                     [allConnections items][x][@"type"],
                     [allConnections items][x][@"database"],
                     [allConnections items][x][@"user"],
                     [allConnections items][x][@"address"],
                     [allConnections items][x][@"method"],
                     [allConnections items][x][@"option"]
                     ];
                    break;
                }
            }
        }
    }

	
	rawSourceData = [[NSMutableString alloc] initWithString:newSource];

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
		rawSourceData = nil;
	}
	
	rawSourceData = [[NSMutableString alloc] initWithString:value];
	
	[self parseSourceData];
}

@end
