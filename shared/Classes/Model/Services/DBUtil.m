//
//  DBUtil.m
//  qliq
//
//  Created by Ravi Ada on 2/27/12.
//  Copyright (c) 2012 Dobeyond inc. All rights reserved.
//

#import "DBUtil.h"
#import "UserSession.h"
#import "ApplicationsSubscription.h"
#import "FMResultSet.h"
#import "FMDatabase.h"
#import "ApplicationsSubscription.h"
#import "UserSessionService.h"
#import "UserSession.h"
#import "AppDelegateProtocol.h"
#import "DBUtilObjcMigration.h"
#import "qxlib/platform/ios/QxPlatfromIOS.h"
#ifdef DEBUG
#import "FhirResources.h"
#endif

#import <objc/runtime.h>

@interface DBUtil()
- (BOOL) openDatabase:(UserSession *)userSession;
//- (void) prepareDBQueries:(NSString *) createStmt;
- (void) processFile:(NSInteger) numCols inDB:(FMDatabase *)db;
//- (void) finalizeQueries;
- (void) parseSeedDataFile:(NSString*) tableName andNumCols:(NSInteger) numCols inDB:(FMDatabase *)db;
//- (void) catMemoryDBToDisk:(NSString *) tableName;
- (void) loadTableWithSeedData:(NSString *)tableName inDB:(FMDatabase *)db;
- (NSMutableDictionary*)convertSqlFileToDict:(NSString *)path;
- (void) processSchemaDict:(NSDictionary*) schemaDict inDB:(FMDatabase *)db;
@end

// Buffer size when reading from the file in bytes (=128 kbytes)
static const NSUInteger ReadBufferSize = 131072;
//static const NSUInteger charactersToRemoveAtEnd=4;
//static const NSUInteger paramQuantity=3;
static NSInteger s_previousDbVersion = 0;
static NSInteger s_currentDbVersion = 0;

@implementation DBUtil
@synthesize realDb,memDb,schemaVersion, queue, dbPath, dbKey, isNewDatabase;

static NSMutableDictionary * statistics;

#define FMDBQuickCheck(SomeBool) { if (!(SomeBool)) { TTDLog(@"Failure on line %d", __LINE__); abort(); } }

#pragma mark Singleton Methods

+ (DBUtil *) sharedInstance{
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [[DBUtil alloc] init];
        
    });
    return shared;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        self.realDb = nil;
    }
    return self;
}

- (void) addDelegate:(DBServiceBase *)base
{
    
}

- (void) removeDelegate:(DBServiceBase *)base
{
    
}

