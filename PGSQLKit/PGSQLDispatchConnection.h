//
//  PGSQLDispatchConnection.h
//  PGSQLKit-Neil
//
//  Created by Neil Tiffin on 1/7/12.
//  Copyright (c) 2012 Performance Champions, Inc. All rights reserved.
//

// Values for __MAC_10_6 and __IPHONE_4_0 are used in case this code is compiled on systems
// where they are not defined and therefore will be evaluated as zero.
#if (MAC_OS_X_VERSION_MIN_REQUIRED >= 1060) || (__IPHONE_OS_VERSION_MIN_REQUIRED >= 40000)

/*
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
#import "PGSQLConnectionBase.h"

@interface PGSQLDispatchConnection : PGSQLConnectionBase
{
    dispatch_queue_t connectionQueue;
    NSNumber *queueWaitingCount;               // Count of unfinished processes in the queue
}

- (id)initWithQueueName:(NSString *)queueName connection:(PGSQLConnectionBase *)connection;
- (void)processResultsFromSQL:(NSString *)sql 
                           usingCallbackBlock:(void (^)(PGSQLRecordset *, NSString *))callbackBlock;

@property (readonly) dispatch_queue_t connectionQueue;
@property (readonly, strong) NSNumber *queueWaitingCount;

// Connection statistics
- (void)incConnectionStatistics;
- (void)decConnectionStatistics;

@end
#endif
