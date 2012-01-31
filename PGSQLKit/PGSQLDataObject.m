/*          file: PGSQLDataObject.m
 *   description: Represents a base object from which the data objects in the 
 *                server core library derive from.  This implementation provides
 *                base support functionality to reduce some of the boilerplate 
 *                overhead inherent in the data objects.  
 *
 * License *********************************************************************
 *
 * Copyright (c) 2005-2012, Andy 'Dru' Satori @ Druware Software Designs 
 * All rights reserved.
 *
 * Redistribution and use in source or binary forms, with or without
 *  modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions in source or binary form must reproduce the above
 *    copyright notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the distribution.
 * 2. Neither the name of the Druware Software Designs nor the names of its
 *    contributors may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 *******************************************************************************
 *
 * history:
 *   see method headers for detailed history of changes
 *
 ******************************************************************************/

#import "PGSQLDataObject.h"
#import "NSData+Base64.h"

@interface PGSQLDataObject () // private elements
- (long)getNextSequenceValue;
- (void)loadFromRecord:(PGSQLRecordset *)rs;
- (void)defaultsFromRecord:(PGSQLRecordset *)rs;
- (NSString *)stringForColumn:(NSDictionary *)column;
@end

@implementation PGSQLDataObject

#pragma mark property implementations;

@synthesize isNew, isDirty, connection, lastError, table, primaryKey, refId;

#pragma mark custom initializers

/* init
 *   description
 *     override the default NSObject init method to prevent a bare init for the
 *     data object. Throws an exception if called.
 *   arguments
 *     none
 *   returns
 *     none
 *   history
 *     who   date    change
 *     --- -------- ----------------------------------------------------------- 
 ******************************************************************************/
- (id)init
{
	NSException* myException = [NSException
								exceptionWithName:@"InvalidInitCalled"
								reason:@"Init Cannot be called without a parameter"
								userInfo:nil];
	@throw myException;
    
    return nil;
}

/* initWithConnection
 *   description
 *     implements an init that takes an active PGSQLConnection for use in data
 *     operations withing the object (and it's children as needed) 
 *   arguments
 *     (PGSQLConnection *) as the connection to be used for the current object.
 *       note that this connection cannot have multiple result sets open at a 
 *       time.
 *   returns
 *     (id) as the current object reference initialized as a new object
 *   history
 *     who   date    change
 *     --- -------- ----------------------------------------------------------- 
 ******************************************************************************/
- (id)initWithConnection:(PGSQLConnection *)pgConn
{
	self = [super init];
	if (!self) {return nil;}
	
	connection = [pgConn retain];
	properties = nil;
    
	isDirty					= NO;
	isNew					= YES;
	
	return self;
}

/* initWithConnection
 *   description
 *     implements an init that takes an active PGSQLConnection for use in data
 *     operations withing the object (and it's children as needed) 
 *   arguments
 *     (PGSQLConnection *) as the connection to be used for the current object.
 *       note that this connection cannot have multiple result sets open at a 
 *       time.
 *     (NSNumber *) as the reference number of the primary key for the desired
 *       data record.
 *   returns
 *     (id) as the current object reference initialized as the referenced 
 *       data record
 *   history
 *     who   date    change
 *     --- -------- ----------------------------------------------------------- 
 ******************************************************************************/
- (id)initWithConnection:(PGSQLConnection *)pgConn forId:(NSNumber *)referenceId
{
	NSException* myException = [NSException
								exceptionWithName:@"InvalidInitCalled"
								reason:@"Init Cannot be called in the base class with a reference"
								userInfo:nil];
	@throw myException;
    
    return nil;
}

/* initWithConnection
 *   description
 *     implements an init that takes an active PGSQLConnection for use in data
 *     operations withing the object (and it's children as needed).  If this 
 *     generic base operation is used, then the class will create an 
 *     NSDictionary* containing all of the properties (columns) from the 
 *     referenced record.  It makes several assumptions:
 *       1. the table in question has a primary key
 *       2. the primary key is serial
 *       3. the table supports 
 *   arguments
 *     (PGSQLConnection *) as the connection to be used for the current object.
 *       note that this connection cannot have multiple result sets open at a 
 *       time.
 *     (PGSQLRecordset *) as a recordset where the desired record is the current
 *       record in the recordset.
 *   returns
 *     (id) as the current object reference initialized as the referenced 
 *       data record
 *   history
 *     who   date    change
 *     --- -------- ----------------------------------------------------------- 
 ******************************************************************************/
- (id)initWithConnection:(PGSQLConnection *)pgConn forRecord:(PGSQLRecordset *)rs
{
	self = [super init];
	if (!self) {return nil;}
	
	connection = [pgConn retain];
    
    properties = nil;
	
	// load the record from the recordset as passed in
	[self loadFromRecord:rs];
	
	return self;
}

/* initWithConnection
 *   description
 *     implements an init that takes an active PGSQLConnection for use in data
 *     operations withing the object (and it's children as needed) 
 *   arguments
 *     (PGSQLConnection *) as the connection to be used for the current object.
 *       note that this connection cannot have multiple result sets open at a 
 *       time.
 *     (NSString *) as the name of the table this object represents
 *     (NSString *) as the name of the field that is the primary key
 *   returns
 *     (id) as the current object reference initialized as the referenced 
 *       data record
 *   history
 *     who   date    change
 *     --- -------- -----------------------------------------------------------
 *     dru 11/23/11 added to base object to make quick and dirty object wrappers
 *                  practical without lots of boilerplate.
 ******************************************************************************/
