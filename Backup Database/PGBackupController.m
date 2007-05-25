#import "PGBackupController.h"

@implementation PGBackupController

- (id)init
{
    [super init];
	
	conn = nil;
	
    return self;
}

- (void)awakeFromNib
{	
	conn = [[[[Connection alloc] init] autorelease] retain];
	
	// set the defaults
	[databaseList removeAllItems];
	[backupFormat removeAllItems];
	[encodingList removeAllItems];
	
	[backupFormat addItemWithTitle:@"Plain Text"];
	[backupFormat addItemWithTitle:@"Tar"];
	[backupFormat addItemWithTitle:@"Custom"];
	
	[encodingList addItemWithTitle:@"DEFAULT"];
	[encodingList addItemWithTitle:@"SQL_ASCII"];
	[encodingList addItemWithTitle:@"EUC_JP"];
	[encodingList addItemWithTitle:@"EUC_CN"];
	[encodingList addItemWithTitle:@"EUC_KR"];
	[encodingList addItemWithTitle:@"EUC_TW"];
	[encodingList addItemWithTitle:@"UNICODE"];
	[encodingList addItemWithTitle:@"MULE_INTERNAL"];
	[encodingList addItemWithTitle:@"LATIN1"];
	[encodingList addItemWithTitle:@"LATIN2"];
	[encodingList addItemWithTitle:@"LATIN3"];
	[encodingList addItemWithTitle:@"LATIN4"];
	[encodingList addItemWithTitle:@"LATIN5"];
	[encodingList addItemWithTitle:@"KOI8"];
	[encodingList addItemWithTitle:@"WIN"];
	[encodingList addItemWithTitle:@"ALT"];
	
	[toFolder setStringValue:[[NSString stringWithString:@"~/Desktop/"] stringByExpandingTildeInPath]];
	
	// load the rest from a plist
	
	return;
}

- (void)openPanelDidEnd:(NSOpenPanel *)sheet 
			 returnCode:(int)returnCode 
			contextInfo:(void *)x
{
    if (returnCode == NSOKButton)
    {
        [toFolder setStringValue:[sheet filename]];
    }
}

- (IBAction)onBack:(id)sender
{
	[tabs selectPreviousTabViewItem:sender];
	[backButton setEnabled:NO];
}

- (IBAction)onBrowseForFolder:(id)sender
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:NO];
    [panel setCanChooseDirectories:YES];
    [panel beginSheetForDirectory:nil 
							 file:nil 
							types:nil
				   modalForWindow:[NSApp mainWindow]
					modalDelegate:self
				   didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) 
					  contextInfo:nil];
}

- (IBAction)onCancel:(id)sender
{
	[NSApp terminate:sender];
}

- (IBAction)onDataOnly:(id)sender
{
	[useSchemaOnly setEnabled:(!([useDataOnly state] == NSOnState))];
}

