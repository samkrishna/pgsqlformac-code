/* PGBackupController */

#import <Cocoa/Cocoa.h>
#import <pgCocoaDB/Connection.h>
#import <pgCocoaDB/Databases.h>
#import <pgCocoaDB/RecordSet.h>

@interface PGBackupController : NSObject
{
	Connection *conn;
	NSPipe *outputPipe;
	NSPipe *errorPipe;
	BOOL processAllDBs;
	
    IBOutlet NSTextField *asFile;
    IBOutlet NSButton *backButton;
    IBOutlet NSPopUpButton *backupFormat;
    IBOutlet NSPopUpButton *databaseList;
    IBOutlet NSPopUpButton *encodingList;
    IBOutlet NSButton *nextButton;
    IBOutlet NSSecureTextField *password;
    IBOutlet NSTextField *port;
    IBOutlet NSProgressIndicator *progress;
    IBOutlet NSTextView *results;
    IBOutlet NSPopUpButton *schemaList;
    IBOutlet NSTextField *server;
    IBOutlet NSPopUpButton *tableList;
    IBOutlet NSTabView *tabs;
    IBOutlet NSTextField *toFolder;
	IBOutlet NSButton *useClean;
    IBOutlet NSButton *useCreateDatabase;
    IBOutlet NSButton *useDataOnly;
    IBOutlet NSButton *useDollarQuoting;
    IBOutlet NSButton *useEncoding;
    IBOutlet NSButton *useInsert;
    IBOutlet NSButton *useInsertWithColumns;
    IBOutlet NSButton *useOIDs;
    IBOutlet NSButton *usePreventBackups;
    IBOutlet NSButton *usePreventOwnership;
    IBOutlet NSButton *useRestrictSchema;
    IBOutlet NSButton *useRestrictTable;
    IBOutlet NSTextField *userName;
    IBOutlet NSButton *useSchemaOnly;
    IBOutlet NSButton *useVacuumDB;
}
- (IBAction)onBack:(id)sender;
- (IBAction)onBrowseForFolder:(id)sender;
- (IBAction)onCancel:(id)sender;
- (IBAction)onDataOnly:(id)sender;
- (IBAction)onNext:(id)sender;
- (IBAction)onRestrictSchema:(id)sender;
- (IBAction)onRestrictTable:(id)sender;
- (IBAction)onSchemaOnly:(id)sender;
- (IBAction)onUseEncoding:(id)sender;
- (IBAction)onSelectDatabase:(id)sender;

@end
