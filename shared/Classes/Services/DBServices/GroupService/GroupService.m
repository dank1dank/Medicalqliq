//
//  GroupService.m
//  qliq
//
//  Created by Paul Bar on 2/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GroupService.h"
#import "Facility.h"
#import "UserSession.h"
#import "UserSessionService.h"
#import "QliqUser.h"

@interface GroupService()

-(BOOL) groupExists:(Group*)group;
-(BOOL) insertGroup:(Group*)group;
-(BOOL) updateGroup:(Group*)group;

@end

@implementation GroupService

-(BOOL) saveGroup:(Group *)group
{
    //delete it when guid will be available in server group_info responce
    group.guid = group.name;
    //---
    
    if([self groupExists:group])
    {
        return [self updateGroup:group];
    }
    else
    {
        return [self insertGroup:group];
    }
}

-(NSArray*) getGroups
{
    NSMutableArray *mutableRez = [[NSMutableArray alloc] init];
    
    NSString *selectQuery = @""
    " SELECT * FROM qliq_group ";
    
    FMResultSet *rs = [self.db executeQuery:selectQuery];
    while ([rs next])
    {
        [mutableRez addObject:[Group groupWithResultSet:rs]];
    }
    
    NSArray *rez = [NSArray arrayWithArray:mutableRez];
    [mutableRez release];
    [rs close];
    return rez;
}

-(Group*) getGroupWithName:(NSString *)groupName
{
    Group *rez = nil;
    
    NSString *selectQuery = @""
    " SELECT * FROM qliq_group WHERE name = ?";
    
    FMResultSet *rs = [self.db executeQuery:selectQuery, groupName];
    if([rs next])
    {
        rez = [Group groupWithResultSet:rs];
    }
    [rs close];
    return rez;
}

-(BOOL) addUser:(QliqUser *)user toGroup:(Group *)group
{
    NSString *selectQuery = @"SELECT * FROM user_group WHERE user_id = ? AND group_id = ?";
    FMResultSet *rs = [self.db executeQuery:selectQuery, user.email, group.guid];
    if([rs next])
    {
        return YES;
    }
    
    NSString *insertQuery = @"INSERT INTO user_group (user_id, group_id) VALUES (?,?)";
   [self.db beginTransaction];
    BOOL rez = [self.db executeUpdate:insertQuery, user.email, group.guid];
    if(!rez)
    {
       [self.db rollback];
    }
    else
    {
       [self.db commit];
    }
    return rez;
}

-(NSArray *) getUsersOfGroup:(Group *)group
{
	QliqUser *user = [UserSessionService currentUserSession].user;
	
    NSString *selectQuery = @""
    "SELECT * FROM qliq_user WHERE email IN"
    " (SELECT user_id FROM user_group WHERE group_id = ? and user_id != ?)";
    
    FMResultSet *rs = [self.db executeQuery:selectQuery, group.guid,user.email];
    
    NSMutableArray *mutableRez = [[NSMutableArray alloc] init];
    while ([rs next])
    {
        [mutableRez addObject:[QliqUser userWithResultSet:rs]];
    }
    
    NSArray *rez = [NSArray arrayWithArray: mutableRez];
    [rs close];
    [mutableRez release];
    return rez;
}

-(NSArray*) getGroupsOfUser:(QliqUser *)user
{
    NSString *selectQuery = @""
    "SELECT * FROM qliq_group WHERE guid IN"
    " (SELECT group_id FROM user_group WHERE user_id = ?)";
    
    FMResultSet *rs = [self.db executeQuery:selectQuery, user.email];
    
    NSMutableArray *mutableRez = [[NSMutableArray alloc] init];
    while ([rs next])
    {
        [mutableRez addObject:[Group groupWithResultSet:rs]];
    }
    
    NSArray *rez = [NSArray arrayWithArray: mutableRez];
    [rs close];
    [mutableRez release];
    return rez;
}

-(NSArray *) getGroupsOfFacility:(Facility *)facility
{
    NSString *selectQuery = @""
    "SELECT * FROM qliq_group WHERE guid IN"
    " (SELECT group_id FROM group_facility WHERE facility_npi = ?)";
    
    FMResultSet *rs = [self.db executeQuery:selectQuery, facility.npi];
    
    NSMutableArray *mutableRez = [[NSMutableArray alloc] init];
    while ([rs next])
    {
        [mutableRez addObject:[Group groupWithResultSet:rs]];
    }
    
    NSArray *rez = [NSArray arrayWithArray: mutableRez];
    [rs close];
    [mutableRez release];
    
    return rez;
}

-(NSArray*) getGroupmatesOfUser:(QliqUser *)user inGroup:(Group *)group
{
    NSString *selectQuery = @""
    "SELECT * FROM qliq_user WHERE email != ? AND email IN"
    " (SELECT user_id FROM user_group WHERE group_id = ?)";
    
    FMResultSet *rs = [self.db executeQuery:selectQuery, user.email, group.guid];
    
    NSMutableArray *mutableRez = [[NSMutableArray alloc] init];
    while ([rs next])
    {
        [mutableRez addObject:[QliqUser userWithResultSet:rs]];
    }
    
    NSArray *rez = [NSArray arrayWithArray: mutableRez];
    [rs close];
    [mutableRez release];
    return rez;
}

#pragma mark -
#pragma mark Private

-(BOOL) groupExists:(Group *)group
{
    BOOL rez = NO;
    
    NSString *selectQuery = @""
    "SELECT * FROM qliq_group WHERE guid = ?";
    
    FMResultSet *rs = [self.db executeQuery:selectQuery, group.guid];
    
    if([rs next])
    {
        rez = YES;
    }
    
    return rez;
}

-(BOOL) insertGroup:(Group *)group
{
    NSString *insertQuery = @""
    "INSERT INTO qliq_group "
    " (guid, "
    " name, "
    " type, "
    " npi, "
    " state, "
    " city, "
    " zip, "
    " address) "
    "VALUES (?,?,?,?,?,?,?,?)";
    
    BOOL rez = NO;
    
    [self.db beginTransaction];
    
    rez = [self.db executeUpdate:insertQuery,
           group.guid,
           group.name,
           group.type,
           group.npi,
           group.state,
           group.city,
           group.zip,
           group.address];
    
    if(!rez)
    {
        [self.db rollback];
    }
    else
    {
       [self.db commit];
    }
    return rez;
}

-(BOOL) updateGroup:(Group *)group
{
    NSString *updateQuery = @""
    " UPDATE qliq_group SET "
    " name = ?, "
    " type =  ?, "
    " npi = ?, "
    " state = ?, "
    " city = ?, "
    " zip = ?, "
    " address = ? "
    " WHERE guid = ?";
    
    BOOL rez = NO;
    
    [self.db beginTransaction];
    
    rez = [self.db executeUpdate:updateQuery,
           group.name,
           group.type,
           group.npi,
           group.state,
           group.city,
           group.zip,
           group.address,
           group.guid];
    
    if(!rez)
    {
        [self.db rollback];
    }
    else
    {
        [self.db commit];
    }
    return rez;
}

@end
