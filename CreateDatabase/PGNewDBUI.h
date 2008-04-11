/* PGNewDBUI */

#import <Cocoa/Cocoa.h>
#import <PGSQLKit/PGSQLKit.h>

@interface PGNewDBUI : NSObject
{
    IBOutlet NSButton *back;
    IBOutlet NSPopUpButton *encoding;
    IBOutlet NSButton *next;
    IBOutlet NSTextField *owner;
    IBOutlet NSSecureTextField *password;
    IBOutlet NSTextField *port;
    IBOutlet NSTextField *database;
    IBOutlet NSTextView *resultOutput;
    IBOutlet NSProgressIndicator *resultStatus;
    IBOutlet NSTextField *server;
    IBOutlet NSTextField *tableSpace;
    IBOutlet NSTabView *tabs;
    IBOutlet NSPopUpButton *templates;
    IBOutlet NSTextField *user;
    IBOutlet NSWindow *window;
	IBOutlet NSButton *versionSevenFeaturesOnly;
	
	PGSQLConnection *conn;
}
- (IBAction)onBack:(id)sender;
- (IBAction)onCancel:(id)sender;
- (IBAction)onNext:(id)sender;

- (void)createDatabase;

@end