- (id)initWithConnection:(PGSQLConnection *)pgConn
forTable:(NSString *)tableName
withPrimaryKey:(NSString *)keyName
{
	self = [super init];
	if (!self) {return nil;}
    
	connection = [pgConn retain];
    table = [[tableName copy] retain];
	primaryKey = [[keyName copy] retain];
    
    properties = nil;
    
	// load the record by Id
	NSString *cmd = [NSString stringWithFormat:@"select * from %@ limit 1", 
                     table, primaryKey];
	PGSQLRecordset *rs = [pgConn open:cmd]; 
    
    if (rs != nil)
    {
        [self defaultsFromRecord:rs];
        [rs close];
	}
	return self;
}

/* initWithConnection
 *   description
 *     implements an init that takes an active PGSQLConnection for use in data
 *     operations withing the object (and it's children as needed) 
 *   arguments
 *     (PGSQLConnection *) as the connection to be used for the current object.
 *       note that this connection cannot have multiple result sets open at a 
 *       time.
 *     (NSString *) as the name of the table this object represents
 *     (NSString *) as the name of the field that is the primary key
 *     (NSNumber *) as the number referencing the value of the primary key to 
 *       load the record with.
 *   returns
 *     (id) as the current object reference initialized as the referenced 
 *       data record
 *   history
 *     who   date    change
 *     --- -------- -----------------------------------------------------------
 *     dru 11/23/11 added to base object to make quick and dirty object wrappers
 *                  practical without lots of boilerplate.
 ******************************************************************************/
- (id)initWithConnection:(PGSQLConnection *)pgConn
forTable:(NSString *)tableName
withPrimaryKey:(NSString *)keyName
forId:(NSNumber *)referenceId
{
	self = [super init];
	if (!self) {return nil;}
    
	connection = [pgConn retain];
    table = [[tableName copy] retain];
	primaryKey = [[keyName copy] retain];
    refId = [[referenceId copy] retain];
    
    properties = nil;
    
	// load the record by Id
	NSString *cmd = [NSString stringWithFormat:@"select * from %@ where %@ = %d", 
                     table, primaryKey, [referenceId longValue]];
	PGSQLRecordset *rs = [pgConn open:cmd]; 
	if (![rs isEOF])
	{
		[self loadFromRecord:rs];
	}
	[rs close];
	
	return self;
}

/* dealloc
 *   description
 *     performs the cleanup of the object, releasing any allocated resources.
 *   arguments
 *     none
 *   returns
 *     none
 *   history
 *     who   date    change
 *     --- -------- ----------------------------------------------------------- 
 ******************************************************************************/
- (void)dealloc
{
	if (table != nil) { [table release]; table = nil; }
	if (primaryKey != nil) { [primaryKey release]; primaryKey = nil; }	
	if (refId != nil) { [refId release]; refId = nil; }	
	if (properties != nil) { [properties release]; properties = nil; }	
    
    if (lastError != nil) { [lastError release]; lastError = nil; }
	
	[connection release];
	
	[super dealloc];
}

#pragma mark mata management methods (RDBMS & Xml)

/* save
 *   description
 *     performs a save using the generic structure internally.  more complex
 *     classes that inherit from this class may want to override this work 
 *     rather than use this implementation
 *   arguments
 *     none
 *   returns
 *     BOOL returns YES if the save is successful, if the result is NO then 
 *       the lastError property will be populated with the reason for the 
 *       failure.
 *   history
 *     who   date    change
 *     --- -------- ----------------------------------------------------------- 
 *     dru 11/23/11 stubbed in but not implemented for internal use
 *     dru 12/09/11 started dynamic save logic, using the columns from the 
 *                  properties dictionary.
 *     dru 12/20/11 removed key from insert logic
 *     dru 01/20/12 addressed an issue where if the primary key was the last 
 *                  item in the properties allKeys array an extra , would be 
 *                  added
 ******************************************************************************/
