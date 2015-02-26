//
//  GenDBProtocol.h
//

/* License ********************************************************************
 
 Copyright (c) 2005-2012, Druware Software Designs
 All rights reserved.
 
 Redistribution and use in source or binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1. Redistributions in source or binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 2. Neither the name of the Druware Software Designs nor the names of its
 contributors may be used to endorse or promote products derived from this
 software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 ******************************************************************************/

#ifndef GENDBPROTOCOL
#define GENDBPROTOCOL

#pragma mark GenDBField

@protocol GenDBField

-(NSString *)asString;
-(NSString *)asString:(NSStringEncoding)encoding;
-(NSNumber *)asNumber;
-(short)asShort;
-(long)asLong;
-(NSDate *)asDate;
-(NSDate *)asDateWithGMTOffset:(NSString *)gmtOffset;
-(NSData *)asData;
-(BOOL)isNull;

/*!
	@function
	@abstract   Get the connection's defaultEncoding for all string operations
 returning.
	@discussion The default setting is NSUTF8StringEncoding.
	@result     returns the defaultEncoding as an NSSTringEncoding (
 http://developer.apple.com/mac/library/documentation/Cocoa/Reference/Foundation/Classes/NSString_Class/Reference/NSString.html#//apple_ref/doc/c_ref/NSStringEncoding )
 */
-(NSStringEncoding)defaultEncoding;

/*!
	@function
	@abstract   Set the defaultEncoding for all string operations on the current
 connection
	@discussion The default setting is NSUTF8StringEncoding.
	@param      value the defaultEncoding as an NSSTringEncoding (
 http://developer.apple.com/mac/library/documentation/Cocoa/Reference/Foundation/Classes/NSString_Class/Reference/NSString.html#//apple_ref/doc/c_ref/NSStringEncoding )
	@result     void
 */
-(void)setDefaultEncoding:(NSStringEncoding)value;

@end

#pragma mark GenDBRecord

/*!
 @protocol
 @abstract   Generic Record Definitions to the GenDB Protocol
 @discussion Provide a common implementation of a Record in a result set.
 Each record in a result set represents a single row.  For the
 most part this implementation is used as a thin veneer and the
 bulk of the work and usability is also exposed by the recordset.
 */
@protocol GenDBRecord

/*!
 @function
 @abstract   return a field in the record by its ordinal into the record
 @discussion While faster than using the name, this implementation is less
 flexible as the SQL used to generate the lists is altered, and
 it is frequently skipped in favor of the ByName() counterpart.
 @param      fieldIndex as the ordinal of the field to return.
 @result     a Field object that conforms to the GenDBField protocol
 corresponding to the field in the record.
 */
-(id <GenDBField>)fieldByIndex:(long)fieldIndex;
/*!
 @function
 @abstract   return a field in the record by its column name in the record
 @discussion While slower than using the name, this implementation is more
 flexible as the SQL used to generate the lists is altered.
 @param      name as the string name of the field to return.
 @result     a Field object that conforms to the GenDBField protocol
 corresponding to the field in the record.
 */
-(id <GenDBField>)fieldByName:(NSString *)name;

/*!
	@function
	@abstract   Get the connection's defaultEncoding for all string operations
 returning.
	@discussion The default setting is NSUTF8StringEncoding.
	@result     returns the defaultEncoding as an NSSTringEncoding (
 http://developer.apple.com/mac/library/documentation/Cocoa/Reference/Foundation/Classes/NSString_Class/Reference/NSString.html#//apple_ref/doc/c_ref/NSStringEncoding )
 */
-(NSStringEncoding)defaultEncoding;

/*!
	@function
	@abstract   Set the defaultEncoding for all string operations on the current
 connection
	@discussion The default setting is NSUTF8StringEncoding.
	@param      value the defaultEncoding as an NSSTringEncoding (
 http://developer.apple.com/mac/library/documentation/Cocoa/Reference/Foundation/Classes/NSString_Class/Reference/NSString.html#//apple_ref/doc/c_ref/NSStringEncoding )
	@result     void
 */
-(void)setDefaultEncoding:(NSStringEncoding)value;

@end

#pragma mark GenDBColumn

@protocol GenDBColumn

-(NSString *)name;
-(int)index;
-(int)type;
-(int)size;
-(int)offset;

@end

#pragma mark GenDBRecordset

/*!
 @protocol
 @abstract    Provides a common implmentation protocol for a recordset in the
 the data.  This template encapsulates the columns and rows, as
 well as providing utility methods to quickly access the data.
 @discussion  Provides a common implmentation protocol for a recordset in the
 the data.  This template encapsulates the columns and rows, as
 well as providing utility methods to quickly access the data.
 In some implementations, this will be a thin veneer over the
 underlying result.  In others however, the ability to read the
 results out of order may cause the implementation to require an
 internal cache mechanism for the results.
 */
@protocol GenDBRecordset

