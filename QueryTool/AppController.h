//
//  AppController.h
//  Query Tool for PostgresN
//
//  Created by Neil Tiffin on 8/26/06.
//  Copyright 2006 Performance Champions, Inc.. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class PreferenceController;

@interface AppController : NSObject {
	PreferenceController *preferenceController;
}

-(IBAction)showPreferencePanel:(id)sender;

@end
