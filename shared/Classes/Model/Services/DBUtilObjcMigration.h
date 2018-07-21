//
//  DBUtilObjcMigration.h
//  qliq
//
//  Created by Aleksey Garbarev on 12.12.12.
//
//

#import <Foundation/Foundation.h>

@interface DBUtilObjcMigration : NSObject

+ (BOOL) migration_to_23:(FMDatabase *)db;

@end
