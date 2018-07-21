//
//  DBUtil.h
//  qliq
//
//  Created by Ravi Ada on 2/27/12.
//  Copyright (c) 2012 Dobeyond inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#import "FMDatabaseQueue.h"
#import "DBServiceBase.h"

#import "sqlite3.h"

@class UserSession;


@interface DBUtil : NSObject
{
	FMDatabase *realDb;
	FMDatabase *memDb;
    FMDatabaseQueue * queue;
    NSString *schemaVersion;
	
	sqlite3 *database;
	sqlite3 *memory_database;
	NSUInteger numRecordsParsed;
	NSDictionary *createStmts;
	NSDictionary *prepareStmts;
	NSDictionary *numColsDict;
	NSString *dbPath;
	NSString *dbKey;
	NSString *csvFilePath;
	NSMutableString *insertSql;
}
@property (nonatomic, retain) FMDatabase *realDb;
@property (nonatomic, retain) FMDatabase *memDb;
@property (nonatomic, retain) FMDatabaseQueue *queue;
@property (nonatomic, readonly) NSString *schemaVersion;
@property (nonatomic, readonly) NSString *dbPath;
@property (nonatomic, readonly) NSString *dbKey;
@property (nonatomic, readonly) BOOL isNewDatabase;

//Static methods
+ (DBUtil *) sharedInstance;

+ (NSString *) statistics;
+ (void) clearStatistics;

+ (FMDatabase *) sharedDBConnection;
+ (FMDatabaseQueue *) sharedQueue;
+ (BOOL)executeSqlFileAtPath:(NSString *)path forDatabase:(FMDatabase *)database;
+ (BOOL)upgradeDatabase:(FMDatabase *)database;
+ (NSInteger) previousDbVersion;
+ (NSInteger) currentDbVersion;
+ (NSString *) databasePathForQliqId:(NSString *)qliqId;

-(BOOL) prepareDBForUserSession:(UserSession*)userSession;
-(BOOL) resetDatabase:(UserSession*)userSession;
-(BOOL) deleteOpenDatabase;
- (void) addDelegate:(DBServiceBase *)base;
- (void) removeDelegate:(DBServiceBase *)base;
- (void) setDbExists;
- (NSString *) exportPlainText;

@end

#ifdef DEBUG
@interface FMDatabaseDebugWrapper : FMDatabase
- (BOOL)update:(NSString*)sql withErrorAndBindings:(NSError**)outErr, ...;
- (BOOL)executeUpdate:(NSString*)sql, ...;
- (BOOL)executeUpdateWithFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);
- (BOOL)executeUpdate:(NSString*)sql withArgumentsInArray:(NSArray *)arguments;
- (BOOL)executeUpdate:(NSString*)sql withParameterDictionary:(NSDictionary *)arguments;
- (BOOL)executeUpdate:(NSString*)sql withVAList: (va_list)args;
- (FMResultSet *)executeQuery:(NSString*)sql, ...;
- (FMResultSet *)executeQueryWithFormat:(NSString*)format, ... NS_FORMAT_FUNCTION(1,2);
- (FMResultSet *)executeQuery:(NSString *)sql withArgumentsInArray:(NSArray *)arguments;
- (FMResultSet *)executeQuery:(NSString *)sql withParameterDictionary:(NSDictionary *)arguments;
- (FMResultSet *)executeQuery:(NSString*)sql withVAList: (va_list)args;
- (void) mainThreadCheck;
@end
#endif
