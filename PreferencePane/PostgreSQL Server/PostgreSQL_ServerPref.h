//
//  PostgreSQL_ServerPref.h
//  PostgreSQL Server
//
//  Created by Andy Satori on 8/8/08.
//  Copyright (c) 2008 Druware Software Designs. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>
#import <Cocoa/Cocoa.h>


@interface PostgreSQL_ServerPref : NSPreferencePane

- (NSMutableDictionary *)getPreferencesFromFile;
-(void)savePreferencesFile:(NSDictionary *)savePreferences;

@end
