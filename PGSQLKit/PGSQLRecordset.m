//
//  PGSQLRecordset.m
//  PGSQLKit
//
//  Created by Andy Satori on 5/29/07.
//  Copyright 2007 Druware Software Designs. All rights reserved.
//

#import "PGSQLRecordset.h"
#import "libpq-fe.h"

@implementation PGSQLRecordset

#pragma mark -
#pragma mark NSObject Override Methods

// Returned string contains column names in the first line, then data for each row of the record set.
- (NSString *)description
{
    // column names.
    NSMutableString *descriptionStr = [[[NSMutableString alloc] init] autorelease];
    for (PGSQLColumn *col in self.columns)
    {
        if ([descriptionStr length] != 0)
        {
            [descriptionStr appendString:@", "];
        }
        [descriptionStr appendFormat:@"'%@'", [col name]];
    }
    [descriptionStr appendString:@"\n"];

    // column data.
    PGSQLRecord *record = [self moveFirst];
    while (![self isEOF])
    {
        NSMutableString *columnDataStr = [[[NSMutableString alloc] init] autorelease];
        for (int myIndex = 0; myIndex < [[self columns] count]; myIndex++)
        {
            if ([columnDataStr length] != 0)
            {
                [columnDataStr appendString:@", "];
            }
            PGSQLField *field = [record fieldByIndex:myIndex];
            [columnDataStr appendFormat:@"'%@'", [field asString]];
        }
        [descriptionStr appendFormat:@"%@\n", columnDataStr];
        [columnDataStr setString:@""];
        record = [self moveNext];
    }
    return descriptionStr;
}

#pragma mark -
#pragma mark Lifecycle Methods

-(id)initWithResult:(void *)result
{
    self = [super init];
	if (self != nil)
	{
		_isOpen = YES;
		_isEOF = YES;
		
		// this will default to NSUTF8StringEncoding with PG9
		// defaultEncoding = NSMacOSRomanStringEncoding;
		
		columns = [[[[NSMutableArray alloc] init] retain] autorelease];
		
		pgResult = result;
		
		rowCount = -1;
		rowCount = PQntuples(pgResult);
		
		// cache the colum list for faster data access via lookups by name
		// Loop through and get the fields into Field Item Classes
		PGSQLColumn *column;
		
		int iCols = 0;
		iCols = PQnfields(pgResult);
		
		int i;
		for ( i = 0; i < iCols; i++)
		{
			column = [[[PGSQLColumn alloc] initWithResult:pgResult 
												   atIndex:i] autorelease];
			[columns addObject:column];
		}
		
		if (rowCount == 0)
		{
			_isEOF = YES;
			return self;
		}
		
		_isEOF = NO;
		
		// move to the first record (and check EOF / BOF state)
		[self moveFirst];
	}
    return self;
}

-(void)close
{
	if (_isOpen) {
		[columns release];
		columns = nil;
		PQclear(pgResult);
		pgResult = nil;
	}
	[currentRecord release];
	currentRecord = nil;
	_isOpen = NO;
}

-(void)dealloc
{
	[self close];
	[super dealloc];
}

#pragma mark -
#pragma mark Info Methods

-(PGSQLField *)fieldByName:(NSString *)fieldName
{
	return [currentRecord fieldByName:fieldName];
}

-(PGSQLField *)fieldByIndex:(long)fieldIndex
{
	return [currentRecord fieldByIndex:fieldIndex];
}

- (NSArray *)columns
{
	return columns;
}

- (long)recordCount
{
	return rowCount;
}

- (NSUInteger)rowCount
{
	return rowCount;
}

- (void)setCurrentRecordWithRowIndex:(int)rowIndex
{
	[currentRecord release];
	currentRecord = [[PGSQLRecord alloc] initWithResult:pgResult
														atRow:rowIndex
													  columns:columns];
	[currentRecord setDefaultEncoding:defaultEncoding];
}

- (NSString *)lastError {
    return lastError;
}

