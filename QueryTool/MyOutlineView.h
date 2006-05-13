/* MyOutlineView */

#import <Cocoa/Cocoa.h>

@interface MyOutlineView : NSOutlineView
{
	NSMenu *tableMenu;
	NSMenu *columnMenu;
	
	id menuActionTarget;
}

- (void)setMenuActionTarget:(id)theSQLDocument;

@end