- (BOOL)save
{
	if (!isDirty) { return NO; }
	
    NSMutableString *cmd = [[NSMutableString alloc] init];
    int i;
    
	if (isNew) 
	{
		// get the next id from the sequence. this needs a bit of a rework to 
        // lose the dependance upon the refId being set internally in the get
        // function
        
        if ([self getNextSequenceValue] < 0) 
        { 
            [cmd release];
            return NO; 
        } 
        
        [self setValue:refId forProperty:primaryKey];
        
        // build the insert command
        [cmd appendFormat:@"insert into %@ ( ", table];
        // for each column
        for (i = 0; i < [[properties allKeys] count]; i++)
        {
            [cmd appendString:[[properties allKeys] objectAtIndex:i]];
            if (i < [[properties allKeys] count] - 1)
            {
                [cmd appendString:@", "];
            }
		}
        [cmd appendString:@") values ("];
        for (i = 0; i < [[properties allKeys] count]; i++)
        {
            NSDictionary *column = [properties objectForKey:[[properties allKeys] objectAtIndex:i]];
            [cmd appendFormat:@"%@", [self stringForColumn:column]];
            
            if (i < [[properties allKeys] count] - 1)
            {
                [cmd appendString:@", "];
            }
		}
        [cmd appendString:@")"];
        
	} else {
		// perform an update
		[cmd appendFormat:@"update %@ set ", table];
        
        for (i = 0; i < [[properties allKeys] count]; i++)
        {
            NSDictionary *column = [properties objectForKey:[[properties allKeys] objectAtIndex:i]];
            if (![[[properties allKeys] objectAtIndex:i] isEqualToString:primaryKey])
            {                
                [cmd appendFormat:@"%@ = %@",
                 [[properties allKeys] objectAtIndex:i], 
                 [self stringForColumn:column]];
                
                if (i < [[properties allKeys] count] - 1)
                {
                    if (![[[properties allKeys] objectAtIndex:i+1] isEqualToString:primaryKey])
                    {
                        [cmd appendString:@", "];
                    }
                }
            }
		}
        
		[cmd appendFormat:@" where %@ = %@;",
         primaryKey, 
         [self stringForLongNumber:refId]];
	}
    BOOL result = ([connection execCommand:cmd] > 0);
    if (!result)
    {
        [self setLastError:[connection lastError]];
        if (isNew && refId != nil)
        {
            [refId release];
            refId = nil;            
        }
    }
    [cmd release];
    
    if (result)
    {
        isNew = NO;
        isDirty = NO;
    }
	return result;
}

/* remove
 *   description
 *     performs a delete using the generic structure internally.  more complex
 *     classes that inherit from this class may want to override this work 
 *     rather than use this implementation
 *   arguments
 *     none
 *   returns
 *     BOOL returns YES if the delete is successful, if the result is NO then 
 *       the lastError property will be populated with the reason for the 
 *       failure.
 *   history
 *     who   date    change
 *     --- -------- ----------------------------------------------------------- 
 ******************************************************************************/
- (BOOL)remove
{
    // cannot delete a new record
	if (isNew) { return NO; }
    
    NSMutableString *deleteCmd = [[NSMutableString alloc] init];
    [deleteCmd appendFormat:@"delete from %@ ", table];
    [deleteCmd appendFormat:@"where %@ =  %d;", primaryKey, [refId longValue]];
    
    if ([connection execCommand:deleteCmd] == 0)
    {
        lastError = [[[NSString alloc] initWithFormat:@"Unable to delete Data Object: %@", 
                      [connection lastError]] retain];
        [deleteCmd release];
        return NO;
    }
    [deleteCmd release];
    
    return YES;
}

/* xmlForObject
 *   description
 *     if the table name contains a t_ prefix, it will 
 *       removed in the element name.
 *   arguments
 *     none
 *   returns
 *     NSXMLElement * representing the XmlElement that contains the description
 *       of the current table.  
 *   history
 *     who   date    change
 *     --- -------- ----------------------------------------------------------- 
 *     dru 12/28/11 add attributes to node values to reflect the property defs.
 *     dru 01/04/12 stubbed in support for writing XML nodes based upon data 
 *                  type information in the dictionary, many formats need 
 *                  type specific output, and where needed, wrapping in CDATA 
 *                  nodes.
 ******************************************************************************/
- (NSXMLElement *)xmlForObject
{
    NSMutableString *nodeName = [[NSMutableString alloc] init];
    
    [nodeName appendString:table];
    
    // if it begins with t_ strip it
    
    NSXMLElement *thisNode = [[NSXMLElement alloc] initWithName:nodeName];    
    // loop the properties dictionary and convert the properties to xml 
    // key/value pairs
    int i;
    for (i = 0; i < [[properties allKeys] count]; i++)
    {
        NSDictionary *column = [properties objectForKey:[[properties allKeys] objectAtIndex:i]];
        
        // needs to pass back the isnull values of the node
        
        NSXMLElement *childNode = [[NSXMLElement alloc] initWithName:[column objectForKey:@"name"]];
        
        NSXMLNode *attribute = [NSXMLNode attributeWithName:@"isnull"
                                                        URI:@""
                                                stringValue:[column objectForKey:@"isnull"]];
        [childNode addAttribute:attribute];
        
        if ([[column objectForKey:@"isnull"] isEqualToString:@"no"])
        {
            /* add logic to put the data into the xml in usable resulting format 
             -- CDATA encapsulated if needed. */
            switch ([[column objectForKey:@"type"] intValue])
            {
                    // Bit
                case 1560: // bit
                case 1562: // bit varying / varbit
                    [childNode setStringValue:[column objectForKey:@"value"]];
                    break;
                    
                    // Boolean
                case 16: // boolean
                    [childNode setStringValue:[column objectForKey:@"value"]];
                    break;
                    
                    // Data -- CDATA -- Base64 Encoded
                case 17: // bytea
                {
                    NSXMLNode *cdata = [[NSXMLNode alloc] initWithKind:NSXMLTextKind options:NSXMLNodeIsCDATA];
                    NSString *dataString = [(NSData *)[column objectForKey:@"value"] base64EncodedString];
                    [cdata setStringValue:dataString];
                    [dataString release];
                    [childNode addChild:cdata];
                    break;
                }
                    // Date & Time
                case 702:   // abstime (date and time)
                    [childNode setStringValue:[column objectForKey:@"value"]];
                    break;
                    
                case 1082:  // date  
                    [childNode setStringValue:[column objectForKey:@"value"]];
                    break;
                    
                case 1083:  // time
                case 1114:  // timestamp
                case 1184:  // timestamptz
                case 1266:  // timetz
                    [childNode setStringValue:[column objectForKey:@"value"]];
                    break;
                    
                case 1186:  // interval
                    [childNode setStringValue:[column objectForKey:@"value"]];
                    break;
                    
                    // Numbers
                case 1700:  // numeric
                case 790:   // money
                case 700:   // float4
                case 701:   // float8
                    // use the size and offset params to determine the layout
                    [childNode setStringValue:[[column objectForKey:@"value"] stringValue]];
                    break;
                    
                case 20:    // int8
                case 21:    // int2
                case 23:    // int4
                case 10:    // int8 (bigserial)
                    [childNode setStringValue:[[column objectForKey:@"value"] stringValue]];
                    break;
                    
                    // Strings
                case 2950:  // UUID
                    [childNode setStringValue:[column objectForKey:@"value"]];
                    break;
                    
                case 25:    // text  -- CDATA
                case 142:   // xml   -- CDATA
                case 1042:  // char  -- CDATA
                case 1043:  // varchar (length is inthe offset)  -- CDATA
                {
                    NSXMLNode *cdata = [[NSXMLNode alloc] initWithKind:NSXMLTextKind options:NSXMLNodeIsCDATA];
                    [cdata setStringValue:[column objectForKey:@"value"]];
                    [childNode addChild:cdata];
                    break;
                }
                    
                default: //  -- CDATA
                {
                    NSXMLNode *cdata = [[NSXMLNode alloc] initWithKind:NSXMLTextKind options:NSXMLNodeIsCDATA];
                    [cdata setStringValue:[column objectForKey:@"value"]];
                    [childNode addChild:cdata];
                    break;
                }
            }
        }
        
        [thisNode addChild:childNode];
        [childNode release];
    }    
    
    [nodeName release];
    
	return [thisNode autorelease];	
}

