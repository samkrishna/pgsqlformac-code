/*
 *  newid.c
 *  guid
 *
 *  Created by Andy Satori on 9/29/04.
 *  Copyright 2004 __MyCompanyName__. All rights reserved.
 *
 */

#include "newid.h"
#include <CoreFoundation/CFUUID.h>

char* getNewGUID()
{
	CFUUIDRef myUUID = CFUUIDCreate(kCFAllocatorDefault);
    CFUUIDBytes      myUUIDBytes;
    CFStringRef      myUUIDString;
    char			*strBuffer;
	
	strBuffer = malloc(42);
    
    myUUIDString = CFUUIDCreateString(kCFAllocatorDefault, myUUID);
    myUUIDBytes = CFUUIDGetUUIDBytes(myUUID);

    // This is the safest way to obtain a C string from a CFString.
    CFStringGetCString(myUUIDString, strBuffer, 42, kCFStringEncodingASCII);		

    return strBuffer;
}