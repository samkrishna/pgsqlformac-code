//
//  PGSQLRecordset.h
//  PGSQLKit
//
//  Created by Andy Satori on 5/29/07.
//  Copyright 2007 Druware Software Designs. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PGSQLColumn.h"
#import "PGSQLRecord.h"
#import "PGSQLField.h"
	
@interface PGSQLRecordset : NSObject {
	void *pgResult;
	
	BOOL isEOF;
	BOOL isOpen;
	
	long rowCount;
	
	NSMutableArray *columns;
	
	PGSQLRecord *currentRecord;
}

-(id)initWithResult:(void *)result;
-(PGSQLField *)fieldByIndex:(long)fieldIndex;
-(PGSQLField *)fieldByName:(NSString *)fieldName;
-(void)close;

-(NSArray *)columns;

-(PGSQLRecord *)moveFirst;
-(PGSQLRecord *)movePrevious;
-(PGSQLRecord *)moveNext;	
-(PGSQLRecord *)moveLast;

-(BOOL)isEOF;

-(NSDictionary *)dictionaryFromRecord;

@end