-(BOOL) prepareDBForUserSession:(UserSession *)userSession
{
	NSString *qliqId = userSession.user.qliqId;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *userDir = [documentsDirectory stringByAppendingFormat:@"/%@", qliqId];
    if(![fileManager fileExistsAtPath:userDir])
    {
        [fileManager createDirectoryAtPath:userDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString *relativeDBPath = [NSString stringWithFormat:@"%@/%@.sqlite", qliqId, qliqId];
    NSString *newDbPath = [documentsDirectory stringByAppendingPathComponent:relativeDBPath];
    
    if (self.queue) {
        __block BOOL alreadyOpen = NO;
        [self.queue inDatabase:^(FMDatabase *db) {
            if ([db goodConnection] && [dbPath isEqualToString:newDbPath]) {
                alreadyOpen = YES;
            }
        }];
        if (alreadyOpen) {
            DDLogError(@"The db is already open for the current user");
            return YES;
        }
    }
    
    [self.realDb close];
    [self.queue close];
    self.realDb = nil;
    self.queue = nil;
    dbPath = newDbPath;
    isNewDatabase = NO;

    DDLogSupport(@"Preparing db %@", dbPath);
    NSLog(@"Preparing db %@", dbPath);
    
    BOOL databaseExists = [fileManager fileExistsAtPath:dbPath];
    
    if (![self openDatabase:userSession]) {
        NSError *error = nil;
        DDLogError(@"Couldn't open the database, deleting the file and retrying");
        if ([fileManager fileExistsAtPath:dbPath] && ![[NSFileManager defaultManager] removeItemAtPath:dbPath error:&error]) {
            DDLogError(@"Couldn't delete existing db, giving up. Error: %@", [error localizedDescription]);
            return NO;
        }
        if (![self openDatabase:userSession]) {
            DDLogError(@"Couldn't open the database for the second time, giving up.");
            return NO;
        }
        databaseExists = NO;
    }
    
    if (!databaseExists) {
        isNewDatabase = YES;
        
        DDLogInfo(@"DB file: %@ does not exist, creating it...", dbPath);
//        [fileManager createFileAtPath:dbPath contents:nil attributes:nil];
        
        [self.queue inDatabase:^(FMDatabase *db) {
            DDLogSupport(@"Creating common schema");
            NSString *qliqSchemaPath = [[NSBundle mainBundle] pathForResource:@"common-schema" ofType:@"sql"];
            NSDictionary *schemaDict = [self convertSqlFileToDict:qliqSchemaPath];
            [self processSchemaDict:schemaDict inDB:db];
            DDLogSupport(@"common schema done");
            
            
            //prepare database tables according to subscription
            DDLogSupport(@"Creating qliqConnect schema");
            qliqSchemaPath = [[NSBundle mainBundle] pathForResource:@"qliqConnect-schema" ofType:@"sql"];
            schemaDict = [self convertSqlFileToDict:qliqSchemaPath];
            [self processSchemaDict:schemaDict inDB:db];
            DDLogSupport(@"qliqConnect schema done");
            
            if([userSession.subscriprion subscriptionContains:ApplicationsSubscriptionQliqCharge])
            {
                DDLogSupport(@"Creating qliqCharge schema");
                qliqSchemaPath = [[NSBundle mainBundle] pathForResource:@"qliqCharge-schema" ofType:@"sql"];
                schemaDict = [self convertSqlFileToDict:qliqSchemaPath];
                [self processSchemaDict:schemaDict inDB:db];
                DDLogSupport(@"qliqCharge schema done");
            }
            if([userSession.subscriprion subscriptionContains:ApplicationsSubscriptionQliqCare])
            {
                DDLogSupport(@"Creating qliqCare schema");
                qliqSchemaPath = [[NSBundle mainBundle] pathForResource:@"qliqCare-schema" ofType:@"sql"];
                schemaDict = [self convertSqlFileToDict:qliqSchemaPath];
                [self processSchemaDict:schemaDict inDB:db];
                DDLogSupport(@"qliqCare schema done");
            }
            DDLogSupport(@"DB creation complete....");
        }];
    }

    __block BOOL migrationSucceeded = NO;
        [self.queue inDatabase:^(FMDatabase *db) {
            @try {
                [DBUtil upgradeDatabase:db];
                migrationSucceeded = YES;
            }
            @catch (NSException *exception) {
                migrationSucceeded = NO;
            }
        }];

    if (migrationSucceeded) {
        [QxPlatfromIOS openDatabase:dbPath withKey:dbKey];
    } else {
        [self.realDb close];
        [self.queue close];
        self.realDb = nil;
        self.queue = nil;
    }
    return migrationSucceeded;
}

-(BOOL) openDatabase:(UserSession *)userSession
{
    dbKey = [userSession.dbKey copy];
#ifdef DISABLE_DATABASE_ENCRYPTION
    dbKey = nil;
#endif
    DDLogSupport(@"dbKey = '%@'", dbKey);
    DDLogSupport(@"dbPath = '%@'", dbPath);
    
    BOOL isMigrationToEncryptedShouldBePerformed = NO;

    // Since we cannot call 'open' directly on FMDatabaseQueue
    // we create a temporary FMDatabase object and open the db using it
    // to capture any error on opening.
    {
        FMDatabase *db = [FMDatabase databaseWithPath:dbPath];
        [db setLogsErrors:TRUE];
        db.maxBusyRetryTimeInterval = 1;
        if ([db open] == NO) {
            DDLogError(@"Error opening DB: %@, path: %@", db.lastErrorMessage, dbPath);
            return NO;
        }

#ifndef DISABLE_DATABASE_ENCRYPTION
        if (dbKey.length > 0) {
#ifdef DEBUG
            DDLogSupport(@"Using db key: %@", dbKey);
#endif
            // Key must be set as a first operation on db
             [db setPassphraseKey:dbKey]; //AIII
           
            // Do any query to test key validity
            FMResultSet *result = [db executeQuery:@"SELECT count(*) FROM sqlite_master"];
            if (nil == result || SQLITE_NOTADB == db.lastError.code) {
                isMigrationToEncryptedShouldBePerformed = YES;
            }
            [result close];
        }
#endif // !DISABLE_DATABASE_ENCRYPTION
        [db close];
    }
    
    if (isMigrationToEncryptedShouldBePerformed) {
        DDLogSupport(@"The database is plain text or encrypted using a diff. key, trying to encrypt it now");
        if (![self encryptDataBase]) {
            DDLogError(@"Couldn't encrypt existing plain text db");
            return NO;
        }
    }

    __block BOOL integrityCheckPassed = YES;
    self.queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    [self.queue inDatabase:^(FMDatabase *db) {
#ifndef DISABLE_DATABASE_ENCRYPTION
        if (dbKey.length > 0) {
            // Key must be set as a first operation on db
             [db setPassphraseKey:dbKey]; //AIII
          
        }
#endif //!DISABLE_DATABASE_ENCRYPTION
        [db setLogsErrors:TRUE];
        db.maxBusyRetryTimeInterval = 1;
        
        FMResultSet *rs = [db executeQuery:@"PRAGMA journal_mode = WAL"];
        if ([rs next] == NO) {
            DDLogError(@"Cannot set database journal_mode to WAL");
        }
        [rs close];
        
        rs = [db executeQuery:@"SELECT sqlite_version() AS sqlite_version"];
        if ([rs next]) {
            DDLogSupport(@"SQLite version: %@", [rs stringForColumnIndex:0]);
        }
        [rs close];
        
        NSDate *start = [NSDate date];
        rs = [db executeQuery:@"PRAGMA integrity_check"];
        DDLogSupport(@"Integrity check took: %f sec", -[start timeIntervalSinceNow]);
        
        int err = [db lastErrorCode];
        NSString *errorMessage = [db lastErrorMessage];
        if (err != 0) {
            DDLogError(@"Database integrity check failed. Code: %d: %@", err, errorMessage);
            integrityCheckPassed = NO;
        }
        [rs close];
    }];
    
    return integrityCheckPassed;
}

- (BOOL)encryptDataBase {
    
    BOOL result = NO;
    
    DDLogSupport(@"DB file is not encrypted. Going to encrypt now...");
    
    NSString *pathToUnencryptedDB = dbPath;
    NSString *pathToEncryptedDB = [dbPath stringByAppendingPathExtension:@"tmp"];
    NSError *error = nil;
    char *errorMsg = nil;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:pathToEncryptedDB])
    {
        DDLogError(@"Temporary encrypted db from another run already exists, removing it");
        if (![[NSFileManager defaultManager] removeItemAtPath:pathToEncryptedDB error:&error])
            DDLogError(@"Couldn't remove previous temporary encrypted db, the migration will fail");
    }
    
    sqlite3 *db;
    if (sqlite3_open([pathToUnencryptedDB UTF8String], &db) == SQLITE_OK)
    {
        int userVersion = 0;
        NSString *sql = [NSString stringWithFormat:@"pragma user_version;"];
        DDLogInfo(@"Fetching user_version...");
        sqlite3_stmt *statement = NULL;
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wconversion"
        if (SQLITE_OK == sqlite3_prepare(db, [sql UTF8String], sql.length, &statement, NULL))
        {
            if (SQLITE_ROW == sqlite3_step(statement))
            {
                userVersion = sqlite3_column_int64(statement, 0);
                
                sqlite3_finalize(statement);
                statement = NULL;
                
                DDLogSupport(@"user_version of DB is %d", userVersion);
                DDLogInfo(@"Attaching encrypted DB...");
                
                sql = [NSString stringWithFormat:@"ATTACH DATABASE '%@' AS encrypted KEY '%@'", pathToEncryptedDB, dbKey];
                if (SQLITE_OK == sqlite3_exec(db, (const char*) [sql UTF8String], NULL, NULL, &errorMsg))
                {
                    DDLogInfo(@"Encrypted DB attached. Exporting…");
                    sql = [NSString stringWithFormat:@"SELECT sqlcipher_export('%@')", @"encrypted"];
                    if (SQLITE_OK == sqlite3_exec(db, (const char*) [sql UTF8String], NULL, NULL, &errorMsg))
                    {
                        sqlite3_exec(db, "DETACH DATABASE encrypted;", NULL, NULL, NULL);
                        sqlite3_close(db);
                        db = NULL;
                        
                        DDLogSupport(@"DB export succeeded. Trying to set user_version…");
                        
                        sqlite3 *newDb;
                        if (SQLITE_OK == sqlite3_open_v2([pathToEncryptedDB UTF8String], &newDb, O_RDWR, NULL))
                        {
                            if (SQLITE_OK == sqlite3_key(newDb, [dbKey UTF8String], [dbKey lengthOfBytesUsingEncoding:NSUTF8StringEncoding]))
                            {
                                sql = [NSString stringWithFormat:@"pragma user_version = %d;", userVersion];
                                int res = SQLITE_OK;
                                if (SQLITE_OK == (res = sqlite3_exec(newDb, [sql UTF8String], NULL, NULL, NULL)))
                                {
                                    result = YES;
                                    DDLogInfo(@"user_version successfully set");
                                }
                                else
                                    DDLogInfo(@"Setting user_version failed. New encrypted DB file will be created. Error: %s", errorMsg);
                            }
                            else
                                DDLogInfo(@"Setting encrypted DB key failed. New encrypted DB file will be created. Error: %s", errorMsg);
                            
                            sqlite3_close(newDb);
                        }
                        else
                            DDLogInfo(@"Opening encrypted DB failed. New encrypted DB file will be created");
                        
                        NSURL *resultingUrl = nil;
                        if ([[NSFileManager defaultManager] replaceItemAtURL:[NSURL fileURLWithPath:pathToUnencryptedDB] withItemAtURL:[NSURL fileURLWithPath:pathToEncryptedDB] backupItemName:nil options:NSFileManagerItemReplacementUsingNewMetadataOnly resultingItemURL:&resultingUrl error:&error])
                        {
                            DDLogSupport(@"DB export completed");
                        }
                        else
                            DDLogError(@"DB export completed but unable to replace old DB with encrypted. New encrypted DB file will be created");
                    }
                    else
                        DDLogError(@"DB export failed. New encrypted DB file will be created");
                    
                    [[NSFileManager defaultManager] removeItemAtPath:pathToEncryptedDB error:&error];
                }
                else
                  DDLogError(@"Unable to attach encrypted DB. Error: %s", errorMsg);
            }
            else
                DDLogInfo(@"Unable to fetch user_version. sqlite3_step failed. DB export will not be performed. New encrypted DB file will be created");
        }
        else
            DDLogInfo(@"Unable to fetch user_version. DB export will not be performed. New encrypted DB file will be created");
        
#pragma clang diagnostic pop
        
        if (statement)
            sqlite3_finalize(statement);
        
        if (db)
            sqlite3_close(db);
    }
    else
        DDLogError(@"Unable to open unencrypted DB file. New encrypted DB file will be created");
    
    if (NO == result)
    {
        [[NSFileManager defaultManager] removeItemAtPath:pathToUnencryptedDB error:&error];
        [[NSFileManager defaultManager] removeItemAtPath:pathToEncryptedDB error:&error];
    }
    
    return result;
}

