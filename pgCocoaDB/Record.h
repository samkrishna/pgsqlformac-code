//
//  Record.h
//  Query Tool
//
//  Created by Andy Satori on Tue Feb 03 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Fields.h"

@interface Record : NSObject 
{
	Fields *fields;
}

- (Fields *)fields;

@end
