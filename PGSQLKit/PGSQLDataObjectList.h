

/*          file: PGSQLDataObjectList.h
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
 *   WHO MM/DD/YY Description
 *   --- -------- --------------------------------------------------------------
 *   dru 11/26/11 Stubbed in for refactoring the prototype classes  
 *
 ******************************************************************************/

#import <Foundation/Foundation.h>
#import "PGSQLConnection.h"
#import "PGSQLDataObject.h"

@interface PGSQLDataObjectList : NSObject
{
    NSString        *table;
    NSMutableArray  *items;
    NSString        *primaryKey;
    
    NSString        *lastError;
    PGSQLConnection *connection;
    
}

#pragma mark custom initializers

- (id)init;
- (id)initWithConnection:(PGSQLConnection *)conn;
- (id)initWithConnection:(PGSQLConnection *)pgConn
                forTable:(NSString *)tableName
          withPrimaryKey:(NSString *)keyName;

#pragma mark save and delete methods

- (BOOL)save;

#pragma mark xml processing methods

- (NSXMLElement *)xmlForObject;
- (BOOL)loadFromXml:(NSXMLElement *)xmlElement;

#pragma mark JSON processing methods

- (NSMutableArray *)jsonForObject;
- (BOOL)loadFromJson:(NSArray *)jsonElement;

#pragma mark custom properties

- (NSMutableArray *)items;
- (PGSQLDataObject *)objectAtIndex:(int)index;
- (long)count;

#pragma mark standard data connection properties

@property (readonly) NSString *lastError;
@property (readonly) PGSQLConnection *connection;

@end

