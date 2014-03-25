//
//  PGMChangeDataPath.h
//  PostgreSQL Server
//
//  Created by Andy Satori on 2/16/09.
//  Copyright 2009 Druware Software Designs. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef void (^SaveCallback)(NSMutableDictionary *);
typedef void (^CancelCallback)(void);

@interface PGMChangeDataPath : NSObject <NSTextDelegate>

@property (strong, nonatomic) NSString *currentPath;

- (void)showModalForWindow:(NSWindow *)window;

    // SaveCallback is required and is only called if preferences are changed.
- (instancetype)initWithSaveCallback:(SaveCallback)saveBlock cancelCallback:(CancelCallback)cancelBlock;

@end
