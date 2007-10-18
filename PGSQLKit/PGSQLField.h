//
//  PGSQLField.h
//  PGSQLKit
//
//  Created by Andy Satori on 6/7/07.
//  Copyright 2007 Druware Software Designs. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PGSQLColumn.h"


@interface PGSQLField : NSObject {
	NSData *data;
	
	PGSQLColumn *column;
}

-(id)initWithResult:(void *)result forColumn:(PGSQLColumn *)forColumn
			  atRow:(int)atRow;
-(NSString *)asString;
-(NSNumber *)asNumber;
-(long)asLong;
-(NSDate *)asDate;
-(NSData *)asData;
-(BOOL)asBoolean;

-(BOOL)isNull;

@end