- (IBAction)onNext:(id)sender
{	// based upon the current page, determine the needed action
	switch ([tabs indexOfTabViewItem:[tabs selectedTabViewItem]])
	{
		case 0: // connection data
			if ([[server stringValue] length] == 0) { return; }
			if ([[port stringValue] length] == 0) { return; }
			if ([[userName stringValue] length] == 0) { return; }
			
			[conn setUserName:[userName stringValue]];
			[conn setHost:[server stringValue]];
			[conn setPort:[port stringValue]];
			[conn setPassword:[password stringValue]];
			
			if (![conn connect])
			{
				// show an alert because it failed to connect.
				
				NSAlert *alert = [NSAlert 
					alertWithMessageText:@"Database Connection failed" 
						   defaultButton:@"OK" alternateButton:nil 
							 otherButton:nil informativeTextWithFormat:@"%@", [conn errorDescription]]; 
				[alert beginSheetModalForWindow:[NSApp mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
				return;
			}
				
			// fetch the databaselist and update it
			int i;
			[databaseList removeAllItems];
			// [databaseList addItemWithTitle:@"-- all --"];

			// add the -- all databases -- option to the list for dumpall
			for (i = 0; i < [[conn databases] count]; i++)
			{
				[databaseList addItemWithTitle:[[[conn databases] itemAtIndex:i] name]];
			}
				
			[asFile setStringValue:[NSString stringWithFormat:@"%@.pgbackup",[[databaseList selectedItem] title]]];				
								
			[backButton setEnabled:YES];
			
			break;
		case 1: // set the options
			if ([[toFolder stringValue] length] == 0) { return; }
			if ([[asFile stringValue] length] == 0) { return; }
			
			[schemaList removeAllItems];
			[schemaList addItemWithTitle:@"-- all --"];
			[tableList removeAllItems];
			[tableList addItemWithTitle:@"-- all --"];			
			
			if ([databaseList indexOfSelectedItem] > 0)
			{
				if ([conn isConnected])
				{
					[conn disconnect];
				}
				
				if ([[[databaseList selectedItem]  title] length] == 0)
				{
					[conn setDbName:@""];
				} else {
					[conn setDbName:[[databaseList selectedItem] title]];
				}
				
				// perform the connection
				if (![conn connect])
				{
					NSLog(@"Connection failed.");
					return;
				}

				// fetch the schema list
				RecordSet *rs = [conn execQuery:@"select distinct schemaname from pg_tables"];
				int x = 0;
				for (x = 0; x < [rs count]; x++)
				{
					[schemaList addItemWithTitle:
						[[[[rs itemAtIndex:x] fields] itemAtIndex:0] value]];
				}
				
				// fetch the table list
				rs = [conn execQuery:@"select distinct tablename from pg_tables order by tablename asc"];
				for (x = 0; x < [rs count]; x++)
				{
					[tableList addItemWithTitle:
						[[[[rs itemAtIndex:x] fields] itemAtIndex:0] value]];
				}
				
			}
			
			// disable the controls where appropriate if this is an all
			[useRestrictSchema setEnabled:([databaseList indexOfSelectedItem] > 0)];
			[useRestrictTable setEnabled:([databaseList indexOfSelectedItem] > 0)];
			[useEncoding setEnabled:([databaseList indexOfSelectedItem] > 0)];
			[useCreateDatabase setEnabled:([databaseList indexOfSelectedItem] > 0)];
				
			[backButton setEnabled:YES];
			
			break;
		case 2: // set up the task and call the thread
			[progress startAnimation:self];
			[backButton setEnabled:NO];
			
			
			// [NSThread detachNewThreadSelector:@selector(createUser) toTarget:self withObject:nil];
			 [self performSelector:@selector(execPGDump) withObject:self afterDelay:0.5];
			break;
		default: // all done
			[NSApp terminate:sender];
			break;
	}
	
	[tabs selectNextTabViewItem:sender];
	return;	
}

- (IBAction)onRestrictSchema:(id)sender
{
	[schemaList setEnabled:([useRestrictSchema state] == NSOnState)];
}

- (IBAction)onRestrictTable:(id)sender
{
	[tableList setEnabled:([useRestrictTable state] == NSOnState)];
}

- (IBAction)onSchemaOnly:(id)sender
{
	[useDataOnly setEnabled:(!([useSchemaOnly state] == NSOnState))];
}

- (IBAction)onUseEncoding:(id)sender
{
	[encodingList setEnabled:([useEncoding state] == NSOnState)];
}

- (IBAction)onSelectDatabase:(id)sender
{
	// set the asFile to the database_name.current_short_date_time.pgbackup
	[asFile setStringValue:[NSString stringWithFormat:@"%@.pgbackup",[[databaseList selectedItem] title]]]; 
}

// Window Delegate Implementations

- (void)windowWillClose:(NSNotification *)aNotification
{
	if ([conn isConnected])
	{
		[conn disconnect];
		[conn release];
		conn = nil;
	}
	
    [NSApp terminate:self];
    return;
}


- (void)execPGDump
{
	//NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(checkBackupTaskStatus:) 
												 name:NSTaskDidTerminateNotification 
											   object:nil];	
	
	NSTask *task = [[NSTask alloc] init];
	outputPipe = [NSPipe pipe];
	errorPipe = [NSPipe pipe];
	
	NSMutableArray *args = [[NSMutableArray alloc] init];
	NSBundle *bundleApp = [NSBundle mainBundle];
	NSString *pathToTool;
	
	processAllDBs = NO;
	//processAllDBs = ([databaseList indexOfSelectedItem] == 0);
	//if (processAllDBs)
	//{
	//	pathToTool = [bundleApp pathForResource:@"pg_dumpall" ofType:nil];
	//} else {
		pathToTool = [bundleApp pathForResource:@"pg_dump" ofType:nil];		
	//}

	[task setLaunchPath:pathToTool];
	
	// server
	[args addObject:@"-h"];
	[args addObject:[server stringValue]];
	[args addObject:@"-p"];
	[args addObject:[port stringValue]];
	[args addObject:@"-U"];
	[args addObject:[userName stringValue]];
	if ([[password stringValue] length] > 0){
		[args addObject:@"-W"];
		[args addObject:[password stringValue]];		
	}
	
	// options
	if ([useDataOnly state] == NSOnState) {
		[args addObject:@"-a"];	
	}
	if ([useSchemaOnly state] == NSOnState) {
		[args addObject:@"-s"];	
	}
	if ([useClean state] == NSOnState) {
		[args addObject:@"-c"];	
	}
	if ([useInsert state] == NSOnState) {
		[args addObject:@"-d"];	
	}
	if ([useInsertWithColumns state] == NSOnState) {
		[args addObject:@"-D"];	
	}
	if ([useOIDs state] == NSOnState) {
		[args addObject:@"-o"];	
	}	
	if ([usePreventBackups state] == NSOnState) {
		[args addObject:@"--disable-triggers"];	
	}	
	if ([usePreventOwnership state] == NSOnState) {
		[args addObject:@"-O"];	
	}	
	if ([useDollarQuoting state] == NSOffState) {
		[args addObject:@"--disable-dollar-quoting"];	
	}	
	
	// for use with pg_dump (pg_dumpall doesn't support)
	if (!processAllDBs) {
		// destination file
		[args addObject:@"-f"];
		[args addObject:[NSString stringWithFormat:@"%@/%@", [toFolder stringValue], [asFile stringValue]]];
		
		[args addObject:@"-F"];
		switch ([backupFormat indexOfSelectedItem])
		{
			case 0:
				[args addObject:@"p"];
				break;
			case 1:
				[args addObject:@"t"];
				break;
			default:
				[args addObject:@"c"];
				break;
		}
		
		if ([useCreateDatabase state] == NSOnState) {
			[args addObject:@"-C"];	
		}
		
		if ([useEncoding state] == NSOnState) {
			[args addObject:@"-E"];	
			[args addObject:[[encodingList selectedItem] title]];
		}		
		
		if ([useRestrictSchema state] == NSOnState) {
			[args addObject:@"-n"];	
			[args addObject:[[schemaList selectedItem] title]];
		}		
		
		if ([useRestrictTable state] == NSOnState) {
			[args addObject:@"-t"];	
			[args addObject:[[tableList selectedItem] title]];
		}		
		
		// database
		[args addObject:[[databaseList selectedItem] title]];		
	} else {
		// [args addObject:@">"];
		// [args addObject:[NSString stringWithFormat:@"%@/%@", [toFolder stringValue], [asFile stringValue]]];		
	}
		
	[task setArguments:args];
	 
	[task setStandardOutput:outputPipe];
	[task setStandardError:errorPipe];
	[task launch];
	 
	return;
}

- (void)execVacuumDB
{
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(checkVacuumTaskStatus:) 
												 name:NSTaskDidTerminateNotification 
											   object:nil];	
	
	outputPipe = [NSPipe pipe];
	errorPipe = [NSPipe pipe];
	
	NSTask *task = [[NSTask alloc] init];
	
	NSMutableArray *args = [[NSMutableArray alloc] init];
	NSBundle *bundleApp = [NSBundle mainBundle];
	NSString *pathToTool = [bundleApp pathForResource:@"vacuumdb" ofType:nil];
	
	[task setLaunchPath:pathToTool];
	
	// server
	[args addObject:@"-h"];
	[args addObject:[server stringValue]];
	[args addObject:@"-p"];
	[args addObject:[port stringValue]];
	[args addObject:@"-U"];
	[args addObject:[userName stringValue]];
	if ([[password stringValue] length] > 0){
		[args addObject:@"-W"];
		[args addObject:[password stringValue]];		
	}
	
	[args addObject:@"-f"];
	
	if (processAllDBs)
	{
		[args addObject:@"-a"];		
	}
	
	
	// database
	[args addObject:[[databaseList selectedItem] title]];
	
	[task setArguments:args];
	
	[task setStandardOutput:outputPipe];
	[task setStandardError:errorPipe];
	[task launch];
	
	return;
}


