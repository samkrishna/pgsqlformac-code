/*          file: PGSQLDataObjectList.m
 *   description: Represents a base object list from which the lists of data 
 *                objects in the server core library derive from.  This 
 *                implementation provides base support functionality to reduce 
 *                some of the boilerplate overhead inherent in the data objects. 
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

#import "PGSQLDataObjectList.h"
#import "PGSQLRecordset.h"

@implementation PGSQLDataObjectList

@synthesize lastError, connection;

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
-(id)init
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
 *     dru 02/02/12 changed to return throw an exception, as this should NEVER
 *                  be called without a table and primary key.
 ******************************************************************************/
-(id)initWithConnection:(PGSQLConnection *)conn
{
	NSException* myException = [NSException
								exceptionWithName:@"InvalidInitCalled"
								reason:@"Init Cannot be called in the base class with a table and primary key"
								userInfo:nil];
	@throw myException;
    
    return nil;	
}

/* initWithConnection
 *   description
 *     implements an init that takes an active PGSQLConnection for use in data
 *     operations withing the object list.  If this generic base operation is 
 *     used generic base operation is used.  It makes several assumptions:
 *       1. the table in question has a primary key
 *       2. the primary key is serial
 *       3. the table supports 
 *   arguments
 *     (PGSQLConnection *) as the connection to be used for the current object.
 *       note that this connection cannot have multiple result sets open at a 
 *       time.
 *   returns
 *     (id) as the current object reference initialized as the referenced 
 *       data record
 *   history
 *     who   date    change
 *     --- -------- ----------------------------------------------------------- 
 ******************************************************************************/
- (id)initWithConnection:(PGSQLConnection *)conn
                forTable:(NSString *)tableName
          withPrimaryKey:(NSString *)keyName
{
    self = [super init];
	
	if (self != nil) {
		connection = conn;
        table = [tableName copy];
        primaryKey = [keyName copy];
		
		items = [[NSMutableArray alloc] init];	
        
        // it'sjust a thought, but perhaps this should, well, you know run a 
        // or something
		NSString *cmd = [NSString stringWithFormat:@"select * from %@", 
                         table];
        PGSQLRecordset *rs = (PGSQLRecordset *)[connection open:cmd];
        while (![rs isEOF])
        {
            // do the load here
            PGSQLDataObject *dataObject = [[PGSQLDataObject alloc] 
                                           initWithConnection:connection 
                                           forTable:table
                                           withPrimaryKey:keyName
                                           forRecord:rs];
            [items addObject:dataObject];
            [rs moveNext];
        }
        [rs close];}
	
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
 ******************************************************************************/
-(BOOL)save
{
	BOOL result = NO;
	
	// loop through the children and save each dirty one
	int i;
	for (i = 0; i < [items count]; i++)
	{
		PGSQLDataObject *item = [items objectAtIndex:i];
		if ([item isDirty])
		{
			result = [item save];
			if (result == NO)
			{
				return NO;
			}
		}
	}
	return YES;
}

#pragma mark xml processing methods

/* xmlForObject
 *   description
 *     provides a method for populating an object from a passed in xml stream. 
 *     the stream populates the state of the object and the current state can be
 *     used to update or create a database record based upon the input.
 *   arguments
 *     none
 *   returns
 *     (NSXMLElement *) containing an Xml Node that represents the contents of 
 *       of the object.
 *   history
 *     who   date    change
 *     --- -------- ----------------------------------------------------------- 
 ******************************************************************************/
- (NSXMLElement *)xmlForObject
{
	NSXMLElement *thisNode = [[NSXMLElement alloc] initWithName:table];
    
	int i;
	for (i = 0; i < [items count]; i++)
	{
		PGSQLDataObject *item = [items objectAtIndex:i];
		NSXMLElement *childNode = [item xmlForObject];
		[thisNode addChild:childNode];
	}
	
	return thisNode;	
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
    return NO;
}

#pragma mark Property Accessors

/* items
 *   description
 *     return the array that contains the items in the list
 *   arguments
 *     (none)
 *   returns
 *     NSArray* result as the list ofo items.  
 *   history
 *     who   date    change
 *     --- -------- ----------------------------------------------------------- 
 ******************************************************************************/
-(NSArray *)items
{
	return items;
}

/* objectAtIndex
 *   description
 *     return the item as the index from the array 
 *   arguments
 *     (int) as the index if the desired item in the array
 *   returns
 *     TWJDataObject * as the object at the index in the array
 *   history
 *     who   date    change
 *     --- -------- ----------------------------------------------------------- 
 ******************************************************************************/
-(PGSQLDataObject *)objectAtIndex:(int)index
{
	if (items == nil) 
	{
		return nil;
	}
	
	if (index >= [items count])
	{
		return nil;
	}
	
	return (PGSQLDataObject *)[items objectAtIndex:index];
}

/* count
 *   description
 *     return the count of items in the array
 *   arguments
 *     (none)
 *   returns
 *     long result as the count of the items in the list.  
 *   history
 *     who   date    change
 *     --- -------- ----------------------------------------------------------- 
 ******************************************************************************/
-(long)count
{
	if (items == nil) 
	{
		return 0;
	}
	return [items count];
}

@end

