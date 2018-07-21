//
//  InvitationService.m
//  qliq
//
//  Created by Paul Bar on 2/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "InvitationService.h"
#import "UserSession.h"
#import "UserSessionService.h"
#import "QliqUser.h"
#import "ContactDBService.h"
#import "DBUtil.h"

@interface InvitationService()


-(BOOL) insertInvitation:(Invitation*)invitation;
-(BOOL) updateInvitation:(Invitation*)invitation;

-(void) invitationsChanged;
@end


NSString * InvitationServiceInvitationsChangedNotification = @"InvitationServiceInvitationsCountChangedNotification";

@implementation InvitationService

+ (InvitationService *) sharedService{
    
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [[InvitationService alloc] init];
        
    });
    return shared;
}

-(BOOL) saveInvitation:(Invitation*)invitation
{
    if (![[ContactDBService sharedService] saveContact:invitation.contact]) return NO;

    if([self isInvitationExists:invitation])
    {
        return [self updateInvitation:invitation];
    }
    else
    {
        return [self insertInvitation:invitation];
    }
    
}


-(Invitation*) getInvitationWithUuid:(NSString *)invitationUuid
{
    __block Invitation *rez = nil;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *selectQuery = @""
        " SELECT * FROM invitation WHERE uuid = ?";
        
        FMResultSet *rs = [db executeQuery:selectQuery, invitationUuid];
        if([rs next])
        {
            rez = [Invitation invitationWithResultSet:rs];
        }
        [rs close];
    }];
    return rez;
}

-(NSArray*) getReceivedInvitations;
{
    __block NSMutableArray *mutableRez = [[NSMutableArray alloc] init];
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString * selectQuery = [NSString stringWithFormat:@"SELECT * FROM invitation WHERE operation = %ld ORDER BY invited_at DESC",(long)InvitationOperationReceived];
        
        FMResultSet *rs = [db executeQuery:selectQuery];
        while ([rs next])
        {
            [mutableRez addObject:[Invitation invitationWithResultSet:rs]];
        }
        [rs close];
    }];
    return mutableRez;
}

-(NSArray*) getSentInvitations;
{
    __block NSMutableArray *mutableRez = [[NSMutableArray alloc] init];
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString * selectQuery = [NSString stringWithFormat:@"SELECT * FROM invitation WHERE operation = %ld ORDER BY invited_at DESC",(long)InvitationOperationSent];
        
        FMResultSet *rs = [db executeQuery:selectQuery];
        
        while ([rs next])
        {
            [mutableRez addObject:[Invitation invitationWithResultSet:rs]];
        }
        [rs close];
    }];
    return mutableRez;
}

-(int) getPendingInvitationCount;
{
    __block int pendingInvitations = 0;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString * selectQuery = [NSString stringWithFormat:
                                  @"SELECT count(*) AS pending_invitations FROM invitation WHERE status = \"%ld\" AND operation = %ld",(long)InvitationStatusNew,(long)InvitationOperationReceived];
       
        
        FMResultSet *rs = [db executeQuery:selectQuery];
        
        
        
        while ([rs next])
        {
            pendingInvitations = [rs intForColumn:@"pending_invitations"];
        }
        [rs close];
    }];
    return pendingInvitations;
}



-(BOOL) isInvitationExists:(Invitation*)invitation
{
    __block BOOL rez = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *selectQuery = @""
        "SELECT * FROM invitation WHERE uuid = ?";
        
        FMResultSet *rs = [db executeQuery:selectQuery, invitation.uuid];
        
        if([rs next])
        {
            rez = YES;
        }
        [rs close];
    }];
    return rez;
}


#pragma mark -
#pragma mark Private

- (void) invitationsChanged{
    [[NSNotificationCenter defaultCenter] postNotificationName:InvitationServiceInvitationsChangedNotification object:nil userInfo:nil];
}

-(BOOL) insertInvitation:(Invitation*)invitation
{
    __block BOOL rez = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *insertQuery = @"INSERT INTO invitation "
                                 " (uuid, url, contact_id, operation, invited_at, status) "
                                 " VALUES (?,?,?,?,?,?)";
                                 
        rez = [db executeUpdate:insertQuery,
               invitation.uuid,
               (invitation.url && invitation.url.length ? invitation.url : @""),
               [NSNumber numberWithInteger:invitation.contact.contactId],
               [NSNumber numberWithInt:invitation.operation],
               [NSNumber numberWithDouble:invitation.invitedAt],
               [NSString stringWithFormat:@"%ld", (long)invitation.status]];
    }];

     if (rez) {
         [self invitationsChanged];
     }
     
     return rez;
}

- (BOOL) deleteInvitation:(Invitation *) invitation{
    __block BOOL rez = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString * deleteQuery = @"DELETE FROM invitation WHERE uuid = ? ";
        rez = [db executeUpdate:deleteQuery,invitation.uuid];
    }];
	
    if(rez)
    {
        [self invitationsChanged];
    }
    return rez;

}

-(BOOL) updateInvitation:(Invitation*)invitation
{
    __block BOOL rez = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *updateQuery = nil;
        if (invitation.url.length) {
            
            updateQuery = @"UPDATE invitation SET "
            " url = ?, "
            " contact_id = ?, "
            " operation = ?, "
            " invited_at = ?, "
            " status = ? "
            " WHERE uuid = ? ";
            
            rez = [db executeUpdate:updateQuery,
                   invitation.url,
                   [NSNumber numberWithInteger:invitation.contact.contactId],
                   [NSNumber numberWithInt:invitation.operation],
                   [NSNumber numberWithDouble:invitation.invitedAt],
                   [NSString stringWithFormat:@"%ld", (long)invitation.status],
                   invitation.uuid];
        } else {
            
            updateQuery = @"UPDATE invitation SET "
            " contact_id = ?, "
            " operation = ?, "
            " invited_at = ?, "
            " status = ? "
            " WHERE uuid = ? ";
            
            rez = [db executeUpdate:updateQuery,
                   [NSNumber numberWithInteger:invitation.contact.contactId],
                   [NSNumber numberWithInteger:invitation.operation],
                   [NSNumber numberWithDouble:invitation.invitedAt],
                   [NSString stringWithFormat:@"%ld", (long)invitation.status],
                   invitation.uuid];
        }
    }];
    if(rez)
    {
        [self invitationsChanged];
        
    }
    return rez;
}

@end
