//
//  QliqDBService.h
//  qliq
//
//  Created by Aleksey Garbarev on 12/3/12.
//
//

#import <Foundation/Foundation.h>
#import "DBCoder.h"
#import "FMDatabase.h"

typedef void(^DBSaveCompletion)(BOOL wasInserted, id objectId, NSError * error);
typedef void(^DBDeleteCompletion)(NSError * error);

typedef enum {DBModeSingle = 0, DBModeToMany = 1u << 1, DBModeToOne = 1u << 2} DBMode;

typedef enum { DBErrorCodeObjectIsNil = 100, DBErrorCodeObjectIsNotExist, DBErrorCodeUnknown } DBErrorCode;

/* QliqDBService developed to provide common method to save, load and delete objects from SQLite.
 * Service work over FMDB (My modified threaded-safe FMDB. In future better to handle multithreading
 * this service and use original FMDB).
 * All methods works synchonicaly. 
 * Service works only with objects which confirms DBCoding protocol. */
@interface QliqDBService : NSObject

@property  (nonatomic, strong) FMDatabase * database;

- (id) initWithDatabase:(FMDatabase *) database;

/* 
 *   'as: (Class)' - Used to save one object as another object.
 *   It is used when objects are inherited. Because DBCoding compatible class contain all nessesary db schema to be stored
 *   For example when we saving QliqUser we save it as Contact then save as QliqUser because QliqUser inherited from Contact
 *
 *   mode (DBMode type) used to save, delete related objects. Implementation of initWithDecoder responds to loading related objects.
 *   On 'related objects' I mean 'to-one' and 'to-many' related 'DBCoding' ready objects. When we encoding 'DBCoding' object to some column,
 *   it means 'to-one' relation. When we using encode encodeObjects: it means 'to-many' relation.
*/


/* Insertion/Updating */
- (void) save:(id<DBCoding>) object completion:(DBSaveCompletion)completion; /* Saves object as their class and with DBModeToOne|DBModeToMany mode */
- (void) save:(id<DBCoding>) object as:(Class)objectClass completion:(DBSaveCompletion)completion;  
- (void) save:(id<DBCoding>) object as:(Class)objectClass mode:(DBMode) mode completion:(DBSaveCompletion)completion;

/* Accessing */
- (id) objectWithId:(id) identifier andClass:(Class) objectClass NS_RETURNS_RETAINED;
- (id) objectOfClass:(Class) objectClass fromDecoder:(DBCoder *) decoder NS_RETURNS_RETAINED;

- (void) writeObject:(id)object asClass:(Class)asClass fromId:(id)identifier;
- (void) writeObject:(id)object asClass:(Class)asClass fromDecoder:(DBCoder *) decoder;

/* Returns array of decoders for sql-query. To craete objects from decoders use objectOfClass:fromDecoder:
 * result of sql-query have to contain all columns which used by DBCoding objects in initWithDBCoder/encodeWithDBCoder methods
 * Usually it is SELECT * FROM object_table WHERE ...; */
- (NSArray *) decodersFromSQLQuery:(NSString *) query withArgs:(NSArray *) args;

/* it returns latest primary key. Useful for autoincrement PKs to know which PK will be insterted */
- (id) latestPrimaryKeyForClass:(Class) objectClass;

/* Deletetion */
/* Used object instead of only object's primary key to ablility delete related objects */
- (void) deleteObject:(id<DBCoding>) object mode:(DBMode) mode completion:(DBDeleteCompletion) completion;
- (void) deleteObject:(id<DBCoding>) object as:(Class) objectClass mode:(DBMode)mode completion:(DBDeleteCompletion)completion;

/* Returns object with same primary key and class, loaded from db */
- (id) reloadObject:(id<DBCoding>) object;

@end
