 //
//  Created by Adam Sowa.
//
#import <Foundation/Foundation.h>
#import "FaxContact.h"

@interface FaxContactDBService : NSObject

+ (FaxContact *) getWithId:(int)databaseId;
+ (NSMutableArray *) getWithLimit:(int)limit skip:(int)skip;
+ (NSMutableArray *) searchByFilter:(NSString *)filter limit:(int)limit skip:(int)skip;

// Delete row from db table only
+ (BOOL) deleteRowWithId:(int)databaseId;

@end
