/* MyOutlineView */

#import <Cocoa/Cocoa.h>

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