- (NSString *) exportPlainText
{
    __block BOOL ret = NO;
    NSString *encryptedPath = [self dbPath];
    NSString *plainTextDbPath = [encryptedPath stringByDeletingPathExtension];
    plainTextDbPath = [plainTextDbPath stringByAppendingString:@"-plain.sqlite"];
    
    [self.queue inDatabase:^(FMDatabase *db) {
        int userVersion = [db intForQuery:@"PRAGMA user_version"];
        if ([db executeUpdate:@"ATTACH DATABASE ? AS plaintext KEY ''", plainTextDbPath]) {
            FMResultSet *rs = [db executeQuery:@"SELECT sqlcipher_export('plaintext')"];
            [rs next];
            [rs close];

            [db executeUpdate:@"PRAGMA plaintext.user_version = ?", [NSNumber numberWithInt:userVersion]];
            [db executeUpdate:@"DETACH DATABASE plaintext"];
            ret = YES;
        } else {
            DDLogError(@"Cannot attach database: %@", plainTextDbPath);
        }
    }];
    if (!ret) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:plainTextDbPath error:&error];
        plainTextDbPath = nil;
    }
    return plainTextDbPath;
}

-(BOOL) deleteOpenDatabase
{
    NSString *path = [self.realDb databasePath];
    if (path.length == 0) {
        path = dbPath;
    }
    [self.realDb close];
    [self.queue close];
    self.realDb = nil;
    self.queue = nil;
    
    if ([path length] > 0) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:path]) {
            DDLogSupport(@"Deleting old database file");
            return [fileManager removeItemAtPath:path error:nil];
        }
    }
    return YES;
}

