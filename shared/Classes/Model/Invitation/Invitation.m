//
//  Invitation.m
//  qliq
//
//  Created by Ravi Ada on 06/05/12.
//  Copyright (c) 2012 qliqSoft Inc. All rights reserved.
//

#import "Invitation.h"
#import "NSObject+AutoDescription.h"
#import "FMResultSet.h"
#import "InvitationService.h"
#import "ContactDBService.h"

@implementation Invitation


@synthesize uuid;
@synthesize url;
@synthesize contact;
@synthesize invitedAt;
@synthesize status;
@synthesize operation;

+(Invitation*) invitationWithResultSet:(FMResultSet *)resultSet
{
    @autoreleasepool {
        
        Invitation *invitation = [[Invitation alloc] init];
        
        invitation.uuid = [resultSet stringForColumn:@"uuid"];
        invitation.url = [resultSet stringForColumn:@"url"];
        invitation.invitedAt = [resultSet doubleForColumn:@"invited_at"];
        invitation.status = [[resultSet stringForColumn:@"status"] integerValue];
        invitation.operation = [resultSet intForColumn:@"operation"];
        invitation.contact = [[ContactDBService sharedService] getContactById:[resultSet intForColumn:@"contact_id"]];
        
        return invitation;
    }
}

- (NSString *) description{
    return [NSString stringWithFormat:@"{\nuuid = %@,\nurl = %@,\ninvitedAt = %g,\nstatus=%ld,\noperation=%ld,\ncontact=%@\n}",uuid,url,invitedAt,(long)status, (long)operation,contact];
}

-(void) dealloc
{
    self.uuid = nil;
    self.url = nil;
    self.contact = nil;
}

#pragma mark -
#pragma mark Serialization

//- (void)encodeWithCoder:(NSCoder *)encoder
//{
//    [encoder encodeObject:self.uuid forKey:@"uuid"];
//    [encoder encodeObject:self.url forKey:@"url"];
//    [encoder encodeObject:self.qliqId forKey:@"qliqId"];
//    [encoder encodeObject:self.email forKey:@"email"];
//    [encoder encodeObject:self.mobile forKey:@"mobile"];
//    [encoder encodeObject:self.name forKey:@"name"];
//    [encoder encodeObject:self.profession forKey:@"profession"];
//    [encoder encodeObject:self.specialty forKey:@"specialty"];
//    [encoder encodeObject:self.operation forKey:@"operation"];
//    [encoder encodeObject:[NSNumber numberWithDouble:self.invitedAt] forKey:@"invitedAt"];
//    [encoder encodeObject:self.status forKey:@"status"];
//	
//}
//
//- (id)initWithCoder:(NSCoder *)decoder
//{
//    if((self = [super init]))
//    {
//        self.uuid = [decoder decodeObjectForKey:@"uuid"];
//        self.url = [decoder decodeObjectForKey:@"url"];
//        self.qliqId = [decoder decodeObjectForKey:@"qliqId"];
//		self.email = [decoder decodeObjectForKey:@"email"];
//		self.mobile = [decoder decodeObjectForKey:@"mobile"];
//		self.name = [decoder decodeObjectForKey:@"name"];
//		self.profession = [decoder decodeObjectForKey:@"profession"];
//		self.specialty = [decoder decodeObjectForKey:@"specialty"];
//		self.operation = [decoder decodeObjectForKey:@"operation"];
//		self.invitedAt =[[decoder decodeObjectForKey:@"invitedAt"] doubleValue];
//		self.status = [decoder decodeObjectForKey:@"status"];
//    }
//    return self;
//}

@end
