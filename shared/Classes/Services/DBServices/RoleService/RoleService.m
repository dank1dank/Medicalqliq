//
//  RoleService.m
//  qliq
//
//  Created by Paul Bar on 2/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RoleService.h"

@interface RoleService()

@end

@implementation RoleService

-(BOOL) addRole:(Role *)role toUser:(QliqUser *)user
{
    NSString *selectQuery = @""
    "SELECT * FROM user_role WHERE role = ? AND user_id = ?";
    
    FMResultSet *rs = [self.db executeQuery:selectQuery, role.name, user.email];
    if([rs next])
    {
        return YES;
    }
    
    NSString *insertQuery = @""
    "INSERT INTO user_role (user_id, role) values (?,?)";
    
    BOOL rez = NO;
    [self.db beginTransaction];
    rez = [self.db executeUpdate:insertQuery, user.email, role.name];
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


-(NSArray*) getRolesOfUser:(QliqUser *)user
{
    NSString *selectQuery = @""
    "SELECT * FROM user_role WHERE user_id = ?";
    
    NSMutableArray *mutableRez = [[NSMutableArray alloc] init];
    
    FMResultSet *rs = [self.db executeQuery:selectQuery, user.email];
    while ([rs next]) 
    {
        [mutableRez addObject:[Role roleWithResultSet:rs]];
    }
    
    NSArray *rez = [NSArray arrayWithArray:mutableRez];
    [mutableRez release];
    return rez;
}

-(BOOL) user:(QliqUser *)user haveRoleWithName:(NSString *)roleName
{
    BOOL rez = NO;
    NSString *selectQuery = @""
    @"SELECT * FROM user_role WHERE user_id = ? AND role = ?";
    FMResultSet *rs = [self.db executeQuery:selectQuery,user.email, roleName];
    if([rs next])
    {
        rez = YES;
    }
    
    return rez;
}

#pragma mark -
#pragma mark Private



@end
