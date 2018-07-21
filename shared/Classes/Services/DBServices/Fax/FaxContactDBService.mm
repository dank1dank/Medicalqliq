 //
//  Created by Adam Sowa.
//
#import "FaxContactDBService.h"
#import "qxlib/platform/ios/QxPlatfromIOSHelpers.h"
#include "qxlib/dao/fax/QxFaxContactDao.hpp"

using qx::toStdString;
using qx::toNSString;

@implementation FaxContactDBService

+ (FaxContact *) getWithId:(int)databaseId
{
    qx::FaxContact cpp = qx::FaxContactDao::selectOneBy(qx::FaxContactDao::IdColumn, std::to_string(databaseId));
    return [[FaxContact alloc] initWithCpp2:&cpp];
}

+ (NSMutableArray *) getWithLimit:(int)limit skip:(int)skip
{
    qx::dao::Query q;
    q.skip = skip;
    q.limit = limit;

    std::vector<qx::FaxContact> cppVec = qx::FaxContactDao::select(q);
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:cppVec.size()];
    for (qx::FaxContact& cpp: cppVec) {
        FaxContact *obj = [[FaxContact alloc] initWithCpp2:&cpp];
        [array addObject:obj];
    }
    return array;
}

+ (NSMutableArray *) searchByFilter:(NSString *)filter limit:(int)limit skip:(int)skip
{
    std::vector<qx::FaxContact> cppVec = qx::FaxContactDao::search(toStdString(filter), limit, skip);
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:cppVec.size()];
    for (qx::FaxContact& cpp: cppVec) {
        FaxContact *obj = [[FaxContact alloc] initWithCpp2:&cpp];
        [array addObject:obj];
    }
    return array;
}

+ (BOOL) deleteRowWithId:(int)databaseId
{
    return qx::FaxContactDao::delete_(qx::FaxContactDao::IdColumn, std::to_string(databaseId));
}


@end
