//
//  PGSQLDispatchConnection.h
//  PGSQLKit-Neil
//
//  Created by Neil Tiffin on 1/7/12.
//  Copyright (c) 2012 Performance Champions, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PGSQLConnection.h"

@interface PGSQLDispatchConnection : PGSQLConnection
{
    dispatch_queue_t connectionQueue;
}

- (id)initWithQueueName:(NSString *)queueName;

@property (readonly) dispatch_queue_t connectionQueue;

@end
