//
//  PGSQLLoginDelegate.h
//  PGSQLKit
//
//  Created by Andy Satori on 6/9/11.
//  Copyright 2011 Satori & Associates, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PGSQLKit.h"

@protocol PGSQLLoginDelegate <NSObject>

-(IBAction)loginCompleted:(PGSQLConnection *)resultConnection;

@end
