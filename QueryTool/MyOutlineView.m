#import "MyOutlineView.h"

@implementation MyOutlineView

- (NSMenu *) menuForEvent:(NSEvent *) event
{
	int theRow =[self selectedRow];
	if (theRow == -1)
	{
		return [self menu];
	}
	
	ExplorerNode *selectedItem = [self itemAtRow:theRow];
	if ([[selectedItem explorerType] isLike:@"Table Name"])
	{
		if (!tableMenu)
		{
			NSMenuItem *newItem;
			tableMenu = [[NSMenu alloc] init];
			
			newItem = [[NSMenuItem alloc] init];
			[newItem setTitle:@"SELECT * FROM <tab>"];
			[newItem setTarget: menuActionTarget];
			[newItem setAction: @selector(onSelectSelectTableMenuItem:)];
			[tableMenu addItem: newItem];

			newItem = [[NSMenuItem alloc] init];
			[newItem setTitle:@"CREATE TABLE <tab> (<all col>)"];
			[newItem setTarget: menuActionTarget];
			[newItem setAction: @selector(onSelectCreateTableMenuItem:)];
			[tableMenu addItem: newItem];
			
			newItem = [[NSMenuItem alloc] init];
			[newItem setTitle:@"CREATE TABLE <tab_backup_date> AS SELECT * from <tab>"];
			[newItem setTarget: menuActionTarget];
			[newItem setAction: @selector(onSelectCreateBakTableMenuItem:)];
			[tableMenu addItem: newItem];

			newItem = [[NSMenuItem alloc] init];
			[newItem setTitle:@"ALTER TABLE <tab> RENAME TO <new tab>"];
			[newItem setTarget: menuActionTarget];
			[newItem setAction: @selector(onSelectAlterTableRenameMenuItem:)];
			[tableMenu addItem: newItem];

			newItem = [[NSMenuItem alloc] init];
			[newItem setTitle:@"VACUUM FULL <tab>"];
			[newItem setTarget: menuActionTarget];
			[newItem setAction: @selector(onSelectVacuumTableMenuItem:)];
			[tableMenu addItem: newItem];

			newItem = [NSMenuItem separatorItem];
			[tableMenu addItem: newItem];

			newItem = [[NSMenuItem alloc] init];
			[newItem setTitle:@"TRUNCATE TABLE <tab>"];
			[newItem setTarget: menuActionTarget];
			[newItem setAction: @selector(onSelectTruncateTableMenuItem:)];
			[tableMenu addItem: newItem];

			newItem = [[NSMenuItem alloc] init];
			[newItem setTitle:@"DROP TABLE <tab>"];
			[newItem setTarget: menuActionTarget];
			[newItem setAction: @selector(onSelectDropTableMenuItem:)];
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
			[newItem setTitle:@"SELECT <col(s)> FROM <tab>"];
			[newItem setTarget: menuActionTarget];
			[newItem setAction: @selector(onSelectColSelectMenuItem:)];
			[columnMenu addItem: newItem];

			newItem = [[NSMenuItem alloc] init];
			[newItem setTitle:@"col, col, col..."];
			[newItem setTarget: menuActionTarget];
			[newItem setAction: @selector(onSelectColsMenuItem:)];
			[columnMenu addItem: newItem];

			newItem = [[NSMenuItem alloc] init];
			[newItem setTitle:@"CREATE INDEX <name> ON <tab> (<cols>)"];
			[newItem setTarget: menuActionTarget];
			[newItem setAction: @selector(onSelectCreateIndexOnColsMenuItem:)];
			[columnMenu addItem: newItem];

			newItem = [[NSMenuItem alloc] init];
			[newItem setTitle:@"CREATE UNIQUE INDEX <tab01_idx> ON <tab> (<cols>)"];
			[newItem setTarget: menuActionTarget];
			[newItem setAction: @selector(onSelectCreateUniqIndexOnColsMenuItem:)];
			[columnMenu addItem: newItem];

			newItem = [[NSMenuItem alloc] init];
			[newItem setTitle:@"ALTER TABLE <tab> ALTER COLUMN <col> TYPE <type>"];
			[newItem setTarget: menuActionTarget];
			[newItem setAction: @selector(onSelectAlterTabAlterColMenuItem:)];
			[columnMenu addItem: newItem];

			newItem = [[NSMenuItem alloc] init];
			[newItem setTitle:@"ALTER TABLE <tab> ADD COLUMN <col> <type>"];
			[newItem setTarget: menuActionTarget];
			[newItem setAction: @selector(onSelectAlterAddColMenuItem:)];
			[columnMenu addItem: newItem];

			newItem = [[NSMenuItem alloc] init];
			[newItem setTitle:@"ALTER TABLE <tab> RENAME COLUMN <col> TO <new col>"];
			[newItem setTarget: menuActionTarget];
			[newItem setAction: @selector(onSelectAlterRenameColMenuItem:)];
			[columnMenu addItem: newItem];

			newItem = [[NSMenuItem alloc] init];
			[newItem setTitle:@"CREATE TABLE <tab> (<sel cols>)"];
			[newItem setTarget: menuActionTarget];
			[newItem setAction: @selector(onSelectCreateTabColsMenuItem:)];
			[columnMenu addItem: newItem];

			newItem = [NSMenuItem separatorItem];
			[tableMenu addItem: newItem];

			newItem = [[NSMenuItem alloc] init];
			[newItem setTitle:@"ALTER TABLE <tab> DROP COLUMN <col>"];
			[newItem setTarget: menuActionTarget];
			[newItem setAction: @selector(onSelectDropColMenuItem:)];
			[columnMenu addItem: newItem];
		}
		return columnMenu;
	}
	else if ([[selectedItem explorerType] isLike:@"Index Name"])
	{
		if (!indexMenu)
		{
			NSMenuItem *newItem;
			indexMenu = [[NSMenu alloc] init];
			
			newItem = [[NSMenuItem alloc] init];
			[newItem setTitle:@"DROP INDEX <name>"];
			[newItem setTarget: menuActionTarget];
			[newItem setAction: @selector(onSelectDropIndexMenuItem:)];
			[indexMenu addItem: newItem];
									
		}
		return indexMenu;
	}
	else if ([[selectedItem explorerType] isLike:@"Function Name"])
	{
		if (!functionMenu)
		{
			NSMenuItem *newItem;
			functionMenu = [[NSMenu alloc] init];

			newItem = [[NSMenuItem alloc] init];
			[newItem setTitle:@"CREATE OR REPLACE FUNCTION template ()"];
			[newItem setTarget: menuActionTarget];
			[newItem setAction: @selector(onSelectCreateFunctionTemplateMenuItem:)];
			[functionMenu addItem: newItem];

			newItem = [[NSMenuItem alloc] init];
			[newItem setTitle:@"CREATE OR REPLACE FUNCTION <name>"];
			[newItem setTarget: menuActionTarget];
			[newItem setAction: @selector(onSelectCreateFunctionMenuItem:)];
			[functionMenu addItem: newItem];
			
			newItem = [NSMenuItem separatorItem];
			[tableMenu addItem: newItem];

			newItem = [[NSMenuItem alloc] init];
			[newItem setTitle:@"DROP FUNCTION <name>"];
			[newItem setTarget: menuActionTarget];
			[newItem setAction: @selector(onSelectDropFunctionMenuItem:)];
			[functionMenu addItem: newItem];
			
		}
		return functionMenu;
	}
	else if ([[selectedItem explorerType] isLike:@"View Name"])
	{
		if (!viewMenu)
		{
			NSMenuItem *newItem;
			viewMenu = [[NSMenu alloc] init];
			
			newItem = [[NSMenuItem alloc] init];
			[newItem setTitle:@"SELECT * FROM <tab>"];
			[newItem setTarget: menuActionTarget];
			[newItem setAction: @selector(onSelectSelectTableMenuItem:)];
			[viewMenu addItem: newItem];

			newItem = [[NSMenuItem alloc] init];
			[newItem setTitle:@"CREATE VIEW <tab> as <query>"];
			[newItem setTarget: menuActionTarget];
			[newItem setAction: @selector(onSelectCreateViewMenuItem:)];
			[viewMenu addItem: newItem];

			newItem = [[NSMenuItem alloc] init];
			[newItem setTitle:@"CREATE VIEW template"];
			[newItem setTarget: menuActionTarget];
			[newItem setAction: @selector(onSelectCreateViewTemplateMenuItem:)];
			[viewMenu addItem: newItem];

			newItem = [NSMenuItem separatorItem];
			[tableMenu addItem: newItem];

			newItem = [[NSMenuItem alloc] init];
			[newItem setTitle:@"DROP VIEW <name>"];
			[newItem setTarget: menuActionTarget];
			[newItem setAction: @selector(onSelectDropViewMenuItem:)];
			[viewMenu addItem: newItem];
			
		}
		return viewMenu;
	}
	return [self menu];
}

- (void)setMenuActionTarget:(id) theSQLDocument
{	
	[theSQLDocument retain];
	[menuActionTarget release];
	menuActionTarget = theSQLDocument;
}

-(void)changeFont:(id)sender
{
	int i;
	NSFont *oldFont = currentFont;
	currentFont = [sender convertFont:oldFont];
	NSArray *theCols = [self tableColumns];
	int colCnt = [self numberOfColumns];
	for(i=0; i< colCnt; i++)
	{   
		[[[theCols objectAtIndex:i] dataCell] setFont:currentFont];
	}
	[self setRowHeight:[[[theCols objectAtIndex:0] dataCell] cellSize].height];
	
	[[NSUserDefaults standardUserDefaults] setObject:[currentFont fontName] forKey:@"PGSqlForMac_QueryTool_SchemaTableFontName"];
	[[NSUserDefaults standardUserDefaults] setFloat:[currentFont pointSize] forKey:@"PGSqlForMac_QueryTool_SchemaTableFontSize"];
}

-(NSFont*)currentFont
{
	return currentFont;
}

-(void)setCurrentFont:(NSFont*)theFont
{
	currentFont=theFont;
}


@end
