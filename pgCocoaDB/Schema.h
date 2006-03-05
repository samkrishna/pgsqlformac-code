//
//  Schema.h
//  pgCocoaDB
//
//  Created by Neil Tiffin on 2/26/06.
//  Copyright 2006 Performance Champions, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "Recordset.h"
#import "Connection.h"

@interface Schema : NSObject {

	Connection *connection;
	NSString *defaultSchemaName;  // "public"
	NSString *pg_version_found;
}

- initWithConnection:(Connection *) theConnection;

-(RecordSet *)getFunctionNamesFromSchema:(NSString *)schemaName;
-(RecordSet *)getFunctionSourceFromSchema:(NSString *)schemaName functionName: (NSString *) functionName;
-(RecordSet *)getIndexInfoFromSchema:(NSString *)schemaName tableName:(NSString *) tableName indexName:(NSString *) indexName;
-(RecordSet *)getIndexNamesFromSchema:(NSString *)schemaName tableName:(NSString *) tableName;
-(RecordSet *)getObjectDescriptionFromSchema:(NSString *)schemaName objectType:(NSString *)objectType objectName:(NSString *)objectName;
-(RecordSet *)getSchemaNames;
-(RecordSet *)getTableColumnInfoFromSchema:(NSString *)schemaName fromTableName:(NSString *) tableName fromColumnName:(NSString *)columnName;
-(RecordSet *)getTableColumnNamesFromSchema:(NSString *)schemaName fromTableName:(NSString *) tableName;
-(RecordSet *)getTableNamesFromSchema:(NSString *)schemaName;
-(RecordSet *)getTriggerInfoFromSchema:(NSString *)schemaName;
-(RecordSet *)getTriggerNamesFromSchema:(NSString *)schemaName fromTableName:(NSString *) tableName;
-(RecordSet *)getViewColumnInfoFromSchema:(NSString *)schemaName viewName:(NSString *) viewName;
-(RecordSet *)getViewNamesFromSchema:(NSString *)schemaName;

@end
