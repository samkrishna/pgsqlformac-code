//
//  MyResultsView.m
//  Query Tool for PostgresN
//
//  Created by Neil Tiffin on 7/16/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "MyResultsView.h"


@implementation MyResultsView

-(void)changeFont:(id)sender
{
	int i;
	NSFont *oldFont = currentFont;
	currentFont = [sender convertFont:oldFont];
	NSArray *theCols = [self tableColumns];
	int colCnt = [self numberOfColumns];
	for(i=0; i< colCnt; i++)
	{   
		[[[theCols objectAtIndex:i] dataCell] setFont:currentFont];
	}
	[self setRowHeight:[[[theCols objectAtIndex:0] dataCell] cellSize].height];
	
	[[NSUserDefaults standardUserDefaults] setObject:[currentFont fontName] forKey:@"PGSqlForMac_QueryTool_ResultsTableFontName"];
	[[NSUserDefaults standardUserDefaults] setFloat:[currentFont pointSize] forKey:@"PGSqlForMac_QueryTool_ResultsTableFontSize"];
}

-(NSFont*)currentFont
{
	return currentFont;
}

-(void)setCurrentFont:(NSFont*)theFont
{
	currentFont=theFont;
}

@end
