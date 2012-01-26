//
//  PGSQLDispatch.h
//  PGSQLKit
//
//  Created by Neil Tiffin on 1/6/12.
//  Copyright (c) 2012 Performance Champions, Inc. All rights reserved.
//

/*!
 @header	 PGSQLDispatch
 @abstract   The PGSQLDispatch singleton class provides multi-threaded queued execution of
             SQL statements creating or reusing connections as necessary.
 
 @discussion PGSQLDispatch processes SQL in the form of an NSString.
             If no connections are open, then PGSQLDispatch attempts to open one.  If
             no connections are available then PGSQLDispatch attempts to open a
             connection up to the connection limit and queues the request.  If PGSQLDispatch
             cannot use or open a connection then it queues the SQL request on an existing
             connection using GCD dispatch_async().
 
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

@interface PGSQLDispatch : NSObject
{
    // Dispatcher configuration settings
    NSUInteger maxNumberConnections;            // The maximum number of connections PGSQLDispatch will open.
    
    // Dispatcher Processing
    NSMutableArray *sqlConnections;             // Array of (PGSQLDispatchConnection *).
    NSMutableArray *sqlConnectionsStatistics;   // Currently Array of (NSNumber *) with count of unfinished processes.
                                                //      In the future sqlConnectionsStatistics may become a statistics object.
    NSUInteger indexOfLastDispatch;             // Index into sqlConnections and sqlConnectionsStatistics 
                                                //      of last or pending dispatch
}

// Before PGSQLDispatch can be accessed globalPGSQLConnection must be valid and connected.
+ (PGSQLDispatch *)sharedPGSQLDispatch;

// returns error number, callbacks always happen on the main thread
// The callback method must conform to -(void)resultsToSelector:(PGSQLRecordSet *)recordSet
- (NSInteger)resultsFromSQL:(NSString *)sql toObject:(id)resultsToObject usingSelector:(SEL)resultsToSelector;

@property (assign) NSUInteger maxNumberConnections;

@end
