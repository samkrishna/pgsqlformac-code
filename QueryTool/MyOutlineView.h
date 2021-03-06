/* MyOutlineView */

#import <Cocoa/Cocoa.h>
#import <pgCocoaDB/ExplorerModel.h>
#import "QueryTool.h"

@interface MyOutlineView : NSOutlineView
{
	NSMenu *tableMenu;
	NSMenu *columnMenu;
	NSMenu *indexMenu;
	NSMenu *functionMenu;
	NSMenu *viewMenu;
	
	id menuActionTarget;
	
	NSFont *currentFont;
}

- (void)setMenuActionTarget:(id)theSQLDocument;
- (void)changeFont:(id)sender;
- (NSFont *)currentFont;
- (void)setCurrentFont:(NSFont *)theFont;

@end