-(NSDictionary *)dictionaryFromRecord
{
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
	long i;
	for (i = 0; i < [columns count]; i++)
	{
		PGSQLColumn *column = [columns objectAtIndex:i];
		
		// for each column, add the value for the key.
		// select oid, typname from pg_type
		
		switch ([column type])
		{
                /*
                 case SQL_UNKNOWN_TYPE:
                 [dict setValue:[[self fieldByName:[column name]] asData] forKey:[[column name] lowercaseString]];
                 break;				
                 case SQL_CHAR:
                 case SQL_VARCHAR:
                 [dict setValue:[[self fieldByName:[column name]] asString] forKey:[[column name] lowercaseString]];
                 break;
                 case SQL_NUMERIC:
                 case SQL_DECIMAL:
                 case SQL_INTEGER:
                 case SQL_SMALLINT:
                 case SQL_FLOAT:
                 case SQL_REAL:
                 case SQL_DOUBLE:
                 [dict setValue:[[self fieldByName:[column name]] asNumber] forKey:[[column name] lowercaseString]];
                 break;				
                 case SQL_DATETIME:
                 [dict setValue:[[self fieldByName:[column name]] asDate] forKey:[[column name] lowercaseString]];
                 NSLog(@"Date Being Set: %@ for: %@", [[self fieldByName:[column name]] asDate], [[column name] lowercaseString]);
                 break;
                 case 11: // Undefined, MSSQL SHORTDATETIME
                 [dict setValue:[[self fieldByName:[column name]] asDate] forKey:[[column name] lowercaseString]];
                 NSLog(@"Date Being Set: %@ for: %@", [[self fieldByName:[column name]] asDate], [[column name] lowercaseString]);
                 break;
                 */
			case 16: // BOOL
				if ([[self fieldByName:[column name]] asBoolean])
				{
					[dict setValue:@"true" forKey:[column name]];
				} else {
					[dict setValue:@"false" forKey:[column name]];
				}
				break;
			default:
				[dict setValue:[[self fieldByName:[column name]] asString:defaultEncoding] forKey:[column name]];
				break;
		}
	}
	NSDictionary *result = [[[NSDictionary alloc] initWithDictionary:dict] autorelease];
	[dict release];
	return result;
}

#pragma mark -
#pragma mark Navigation Methods

- (PGSQLRecord *)moveNext
{
	if (rowCount == 0) {
		return nil;
	}
	
	int currentRowIndex = -1;
	if (currentRecord != nil) 
	{
		currentRowIndex = [currentRecord rowNumber];
	}
	currentRowIndex++;
	
	if (currentRowIndex >= rowCount) {
		_isEOF = true;
		[currentRecord release];
		currentRecord = nil;
		return nil;
	}
	
	[self setCurrentRecordWithRowIndex:currentRowIndex];
	return [[currentRecord retain] autorelease];
}

- (PGSQLRecord *)moveFirst
{
	if (rowCount == 0) {
		return nil;
	}
	int currentRowIndex = 0;
	_isEOF = false;
	
	[self setCurrentRecordWithRowIndex:currentRowIndex];
	return [[currentRecord retain] autorelease];
}

- (PGSQLRecord *)movePrevious
{
	if (rowCount == 0) {
		return nil;
	}
	int currentRowIndex = -1;
	if (currentRecord != nil) 
	{
		currentRowIndex = [currentRecord rowNumber];
	}
	currentRowIndex--;
	
	if (currentRowIndex < 0) {
		_isEOF = true;
		currentRecord = nil;
		return nil;
	}
	
	[self setCurrentRecordWithRowIndex:currentRowIndex];
	return [[currentRecord retain] autorelease];
}

- (PGSQLRecord *)moveLast
{
	if (rowCount == 0) {
		return nil;
	}
	int currentRowIndex = rowCount;
	_isEOF = false;

	[self setCurrentRecordWithRowIndex:currentRowIndex];
	return [[currentRecord retain] autorelease];
}

-(BOOL)isEOF
{
	return _isEOF;
}


#pragma mark -
#pragma mark Encoding Methods

-(NSStringEncoding)defaultEncoding
{
	return defaultEncoding;
}

-(void)setDefaultEncoding:(NSStringEncoding)value
{
    if (defaultEncoding != value) {
        defaultEncoding = value;
        
        if (currentRecord != nil)
        {
            [currentRecord setDefaultEncoding:defaultEncoding];
        }
    }	
}

@end
