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

// SQL generating functions
-(NSString *)getFunctionSQLFromSchema:(NSString *)schemaName fromFunctionName: (NSString *) functionName;
-(NSString *)getIndexSQLFromSchema:(NSString *)schemaName fromTableName:(NSString *) tableName fromIndexName:(NSString *) indexName;
-(NSString *)getTableSQLFromSchema:(NSString *)schemaName fromTableName:(NSString *) tableName;
-(NSString *)getTriggerSQLFromSchema:(NSString *)schemaName fromTriggerName:(NSString *)triggerName;
-(NSString *)getViewSQLFromSchema:(NSString *)schemaName fromView:(NSString *)viewName pretty:(int)pretty;

// info functions
-(RecordSet *)getDatabaseNames;
-(RecordSet *)getFunctionNamesFromSchema:(NSString *)schemaName;
-(RecordSet *)getIndexNamesFromSchema:(NSString *)schemaName fromTableName:(NSString *) tableName;
-(RecordSet *)getObjectDescriptionFromSchema:(NSString *)schemaName objectType:(NSString *)objectType objectName:(NSString *)objectName;
-(RecordSet *)getSchemaNames;
-(RecordSet *)getTableColumnInfoFromSchema:(NSString *)schemaName fromTableName:(NSString *) tableName fromColumnName:(NSString *)columnName;
-(RecordSet *)getTableColumnsInfoFromSchema:(NSString *)schemaName fromTableName:(NSString *)tableName;
-(RecordSet *)getTableColumnNamesFromSchema:(NSString *)schemaName fromTableName:(NSString *) tableName;
-(RecordSet *)getTableNamesFromSchema:(NSString *)schemaName;
-(RecordSet *)getTriggerNamesFromSchema:(NSString *)schemaName fromTableName:(NSString *) tableName;
-(RecordSet *)getViewColumnInfoFromSchema:(NSString *)schemaName viewName:(NSString *) viewName;
-(RecordSet *)getViewNamesFromSchema:(NSString *)schemaName;

@end
