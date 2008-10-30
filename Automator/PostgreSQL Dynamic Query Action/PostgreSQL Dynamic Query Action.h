//
//  PostgreSQL Dynamic Query Action.h
//  PostgreSQL Dynamic Query Action
//
//  Created by Andy Satori on 9/25/07.
//  Copyright 2007 Druware Software Designs. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Automator/AMBundleAction.h>
#import <PGSQLKit/PGSQLKit.h>


@interface PostgreSQL_Dynamic_Query_Action : AMBundleAction 
{
	IBOutlet NSPopUpButton *dataSourceList;	
}

- (id)runWithInput:(id)input fromAction:(AMAction *)anAction error:(NSDictionary **)errorInfo;
- (IBAction)onSelectConnection:(id)sender;

@end
