//
//  PGSQLDispatch.h
//  PGSQLKit
//
//  Created by Neil Tiffin on 1/6/12.
//  Copyright (c) 2012 Performance Champions, Inc. All rights reserved.
//

// Values for __MAC_10_6 and __IPHONE_4_0 are used in case this code is compiled on systems
// where they are not defined and therefore will be evaluated as zero.
#if (MAC_OS_X_VERSION_MIN_REQUIRED >= 1060) || (__IPHONE_OS_VERSION_MIN_REQUIRED >= 40000)

/*!
 @header	 PGSQLDispatch
 @abstract   The PGSQLDispatch singleton class provides multi-threaded queued execution of
             SQL statements creating or reusing connections as necessary.
 
 @discussion PGSQLDispatch processes SQL in the form of an NSString the returns the result in
             the form of a PGSQLRecordSet.
 
             PGSQLDispatch automatically opens connections as needed but requires an initial
             PGSQLConnection setup with host info, passwords, etc.  The PGSQLConnection does not have
             to be open, but if PGSQLDispatch opening the connection fails, PGSQLDispatch is not able to
             correct the faulty connection info.  So the first connection should be established and tested
             prior to calling PGSQLDispatch for the first time.
  
             If only busy connections are available then PGSQLDispatch attempts to open a new
             connection up to the connection limit, then queues the request on the new connection.  
             If PGSQLDispatch cannot open a connection then it queues the SQL request round robin
             on an existing connection.
 
             PGSQLDispatch requires iOS 4.0+ or OS X 10.6+ because it uses blocks.  For older systems
             the classes PGSQLDispatch and PGSQLDispatchConnection are not included in
             the framework.
 
             License 
 
             Copyright (c) 2012, Performance Champions, Inc.
             All rights reserved.
 
             Redistribution and use in binary forms, with or without modification, are 
             permitted provided that the following conditions are met:
 
             1. Redistributions in binary form must reproduce the above copyright notice, 
             this list of conditions and the following disclaimer in the documentation 
             and/or other materials provided with the distribution. 
             2. Neither the name of the Performance Champions, Inc. nor the names of its 
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

#import <Foundation/Foundation.h>

@class PGSQLRecordset;

@interface PGSQLDispatch : NSObject
{
    // Dispatcher configuration settings
    NSUInteger maxNumberConnections;            // The maximum number of connections PGSQLDispatch can open.
                                                //      Can be changed on the fly (anytime).
                                                //      Defaults to number of cores minus 1.
                                                //      Minimum setting is 1, Maximum is 30.
    
    NSUInteger queryTimeoutSeconds;             // queries taking longer than queryTimeoutSeconds may be cancelled.
    
    // Dispatcher Processing
    NSMutableArray *sqlConnections;             // Array of (PGSQLDispatchConnection *).
    NSUInteger indexOfLastDispatch;             // Index into sqlConnections of last or pending dispatch
}

// Before PGSQLDispatch can be created globalPGSQLConnection must be valid and it's connection info must remain accessible.
// PGSQLDispatch can be alloc init'ed in the standard fashion to create multiple dispatchers or
// one may use sharedPGSQLDispatch to keep one global dispatch.
+ (PGSQLDispatch *)sharedPGSQLDispatch;

// Error return type.
typedef enum {PGSQLDispatchErrorNone = 0, PGSQLDispatchErrorNoAvailableConnections} PGSQLDispatchError_t;

// Callback block type.
typedef void (^PGSQLDispatchCallback_t)(PGSQLRecordset *recordset, NSString *errorString);

// All SQL is dispatched through here.
// Note that each call may be dispatched using a different connection, so be careful how transactions are handled.
// For block example see PGSQLKitUnitTest.m
// Long running SQL queries are managed so they don't block all connections.
- (PGSQLDispatchError_t)processResultsFromSQL:(NSString *)sql
                                    expectLongRunning:(BOOL)longRunning
                             usingCallbackBlock:(PGSQLDispatchCallback_t)callbackBlock;

// Returns text description for PGSQLDispatchError_t.
- (NSString *)stringDescriptionForErrorNumber:(PGSQLDispatchError_t)error;

@property (assign) NSUInteger maxNumberConnections;
@property (assign) NSUInteger queryTimeoutSeconds;

#ifdef DEBUG
// Returns the total queue blocks across all connections.
// If all work as been submitted then all work will be done when this is zero.
- (NSUInteger)totalQueuedBlocks;
#endif


@end
#endif