/* loadFromXml
 *   description
 *     provides a method for populating an object from a passed in xml stream. 
 *     the stream populates the state of the object and the current state can be
 *     used to update or create a database record based upon the input.
 *   arguments
 *     (NSXMLElement *)xmlElement as the data element defining this object (and 
 *       potentially any child objects associated with it.
 *   returns
 *     BOOL result as success or failure of the load.  Should this return NO
 *       then the lastError property should contain a string defining the 
 *       reason(s) for the failure.
 *   history
 *     who   date    change
 *     --- -------- ----------------------------------------------------------- 
 ******************************************************************************/
- (BOOL)loadFromXml:(NSXMLElement *)xmlElement
{
    int iFoundChildren = 0;
    for (int i = 0; i < [xmlElement childCount]; i++)
    {
        NSXMLElement *currentElement = (NSXMLElement *)[xmlElement childAtIndex:i];
        
        
        // check the property names against the current element names
        // since the data is expected to conform to the string values, just set
        // the values and do no type checking other than for null.
        
        // 
        for (int x = 0; x < [[properties allKeys] count]; x++)
        { 
            // handle the primary key
            if ([[currentElement name] isEqualToString:primaryKey])
            {
                // get the value and transform it to an NSNumber
                NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
                [f setNumberStyle:NSNumberFormatterDecimalStyle];
                refId = [[f numberFromString:[currentElement stringValue]] retain];
                [f release];
                iFoundChildren++;
            } else if ([[currentElement name] isEqualToString:[[properties allKeys] objectAtIndex:x]])
            {
                NSMutableDictionary *property = [properties objectForKey:[[properties allKeys] objectAtIndex:x]];
                
                if ([[[currentElement attributeForName:@"isnull"] stringValue] isEqualToString:@"yes"])
                {
                    [property setValue:@"yes" forKey:@"isnull"];
                } else {
                    [property setValue:@"no" forKey:@"isnull"];
                    
                    // the following should be adjusted into a switch to make 
                    // intelligent choices about converting the string data 
                    // back into a more suitable native datatype
                    // check to make sure that we are not 'isnull=YES'
                    switch ([[property objectForKey:@"type"] intValue])
                    {
                            // Bit
                        case 1560: // bit
                        case 1562: // bit varying / varbit
                            [property setObject:[currentElement stringValue] 
                                         forKey:@"value"];
                            break;
                            
                            // Boolean
                        case 16: // boolean
                            [property setObject:[currentElement stringValue] 
                                         forKey:@"value"];
                            break;
                            
                            // Data -- CDATA  
                        case 17: // bytea
                        {
                            NSString *currentValue = [currentElement stringValue];
                            NSData *data = [NSData dataFromBase64String:currentValue];
                            [property setObject:data forKey:@"value"];
                            break;
                        }
                            
                            // Date & Time
                        case 702:   // abstime (date and time)
                        {
                            //"2012-01-01T16:15:31"
                            NSDateFormatter* dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
                            [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
                            [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
                            NSDate *newDate = [dateFormatter dateFromString:[currentElement stringValue]];
                            [property setObject:newDate forKey:@"value"];
                            break;
                        }
                            
                        case 1082:  // date  
                        {
                            //"2012-01-01T16:15:31"
                            NSDateFormatter* dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
                            [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
                            [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
                            NSDate *newDate = [dateFormatter dateFromString:[currentElement stringValue]];
                            [property setObject:newDate forKey:@"value"];
                            break;
                        }
                            
                        case 1083:  // time
                        {
                            //"2012-01-01T16:15:31"
                            NSDateFormatter* dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
                            [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
                            [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                            // prepend a reference date of 1970-01-01 to the time to get a valid NSdate
                            NSString *value = [NSString stringWithFormat:@"1970-01-01 %@", 
                                               [currentElement stringValue]];
                            NSDate *newDate = [dateFormatter dateFromString:value];
                            [property setObject:newDate forKey:@"value"];
                            break;
                        }
                            
                        case 1114:  // timestamp
                        {
                            //"2012-01-01T16:15:31"
                            NSDateFormatter* dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
                            [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
                            [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
                            NSDate *newDate = [dateFormatter dateFromString:[currentElement stringValue]];
                            [property setObject:newDate forKey:@"value"];
                            break;
                        }
                            
                        case 1184:  // timestamptz
                        {
                            NSDateFormatter* dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
                            [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
                            [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
                            NSDate *newDate = [dateFormatter dateFromString:[currentElement stringValue]];
                            [property setObject:newDate forKey:@"value"];
                            break;
                        }
                        case 1266:  // timetz
                        {
                            //"2012-01-01T16:15:31"
                            NSDateFormatter* dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
                            [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
                            [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
                            NSDate *newDate = [dateFormatter dateFromString:[currentElement stringValue]];
                            [property setObject:newDate forKey:@"value"];
                            break;
                        }
                            
                        case 1186:  // interval
                        {
                            //"2012-01-01T16:15:31"
                            NSDateFormatter* dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
                            [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
                            [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
                            NSDate *newDate = [dateFormatter dateFromString:[currentElement stringValue]];
                            [property setObject:newDate forKey:@"value"];
                            break;
                        }
                            
                            // Numbers -- this probably ought to format into a much
                            //            more specific format
                        case 1700:  // numeric
                        case 790:   // money
                        case 700:   // float4
                        case 701:   // float8
                        case 20:    // int8
                        case 21:    // int2
                        case 23:    // int4
                        case 10:    // int8 (bigserial)
                        {
                            NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
                            [f setNumberStyle:NSNumberFormatterDecimalStyle];
                            [property setObject:[f numberFromString:[currentElement stringValue]] 
                                         forKey:@"value"];
                            [f release];
                            break;
                        }
                            
                            // Strings
                        case 2950:  // UUID
                            [property setObject:[currentElement stringValue] 
                                         forKey:@"value"];
                            break;
                            
                        case 25:    // text  -- CDATA
                        case 142:   // xml   -- CDATA
                        case 1042:  // char  -- CDATA
                        case 1043:  // varchar (length is inthe offset)  -- CDATA
                            [property setObject:[currentElement stringValue] 
                                         forKey:@"value"];
                            break;
                            
                        default: //  -- CDATA
                            [property setObject:[currentElement stringValue] 
                                         forKey:@"value"];
                            break;
                    }
                }
                iFoundChildren++;
            }
        }
    }
    
    isNew = NO;
    if ([refId longValue] == -1)
    {
        isNew = YES;
    }
    
    isDirty = NO;
    if (iFoundChildren > 0)
    {
        isDirty = YES;
    }
    
	return (iFoundChildren >= 2);
}

#pragma mark private method implementations

/* getNextSequenceValue
 *   description
 *     assuming the table name, fetch the next value from the serial key
 *   arguments
 *     (none)
 *   returns
 *     long result as value of the next value in the key sequnce.
 *   history
 *     who   date    change
 *     --- -------- ----------------------------------------------------------- 
 ******************************************************************************/
- (long)getNextSequenceValue
{
	// fetch the next sequence value for the primary key / serial insert logic
    NSString *cmd = [[NSString alloc] initWithFormat:@"select nextval('%@_%@_seq') as _id;",
                     table, primaryKey];
	PGSQLRecordset *rs = [connection open:cmd]; 
	if (![rs isEOF])
	{
		refId = [[[rs fieldByName:@"_id"] asNumber] retain];
	}
	[rs close];
    [cmd release];
	
	return [refId longValue];
}

/* setValue
 *   description
 *     using the internal properties array, update the value in the dictionary.
 *     -- NOTE --
 *       because nulls are a special case in sql, there is a difference        |
 *       between an empty '' value and a nil.  if the value is nil, the        |
 *       field will be set to null on save.  a blank string value ''           |
 *       will not be saved as a null, but will instead be treated as a         |
 *       zero length string.                                                   |
 *   arguments
 *     (none)
 *   returns
 *     long result as value of the next value in the key sequnce.
 *   history
 *     who   date    change
 *     --- -------- ----------------------------------------------------------- 
 *     dru 12/21/11 added isnull support, see description NOTE for details.
 ******************************************************************************/
- (void)setValue:(id)value forProperty:(NSString *)property
{
    // find the column value by name
    NSMutableDictionary *column = [properties objectForKey:property];
    if (value == nil)
    {
        [column setValue:@"yes" forKey:@"isnull"];        
        [column setValue:@"" forKey:@"value"];
    } else {
        [column setValue:@"no" forKey:@"isnull"];        
        [column setValue:value forKey:@"value"];
    }
    
    isDirty = YES;
}

/* valueForProperty
 *   description
 *     using the internal properties array return the object stored as the value
 *     of the given property name
 *   arguments
 *     property as the NSString * naming the property to be retrieved.
 *   returns
 *     the object contained in the value key of the dictionary associated with 
 *     the passed in property
 *   history
 *     who   date    change
 *     --- -------- ----------------------------------------------------------- 
 ******************************************************************************/
- (id)valueForProperty:(NSString *)property
{
    NSDictionary *column = [properties objectForKey:property];
    if (!column)
    {
        return nil;
    }
    return [column objectForKey:@"value"];
}

/* propertyIsNull
 *   description
 *     using the internal properties array return the objects null state  
 *     of the given property name
 *   arguments
 *     property as the NSString * naming the property to be retrieved.
 *   returns
 *     the boolean isnull state contained in the dictionary associated with 
 *     the passed in property name
 *   history
 *     who   date    change
 *     --- -------- ----------------------------------------------------------- 
 ******************************************************************************/
- (BOOL)propertyIsNull:(NSString *)property
{
    NSDictionary *column = [properties objectForKey:property];
    if (!column)
    {
        return NO;
    }
    return [[column objectForKey:@"isnull"] isEqualToString:@"yes"];
}

/* loadFromRecord
 *   description
 *     load the record data from the recordset into a local dictionary of 
 *     properties.  this dictinoary contains keys matching field names.  each
 *     value is another dictionary of 'value', 'type', 'size', 'offset'
 *   arguments
 *     rs as a pointer to a PGSQLRecordset set to the current record to be read 
 *       and populated into the properties dictionary.
 *   returns
 *     (none)
 *   history
 *     who   date    change
 *     --- -------- ----------------------------------------------------------- 
 *     dru 12/02/11 fleshed in to load a record into the properties dictionary
 *                  test case remains to be written. remains to be altered to 
 *                  for better usage of the types and value data into more 
 *                  usable formats.
 *     dru 12/30/11 expanded to try and use reasonable data formats in the 
 *                  dictionary, rather than all strings to improve inherited
 *                  usability and data consistancy
 ******************************************************************************/
- (void)loadFromRecord:(PGSQLRecordset *)rs
{
    // build the properties dictionary from the record
    if (properties != nil)
    {
        [properties release];
        properties = nil;
    }
    
    properties = [[NSMutableDictionary alloc] init];
    [properties retain];    
    int i = 0;
    for (i = 0; i < [[rs columns] count]; i++)
    {
        PGSQLColumn *column = [[rs columns] objectAtIndex:i];
        PGSQLField *field = [rs fieldByIndex:i];
        NSMutableDictionary *columnDict = [[NSMutableDictionary alloc] init];
        
        [columnDict setValue:[column name] forKey:@"name"];
        // internally convert this to a string we can work with
        [columnDict setValue:[NSNumber numberWithInt:[column type]] forKey:@"type"];
        [columnDict setValue:[NSNumber numberWithInt:[column size]] forKey:@"size"];
        [columnDict setValue:[NSNumber numberWithInt:[column offset]] forKey:@"offset"];
        
        // depending upon the type, this needs to be stored in a type specific
        // manner, NSData, NSDate, NSNumber, NSString, BOOL
        [columnDict setValue:@"no" forKey:@"isnull"];
        if ([[rs fieldByIndex:i] isNull])
        {
            [columnDict setValue:@"yes" forKey:@"isnull"];
            [columnDict setValue:@"" forKey:@"value"];
        } else {
            switch ([column type])
            {
                    // Bit
                case 1560: // bit
                case 1562: // bit varying / varbit
                    [columnDict setValue:[field asString] forKey:@"value"];
                    break;
                    
                    // Boolean
                case 16: // boolean
                    if ([field asBoolean]) 
                    {
                        [columnDict setValue:@"yes" forKey:@"value"];
                    } else {
                        [columnDict setValue:@"no" forKey:@"value"];
                    }
                    break;
                    
                    // Data    
                case 17: // bytea
                    [columnDict setValue:[connection sqlDecodeData:[field asData]] forKey:@"value"];
                    break;
                    
                    // Date & Time
                case 702:   // abstime (date and time)
                    [columnDict setValue:[field asDate] forKey:@"value"];
                    break;
                case 1082:  // date  
                case 1083:  // time
                case 1114:  // timestamp
                case 1184:  // timestamptz
                case 1266:  // timetz
                    [columnDict setValue:[field asDate] forKey:@"value"];
                    break;
                    
                case 1186:  // interval
                    // TODO: need to evaluate the best method for this, it could 
                    // TODO: require a good bit more than just this.
                    [columnDict setValue:[field asString] forKey:@"value"];
                    break;
                    
                    // Numbers
                case 1700:  // numeric
                case 700:   // float4
                case 701:   // float8
                case 20:    // int8
                case 21:    // int2
                case 23:    // int4
                case 10:    // int8 (bigserial)
                    // use the size and offset params to determine the layout
                    [columnDict setValue:[field asNumber] forKey:@"value"];
                    break;
                    
                case 790:   // money
                {
                    NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
                    [f setNumberStyle:NSNumberFormatterCurrencyStyle];
                    [columnDict setValue:[f numberFromString:[field asString]] forKey:@"value"];
                    [f release];
                    break;
                }
                    
                    // Strings
                case 25:    // text
                case 2950:  // UUID
                case 142:   // xml
                case 1042:  // char
                case 1043:  // varchar (length is inthe offset)
                    [columnDict setValue:[field asString] forKey:@"value"];
                    break;
                    
                default:
                    [columnDict setValue:[field asString] forKey:@"value"];
                    break;
            }
            
            // [columnDict setValue:[field asString] forKey:@"value"];
        }
        
        [properties setValue:columnDict forKey:[column name]];
        [columnDict release];
    }
    
	isDirty					= NO;
	isNew					= NO;
}

/* defaultsFromRecord
 *   description
 *     load the definitions of the results set, but no record.  also sets the 
 *     isNew flag to YES in order to properly set the object for a save.
 *   arguments
 *     rs as a pointer to a PGSQLRecordset set to the current record to be read 
 *       and populated into the properties dictionary.
 *   returns
 *     (none)
 *   history
 *     who   date    change
 *     --- -------- ----------------------------------------------------------- 
 *     dru 12/08/11 fleshed in to load a record into the properties dictionary
 *                  test case remains to be written. remains to be altered to 
 *                  for better usage of the types and value data into more 
 *                  usable formats.
 ******************************************************************************/
- (void)defaultsFromRecord:(PGSQLRecordset *)rs
{
    if (properties != nil)
    {
        [properties release];
        properties = nil;
    }
    
    properties = [[NSMutableDictionary alloc] init];
    [properties retain];    
    int i = 0;
    for (i = 0; i < [[rs columns] count]; i++)
    {
        PGSQLColumn *column = [[rs columns] objectAtIndex:i];
        NSMutableDictionary *columnDict = [[NSMutableDictionary alloc] init];
        
        
        [columnDict setValue:[column name] forKey:@"name"];
        [columnDict setValue:[NSNumber numberWithInt:[column type]] forKey:@"type"];
        [columnDict setValue:[NSNumber numberWithInt:[column size]] forKey:@"size"];
        [columnDict setValue:[NSNumber numberWithInt:[column offset]] forKey:@"offset"];
        
        [columnDict setValue:@"yes" forKey:@"isnull"];
        [columnDict setValue:@"" forKey:@"value"];
        
        [properties setValue:columnDict forKey:[column name]];
        [columnDict release];
    }
	
	isDirty					= NO;
	isNew					= YES;
}

/* stringForColumn
 *   description
 *     using the value in the 'type' of the column, convert the internal data 
 *     into a sql safe string.
 *   arguments
 *     column as a dictionary item defining the column itslelf
 *   returns
 *     a sql safe string
 *   history
 *     who   date    change
 *     --- -------- ----------------------------------------------------------- 
 *     dru 12/10/11 stubbed in, roughed in datatype selection handlers
 *     dru 01/14/12 date, xml, time, timestamp, timetz, timestamptz all are 
 *                  are putting the wrong format strings out to the insert and 
 *                  update clauses.
 ******************************************************************************/
- (NSString *)stringForColumn:(NSDictionary *)column
{
    // check the type
    int type = (int)[[column objectForKey:@"type"] intValue];
    NSString *result = nil;
    
    // handle nulls gracefulle
    if ([[column objectForKey:@"isnull"] isEqualToString:@"yes"])
    {
        result = [[[NSString alloc] initWithString:@"null"] autorelease];
        return result;
    }
    
    // based upon the type, format the data accordingly
    // don't forget to wrap it in ' ' if needed and make sure to call the 
    // connection sqlEncodeString() on the input to prevent any sql injection 
    // style attacks agains the foundation.
    
    switch (type)
    {
            // Bit
        case 1560: // bit
        case 1562: // bit varying / varbit
            result = [self stringForBit:[column objectForKey:@"value"]];
            break;
            
            // Boolean
        case 16: // boolean
        {
            if ([[column objectForKey:@"value"] isEqualToString:@"yes"])
            {
                result = [NSString stringWithString:@"true"];
            } else {
                result = [NSString stringWithString:@"false"];
            }
            break;
        }
            
            // Data    
        case 17: // bytea
            result = [self stringForData:[column objectForKey:@"value"]];
            break;
            
            // Date & Time
        case 702:   // abstime (date and time)
            result = [self stringForAbsTime:[column objectForKey:@"value"]];
            break;
        case 1082:  // date  
            result = [self stringForDate:[column objectForKey:@"value"]];
            break;
            
        case 1083:  // time
            result = [self stringForTime:[column objectForKey:@"value"]];
            break;
            
        case 1114:  // timestamp
            result = [self stringForTimeStamp:[column objectForKey:@"value"]];
            break;
            
        case 1184:  // timestamptz
            result = [self stringForTimeStampTZ:[column objectForKey:@"value"]];
            break;
            
        case 1266:  // timetz
            result = [self stringForTimeTZ:[column objectForKey:@"value"]];
            break;
            
        case 1186:  // interval
            result = [self stringForString:[column objectForKey:@"value"]];
            break;
            
            // Numbers
        case 790:   // money
        {
            // use the size and offset params to determine the layout
            // get the real number then format it as money
            result = [self stringForMoney:[column objectForKey:@"value"]];
            break;            
        }
        case 1700:  // numeric
        case 700:   // float4
        case 701:   // float8
            // use the size and offset params to determine the layout
            result = [self stringForRealNumber:[column objectForKey:@"value"]];
            break;
            
        case 20:    // int8
        case 21:    // int2
        case 23:    // int4
        case 10:    // int8 (bigserial)
            result = [self stringForLongNumber:[column objectForKey:@"value"]];
            break;
            
            // Strings
        case 25:    // text
        case 2950:  // UUID
            
        case 1042:  // char
        case 1043:  // varchar (length is inthe offset)
            result = [self stringForString:[column objectForKey:@"value"]];
            break;
            
        case 142:   // xml
            result = [self stringForString:[column objectForKey:@"value"]];
            break;
            
        default:
            result = [self stringForString:[column objectForKey:@"value"]];
            break;
    }
    
    return result;
}

#pragma mark utility functions

- (NSString *)sqlEncodeString:(NSString *)value
{
    return [connection sqlEncodeString:value];
}

- (NSString *)stringForBit:(NSString *)value
{
	if (value == nil)
	{
		return [NSString stringWithString:@"null"];
	}
	return [NSString stringWithFormat:@"B'%@'", value];
}

- (NSString *)stringForBool:(BOOL)value
{
	if (value)
	{
		return [NSString stringWithString:@"true"];
	}
	return [NSString stringWithString:@"false"];
}

- (NSString *)stringForAbsTime:(NSDate *)value
{
	if (value == nil) 
	{
		return [NSString stringWithString:@"null"];
	}
	
	NSDateFormatter *format = [[[NSDateFormatter alloc] init] autorelease];
	[format setDateFormat:@"MMM dd HH:mm:ss yyyy"];
    
	return [NSString stringWithFormat:@"'%@'", [format stringFromDate:value]];
}

- (NSString *)stringForDate:(NSDate *)value
{
	if (value == nil) 
	{
		return [NSString stringWithString:@"null"];
	}
	
	NSDateFormatter *format = [[[NSDateFormatter alloc] init] autorelease];
    [format setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
	[format setDateFormat:@"yyyy-MM-dd"];
    
	return [NSString stringWithFormat:@"'%@'", [format stringFromDate:value]];
}

- (NSString *)stringForTime:(NSDate *)value
{
	if (value == nil) 
	{
		return [NSString stringWithString:@"null"];
	}
	
	NSDateFormatter *format = [[[NSDateFormatter alloc] init] autorelease];
    [format setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
	[format setDateFormat:@"HH:mm:ss"];
    
	return [NSString stringWithFormat:@"'%@'", [format stringFromDate:value]];
}

- (NSString *)stringForTimeStamp:(NSDate *)value
{
	if (value == nil) 
	{
		return [NSString stringWithString:@"null"];
	}
	
	NSDateFormatter *format = [[[NSDateFormatter alloc] init] autorelease];
    [format setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
	[format setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
	return [NSString stringWithFormat:@"'%@'", 
            [format stringFromDate:value]];
}

- (NSString *)stringForTimeStampTZ:(NSDate *)value
{
	if (value == nil) 
	{
		return [NSString stringWithString:@"null"];
	}
	
	NSDateFormatter *format = [[[NSDateFormatter alloc] init] autorelease];
    [format setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
	[format setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
	return [NSString stringWithFormat:@"'%@ +0'", 
            [format stringFromDate:value]];
}

- (NSString *)stringForTimeTZ:(NSDate *)value
{
	if (value == nil) 
	{
		return [NSString stringWithString:@"null"];
	}
	
	NSDateFormatter *format = [[[NSDateFormatter alloc] init] autorelease];
	[format setDateFormat:@"HH:mm:ss z"];
    
	return [NSString stringWithFormat:@"'%@'", 
            [format stringFromDate:value]];
}

- (NSString *)stringForData:(NSData *)value
{
	if (value == nil) 
	{
		return [NSString stringWithString:@"null"];
	}
    
    return [NSString stringWithFormat:@"'%@'", 
            [connection sqlEncodeData:value]];
}

- (NSString *)stringForString:(NSString *)value
{
	if (value == nil) 
	{
		return [NSString stringWithString:@"null"];
	}
	return [NSString stringWithFormat:@"'%@'", [connection sqlEncodeString:value]];
}

- (NSString *)stringForLongNumber:(NSNumber *)value
{
	if (value == nil) 
	{
		return [NSString stringWithString:@"null"];
	}
	return [NSString stringWithFormat:@"%d", [value longValue]];
}

- (NSString *)stringForRealNumber:(NSNumber *)value
{
	if (value == nil) 
	{
		return [NSString stringWithString:@"null"];
	}
	return [NSString stringWithFormat:@"%f", [value floatValue]];
}

- (NSString *)stringForMoney:(NSNumber *)value
{
	if (value == nil) 
	{
		return [NSString stringWithString:@"null"];
	}
	return [NSString stringWithFormat:@"'%.2f'", [value floatValue]];
}

- (void)setLastError:(NSString *)value
{
    if (lastError != nil)
    {
        [lastError release];
        lastError = nil;
    }
    
    lastError = [[[NSString alloc] initWithString:value] retain];
}

@end
