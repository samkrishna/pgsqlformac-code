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

-(RecordSet *)getDatabaseNames;
-(RecordSet *)getFunctionNamesFromSchema:(NSString *)schemaName;
-(RecordSet *)getFunctionSQLFromSchema:(NSString *)schemaName fromFunctionName: (NSString *) functionName;
-(RecordSet *)getIndexSQLFromSchema:(NSString *)schemaName fromTableName:(NSString *) tableName fromIndexName:(NSString *) indexName;
-(RecordSet *)getIndexNamesFromSchema:(NSString *)schemaName fromTableName:(NSString *) tableName;
-(RecordSet *)getObjectDescriptionFromSchema:(NSString *)schemaName objectType:(NSString *)objectType objectName:(NSString *)objectName;
-(RecordSet *)getSchemaNames;
-(RecordSet *)getTableColumnInfoFromSchema:(NSString *)schemaName fromTableName:(NSString *) tableName fromColumnName:(NSString *)columnName;
-(RecordSet *)getTableColumnNamesFromSchema:(NSString *)schemaName fromTableName:(NSString *) tableName;
-(RecordSet *)getTableNamesFromSchema:(NSString *)schemaName;
-(NSString *)getTableSQLFromSchema:(NSString *)schemaName fromTableName:(NSString *) tableName;
-(NSString *)getTriggerSQLFromSchema:(NSString *)schemaName fromTriggerName:(NSString *)triggerName;
-(RecordSet *)getTriggerNamesFromSchema:(NSString *)schemaName fromTableName:(NSString *) tableName;
-(RecordSet *)getViewColumnInfoFromSchema:(NSString *)schemaName viewName:(NSString *) viewName;
-(RecordSet *)getViewNamesFromSchema:(NSString *)schemaName;
-(NSString *)getViewSQLFromSchema:(NSString *)schemaName fromView:(NSString *)viewName pretty:(int)pretty;

@end
