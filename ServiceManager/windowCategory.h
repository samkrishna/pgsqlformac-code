//
//  windowCategory.h
//  Service Manager
//
//  Created by Andy Satori on Wed Jan 28 2004.
//  Copyright (c) 2004 Druware Software Designs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SQLServiceManager.h"


@interface SQLServiceManager  (WindowDelegateCategory)

- (void)windowWillClose:(NSNotification *)aNotification;


@end
