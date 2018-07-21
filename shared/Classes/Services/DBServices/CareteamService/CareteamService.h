//
//  CareteamService.h
//  qliq
//
//  Created by Paul Bar on 3/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DBServiceBase.h"

@class CareTeamMember;
@class QliqUser;

@interface CareteamService : DBServiceBase

-(BOOL) saveCareteamMember:(CareTeamMember*)careteamMember;
-(NSArray*) getMembersOfCareteamWithId:(NSNumber*)careteamId;
-(NSArray *) getCareteamIdsOfUser:(QliqUser*)user;

@end
