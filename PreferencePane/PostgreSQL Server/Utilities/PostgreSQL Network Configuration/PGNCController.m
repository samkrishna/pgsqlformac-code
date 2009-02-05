//
//  PGNCController.m
//  PostgreSQL Network Configuration
//
//  Created by Andy Satori on 11/13/08.
//  Copyright 2008 Druware Software Designs. All rights reserved.
//

#import "PGNCController.h"


@implementation PGNCController


-(id)init
{
    self = [super init];
	
	if (self != nil) {
		hbaConfiguration = nil;
	}
	
    return self;
}

-(void)awakeFromNib
{
	// check for the file, if it doesn't exist, get it.
	

	[self performSelector:@selector(fetchActiveConfiguration:) withObject:self afterDelay:0.0];
	return;
}

-(void)defaultEditPanel
{
	[database setString:@""];
	[userName setString:@""];
	
	[type removeAllItems];
	[type addItemWithTitle:@""];
	[type addItemWithTitle:@"local"];
	[type addItemWithTitle:@"host"];
	[type addItemWithTitle:@"hostssl"];
	[type addItemWithTitle:@"hostnossl"];
	
	[group removeAllItems];
	[group addItemWithTitle:@"Local"];
	[group addItemWithTitle:@"IPv4"];
	[group addItemWithTitle:@"IPv6"];
	
	[method removeAllItems];
	[method addItemWithTitle:@"md5"];
	[method addItemWithTitle:@"trust"];
	[method addItemWithTitle:@"reject"];
	[method addItemWithTitle:@"crypt"];
	[method addItemWithTitle:@"password"];
	[method addItemWithTitle:@"gss"];
	[method addItemWithTitle:@"sspi"];
	[method addItemWithTitle:@"krb5"];
	[method addItemWithTitle:@"ident"];
	[method addItemWithTitle:@"pam"];
	[method addItemWithTitle:@"ldap"];
	
	//[address setString:@""];

	[option setStringValue:@""]; // the user is going to have to know the options.
}

-(IBAction)onAddEntry:(id)sender
{
	[self defaultEditPanel];
	
	[NSApp beginSheet:connectionDetails
       modalForWindow:[NSApp mainWindow]
        modalDelegate:nil
       didEndSelector:nil
          contextInfo:nil];
	
	return;
}

-(IBAction)onEditEntry:(id)sender
{	
	[self preloadEditPanel];
	
	[NSApp beginSheet:connectionDetails
       modalForWindow:[NSApp mainWindow]
        modalDelegate:nil
       didEndSelector:nil
          contextInfo:nil];
	
	return;
}
-(IBAction)onDeleteEntry:(id)sender
{
	
}
-(IBAction)onEditOK:(id)sender
{
	
}

-(IBAction)onEditCancel:(id)sender
{
	
}



-(IBAction)fetchActiveConfiguration:(id)sender
{
	OSStatus myStatus;
    AuthorizationFlags myFlags = kAuthorizationFlagDefaults;
    AuthorizationRef myAuthorizationRef;
	
    NSBundle *bundleApp = [NSBundle mainBundle];
    NSString *pathToHelper = [bundleApp pathForResource:@"StartupHelper" ofType:nil];
	
	// myAuthorizationItem.AuthorizationString = "@
    myStatus = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, 
								   myFlags, &myAuthorizationRef);				
    if (myStatus != errAuthorizationSuccess) 
		return;
	
    do 
    {
		AuthorizationItem myItems = {kAuthorizationRightExecute, [pathToHelper length], (char *)[pathToHelper cStringUsingEncoding:NSASCIIStringEncoding], 0};
		AuthorizationRights myRights = {1, &myItems};
		
		myFlags =  kAuthorizationFlagDefaults |          
		kAuthorizationFlagInteractionAllowed |
		kAuthorizationFlagPreAuthorize |
		kAuthorizationFlagExtendRights;         
		myStatus = AuthorizationCopyRights (myAuthorizationRef, &myRights, 
											kAuthorizationEmptyEnvironment, myFlags, NULL );
		
        if (myStatus == errAuthorizationSuccess) 
		{
			const char *myToolPath = [pathToHelper cStringUsingEncoding:NSASCIIStringEncoding]; 
			char *myArguments[5];
			
			myArguments[0] = "/bin/cat";
			myArguments[1] = "/Library/PostgreSQL8/data/pg_hba.conf";
			myArguments[2] = ">";
			myArguments[3] = "/var/tmp/pg_hba.conf.in";
			myArguments[4] = NULL;
			
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
	
	// load the file.
	hbaConfiguration = [[PGHBAFile alloc] initWithContentsOfFile:@"/var/tmp/pg_hba.conf.in"];
	[[hbaConfiguration retain] autorelease];
	
	// set up the UI
	
	[rawSource setString:[hbaConfiguration source]];
	[allConnectionList setDataSource:[hbaConfiguration allConnections]];
	[allConnectionList reloadData];
}

-(IBAction)pushNewConfiguration:(id)sender
{	
	// save the file data
	[hbaConfiguration saveToFile:@"/var/tmp/pg_hba.conf.in"];
	
    OSStatus myStatus;
    AuthorizationFlags myFlags = kAuthorizationFlagDefaults;
    AuthorizationRef myAuthorizationRef;
	
    NSBundle *bundleApp = [NSBundle mainBundle];
    NSString *pathToHelper = [bundleApp pathForResource:@"StartupHelper" ofType:nil];
	
	// myAuthorizationItem.AuthorizationString = "@
    myStatus = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, 
								   myFlags, &myAuthorizationRef);				
    if (myStatus != errAuthorizationSuccess) 
		return;
	
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
			// write the file with changes
			const char *myToolPath = [pathToHelper cString]; 
			char *myArguments[5];
						 
			myArguments[0] = "/bin/cat";
			myArguments[1] = "/var/tmp/pg_hba.conf.in";
			myArguments[2] = ">";
			myArguments[3] = "/Library/PostgreSQL8/data/pg_hba.conf";
			myArguments[4] = NULL;

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
			
			
			// force a reload
			myArguments[0] = "/Library/StartupItems/PostgreSQL/PostgreSQL";
			myArguments[1] = "restart";
			myArguments[2] = "RELOAD";
			myArguments[3] = NULL;
			
			myCommunicationsPipe = NULL;
			
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
}


@end