+ (BOOL) isObjcStatement:(NSString *) statement{
    return [statement rangeOfString:@"objc:"].location != NSNotFound;
}

+ (BOOL) performObjcStatement:(NSString *) statement forDatabase:(FMDatabase *)database
{
    NSString * selectorString = [statement stringByReplacingOccurrencesOfString:@"objc:" withString:@""];
    selectorString = [selectorString stringByReplacingOccurrencesOfString:@";" withString:@""];
    selectorString = [selectorString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    selectorString = [selectorString stringByAppendingString:@":"];
    SEL selector = NSSelectorFromString(selectorString);
    
    return (BOOL) [[DBUtilObjcMigration class] performSelector: selector withObject:database];
    
}

+ (NSString *) stringByRemovingComments:(NSString *) migrationString{
    
    NSMutableString * result = [NSMutableString stringWithCapacity:migrationString.length];
    
    [migrationString enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        
        NSRange commentRange = [line rangeOfString:@"#"];
        if (commentRange.location != NSNotFound){
            commentRange.length = line.length - commentRange.location;
            line = [line stringByReplacingCharactersInRange:commentRange withString:@""];
        }
        
        [result appendFormat:@"%@\n",line];
    }];

    return result;
}

+ (BOOL)executeSqlFileAtPath:(NSString *)path forDatabase:(FMDatabase *)database {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSError *error;
	
	if ([fileManager fileExistsAtPath:path])
    {
		NSString *sql = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
		// loop through lines in string;
		if (sql != nil)
        {
            NSString *sqlWithoutComments = [self stringByRemovingComments:sql];
            [sql release];
			NSArray *sqlStatements = [sqlWithoutComments componentsSeparatedByString:@";\n"];
			for (NSString *sqlStatement in sqlStatements)
            {
                sqlStatement = [sqlStatement stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
                
                if (sqlStatement.length == 0) continue;
                
                BOOL success = NO;
                
                if ([self isObjcStatement:sqlStatement]){
                    success = [self performObjcStatement:sqlStatement forDatabase:database];
                }else{
                    success = [database executeUpdate:[sqlStatement stringByAppendingString:@";"]];
                }
                if (!success){
                    DDLogInfo(@"Error during executing migration sql: '%@' (path: '%@')",sqlStatement,path);
                    return NO;
                }
			}
		}
	}
    return YES;
}
- (NSMutableDictionary*)convertSqlFileToDict:(NSString *)path
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSError *error;
	NSArray* splitLine;
	NSMutableDictionary *sqlDict = [[NSMutableDictionary alloc] init];
	if ([fileManager fileExistsAtPath:path])
    {
		NSString *sql = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
		// loop through lines in string;
		if (sql != nil)
        {
			NSArray *sqlStatementsArray = [sql componentsSeparatedByString:@";\n"];
			for (int i = 0; i < [sqlStatementsArray count] - 1; i++)
			{
                NSString *statement = [sqlStatementsArray objectAtIndex: i];
                NSString* singleLine = [statement substringWithRange: NSMakeRange(1, (statement.length >= 2 ? statement.length - 2 : 0))];
                splitLine = [singleLine componentsSeparatedByString: @"\",\""];
                [sqlDict setObject:[splitLine objectAtIndex: 1] forKey:[splitLine objectAtIndex: 0]];
			}
		}
		[sql release];
	}
	return [sqlDict autorelease];
}

