//
//  CareTeam.m
//  qliq
//
//  Created by Paul Bar on 3/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CareTeamMember.h"
#import "NSObject+AutoDescription.h"
#import "FMResultSet.h"
#import "QliqUserService.h"
#import "QliqUser.h"

@implementation CareTeamMember

@synthesize careTeamId;
@synthesize user;
@synthesize admit;
@synthesize active;

-(void) dealloc
{
    [self.careTeamId release];
    [self.user release];
    [super dealloc];
}

-(NSString *) description
{
    return [self autoDescription];
}

+(CareTeamMember*) careTeamMemberWithResultSet:(FMResultSet *)result_set
{
    CareTeamMember *careTeam = [[CareTeamMember alloc] init];
    
    careTeam.careTeamId = [NSNumber numberWithInt:[result_set intForColumn:@"id"]];
    
    QliqUserService *userService = [[QliqUserService alloc] init];
    careTeam.user = [userService getUserWithId:[result_set stringForColumn:@"user_id"]];
    [userService release];
    
    careTeam.admit = [result_set intForColumn:@"admit"];
    careTeam.active = [result_set intForColumn:@"active"];
    
    return [careTeam autorelease];
}

@end
