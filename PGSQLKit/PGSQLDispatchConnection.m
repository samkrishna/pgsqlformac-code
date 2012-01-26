//
//  PGSQLDispatchConnection.m
//  PGSQLKit-Neil
//
//  Created by Neil Tiffin on 1/7/12.
//  Copyright (c) 2012 Performance Champions, Inc. All rights reserved.
//

#import "PGSQLDispatchConnection.h"

@implementation PGSQLDispatchConnection

@synthesize connectionQueue;

- (id)initWithQueueName:(NSString *)queueName
{
    self = [super init];
    if (self) {
        connectionQueue = dispatch_queue_create([queueName cStringUsingEncoding:[NSString defaultCStringEncoding]], NULL);
        PGSQLConnection *defaultConnection = [PGSQLConnection defaultConnection];
        if (defaultConnection)
        {
            [self setServer:[defaultConnection server]];
            [self setPort:[defaultConnection port]]; 
            [self setUserName:[defaultConnection userName]];
            [self setPassword:[defaultConnection password]];
            [self setDatabaseName:[defaultConnection databaseName]];
            if ([self connect])
            {
                // init complete.
                return self;
            }
            else
            {
                NSLog(@"%@ %s - Error, not able to open connection.", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __func__);
            }
        }
        else
        {
            NSLog(@"%@ %s - Error, defaultConnection has not been established.", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __func__);
        }
    }
    [self release];
    self = nil;
    return self;
}

- (id)init
{
    return [self initWithQueueName:@"PGSQLKit.MyQueue"];
}


- (void)dealloc {
    dispatch_release(connectionQueue);
    [super dealloc];
}

@end
