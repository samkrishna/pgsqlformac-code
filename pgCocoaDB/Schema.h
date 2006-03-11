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
	NSString *pgVersionFound;
}

- initWithConnection:(Connection *) theConnection;

- (NSString *)defaultSchemaName;
- (NSString *)pgVersionFound;

// SQL generating functions
-(NSString *)getFunctionSQLFromSchema:(NSString *)schemaName fromFunctionName: (NSString *) functionName;
-(NSString *)getIndexSQLFromSchema:(NSString *)schemaName fromTableName:(NSString *) tableName fromIndexName:(NSString *) indexName;
-(NSString *)getTableSQLFromSchema:(NSString *)schemaName fromTableName:(NSString *) tableName pretty:(int)pretty;
-(NSString *)getTriggerSQLFromSchema:(NSString *)schemaName fromTriggerName:(NSString *)triggerName;
-(NSString *)getViewSQLFromSchema:(NSString *)schemaName fromView:(NSString *)viewName pretty:(int)pretty;

// info functions
-(RecordSet *)getDatabaseNames;
-(RecordSet *)getFunctionNamesFromSchema:(NSString *)schemaName;
-(RecordSet *)getIndexNamesFromSchema:(NSString *)schemaName fromTableName:(NSString *) tableName;
-(RecordSet *)getSchemaNames;
-(RecordSet *)getSequenceColumnNamesFromSchema:(NSString *)schemaName fromSequence:(NSString *)sequenceName;
-(RecordSet *)getSequenceNamesFromSchema:(NSString *)schemaName;
-(RecordSet *)getTableColumnInfoFromSchema:(NSString *)schemaName fromTableName:(NSString *) tableName fromColumnName:(NSString *)columnName;
-(RecordSet *)getTableColumnsInfoFromSchema:(NSString *)schemaName fromTableName:(NSString *)tableName;
-(RecordSet *)getTableColumnNamesFromSchema:(NSString *)schemaName fromTableName:(NSString *) tableName;
-(RecordSet *)getTableNamesFromSchema:(NSString *)schemaName;
-(RecordSet *)getTriggerNamesFromSchema:(NSString *)schemaName fromTableName:(NSString *) tableName;
-(RecordSet *)getViewNamesFromSchema:(NSString *)schemaName;

// comment returning functions
-(NSString *)getColumnCommentFromSchema:(NSString *)schemaName fromTableName:(NSString *)tableName fromColumnName:(NSString *) columnName;
-(NSString *)getIndexCommentFromSchema:(NSString *)schemaName fromIndexName:(NSString *)indexName;
-(NSString *)getObjectCommentFromSchema:(NSString *)schemaName objectType:(NSString *)objectType objectName:(NSString *)objectName;
-(NSString *)getTableCommentFromSchema:(NSString *)schemaName fromTableName:(NSString *)tableName;
-(NSString *)getTriggerCommentFromSchema:(NSString *)schemaName fromTableName:(NSString *)tableName fromTriggerName:(NSString *)triggerName;

@end
