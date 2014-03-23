//
//  PGMChangeDataPath.h
//  PostgreSQL Server
//
//  Created by Andy Satori on 2/16/09.
//  Copyright 2009 Druware Software Designs. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PGMChangeDataPath : NSObject

@property (strong, nonatomic) NSString *currentPath;

- (void)showModalForWindow:(NSWindow *)window;

@end
