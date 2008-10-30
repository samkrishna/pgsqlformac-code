//
//  PostgreSQL Dynamic Query Action.m
//  PostgreSQL Dynamic Query Action
//
//  Created by Andy Satori on 9/25/07.
//  Copyright 2007 Druware Software Designs. All rights reserved.
//

#import "PostgreSQL Dynamic Query Action.h"
#import <Security/Security.h>
#import <CoreFoundation/CoreFoundation.h>
#import <stdlib.h>

@implementation PostgreSQL_Dynamic_Query_Action

- (id)runWithInput:(id)input fromAction:(AMAction *)anAction error:(NSDictionary **)errorInfo
{
	// Add your code here, returning the data to be passed to the next action.
	NSMutableDictionary *dict = [self parameters];
	
	NSString *user = [dict valueForKey:@"userName"];
	NSString *password = [dict valueForKey:@"password"];
	
	NSString *serverName = [dict valueForKey:@"serverName"];
	NSString *serverPort = [dict valueForKey:@"serverPort"];
	NSString *databaseName = [dict valueForKey:@"databaseName"];
	
	NSString *query = [NSString stringWithString:input];
	
	PGSQLConnection *connection = [[PGSQLConnection alloc] init];
	
	[connection setUserName:user];
	[connection setPassword:password];
	
	[connection setServer:serverName];
	[connection setPort:serverPort];
	[connection setDatabaseName:databaseName];
	
	if ([connection connect])
	{
		PGSQLRecordset *rs = [connection open:query];
		
		NSMutableArray *result = [[NSMutableArray alloc] init];
		while (![rs isEOF])
		{
			[result addObject:[rs dictionaryFromRecord]];
			[rs moveNext];
		}
		[rs close];
		[connection close];
		
		return result;		
	} else {
		// setup the error dictionary 
	}
	return nil;	
	// return input;
}

- (NSString *)connectionNameForKeychainItem:(SecKeychainItemRef)item
{
	OSStatus status;
	SecKeychainAttribute attributes[2];
	SecKeychainAttributeList list;
	NSString *result = nil;
	
	attributes[0].tag = kSecLabelItemAttr;
	
	list.count = 1;
	list.attr = attributes;
	
	status = SecKeychainItemCopyContent(item, NULL, &list, NULL, NULL);
	
	if (status == noErr)
	{
		char buffer[1024];
		SecKeychainAttribute attr;
		int i;
		
		for (i = 0; i < list.count; i++)
		{
			attr = list.attr[i];
			if (attr.length < 1024)
			{
				strncpy(buffer, attr.data, attr.length);
				buffer[attr.length] = '\0';
				result = [[NSString alloc] initWithFormat:@"%s", buffer];
			}
		}
	}
	
	SecKeychainItemFreeContent(&list, NULL);
	return result;
}

- (NSString *)setConnectionDetails:(NSMutableDictionary *)dict forKeychainItem:(SecKeychainItemRef)item
{
	OSStatus status;
	SecKeychainAttribute attributes[4];
	SecKeychainAttributeList list;
	NSString *where = nil;
	char *password;
	UInt32 passwordLen;
	passwordLen = 1024;
	password = malloc(passwordLen);
	
	attributes[0].tag = kSecServiceItemAttr;
	attributes[1].tag = kSecAccountItemAttr;
	
	list.count = 2;
	list.attr = attributes;
	
	[dict setValue:@"" forKey:@"serverName"];
	[dict setValue:@"" forKey:@"port"];
	[dict setValue:@"" forKey:@"userName"];
	[dict setValue:@"" forKey:@"password"];
	[dict setValue:@"" forKey:@"databaseName"];
	
	// alter this to read the password (last two nulls)
	status = SecKeychainItemCopyContent(item, NULL, &list, &passwordLen,
										(void *)&password);
	
	if (status == noErr)
	{
		char buffer[1024];
		SecKeychainAttribute attr;
		int i;
		
		for (i = 0; i < list.count; i++)
		{
			attr = list.attr[i];
			switch (attr.tag)
			{
				case kSecServiceItemAttr:
					if (attr.length < 1024)
					{
						strncpy(buffer, attr.data, attr.length);
						buffer[attr.length] = '\0';
						where = [[NSString alloc] initWithFormat:@"%s", buffer];
						
						// split the where into the location elements
						NSRange range1 = [where rangeOfString:@"@"];
						NSRange range2 = [where rangeOfString:@":"];
						NSRange range3 = NSMakeRange(
													 (range1.location + range1.length),
													 (range2.location - (range1.location + range1.length)));
						
						[dict setValue:[where substringWithRange:range3] forKey:@"serverName"];
						[dict setValue:[where substringFromIndex:range2.location + range2.length] forKey:@"serverPort"];
						[dict setValue:[where substringToIndex:range1.location] forKey:@"databaseName"];
					}
					break;
				case kSecAccountItemAttr:
					if (attr.length < 1024)
					{
						strncpy(buffer, attr.data, attr.length);
						buffer[attr.length] = '\0';
						NSString *who = [[NSString alloc] initWithFormat:@"%s", buffer];
						[dict setValue:who forKey:@"userName"];
					}
					break;
				default:
					break;
			}
		}
		
		strncpy(buffer, password, passwordLen);
		buffer[passwordLen] = '\0';
		// set the password
		[dict setValue:[NSString stringWithFormat:@"%s", buffer]forKey:@"password"];
	}
	
	free(password);
	
	
	return where;
}	

