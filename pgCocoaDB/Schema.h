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
	
}

- initWithConnection:(Connection *) theConnection;

-(RecordSet *)getFunctionInfoFromSchema:(NSString *)schemaName functionName: (NSString *) functionName;
-(RecordSet *)getFunctionNamesFromSchema:(NSString *)schemaName;
-(RecordSet *)getIndexInfoFromSchema:(NSString *)schemaName tableName:(NSString *) tableName indexName:(NSString *) indexName;
-(RecordSet *)getIndexNamesFromSchema:(NSString *)schemaName tableName:(NSString *) tableName;
-(RecordSet *)getObjectDescriptionFromSchema:(NSString *)schemaName objectType:(NSString *)objectType objectName:(NSString *)objectName;
-(RecordSet *)getSchemaNames;
-(RecordSet *)getTableColumnInfoFromSchema:(NSString *)schemaName tableName:(NSString *) tableName;
-(RecordSet *)getTableNamesFromSchema:(NSString *)schemaName;
-(RecordSet *)getViewColumnInfoFromSchema:(NSString *)schemaName viewName:(NSString *) viewName;
-(RecordSet *)getViewNamesFromSchema:(NSString *)schemaName;

@end