// migration support so we can upgrade the database when new features come out.
+ (BOOL)upgradeDatabase:(FMDatabase *)database {
	BOOL success = YES;
	// get current database version of schema
	int currentVersion = 0;
	int databaseVersion = [database intForQuery:@"pragma user_version;"];
	if (databaseVersion) {
		currentVersion = databaseVersion;
	}
    s_previousDbVersion = currentVersion;
	DDLogInfo(@"current database version: %d",currentVersion);
	NSString *migrationFilePath = nil;
	
	// get latest database version number from Info.plist distributed with app
	NSDictionary *dbUpdatesDictionary = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"QliqDBUpdates" ofType:@"plist"]];
	
	int latestVersion = [[dbUpdatesDictionary objectForKey:@"QliqDatabaseVersion"] intValue];
	s_currentDbVersion = latestVersion;
    
    DDLogInfo(@"latest database version: %d",latestVersion);
    
	// if current version is older than latest version, then perform migration
	// read all migration sql files from current version + 1 to latest version
	// execute sql from each file in order.
	NSFileManager *fileManager = [NSFileManager defaultManager];
    
	for (int i = currentVersion + 1; i <= latestVersion; i++) {
		migrationFilePath = [NSString stringWithFormat:@"%@/migration.%i.sql", [[NSBundle mainBundle] resourcePath], i];
		if ([fileManager fileExistsAtPath:migrationFilePath]){
			// load the sql file into memory and execute each sql block
            if ([self executeSqlFileAtPath:migrationFilePath forDatabase:database]){
                [database executeUpdate:[NSString stringWithFormat:@"pragma user_version = %i;", i]];
                 DDLogInfo(@"migrated to: %d",i);
            }else{
                DDLogError(@"Migration error");
                
                [NSException raise:@"Migration error" format:@"Can't execute migration script at path: %@", migrationFilePath]; 
                break;
            }
		}
	}
    
	if (currentVersion < latestVersion) {
		[database executeUpdate:[NSString stringWithFormat:@"pragma user_version = %i;", latestVersion]];
	}

	return success;
}

+ (NSInteger) previousDbVersion
{
    return s_previousDbVersion;
}

+ (NSInteger) currentDbVersion
{
    return s_currentDbVersion;
}

+ (NSString *) databasePathForQliqId:(NSString *)qliqId
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *relativeDBPath = [NSString stringWithFormat:@"%@/%@.sqlite", qliqId, qliqId];
    return[documentsDirectory stringByAppendingPathComponent:relativeDBPath];
}

+ (NSString *) statistics{
    
    @synchronized(self){
        NSMutableString * string = [[NSMutableString alloc] init];
        for (NSString * key in [statistics allKeys]){
            [string appendFormat:@"\n %4.0lu times called by %@",[[statistics valueForKey:key] unsignedLongValue],key];
        }
        return [string autorelease];
    }
    
}

+ (void) clearStatistics{
    @synchronized(self){
        [statistics removeAllObjects];
    }
}

+ (FMDatabase *) sharedDBConnection
{

    /*
    @synchronized(self){

        NSRange stackSymbolsRange;
        stackSymbolsRange.length = 1;  //print 1 symbol
        stackSymbolsRange.location = 1;//from first symbol (excluding)
        
        NSUInteger counter = 0;
        NSMutableString * symbols = [[NSMutableString alloc] init];
        NSRange resultRange;
        for (NSObject * symbol in [NSThread callStackSymbols]){
            counter++;
            if (counter > stackSymbolsRange.location){
                NSString * symbolDescription = [symbol description];
                NSRange first = [symbolDescription rangeOfString:@"["];
                NSRange last  = [symbolDescription rangeOfString:@"]" options:NSBackwardsSearch];
                resultRange.location = first.location - 1;
                resultRange.length = last.location - resultRange.location + 1;
                if ([symbols length] > 0) [symbols appendString:@"\n"];
                
                if (first.location != NSNotFound){
                    [symbols appendFormat:@"%@",[symbolDescription substringWithRange:resultRange]];
                }else{
                    NSArray * array = [symbolDescription componentsSeparatedByString:@" "];
                    [symbols appendFormat:@"%@",[array objectAtIndex:[array count]- 3]];
                }
            }
            if (counter == stackSymbolsRange.location + stackSymbolsRange.length) break;
        }
        
        
        if (!statistics) statistics = [[NSMutableDictionary alloc] init];
        unsigned long callsCount = 1;
        NSNumber * currentValue = [statistics valueForKey:symbols];
        if (currentValue)
            callsCount += [currentValue unsignedLongValue];
        [statistics setValue:[NSNumber numberWithUnsignedLong:callsCount] forKey:symbols];
        [symbols release];
    }
     //
     //    DDLogSupport(@"%@",symbols);
     //
    */
    
	DBUtil *dbUtil = [DBUtil sharedInstance];
	//if(![[dbUtil realDb] goodConnection])
    //{
    //    DDLogSupport(@"Something terrible happened. Dont know what else to do to recover from it");
        //[[DBUtil sharedInstance] prepareDBForUserSession:[UserSessionService currentUserSession]];
    //}
	return [dbUtil realDb];
}


