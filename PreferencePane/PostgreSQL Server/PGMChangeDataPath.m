//
//  PGMChangeDataPath.m
//  PostgreSQL Server
//
//  Created by Andy Satori on 2/16/09.
//  Copyright 2009 Druware Software Designs. All rights reserved.
//
//  Modifications March 2014 Neil Tiffin
//  Changes Copyright 2014 Performance Champions, Inc.
//  All rights reserved except full permission to use is given to Andy Satori and Druware Software Designs.
//

#import "PGMChangeDataPath.h"

@interface PGMChangeDataPath ()

@property (weak) IBOutlet NSTextField *dataFilePath;
@property (weak) IBOutlet NSTextField *binPath;
@property (weak) IBOutlet NSTextField *logPath;
@property (weak) IBOutlet NSTextField *portNumber;

@property (weak) IBOutlet NSPanel *thisPanel;
@property (weak) NSWindow *parentWindow;;

@end

@implementation PGMChangeDataPath

#pragma mark - Lifecycle Methods

- (void)dealloc
{
    self.currentPath = nil;
}

- (void)showModalForWindow:(NSWindow *)window
{
	self.parentWindow = window;
	
	// show the dialog modal
	// load the nib
	if (![NSBundle loadNibNamed:@"ChangeDataPathPanel" owner:self]) 
	{
		NSLog(@"Error loading nib.");
		return;
	}
	
        // load defaults
    [self getSavedPreferences];
    
        // show
	[NSApp beginSheet:self.thisPanel
	   modalForWindow:self.parentWindow
		modalDelegate:nil
	   didEndSelector:nil
		  contextInfo:nil];

	[NSApp runModalForWindow:self.thisPanel];
}

#pragma mark - Preferences Methods

- (void)getSavedPreferences
{
    NSMutableDictionary *preferences;
	NSFileManager *fm = [[NSFileManager alloc] init];
	if ([fm fileExistsAtPath:DRUWARE_PREF_FILE_NSSTRING])
	{
            // replace with NSUserDefaults/NSGlobalDomain
		preferences = [[NSMutableDictionary alloc] initWithContentsOfFile:DRUWARE_PREF_FILE_NSSTRING];
    }
    else
    {
        
    }
#ifdef DEBUG
        // Check that all preferences are set by this time.
        // They should be.
    if ((preferences[PREF_KEY_LOG_PATH] == nil)
        || (preferences[PREF_KEY_DATA_PATH] == nil)
        || (preferences[PREF_KEY_PORT_NUMBER] == nil)
        || (preferences[PREF_KEY_BIN_PATH] == nil))
    {
        NSLog(@"Preferences failed check.");
        NSLog(@"  Log:  %@", preferences[PREF_KEY_LOG_PATH]);
        NSLog(@"  Data: %@", preferences[PREF_KEY_DATA_PATH]);
        NSLog(@"  Port: %@", preferences[PREF_KEY_PORT_NUMBER]);
        NSLog(@"  Bin:  %@", preferences[PREF_KEY_BIN_PATH]);
    }
#endif
    [self.dataFilePath setStringValue:preferences[PREF_KEY_DATA_PATH]];
	[self.binPath setStringValue:preferences[PREF_KEY_BIN_PATH]];
	[self.logPath setStringValue:preferences[PREF_KEY_LOG_PATH]];
	[self.portNumber setStringValue:preferences[PREF_KEY_PORT_NUMBER]];
}

#pragma mark - Folder Search Methods

- (IBAction)onBrowseForDataFolder:(id)sender
{
	NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setTitle:@"Select PostgreSQL Data Location"];
    [openDlg setCanChooseFiles:NO];
    [openDlg setCanChooseDirectories:YES];
    [openDlg setAllowsMultipleSelection:NO];
    [openDlg setShowsHiddenFiles:YES];
    [openDlg setPrompt:@"Select"];

    if ( [openDlg runModal] == NSOKButton )
    {
            // Get an array containing the full names of the directory selected.
        NSArray* dirs = [openDlg URLs];
        
            // Loop through all the dirs and process them.
        for( NSURL *url in dirs)
        {
            NSLog(@"data location: %@", [url description]);
        }
    }
}

- (IBAction)onBrowseForBinFolder:(id)sender;
{
	NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setTitle:@"Select PostgreSQL Binary Files Location"];
    [openDlg setCanChooseFiles:NO];
    [openDlg setCanChooseDirectories:YES];
    [openDlg setAllowsMultipleSelection:NO];
    [openDlg setShowsHiddenFiles:YES];
    [openDlg setPrompt:@"Select"];
    
    if ( [openDlg runModal] == NSOKButton )
    {
            // Get an array containing the full names of the directory selected.
        NSArray* dirs = [openDlg URLs];
        
            // Loop through all the dirs and process them.
        for( NSURL *url in dirs)
        {
            NSLog(@"bin location: %@", [url description]);
        }
    }
}

- (IBAction)onBrowseForLogFolder:(id)sender;
{
	NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setTitle:@"Select PostgreSQL Log File Location"];
    [openDlg setCanChooseFiles:NO];
    [openDlg setCanChooseDirectories:YES];
    [openDlg setAllowsMultipleSelection:NO];
    [openDlg setShowsHiddenFiles:YES];
    [openDlg setPrompt:@"Select"];
    
    if ( [openDlg runModal] == NSOKButton )
    {
            // Get an array containing the full names of the directory selected.
        NSArray* dirs = [openDlg URLs];
        
            // Loop through all the dirs and process them.
        for( NSURL *url in dirs)
        {
            NSLog(@"log location: %@", [url description]);
        }
    }
}

#pragma mark - Button Action Methods

- (IBAction)onSetDataPath:(id)sender
{
	[NSApp stopModal];
	[NSApp endSheet:self.thisPanel];
	[self.thisPanel orderOut:self];
}

- (IBAction)onCancelSetDataPath:(id)sender
{
	[NSApp stopModal];
	[NSApp endSheet:self.thisPanel];
	[self.thisPanel orderOut:self];
}

- (IBAction)onRestoreDefaults:(id)sender;
{
    
}
@end
