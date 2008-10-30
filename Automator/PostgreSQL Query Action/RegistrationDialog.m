//
//  RegistrationDialog.m
//  PostgreSQL Query Action
//
//  Created by Andy Satori on 11/10/07.
//  Copyright 2007 Druware Software Designs. All rights reserved.
//

#import "RegistrationDialog.h"


@implementation RegistrationDialog

#pragma mark -
#pragma mark Class implementation

-(id)init
{
    self = [super init];
	
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onConnectionCompleted:) name:PGSQLConnectionDidCompleteNotification object:nil];
	
	return self;
} 

- (void)beginModalDialogForWindow:(NSWindow *)parent
{
	parentWindow = nil;
	if (nil != parent)
	{
		parentWindow = parent;
	}
	if (nil == parentWindow) 
	{
		return;
	}
	
	// load the nib 
	if (![NSBundle loadNibNamed:@"Registration" owner:self]) 
	{
		NSLog(@"Error loading nib for Registration Handler");
		return;
	}
	
	// populate the list from the keychain
	
	/*
	isShowingDetails = YES;
	[serverName setStringValue:@"localhost"];
	[serverPort setStringValue:@"5432"];
	[serverDatabase setStringValue:@"template1"];
	
	if (defaultDSN != nil)
	{
		isShowingDetails = YES;
		
		//	[savedConnections selectItemWithTitle:defaultDSN];		
	}
	
	[loginUserName setStringValue:@"postgres"];
	if (defaultUser != nil)
	{
		[loginUserName setStringValue:defaultUser];
	}
	
	[loginPassword setStringValue:@""];
	if (defaultPassword != nil)
	{
		[loginPassword setStringValue:defaultPassword];
	}
	*/
	
	// make sure the UI delegates are in place
	//[savedConnections setDelegate:self];
	
	[NSApp beginSheet:regPanel  
	   modalForWindow:parentWindow
		modalDelegate:self
	   didEndSelector:nil
		  contextInfo:nil];
	
    [NSApp runModalForWindow:regPanel];
	
	return;
}

- (IBAction)onOK:(id)sender
{
	[NSApp stopModal];
	

	
	[NSApp endSheet:regPanel];
    [regPanel orderOut:self];	
}


-(IBAction)regenerateOwner:(id)sender
{
	if ([[serialKey string] length] < 300)
	{
		[product setStringValue:@""];
		[ownerName setStringValue:@""];
		[emailAddress setStringValue:@""];
		[purchaseDate setStringValue:@""];
		[version setStringValue:@""];
		[validatedCode setStringValue:@""];
		
		return;
	}
	
	NSString *key = [serialKey string];
	NSString *productCode = [key substringWithRange:NSMakeRange(0,5)];
	NSString *versionString = [[NSString alloc] initWithFormat:@"%@.%@", 
							   [key substringWithRange:NSMakeRange(6,1)],
							   [key substringWithRange:NSMakeRange(7,2)]];
	int nameLength;
	sscanf([[key substringWithRange:NSMakeRange(11,2)] cStringUsingEncoding:NSMacOSRomanStringEncoding], "%X", &nameLength);
	NSString *name = [key substringWithRange:NSMakeRange(21,(nameLength * 2))];
	
	int emailLength;
	sscanf([[key substringWithRange:NSMakeRange(15,2)] cStringUsingEncoding:NSMacOSRomanStringEncoding], "%X", &emailLength);
	NSString *email = [key substringWithRange:NSMakeRange(297,(emailLength * 2))];
	
	NSMutableString *confirmationCode = [[NSMutableString alloc] init];
	[confirmationCode appendString:[key substringWithRange:NSMakeRange(9,2)]];
	[confirmationCode appendString:[key substringWithRange:NSMakeRange(13,2)]];
	[confirmationCode appendString:[key substringWithRange:NSMakeRange(17,2)]];
	[confirmationCode appendString:[key substringWithRange:NSMakeRange(280,1)]];
	[confirmationCode appendString:[key substringWithRange:NSMakeRange(278,1)]];
	[confirmationCode appendString:[key substringWithRange:NSMakeRange(279,1)]];
	[confirmationCode appendString:[key substringWithRange:NSMakeRange(277,1)]];
	
	NSMutableString *dateString = [[NSMutableString alloc] init];
	int yyyy, mm, dd;
	sscanf([[key substringWithRange:NSMakeRange(281,4)] cStringUsingEncoding:NSMacOSRomanStringEncoding], "%d", &yyyy);
	if (((yyyy / 1.167) - (int)(yyyy / 1.167)) > 0) {
		yyyy = (int)(yyyy / 1.167) + 1;
	} else {
		yyyy = (int)(yyyy / 1.167);
	}
	[dateString appendFormat:@"%d-", yyyy];  
	sscanf([[key substringWithRange:NSMakeRange(295,2)] cStringUsingEncoding:NSMacOSRomanStringEncoding], "%d", &mm);
	if (((mm / 7.26) - (int)(mm / 7.26)) > 0) {
		mm = (int)(mm / 7.26) + 1;
	} else {
		mm = (int)(mm / 7.26);
	}
	[dateString appendFormat:@"%d-", mm];  
	sscanf([[key substringWithRange:NSMakeRange(19,2)] cStringUsingEncoding:NSMacOSRomanStringEncoding], "%d", &dd);
	if (((dd / 3.125) - (int)(dd / 3.125)) > 0) {
		dd = (int)(dd / 3.125) + 1;
	} else {
		dd = (int)(dd / 3.125);
	}
	[dateString appendFormat:@"%d", dd];  
	
	
	[validatedCode setStringValue:confirmationCode];
	[purchaseDate setStringValue:dateString];
	[emailAddress setStringValue:[self reconstructString:email]];
	[ownerName setStringValue:[self reconstructString:name]];
	if ([productCode compare:@"DBAAP"] == NSOrderedSame)
	{
		[product setStringValue:@"Database Automator Action Pack"];
	}
	[version setStringValue:versionString];
	
}
- (IBAction)onCancel:(id)sender
{
	[NSApp stopModal];
	
	// exit the application
	NSObject* windowDelegate = [parentWindow delegate];
/*	if ([windowDelegate respondsToSelector:@selector(loginCompleted:)] == YES)
	{
		[windowDelegate loginCompleted:nil];
	}
*/	
	[NSApp endSheet:regPanel];
    [regPanel orderOut:self];	
}

-(NSString *)reconstructString:(NSString *)input
{
	NSMutableString *result = [[NSMutableString alloc] init];
	
	if ([input length] == 0) {
		return result;
	}
	
	int i; 
	for (i = 0; i < [input length]; i++)
	{
		NSString *temp = [input substringWithRange:NSMakeRange(i, 2)];
		int charCode;
		sscanf([temp cStringUsingEncoding:NSMacOSRomanStringEncoding], "%X", &charCode);
		
		[result insertString:[[NSString alloc] initWithFormat:@"%s", (char *)&charCode]
					 atIndex:0];
		i++;
	}
	return result;
}

@end
