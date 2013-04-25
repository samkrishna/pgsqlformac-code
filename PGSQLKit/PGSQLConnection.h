//
//  PGSQLConnection.h
//  PGSQLKit
//
//  Created by Andy Satori on 5/8/07.
//  Copyright 2007-2011 Druware Software Designs. All rights reserved.
//

/*!
 @header        PGSQLConnection
 @abstract		A PGSQLConnection class is one async data access subclass 
                of PGSQLConnectionBase.
 
 @discussion
				License 
 
				Copyright (c) 2005-2010, Druware Software Designs
				All rights reserved.

				Redistribution and use in binary forms, with or without modification, are 
				permitted provided that the following conditions are met:

				1. Redistributions in binary form must reproduce the above copyright notice, 
				this list of conditions and the following disclaimer in the documentation 
				and/or other materials provided with the distribution. 
				2. Neither the name of the Druware Software Designs nor the names of its 
				contributors may be used to endorse or promote products derived from this 
				software without specific prior written permission.

				THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
				AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
				IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
				ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
				LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
				CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
				SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
				INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
				CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
				ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF 
				THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PGSQLConnectionBase.h"
#import "GenDBProtocol.h"

@interface PGSQLConnection : PGSQLConnectionBase <GenDBConnection>
{
	BOOL enableCursors;
}

#pragma mark -
#pragma mark Compatibility Functions

- (NSString *)datasourceFilter;
- (void)setDatasourceFilter:(NSString *)value;

- (BOOL)enableCursors;
- (void)setEnableCursors:(BOOL)value;


// Really should use -(PGSQLConnectionBase *)clone instead.  This is provided for
// compatibility only.
- (PGSQLConnection *)clone;

#pragma mark -
#pragma mark Async Functions

- (void)connectAsync;
- (void)execCommandAsync:(NSString *)sql;
- (void)openAsync:(NSString *)sql;

#pragma mark -
#pragma mark Exported Constants

/*!
    @const 
    @abstract   Notification for use with async connections being established.
    @discussion <#(description)#>
*/
FOUNDATION_EXPORT NSString * const PGSQLConnectionDidCompleteNotification;
/*!
	 @const 
	 @abstract   Notification for use with async command processing.
	 @discussion <#(description)#>
 */
FOUNDATION_EXPORT NSString * const PGSQLCommandDidCompleteNotification;	



@end
