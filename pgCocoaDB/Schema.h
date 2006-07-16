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
	NSString *publicSchemaName;			// is "public"
	NSString *pgCatalogSchemaName;		// is "pg_catalog"
	NSString *informationSchemaName;	// is "information_schema"
	NSString *pgVersionFound;
}

- initWithConnection:(Connection *) theConnection;

- (NSString *)publicSchemaName;
- (NSString *)pgCatalogSchemaName;
- (NSString *)informationSchemaName;
- (NSString *)pgVersionFound;

// generate SQL
-(NSString *)getFunctionSQLFromSchema:(NSString *)schemaName fromFunctionName: (NSString *) functionName pretty:(int)pretty;
-(NSString *)getIndexSQLFromSchema:(NSString *)schemaName fromTableName:(NSString *) tableName fromIndexName:(NSString *) indexName;
-(NSString *)getRuleSQLFromSchema:(NSString *)schemaName fromRuleName:(NSString *)ruleName pretty:(int)pretty;
-(NSString *)getTableSQLFromSchema:(NSString *)schemaName fromTableName:(NSString *) tableName pretty:(int)pretty;
-(NSString *)getTriggerSQLFromSchema:(NSString *)schemaName fromTriggerName:(NSString *)triggerName;
-(NSString *)getViewSQLFromSchema:(NSString *)schemaName fromView:(NSString *)viewName pretty:(int)pretty;

// get schema data
-(RecordSet *)getConstraintNamesFromSchema:(NSString *)schemaName fromTableName:(NSString *) tableName;
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

// get comments
-(NSString *)getColumnCommentFromSchema:(NSString *)schemaName fromTableName:(NSString *)tableName fromColumnName:(NSString *) columnName;
-(NSString *)getConstraintCommentFromSchema:(NSString *)schemaName fromConstraintName:(NSString *)constraintName;
-(NSString *)getDatabaseComment:(NSString *)databaseName;
-(NSString *)getFunctionCommentFromSchema:(NSString *)schemaName fromFunctionName:(NSString *)functionName;
-(NSString *)getIndexCommentFromSchema:(NSString *)schemaName fromIndexName:(NSString *)indexName;
-(NSString *)getSchemaComment:(NSString *)schemaName;
-(NSString *)getSequenceCommentFromSchema:(NSString *)schemaName fromSequenceName:(NSString *)sequenceName;
-(NSString *)getTableCommentFromSchema:(NSString *)schemaName fromTableName:(NSString *)tableName;
-(NSString *)getTriggerCommentFromSchema:(NSString *)schemaName fromTableName:(NSString *)tableName fromTriggerName:(NSString *)triggerName;
-(NSString *)getViewCommentFromSchema:(NSString *)schemaName fromViewName:(NSString *)viewName;

// get server info or misc
-(RecordSet *)getLocks;
-(int)getIndexCountFromSchema:(NSString *)schemaName fromTableName:(NSString *) tableName;

@end