+ (FMDatabaseQueue *) sharedQueue {
    return [[DBUtil sharedInstance] queue];
}

- (void)dealloc
{
	[createStmts release];
	[prepareStmts release];
	[numColsDict release];
    [queue release];
    
	[super dealloc];
}


-(void) processSchemaDict:(NSDictionary*) schemaDict inDB:(FMDatabase *)db
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *createSql=nil;
	for(NSString *tableName in [schemaDict allKeys]){
		//query the database master to find if the table already exists
		FMResultSet *table_rs = [db executeQuery:@"SELECT * FROM sqlite_master where type = 'table' and tbl_name=?",tableName];
		BOOL tableFound = NO;
		
        if ([table_rs next]) {
			tableFound = YES;
            break;
		}
        
		[table_rs close];
		csvFilePath = [[NSBundle mainBundle] pathForResource:tableName ofType:@"csv"];
        
		if(!tableFound){
            
			DDLogInfo(@"%@ not found. creating it",tableName);
			createSql = [schemaDict objectForKey:tableName];
			[db executeUpdate:@"PRAGMA foreign_key=false;"];
			BOOL success = [db executeUpdate:[createSql stringByAppendingString:@";"]];
			DDLogInfo(@"%@ created successfully. %d" ,tableName, success);
			[db executeUpdate:@"PRAGMA foreign_key=true;"];
			
			if([fileManager fileExistsAtPath:csvFilePath])
			{
				[db beginTransaction];
				[self loadTableWithSeedData:tableName inDB:db];
				[db commit];
			}
		}else{
			DDLogInfo(@"%@ found, checking if it has data ",tableName);
			NSString *selectStatement = [NSString stringWithFormat:@"SELECT count(*) as rec_count FROM %@",tableName];
			
			FMResultSet *rec_count_rs = [db executeQuery:selectStatement];
			int recCount=0;
			while ([rec_count_rs next])
			{
				recCount = [rec_count_rs intForColumn:@"rec_count"];
			}
			[rec_count_rs close];
			if([fileManager fileExistsAtPath:csvFilePath] && recCount == 0)
			{
				[db beginTransaction];
				[self loadTableWithSeedData:tableName inDB:db];
				[db commit];
			}
		}
	}
}


- (void) loadTableWithSeedData:(NSString *)tableName inDB:(FMDatabase *)db
{
	NSInteger numCols=0;
	
	insertSql = [NSMutableString stringWithString:@""];
	[insertSql appendString:@"INSERT INTO "];
	[insertSql appendString:tableName];
	[insertSql appendString:@" ("];
    
    DDLogInfo(@"insertSql: %@", insertSql);
	
	NSString *sqlStatement = [NSString stringWithFormat:@"pragma table_info('%@');",tableName];
	FMResultSet *table_rs = [db executeQuery:sqlStatement];
	while ([table_rs next])
	{
		NSInteger colPk = [table_rs intForColumn:@"pk"];
		NSString *colType = [table_rs stringForColumn:@"type"];
		if(!(colPk==1 && [colType isEqualToString:@"integer"])){
			NSString *colName = [table_rs stringForColumn:@"name"];
			[insertSql appendString:colName];
			[insertSql appendString:@","];
			numCols++;
		}
	}
	[table_rs close];
	DDLogInfo(@"%lu",(unsigned long)[insertSql length]);
    
    NSAssert(insertSql.length > 0, @"SQL query generation failed. Query length is 0");
	[insertSql deleteCharactersInRange:NSMakeRange([insertSql length]-1,1)];
	[insertSql appendString:@" ) VALUES ("];
	for (int i=0; i<numCols; i++) {
		[insertSql appendString:@" ?,"];
	}
    
    NSAssert(insertSql.length > 0, @"SQL query generation failed. Query length is 0");
	[insertSql deleteCharactersInRange:NSMakeRange([insertSql length]-1,1)];
	[insertSql appendString:@" );"];
	DDLogInfo(@"%@",insertSql);
	[self parseSeedDataFile:tableName andNumCols:numCols inDB:db];
}

