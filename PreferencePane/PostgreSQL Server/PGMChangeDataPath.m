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
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;

@property (weak) IBOutlet NSPanel *thisPanel;
@property (weak) NSWindow *parentWindow;;

@property (strong) SaveCallback saveCallback;
@property (strong) CancelCallback cancelCallback;

@property (strong) NSMutableDictionary *prefDictionary;

@end

@implementation PGMChangeDataPath

#pragma mark - Lifecycle Methods

- (void)dealloc
{
    self.currentPath = nil;
    self.saveCallback = nil;
    self.cancelCallback = nil;
}

- (instancetype)init
{
    return [self initWithSaveCallback:nil cancelCallback:nil];
}

- (instancetype)initWithSaveCallback:(SaveCallback)saveBlock cancelCallback:(CancelCallback)cancelBlock
{
    self = [super init];
    if (self) {
        self.saveCallback = saveBlock;
        self.cancelCallback = cancelBlock;
    }
    return self;
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

- (NSMutableDictionary *)getSavedPreferences
{
    NSMutableDictionary *preferences;
	NSFileManager *fm = [[NSFileManager alloc] init];
	if ([fm fileExistsAtPath:DRUWARE_PREF_FILE_NSSTRING])
	{
            // replace with NSUserDefaults/NSGlobalDomain
		self.prefDictionary = [[NSMutableDictionary alloc] initWithContentsOfFile:DRUWARE_PREF_FILE_NSSTRING];
        NSLog(@"read pref dict\n%@", self.prefDictionary);
        
            // Check that all preferences are set by this time.
            // They should be.
        NSParameterAssert(self.prefDictionary[PREF_KEY_LOG_PATH] != nil);
        NSParameterAssert(self.prefDictionary[PREF_KEY_DATA_PATH] != nil);
        NSParameterAssert(self.prefDictionary[PREF_KEY_PORT_NUMBER] != nil);
        NSParameterAssert(self.prefDictionary[PREF_KEY_BIN_PATH] != nil);
        
            // Update the GUI
        [self.dataFilePath setStringValue:self.prefDictionary[PREF_KEY_DATA_PATH]];
        [self.binPath setStringValue:self.prefDictionary[PREF_KEY_BIN_PATH]];
        [self.logPath setStringValue:self.prefDictionary[PREF_KEY_LOG_PATH]];
        [self.portNumber setStringValue:self.prefDictionary[PREF_KEY_PORT_NUMBER]];
        return preferences;
    }
    else
    {
        NSLog(@"Preference file not found.");
        [Debug debugErrorBreakInCode:@""];
        
        [self.dataFilePath setStringValue:@""];
        [self.binPath setStringValue:@""];
        [self.logPath setStringValue:@""];
        [self.portNumber setStringValue:@""];
    }
    return nil;
}

#pragma mark - Folder Search Methods

- (IBAction)onBrowseForDataFolder:(id)sender
{
	NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setTitle:@"Select PostgreSQL Data Files Folder"];
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
#ifdef DEBUG
            NSLog(@"data location: '%@'", [url path]);
#endif
            [self.dataFilePath setStringValue:[url path]];
        }
    }
}

- (IBAction)onBrowseForBinFolder:(id)sender;
{
	NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setTitle:@"Select PostgreSQL Executable File Folder"];
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
#ifdef DEBUG
            NSLog(@"bin location: '%@'", [url path]);
#endif
            [self.binPath setStringValue:[url path]];
        }
    }
}

- (IBAction)onBrowseForLogFolder:(id)sender;
{
	NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setTitle:@"Select PostgreSQL Log File Folder"];
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
#ifdef DEBUG
            NSLog(@"log location: '%@'", [url path]);
#endif
            [self.logPath setStringValue:[[url path] stringByAppendingPathComponent:PREF_LOG_FILE_NAME_DEFAULT]];
        }
    }
}

#pragma mark - Button Action Methods

- (void)closePanel
{
    DEBUG_LOG_METHOD
    [self.progressIndicator stopAnimation:self];
    
	[NSApp endSheet:self.thisPanel];
	[self.thisPanel orderOut:self];
}

- (IBAction)onSave:(id)sender
{
    DEBUG_LOG_METHOD
    [self.progressIndicator startAnimation:self];
    
    BOOL dirty = NO;
    if ( ! [self.prefDictionary[PREF_KEY_DATA_PATH] isEqualToString: [self.dataFilePath stringValue]])
    {
        self.prefDictionary[PREF_KEY_DATA_PATH] = [self.dataFilePath stringValue];
        dirty = YES;
    }
    
    if ( ! [self.prefDictionary[PREF_KEY_BIN_PATH] isEqualToString: [self.binPath stringValue]])
    {
        self.prefDictionary[PREF_KEY_BIN_PATH] = [self.binPath stringValue];
        dirty = YES;
    }
    
    if ( ! [self.prefDictionary[PREF_KEY_LOG_PATH] isEqualToString:[self.logPath stringValue]])
    {
        self.prefDictionary[PREF_KEY_LOG_PATH] = [self.logPath stringValue];
        dirty = YES;
    }
    
    if ( ! [self.prefDictionary[PREF_KEY_PORT_NUMBER] isEqualToString: [self.portNumber stringValue]])
    {
        self.prefDictionary[PREF_KEY_PORT_NUMBER] = [self.portNumber stringValue];
        dirty = YES;
    }
    
    NSParameterAssert(self.saveCallback != nil);
    [NSApp stopModal];
    
    if ((dirty) && (self.saveCallback != nil))
    {
        NSLog(@"saved pref dict\n%@", self.prefDictionary);
            //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_async(dispatch_get_main_queue(),^{
            self.saveCallback(self.prefDictionary);
        });
            // wait for async events to complete, the file save takes some time and is not always ready for the
            // main window if there is not a delay here.
        [self performSelector:@selector(closePanel) withObject:nil afterDelay:2.0];
    } else {
        [self closePanel];
    }
}

- (IBAction)onCancel:(id)sender
{
    DEBUG_LOG_METHOD
    if (self.cancelCallback != nil)
    {
        self.cancelCallback();
    }
    
	[NSApp stopModal];
	[NSApp endSheet:self.thisPanel];
	[self.thisPanel orderOut:self];
}

- (IBAction)onRestoreDefaults:(id)sender;
{
        // Update the GUI
    [self.dataFilePath setStringValue:PREF_DATA_PATH_DEFAULT];
    [self.binPath setStringValue:PREF_BIN_PATH_DEFAULT];
    [self.logPath setStringValue:[PREF_LOG_PATH_DEFAULT stringByAppendingPathComponent:PREF_LOG_FILE_NAME_DEFAULT]];
    [self.portNumber setStringValue:PREF_PORT_NUMBER_DEFAULT];
}

#pragma mark - NSTextDelegate Methods

- (void)textDidEndEditing:(NSNotification *)aNotification
{
        // TODO validate text changes
}

@end
