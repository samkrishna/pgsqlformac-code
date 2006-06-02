/* MyOutlineView */

#import <Cocoa/Cocoa.h>
#import "ExplorerNode.h"

@interface MyOutlineView : NSOutlineView
{
	NSMenu *tableMenu;
	NSMenu *columnMenu;
	NSMenu *indexMenu;
	NSMenu *functionMenu;
	NSMenu *viewMenu;
	
	id menuActionTarget;
}

- (void)setMenuActionTarget:(id)theSQLDocument;

@end