-(id <GenDBField>)fieldByIndex:(long)fieldIndex;
-(id <GenDBField>)fieldByName:(NSString *)fieldName;
-(void)close;

-(NSArray *)columns;
-(long) rowCount;

-(id <GenDBRecord>)moveFirst;
-(id <GenDBRecord>)movePrevious;
-(id <GenDBRecord>)moveNext;
-(id <GenDBRecord>)moveLast;

-(BOOL)isEOF;
@property (assign, nonatomic, readonly, getter=isEOF) BOOL IsEOF;


-(NSDictionary *)dictionaryFromRecord;

/*!
 @function
 @abstract   Access to the last error result from the user actions.
 @discussion Access to the last error result from the user actions.
 @param      none
 @result     NSString * as the string formatted results of the last action.
 a NIL result indicates no errors.
 */
-(NSString *)lastError;

/*!
	@function
	@abstract   Get the connection's defaultEncoding for all string operations
 returning.
	@discussion The default setting is NSUTF8StringEncoding.
	@result     returns the defaultEncoding as an NSSTringEncoding (
 http://developer.apple.com/mac/library/documentation/Cocoa/Reference/Foundation/Classes/NSString_Class/Reference/NSString.html#//apple_ref/doc/c_ref/NSStringEncoding )
 */
-(NSStringEncoding)defaultEncoding;

/*!
	@function
	@abstract   Set the defaultEncoding for all string operations on the current
 connection
	@discussion The default setting is NSUTF8StringEncoding.
	@param      value the defaultEncoding as an NSSTringEncoding (
 http://developer.apple.com/mac/library/documentation/Cocoa/Reference/Foundation/Classes/NSString_Class/Reference/NSString.html#//apple_ref/doc/c_ref/NSStringEncoding )
	@result     void
 */
-(void)setDefaultEncoding:(NSStringEncoding)value;

@end

#pragma mark GenDBConnection

@protocol GenDBConnection <NSObject>

/* Connection Property Implementations */
#pragma mark -
#pragma mark Connection Property Implementations

- (BOOL)isConnected;
@property (assign, nonatomic, readonly, getter=isConnected) BOOL IsConnected;

- (NSString *)connectionString;
- (void)setConnectionString:(NSString *)value;
@property (assign, nonatomic, getter=connectionString, setter=setConnectionString:) NSString *ConnectionString;

- (NSString *)userName;
- (void)setUserName:(NSString *)value;
@property (assign, nonatomic, getter=userName, setter=setUserName:) NSString *UserName;

- (NSString *)password;
- (void)setPassword:(NSString *)value;
@property (assign, nonatomic, getter=password, setter=setPassword:) NSString *Password;

- (NSString *)datasourceFilter;
- (void)setDatasourceFilter:(NSString *)value;

- (BOOL)enableCursors;
- (void)setEnableCursors:(BOOL)value;
@property (assign, nonatomic, getter=enableCursors, setter=setEnableCursors:) BOOL EnableCursors;

/*!
	@function
	@abstract   Get the connection's defaultEncoding for all string operations
 returning.
	@discussion The default setting is NSUTF8StringEncoding.
	@result     returns the defaultEncoding as an NSSTringEncoding (
 http://developer.apple.com/mac/library/documentation/Cocoa/Reference/Foundation/Classes/NSString_Class/Reference/NSString.html#//apple_ref/doc/c_ref/NSStringEncoding )
 */
-(NSStringEncoding)defaultEncoding;

/*!
	@function
	@abstract   Set the defaultEncoding for all string operations on the current
 connection
	@discussion The default setting is NSUTF8StringEncoding.
	@param      value the defaultEncoding as an NSSTringEncoding (
 http://developer.apple.com/mac/library/documentation/Cocoa/Reference/Foundation/Classes/NSString_Class/Reference/NSString.html#//apple_ref/doc/c_ref/NSStringEncoding )
 
	@result     void
 */
-(void)setDefaultEncoding:(NSStringEncoding)value;
@property (assign, nonatomic, getter=defaultEncoding, setter=setDefaultEncoding:) NSStringEncoding DefaultEncoding;

/* Connection Management Functions ********************************************/

#pragma mark Connection Management Functions

- (BOOL)close;
- (BOOL)connect;
- (void)connectAsync;
- (long)execCommand:(NSString *)sql;
- (void)execCommandAsync:(NSString *)sql;
- (id <GenDBRecordset>)open:(NSString *)sql;
- (void)openAsync:(NSString *)sql;

- (NSString *)lastError;
@property (assign, nonatomic, readonly, getter=lastError) NSString *LastError;

- (id <GenDBConnection>)clone;

#pragma mark Public Exported Constants

FOUNDATION_EXPORT NSString * const GenDBConnectionDidCompleteNotification;
FOUNDATION_EXPORT NSString * const GenDBCommandDidCompleteNotification;

@end


#endif