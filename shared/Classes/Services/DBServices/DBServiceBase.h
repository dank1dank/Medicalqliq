//
//  DBServiceBase.h
//  qliq
//
//  Created by Paul Bar on 2/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DBUtil.h"

typedef void (^SelectResult)  (BOOL/*success*/,id/*data*/);
typedef void (^BoolResult) (BOOL/*success*/);

@protocol DBUtilDelegate <NSObject>

-(void) updateDbConnection;

@end

@interface DBServiceBase : NSObject<DBUtilDelegate>
{
//    FMDatabase *db;
}
@property (nonatomic, retain) FMDatabase *db;
@property (nonatomic, retain) FMDatabaseQueue * queue;
@end
