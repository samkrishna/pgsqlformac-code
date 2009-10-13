//
//  PGSQLRecord.h
//  PGSQLKit
//
//  Created by Andy Satori on 6/7/07.
//  Copyright 2007 Druware Software Designs. All rights reserved.
//

//#import <Cocoa/Cocoa.h>
#import "PGSQLField.h";

@interface PGSQLRecord : NSObject {	
	void *pgResult;
	long  rowNumber;
	NSArray *columns;
}

-(id)initWithResult:(void *)result atRow:(long)atRow columns:(NSArray *)columncache;

-(PGSQLField *)fieldByIndex:(long)fieldIndex;
-(PGSQLField *)fieldByName:(NSString *)name;

-(long)rowNumber;


@end