- (id)initWithDefinition:(NSDictionary *)dict fromArchive:(BOOL)archived
{
	self = [super initWithDefinition:dict fromArchive:archived];
	
	if (self != nil)
	{
	
		NSColor *unregisteredColor = [NSColor redColor];
		[dict setValue:@"Unregistered" forKey:@"registeredStatus"];
		[dict setValue:unregisteredColor forKey:@"registeredColor"];
		
		
		NSMutableArray *savedConnections = [[NSMutableArray alloc] init];
		NSMutableDictionary *dict = [[[NSMutableDictionary alloc] init] autorelease];
		[dict setValue:@"--none--" forKey:@"name"];
		[savedConnections addObject:dict];
		
		PGSQLConnection *connection = [[PGSQLConnection alloc] init];
		
		// populate the list from the keychain
		OSStatus status;
		SecKeychainSearchRef search;
		SecKeychainAttribute attributes[1];
		SecKeychainAttributeList list;
		SecKeychainItemRef item;
		
		attributes[0].tag = kSecCreatorItemAttr;
		attributes[0].data = "pgds";
		attributes[0].length = 4;
		
		list.count = 1;
		list.attr = attributes;
		
		status = SecKeychainSearchCreateFromAttributes(NULL, 
													   kSecGenericPasswordItemClass,
													   &list, &search);
		if (status != noErr)
		{
			NSLog(@"Error reading the keychain: %d", status); 
		}
		
		while (SecKeychainSearchCopyNext(search, &item) == noErr)
		{
			dict = [[[NSMutableDictionary alloc] init] autorelease];
			[dict setValue:[self connectionNameForKeychainItem:item] forKey:@"name"]; 
			[savedConnections addObject:dict];
			CFRelease(item);
		}
		CFRelease(search);
		
		[[self parameters] setObject:savedConnections forKey:@"savedConnectionList"];
		[connection release];
		connection = nil;
	}
	
	return self;
}


- (IBAction)onSelectConnection:(id)sender
{
	NSLog(@"Selection Changed");
	
	NSMutableDictionary *dict = [self parameters];
	
	if ([dataSourceList indexOfSelectedItem] == 0)
	{
		[dict setValue:@"" forKey:@"serverName"];
		[dict setValue:@"" forKey:@"serverPort"];
		[dict setValue:@"" forKey:@"userName"];
		[dict setValue:@"" forKey:@"password"];
		[dict setValue:@"" forKey:@"databaseName"];
		return;
	}
	
	NSString *selectedValue = [[dataSourceList selectedItem] title];
	
	OSStatus status;
	SecKeychainSearchRef search;
	SecKeychainAttribute attributes[2];
	SecKeychainAttributeList list;
	SecKeychainItemRef item;
	
	attributes[0].tag = kSecCreatorItemAttr;
	attributes[0].data = "pgds";
	attributes[0].length = 4;
	
	attributes[1].tag = kSecLabelItemAttr;
	attributes[1].data = (char *)[selectedValue cString];
	attributes[1].length = [selectedValue length];
	
	list.count = 2;
	list.attr = attributes;
	
	status = SecKeychainSearchCreateFromAttributes(NULL, 
												   kSecGenericPasswordItemClass,
												   &list, &search);
	if (status != noErr)
	{
		NSLog(@"Error reading the keychain: %d", status); 
	}
	
	while (SecKeychainSearchCopyNext(search, &item) == noErr)
	{
		[self setConnectionDetails:dict forKeychainItem:item];
		CFRelease(item);
	}
	
	CFRelease(search);
}

@end
