#import "SQLServiceManager.h"
#import "AGProcess.h"

#include <Security/Authorization.h>
#include <Security/AuthorizationTags.h>

@implementation SQLServiceManager

- (id)init
{
    [super init];
	
	command = nil;
	operation = nil;
	
    return self;
}

- (void)awakeFromNib
{
	BOOL isRunning = NO;
	
    [servers removeAllItems];
    [servers addItemWithTitle:@"(localhost)"];
	
	[services removeAllItems];
	[services addItemWithTitle:@"PostgresSQL"];
	
	[refresh setEnabled:NO];
	[addServer setEnabled:NO];
	
	isRunning = [self checkPostmasterStatus];
	
	[self updateButtonStatus:isRunning];
	return;
}

- (void)updateButtonStatus:(BOOL)isRunning
{	
	NSBundle *bundleApp = [NSBundle mainBundle];
	
	[startService setEnabled:(!isRunning)];
	[startServiceLabel setEnabled:(!isRunning)];
	
	[stopService setEnabled:isRunning];
	[stopServiceLabel setEnabled:isRunning];
	
	[restartService setEnabled:isRunning];
	[restartServiceLabel setEnabled:isRunning];
	
	if (isRunning)
	{
		// set the image to running
		NSString *imagePath = [bundleApp pathForResource:@"xserve-running" ofType:@"png"];
		NSImage *image = [[NSImage alloc] initWithContentsOfFile:imagePath];
		[serviceImage setImage:image];
		[status setStringValue:@"Current Status: Operational"];
		
	} else {
		// set the image to stopped
		NSString *imagePath = [bundleApp pathForResource:@"xserve-stopped" ofType:@"png"];
		NSImage *image = [[NSImage alloc] initWithContentsOfFile:imagePath];
		[serviceImage setImage:image];
		[status setStringValue:@"Current Status: Down"];
	}
	
	return;
}

- (BOOL)checkPostmasterStatus
{
	// check the current run state of postmaster
	NSString *serverProcessName = [[NSString alloc] initWithString:@"postgres"];
	NSArray *processes = [AGProcess allProcesses];
	int i;
	for (i = 0; i < [processes count]; i++)
	{
		AGProcess *process = (AGProcess *)[processes objectAtIndex:i];
		// NSLog(@"%s", [[process command] cString]);
		if ([[process command] isEqual:serverProcessName])
		{
			return YES;
		}
	}
	return NO;
}

- (IBAction)onAddServer:(id)sender
{
	// add a server to the servers that we can attach to 
	// (localhost) only at first
}

- (IBAction)onAutoStartChange:(id)sender
{
	// check to make sure that the StartupItem is in 
	// place and configured correctly
}

- (IBAction)onRefresh:(id)sender
{
	// attempt a connection to determine running/non running state
}

- (IBAction)onRestartService:(id)sender
{
	BOOL isRunning = [self checkPostmasterStatus];
	if (!isRunning) 
	{
		[self updateButtonStatus:isRunning];
		return;
	}
		
	if (command != nil) 
	{
		[command release];
		command = nil;
	}
 	command = [[NSString alloc] initWithString:@"/Library/StartupItems/PostgreSQL/PostgreSQL"];
	
	if (operation != nil)
	{
		[operation release];
		operation = nil;
	}
 	operation = [[NSString alloc] initWithString:@"restart"];
	
	[NSThread detachNewThreadSelector:@selector(execWithRights) toTarget:self withObject:nil];	

    return;	
}

- (IBAction)onStartService:(id)sender
{
	BOOL isRunning = [self checkPostmasterStatus];
	if (isRunning) 
	{
		[self updateButtonStatus:isRunning];
		return;
	}
	
	if (command != nil) 
	{
		[command release];
		command = nil;
	}
 	command = [[NSString alloc] initWithString:@"/Library/StartupItems/PostgreSQL/PostgreSQL"];
	
	if (operation != nil)
	{
		[operation release];
		operation = nil;
	}
 	operation = [[NSString alloc] initWithString:@"start"];
	
	[NSThread detachNewThreadSelector:@selector(execWithRights) toTarget:self withObject:nil];	
				
    return;	
}

- (IBAction)onStopService:(id)sender
{	
	BOOL isRunning = [self checkPostmasterStatus];
	if (!isRunning) 
	{
		[self updateButtonStatus:isRunning];
		return;
	}
		
	if (command != nil) 
	{
		[command release];
		command = nil;
	}
 	command = [[NSString alloc] initWithString:@"/Library/StartupItems/PostgreSQL/PostgreSQL"];
	
	if (operation != nil)
	{
		[operation release];
		operation = nil;
	}
 	operation = [[NSString alloc] initWithString:@"stop"];
	
	[working startAnimation:sender];
	
	[NSThread detachNewThreadSelector:@selector(execWithRights) toTarget:self withObject:nil];	

    return;	
}

- (void)execWithRights
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    OSStatus myStatus;
    AuthorizationFlags myFlags = kAuthorizationFlagDefaults;
    AuthorizationRef myAuthorizationRef;
	
    NSBundle *bundleApp = [NSBundle mainBundle];
    NSString *pathToHelper = [bundleApp pathForResource:@"StartupHelper" ofType:nil];
	
	// myAuthorizationItem.AuthorizationString = "@
    myStatus = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, 
		myFlags, &myAuthorizationRef);				
    if (myStatus != errAuthorizationSuccess) 
		return NO;

    do 
    {
		AuthorizationItem myItems = {kAuthorizationRightExecute, [pathToHelper length], [pathToHelper cString], 0};
		AuthorizationRights myRights = {1, &myItems};

		myFlags =  kAuthorizationFlagDefaults |          
				kAuthorizationFlagInteractionAllowed |
				kAuthorizationFlagPreAuthorize |
				kAuthorizationFlagExtendRights;         
		myStatus = AuthorizationCopyRights (myAuthorizationRef, &myRights, 
			kAuthorizationEmptyEnvironment, myFlags, NULL );
           
        if (myStatus == errAuthorizationSuccess) 
		{
			const char *myToolPath = [pathToHelper cString]; 
			char *myArguments[3];
			
			myArguments[0] = [command cString];
			myArguments[1] = [operation cString];
			myArguments[2] = NULL;
			
			FILE *myCommunicationsPipe = NULL;
			char myReadBuffer[128];

			myFlags = kAuthorizationFlagDefaults;			
			myStatus = AuthorizationExecuteWithPrivileges(myAuthorizationRef, 
					myToolPath, myFlags, myArguments, &myCommunicationsPipe);      

			if (myStatus == errAuthorizationSuccess)
			for(;;)
			{
				int bytesRead = read (fileno (myCommunicationsPipe),
						myReadBuffer, sizeof (myReadBuffer));
				if (bytesRead < 1) break;
				NSLog(@"%s", myReadBuffer);
			}			
		}
    } while (0);

    AuthorizationFree (myAuthorizationRef, kAuthorizationFlagDefaults);                

    if (myStatus) NSLog(@"Status: %i\n", myStatus);
	
	sleep(3);
		
	// update the buttons
	BOOL isRunning = [self checkPostmasterStatus];
	[self updateButtonStatus:isRunning];
	[working stopAnimation:nil];

	[pool release];
	[NSThread exit];
	
    return;
}


@end

