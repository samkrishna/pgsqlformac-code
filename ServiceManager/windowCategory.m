//
//  windowCategory.m
//  Service Manager
//
//  Created by Andy Satori on Wed Jan 28 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "windowCategory.h"


@implementation SQLServiceManager (WindowDelegateCategory)

- (void)windowWillClose:(NSNotification *)aNotification
{
    [NSApp terminate:self];
    return;
}


@end
