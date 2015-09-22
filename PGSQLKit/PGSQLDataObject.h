//
//  PGSQLDataObject.h
//  PGSQLKit
//
//  Created by Dru Satori on 1/30/12.
//  Copyright (c) 2012 Druware Software Designs. All rights reserved.
//

/*!
 @header        PGSQLDataObject
 @abstract      A simple data object class that encapsulates a single record in 
                a recordset, and manages all of the CRUD methods needed to 
                create, read, update, delete, serialize to xml and reconstitute
                from xml.
 
 @discussion	The PGSQLDataObject class was born mostly out of the drudgery 
                of the boilerplate code that is so many simple data classes. In
                this initial pass, it 
 
                License 

                Copyright (c) 2005-2012, Druware Software Designs
                All rights reserved.

                Redistribution and use in binary forms, with or without 
                modification, are permitted provided that the following 
                conditions are met:

                1. Redistributions in binary form must reproduce the above 
                   copyright notice, this list of conditions and the following 
                   disclaimer in the documentation and/or other materials  
                   provided with the distribution. 
                2. Neither the name of the Druware Software Designs nor the 
                   names of its contributors may be used to endorse or promote 
                   products derived from this software without specific prior 
                   written permission.

                THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND 
                CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
                INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
                MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
                DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR 
                CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
                SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT 
                NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
                LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
                HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
                CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR 
                OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
                EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import <Foundation/Foundation.h>
#import "PGSQLConnection.h"

@interface PGSQLDataObject : NSObject
{
    NSNumber        *refId;
    NSString        *table;
    NSMutableDictionary    *properties;
    NSString        *primaryKey;
    
	BOOL             isNew;
	BOOL             isDirty;
	NSString        *lastError;
	
    NSMutableArray  *omittedFields;
    
	PGSQLConnection *connection;
}

#pragma mark customer initializers

- (id)initWithConnection:(PGSQLConnection *)pgConn;
- (id)initWithConnection:(PGSQLConnection *)pgConn 
                   forId:(NSNumber *)referenceId;
- (id)initWithConnection:(PGSQLConnection *)pgConn 
               forRecord:(PGSQLRecordset *)rs;
- (id)initWithConnection:(PGSQLConnection *)pgConn
                forTable:(NSString *)tableName
          withPrimaryKey:(NSString *)keyName;
- (id)initWithConnection:(PGSQLConnection *)pgConn 
                forTable:(NSString *)tableName
          withPrimaryKey:(NSString *)keyName
               forRecord:(PGSQLRecordset *)rs;
- (id)initWithConnection:(PGSQLConnection *)pgConn
                forTable:(NSString *)tableName
          withPrimaryKey:(NSString *)keyName
                   forId:(NSNumber *)referenceId;
- (id)initWithConnection:(PGSQLConnection *)pgConn
                forTable:(NSString *)tableName
          withPrimaryKey:(NSString *)primaryKeyName
               lookupKey:(NSString *)keyName
             lookupValue:(NSString *)keyValue;

#pragma mark utility methods

- (NSString *)stringForBit:(NSString *)value;
- (NSString *)stringForBool:(BOOL)value;
- (NSString *)stringForAbsTime:(NSDate *)value;
- (NSString *)stringForDate:(NSDate *)value;
- (NSString *)stringForTime:(NSDate *)value;
- (NSString *)stringForTimeStamp:(NSDate *)value;
- (NSString *)stringForTimeTZ:(NSDate *)value;
- (NSString *)stringForTimeStampTZ:(NSDate *)value;

- (NSString *)stringForData:(NSData *)value;
- (NSString *)stringForLongNumber:(NSNumber *)value;
- (NSString *)stringForRealNumber:(NSNumber *)value;
- (NSString *)stringForMoney:(NSNumber *)value;
- (NSString *)stringForString:(NSString *)value;

- (NSString *)sqlEncodeString:(NSString *)value;

#pragma mark mata management methods (RDBMS & Xml)

- (BOOL)save;
- (BOOL)remove;
- (NSXMLElement *)xmlForObject;
- (BOOL)loadFromXml:(NSXMLElement *)xmlElement;

- (NSDictionary *)jsonForObject;
- (BOOL)loadFromJson:(NSArray *)xmlElement;

- (void)setLastError:(NSString *)value;

- (BOOL)addOmittedField:(NSString *)fieldName;

#pragma mark standard data connection properties

- (void)setValue:(id)value forProperty:(NSString *)property;
- (id)valueForProperty:(NSString *)property;
- (long)sizeOfProperty:(NSString *)property;
- (BOOL)propertyIsNull:(NSString *)property;

@property (assign,readonly) BOOL isNew;
@property (assign,readonly) BOOL isDirty;
@property (readonly, nonatomic) NSString *lastError;
@property (readonly) PGSQLConnection *connection;
@property (readonly) NSString *table;
@property (readonly) NSString *primaryKey;
@property (readonly) NSNumber *refId;

@end
