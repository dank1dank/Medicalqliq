//
//  CareteamService.m
//  qliq
//
//  Created by Paul Bar on 3/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CareteamService.h"
#import "CareTeamMember.h"
#import "QliqUser.h"
#import "DBUtil.h"

@interface CareteamService()

-(BOOL) careteamMemberExisits:(CareTeamMember*)careteamMember;
-(BOOL) insertCareteamMember:(CareTeamMember*)careteamMember;
-(BOOL) updateCareteamMember:(CareTeamMember*)careteamMember;

@end

@implementation CareteamService

-(id) init
{
    self = [super init];
    if(self)
    {
    }
    return self;
}

-(BOOL) saveCareteamMember:(CareTeamMember *)careteamMember
{
    BOOL rez = NO;
    if([self careteamMemberExisits:careteamMember])
    {
        rez = [self updateCareteamMember:careteamMember];
    }
    else
    {
        rez = [self insertCareteamMember:careteamMember];
    }
    
    return rez;
}

-(NSArray*) getMembersOfCareteamWithId:(NSNumber *)careteamId
{
    NSMutableArray *mutableRez = [[NSMutableArray alloc] init];
    NSString *selectQuery = @""
    "SELECT * FROM careteam WHERE id = ?";
    FMResultSet *rs = [self.db executeQuery:selectQuery, careteamId];
    
    while ([rs next])
    {
        [mutableRez addObject:[CareTeamMember careTeamMemberWithResultSet:rs]];
    }
    [rs close];
    
    NSArray *rez = [NSArray arrayWithArray:mutableRez];
    [mutableRez release];
    return  rez;
}

-(NSArray *) getCareteamIdsOfUser:(QliqUser *)user
{
    NSMutableArray *mutableRez = [[NSMutableArray alloc] init];
    
    NSString *selectQuery = @""
    "SELECT * FROM careteam WHERE user_id = ?";
    FMResultSet *rs = [self.db executeQuery:selectQuery, user.email];
    NSNumber *careteamId;
	
    while ([rs next])
    {
        careteamId = [NSNumber numberWithInt:[rs intForColumn:@"id"]];
        [mutableRez addObject:careteamId];
    }
    [rs close];
    
    NSArray *rez = [NSArray arrayWithArray:mutableRez];
    [mutableRez release];
    return  rez;
}

#pragma mark -
#pragma mark Private

-(BOOL) careteamMemberExisits:(CareTeamMember *)careteamMember
{   
    BOOL rez = NO;
    
    NSString *selectQuery = @""
    "SELECT * FROM careteam WHERE id = ? AND user_id = ?";
    
    FMResultSet *rs = [self.db executeQuery:selectQuery, careteamMember.careTeamId, careteamMember.user.email];
    
    if([rs next])
    {
        rez = YES;
    }
    
    [rs close];
    
    return rez;
}

-(BOOL) insertCareteamMember:(CareTeamMember *)careteamMember
{
    NSString *insertQuery = @""
    "INSERT INTO careteam ("
    " id, "
    " user_id, "
    " admit, "
    " active "
    ") VALUES (?,?,?,?)";
    
    BOOL rez = [self.db executeUpdate:insertQuery,
                careteamMember.careTeamId,
                careteamMember.user.email,
                [NSNumber numberWithInt:careteamMember.admit],
                [NSNumber numberWithInt:careteamMember.active]];
    
    return rez;
}

-(BOOL) updateCareteamMember:(CareTeamMember *)careteamMember
{
    NSString *updateQuery = @""
    "UPDATE careteam SET"
    " user_id = ?, "
    " admit = ?, "
    " active = ? "
    " WHERE id = ? ";
    
    BOOL rez = [self.db executeUpdate:updateQuery,
                careteamMember.user.email,
                [NSNumber numberWithInt:careteamMember.admit],
                [NSNumber numberWithInt:careteamMember.active],
                careteamMember.careTeamId];
    
    return rez;
}

@end
