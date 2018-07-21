//
//  CareTeam.h
//  qliq
//
//  Created by Paul Bar on 3/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DBServiceBase.h"

@class FMResultSet;
@class QliqUser;

@interface CareTeamMember : NSObject

@property (nonatomic, retain) NSNumber *careTeamId;
@property (nonatomic, retain) QliqUser *user;
@property (nonatomic, assign) BOOL admit;
@property (nonatomic, assign) BOOL active;

+(CareTeamMember*)careTeamMemberWithResultSet:(FMResultSet*)result_set;

@end
