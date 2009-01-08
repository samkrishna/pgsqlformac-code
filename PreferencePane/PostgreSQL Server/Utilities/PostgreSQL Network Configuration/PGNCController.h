//
//  PGNCController.h
//  PostgreSQL Network Configuration
//
//  Created by Andy Satori on 11/13/08.
//  Copyright 2008 Druware Software Designs. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <Security/Authorization.h>
#include <Security/AuthorizationTags.h>

#import "PGHBAFile.h"

@interface PGNCController : NSObject {
	PGHBAFile *hbaConfiguration;
	
	IBOutlet NSTextView *rawSource;
	
}

-(IBAction)fetchActiveConfiguration:(id)sender;
-(IBAction)pushNewConfiguration:(id)sender;

-(IBAction)tellServerToReloadConfiguration:(id)sender;




@end
