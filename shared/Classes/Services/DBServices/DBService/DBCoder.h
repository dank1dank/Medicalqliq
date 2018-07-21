//
//  DBCoder.h
//  qliq
//
//  Created by Aleksey Garbarev on 06.12.12.
//
//

#import <Foundation/Foundation.h>

#import "DBTableConnection.h"

@protocol DBCoding;
@class DBCoder;

#define dbPrimaryKeyUndefined 0

typedef void(^DBCodingBlock)(DBCoder * table_coder, id object);
typedef void(^DBDecodingBlock)(DBCoder * table_decoder);

@interface DBCoder : NSObject
/* Skip zero values like 0 or "" in queries */
@property (nonatomic, readwrite) BOOL skipZeroValues;  /* Default: YES */
/* Skip nil values */
@property (nonatomic, readwrite) BOOL skipNilValues;  /* Default: YES */

/* You can encode/decode NSString, NSNumber, NSData, NSDate as standart SQLite types and 'DBCoding'-compatible objects.
 * If you encode/decode DBCoding object, it means 'to-one' or 'to-many' relation. 
 * For example if you encode DBCoding object for column 'foreign_object' and save, QliqDBService initially saves 'to-one'
 * related objects and then set it's primary key for 'foreign_object' column when save root object  */

/* Encode methods */
- (void) encodeObject:(id) object forColumn:(NSString *) column;
- (void) encodeObject:(id) object ofClass:(Class)objectClass forColumn:(NSString *)column;
- (void) encodeObjects:(NSArray *) objects connection:(DBTableConnection *) connection coding:(DBCodingBlock) codingBlock;


/* Decode methods */
- (id)  decodeObjectForColumn:(NSString *) column NS_RETURNS_RETAINED;
- (id)  decodeObjectOfClass:(Class) objectClass forColumn:(NSString *) column NS_RETURNS_RETAINED;

- (void) decodeObject:(id)object asClass:(Class)asClass fromColumn:(NSString *)column;
- (void) decodeObjectsFromConnection:(DBTableConnection *) connection decoding:(DBDecodingBlock) decodingBlock;

@end

@protocol DBCoding <NSObject>

/* Do not call this method directly to init object with coder.
 * Use objectOfClass:fromDecoder: in QliqDBService instead */
- (id) initWithDBCoder:(DBCoder *) decoder;

- (void) encodeWithDBCoder:(DBCoder *) coder;

- (NSString *) dbPKProperty; //KVC key for property which store primary key

+ (NSString *) dbTable;      // table name for object
+ (NSString *) dbPKColumn;   // primary key column name

@end