- (void)checkBackupTaskStatus:(NSNotification *)aNotification {
	[[NSNotificationCenter defaultCenter] removeObserver:self  
													name:NSTaskDidTerminateNotification 
												  object:nil];	
	
	NSFileHandle *outputReader = [errorPipe fileHandleForReading];
	NSData *inData;
	inData = [outputReader readDataToEndOfFile];
	
	NSString *result = [[NSString alloc] initWithData:inData encoding:NSASCIIStringEncoding];
	[outputReader release];
	
	if ([result length] > 0)
	{
		[results setString:result];
		return;
	}	else {
		[results setString:@"Backup Successful"];
	}

	if ([useVacuumDB state] == NSOffState)
	{
		[progress stopAnimation:self];
		[backButton setEnabled:NO];
		[nextButton setTitle:@"Finish"];
	} else {
		[self execVacuumDB];
	}
	
}

- (void)checkVacuumTaskStatus:(NSNotification *)aNotification {
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(checkVacuumTaskStatus:) 
												 name:NSTaskDidTerminateNotification 
											   object:nil];	
	
	NSFileHandle *outputReader = [errorPipe fileHandleForReading];
	NSData *inData;
	inData = [outputReader readDataToEndOfFile];
	
	NSString *result = [[NSString alloc] initWithData:inData encoding:NSASCIIStringEncoding];
	[outputReader release];

	if ([result length] > 0)
	{
		[results setString:result];
	} else {
		[results setString:[NSString stringWithFormat:@"%@\n%@", [results string], @"Vacuum Successful"]];
	}
	
	// if this is an ALL then loop to the next DB in the list.
	
	[progress stopAnimation:self];
	[backButton setEnabled:NO];
	[nextButton setTitle:@"Finish"];
	
}

@end