- (NSUInteger) insertIntoDatabase:(NSArray *)record inDB:(FMDatabase *)db
{
	if (![db goodConnection]) {
		DDLogError(@"database is not present!");
	}
	NSInteger inserted_id=0;
	[record retain];
	if([db executeUpdate:insertSql withArgumentsInArray:[NSArray arrayWithArray:record]]==FALSE)
	{
		NSString *errMsg = [db lastErrorMessage];
		DDLogError(@"Error: Failed to insert %@ ", errMsg);
	}
	else {
		inserted_id = [db lastInsertRowId];
	}
	[record release];
    
	return inserted_id;
}


#pragma mark Parser Delegate
- (void) processFile:(NSInteger) numCols inDB:(FMDatabase *)db
{
	// Get a handle for datafile
	NSFileHandle* dataFile = [NSFileHandle fileHandleForReadingAtPath: csvFilePath];
	
    //NSInteger size = [dataFile seekToEndOfFile];
    [dataFile seekToFileOffset:0];
	NSData* readData;
	NSString* dataString;
	NSArray* lineArray;
	NSArray* splitLine;
	NSUInteger lineArrayCount = 0;
    NSInteger bufferSize = ReadBufferSize;
    
	while (1)
	{
		// create an autorelease pool so we will not run out of memory
        @autoreleasepool {
            
            // read the chunk of data
            readData = [dataFile readDataOfLength: bufferSize];
            
            // exit the loop if no data is available
            if (!readData || [readData length] == 0)
            {
                break;
            }
            
            dataString = [[NSString alloc] initWithData: readData encoding: NSASCIIStringEncoding];
            
            // divide read buffer into lines
            lineArray = [dataString componentsSeparatedByString: @"\n"];
            [dataString release];
            
            lineArrayCount += [lineArray count] - 1;
            
            // go through lines and add them into database. don't add the first line in file
            for (int i = 0; i < [lineArray count] - 1; i++)
            {
                NSString *line = [lineArray objectAtIndex: i];
                NSString* singleLine = [line substringWithRange: NSMakeRange(1, (line.length >= 2 ? line.length - 2 : 0))];
                splitLine = [singleLine componentsSeparatedByString: @"\",\""];
                
                for (int j=0; j<=numCols-1; j++) {
                    [splitLine arrayByAddingObject:[splitLine objectAtIndex:j]];
                }
                
                if ([splitLine count] >= numCols){
                    [self insertIntoDatabase:splitLine inDB:db];
                    numRecordsParsed ++;
                }
            }
            // seek back to the beginning of the last line
            NSString* lastLine = [lineArray lastObject];
            [dataFile seekToFileOffset: [dataFile offsetInFile] - [lastLine length]];
            
            // if there is no endline, read more next time
            if ([lineArray count] == 1)
            {
                bufferSize *= 2;
            }
        }
	}
	// Close a file
	[dataFile closeFile];
	
}


// will detach this thread from the main thread - create our own NSAutoreleasePool
- (void) parseSeedDataFile:(NSString*) tableName andNumCols:(NSInteger) numCols inDB:(FMDatabase *)db
{
	numRecordsParsed = 0;
	//process file
	[self processFile:numCols inDB:db];			// does the parsing and inserting into memory_database
}


-(BOOL) resetDatabase:(UserSession*)userSession
{
	BOOL retVal = FALSE;
	DDLogInfo(@"Resetting the data");
	NSString *qliqId = userSession.sipAccountSettings.username;
    
	NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *relativeDBPath = [NSString stringWithFormat:@"%@/%@.sqlite", qliqId, qliqId];
    dbPath = [documentsDirectory stringByAppendingPathComponent:relativeDBPath];
	
    BOOL databaseExists = [fileManager fileExistsAtPath:dbPath];
    if (databaseExists) {
		NSError* err = nil;
		BOOL res;
		DDLogInfo(@"DB file %@ exists", dbPath);
        res = [fileManager removeItemAtPath:dbPath error:&err];
		if (!res && err) {
			DDLogError(@"Error deleteting the database file : %@",[err localizedDescription]);
		}else{
			retVal = TRUE;
		}
    } else {
        DDLogSupport(@"Database doesn't exist, no need to delete: %@", dbPath);
    }
	
	//create the base schema
	[self prepareDBForUserSession:userSession];
	if (![self.realDb goodConnection]) {
		DDLogError(@"database is not present!");
	}
    
	//Todo: call get group info
	//[self.groupInfoService getGroupInfoForUser:FALSE];
    /*
     NSString *qliqSchemaPath = [[NSBundle mainBundle] pathForResource:@"qliqConnect-schema" ofType:@"sql"];
     [[DBUtil sharedInstance] loadSchema:qliqSchemaPath];
     ReferringProviderService *rpService = [[ReferringProviderService alloc] init];
     [rpService getReferringProviderInfoForUser];
     [rpService release];
     
     //create application specific schemas
     ApplicationsSubscription *subscription = [UserSessionService currentUserSession].subscriprion;
     if([subscription subscriptionContains:ApplicationsSubscriptionQliqCharge]){
     NSString *qliqSchemaPath = [[NSBundle mainBundle] pathForResource:@"qliqCharge-schema" ofType:@"sql"];
     [self loadSchema:qliqSchemaPath];
     SuperbillService *sbService = [[SuperbillService alloc] init];
     [sbService getSuperbillInfoForUser];
     [sbService release];
     } else if([subscription subscriptionContains:ApplicationsSubscriptionQliqCare]){
     NSString *qliqSchemaPath = [[NSBundle mainBundle] pathForResource:@"qliqCare-schema" ofType:@"sql"];
     [[DBUtil sharedInstance] loadSchema:qliqSchemaPath];
     }*/
	
	if (![self.realDb goodConnection]) {
		DDLogError(@"database is not present!");
	}
    
	return retVal;
}

