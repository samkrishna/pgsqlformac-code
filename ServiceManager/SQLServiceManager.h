/* SQLServiceManager */

#import <Cocoa/Cocoa.h>


@interface SQLServiceManager : NSObject
{
    IBOutlet NSButton *addServer;
    IBOutlet NSButton *autostartOption;
    IBOutlet NSProgressIndicator *progress;
    IBOutlet NSButton *refresh;
    IBOutlet NSButton *restartService;
    IBOutlet NSTextField *restartServiceLabel;
    IBOutlet NSPopUpButton *servers;
    IBOutlet NSImageView *serviceImage;
    IBOutlet NSPopUpButton *services;
    IBOutlet NSButton *startService;
    IBOutlet NSTextField *startServiceLabel;
    IBOutlet NSTextField *status;
    IBOutlet NSButton *stopService;
    IBOutlet NSTextField *stopServiceLabel;
    IBOutlet NSWindow *window;
	IBOutlet NSProgressIndicator *working;
	
	NSString *command;
	NSString *operation;
}

- (BOOL)checkPostmasterStatus;
- (void)updateButtonStatus:(BOOL)isRunning;

- (IBAction)onAddServer:(id)sender;
- (IBAction)onAutoStartChange:(id)sender;
- (IBAction)onRefresh:(id)sender;
- (IBAction)onRestartService:(id)sender;
- (IBAction)onStartService:(id)sender;
- (IBAction)onStopService:(id)sender;
@end
