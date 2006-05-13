#import "MyOutlineView.h"

@implementation MyOutlineView

- (NSMenu *) menuForEvent:(NSEvent *) event {
	int theRow =[self selectedRow];
	if (theRow == -1)
	{
		return [self menu];
	}
	
	id selectedItem = [self itemAtRow:theRow];
	if ([[selectedItem explorerType] isLike:@"Table Name"])
	{
		if (!tableMenu)
		{
			NSMenuItem *newItem;
			tableMenu = [[NSMenu alloc] init];
			
			newItem = [[NSMenuItem alloc] init];
			[newItem setTitle:@"CREATE TABLE <tab> (<col>)"];
			[newItem setTarget: menuActionTarget];
			[newItem setAction: @selector(onSelectCreateTableMenuItem:)];
			[tableMenu addItem: newItem];
			
			newItem = [[NSMenuItem alloc] init];
			[newItem setTitle:@"CREATE TABLE <table_backup_date> AS SELECT * from <tab>"];
			[tableMenu addItem: newItem];

			newItem = [[NSMenuItem alloc] init];
			[newItem setTitle:@"ALTER TABLE <tab> RENAME TO <new tab>"];
			[tableMenu addItem: newItem];

			newItem = [[NSMenuItem alloc] init];
			[newItem setTitle:@"VACUUM FULL <tab>"];
			[tableMenu addItem: newItem];

			newItem = [[NSMenuItem alloc] init];
			[newItem setTitle:@"TRUNCATE TABLE <tab>"];
			[tableMenu addItem: newItem];

			newItem = [[NSMenuItem alloc] init];
			[newItem setTitle:@"DROP TABLE <tab>"];
			[tableMenu addItem: newItem];
		}
		return tableMenu;
	}
	else if ([[selectedItem explorerType] isLike:@"Column Name"])
	{
		if (!columnMenu)
		{
			NSMenuItem *newItem;
			columnMenu = [[NSMenu alloc] init];
			
			newItem = [[NSMenuItem alloc] init];
			[newItem setTitle:@"ALTER TABLE <tab> DROP COLUMN <col>"];
			[columnMenu addItem: newItem];
			
			newItem = [[NSMenuItem alloc] init];
			[newItem setTitle:@"ALTER TABLE <tab> ADD COLUMN <col> <type>"];
			[columnMenu addItem: newItem];

			newItem = [[NSMenuItem alloc] init];
			[newItem setTitle:@"ALTER TABLE <tab> RENAME COLUMN <col> TO <new col>"];
			[columnMenu addItem: newItem];

			newItem = [[NSMenuItem alloc] init];
			[newItem setTitle:@"SELECT <col(s)> FROM <tab>"];
			[columnMenu addItem: newItem];
			
			newItem = [[NSMenuItem alloc] init];
			[newItem setTitle:@"CREATE TABLE <tab> (<sel cols>)"];
			[columnMenu addItem: newItem];
		}
		return columnMenu;
	}
	
	return [self menu];
}

- (void)setMenuActionTarget:(id) theSQLDocument
{	
	[theSQLDocument retain];
	[menuActionTarget release];
	menuActionTarget = theSQLDocument;
}
@end
