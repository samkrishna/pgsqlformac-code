//
//  menuCategory.h
//  Service Manager
//
//  Created by Andy Satori on Thu Jan 29 2004.
//  Copyright (c) 2004 Druware Software Designs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SQLServiceManager.h"

@interface SQLServiceManager (MenuDelegateCategory)

- (BOOL)validateMenuItem:(NSMenuItem *)theItem;

@end