/*
 #pragma mark -
 #pragma mark GroupInfoServiceDelegate
 -(void) didGetGroupInfo:(NSDictionary *)groupInfo
 {
 BOOL rez = [self.groupInfoService  storeGroupInfoInfoData:groupInfo];
 DDLogVerbose(@"Success getting group info, %d",rez);
 }
 
 -(void) didFailToGetGroupInfoWithReason:(NSString *)reason
 {
 DDLogError(@"Error getting group info");
 }
 */

- (void) setDbExists {
    isNewDatabase = NO;
}

@end

//////////////////////////////////////////////////////////////////////////////////////
#ifdef DEBUG
@implementation FMDatabaseDebugWrapper

- (BOOL)executeUpdate:(NSString*)sql, ... {
    [self mainThreadCheck];
    va_list args;
    va_start(args, sql);
    
    BOOL result = [super executeUpdate:sql error:nil withArgumentsInArray:nil orDictionary:nil orVAList:args];
    
    va_end(args);
    return result;
}

- (BOOL)executeUpdate:(NSString*)sql withArgumentsInArray:(NSArray *)arguments {
    [self mainThreadCheck];
    return [super executeUpdate:sql error:nil withArgumentsInArray:arguments orDictionary:nil orVAList:nil];
}

- (BOOL)executeUpdate:(NSString*)sql withParameterDictionary:(NSDictionary *)arguments {
    [self mainThreadCheck];
    return [super executeUpdate:sql error:nil withArgumentsInArray:nil orDictionary:arguments orVAList:nil];
}

- (BOOL)executeUpdate:(NSString*)sql withVAList:(va_list)args {
    [self mainThreadCheck];
    return [super executeUpdate:sql error:nil withArgumentsInArray:nil orDictionary:nil orVAList:args];
}

- (BOOL)executeUpdateWithFormat:(NSString*)format, ... {
    [self mainThreadCheck];
    va_list args;
    va_start(args, format);
    
    NSMutableString *sql      = [NSMutableString stringWithCapacity:[format length]];
    NSMutableArray *arguments = [NSMutableArray array];
    
    [super extractSQL:format argumentsList:args intoString:sql arguments:arguments];
    
    va_end(args);
    
    return [self executeUpdate:sql withArgumentsInArray:arguments];
}

- (BOOL)update:(NSString*)sql withErrorAndBindings:(NSError**)outErr, ... {
    [self mainThreadCheck];
    va_list args;
    va_start(args, outErr);
    
    BOOL result = [super executeUpdate:sql error:outErr withArgumentsInArray:nil orDictionary:nil orVAList:args];
    
    va_end(args);
    return result;
}

- (FMResultSet *)executeQuery:(NSString*)sql, ... {
    [self mainThreadCheck];
    va_list args;
    va_start(args, sql);
    
    id result = [super executeQuery:sql withArgumentsInArray:nil orDictionary:nil orVAList:args];
    
    va_end(args);
    return result;
}

- (FMResultSet *)executeQueryWithFormat:(NSString*)format, ... {
    [self mainThreadCheck];
    va_list args;
    va_start(args, format);
    
    NSMutableString *sql = [NSMutableString stringWithCapacity:[format length]];
    NSMutableArray *arguments = [NSMutableArray array];
    [super extractSQL:format argumentsList:args intoString:sql arguments:arguments];
    
    va_end(args);
    
    return [super executeQuery:sql withArgumentsInArray:arguments];
}

- (FMResultSet *)executeQuery:(NSString *)sql withArgumentsInArray:(NSArray *)arguments {
    [self mainThreadCheck];
    return [super executeQuery:sql withArgumentsInArray:arguments orDictionary:nil orVAList:nil];
}

- (FMResultSet *)executeQuery:(NSString*)sql withVAList:(va_list)args {
    [self mainThreadCheck];
    return [super executeQuery:sql withArgumentsInArray:nil orDictionary:nil orVAList:args];
}

- (FMResultSet *)executeQuery:(NSString *)sql withParameterDictionary:(NSDictionary *)arguments {
    [self mainThreadCheck];
    return [super executeQuery:sql withArgumentsInArray:nil orDictionary:arguments orVAList:nil];
}

- (void) mainThreadCheck {
    if (![NSThread isMainThread]) {
        DDLogError(@"BUG: accessing FMDatabase from a background thread!");
        DDLogError(@"Call stack:\n%@", [NSThread callStackSymbols]);
    }
}

@end
#endif // DEBUG
