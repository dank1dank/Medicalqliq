//
//  QliqGroup.m
//  qliq
//
//  Created by Ravi Ada on 06/05/12.
//  Copyright (c) 2012 qliqSoft Inc. All rights reserved.
//

#import "QliqGroup.h"
#import "NSObject+AutoDescription.h"
#import "FMResultSet.h"
#import "QliqGroupDBService.h"
#import "QliqUserDBService.h"

@implementation QliqGroup


@synthesize qliqId;
@synthesize parentQliqId;
@synthesize contactId;
@synthesize name;
@synthesize acronym;
@synthesize address;
@synthesize city;
@synthesize state;
@synthesize zip;
@synthesize phone;
@synthesize fax;
@synthesize npi;
@synthesize taxonomyCode;
@synthesize accessType;
@synthesize locked;
@synthesize belongs;
@synthesize openMembership;
@synthesize canMessage;
@synthesize canBroadcast;
@synthesize isDeleted;

+ (QliqGroup *)groupWithResultSet:(FMResultSet *)resultSet
{
    QliqGroup *qliqGroup = [[QliqGroup alloc] init];
    
    qliqGroup.qliqId        = [resultSet stringForColumn:@"qliq_id"];
    qliqGroup.parentQliqId  = [resultSet stringForColumn:@"parent_qliq_id"];
    qliqGroup.acronym       = [resultSet stringForColumn:@"acronym"];
    qliqGroup.name          = [resultSet stringForColumn:@"name"];
    qliqGroup.address       = [resultSet stringForColumn:@"address"];
    qliqGroup.city          = [resultSet stringForColumn:@"city"];
    qliqGroup.state         = [resultSet stringForColumn:@"state"];
    qliqGroup.zip           = [resultSet stringForColumn:@"zip"];
    qliqGroup.phone         = [resultSet stringForColumn:@"phone"];
    qliqGroup.fax           = [resultSet stringForColumn:@"fax"];
    qliqGroup.npi           = [resultSet stringForColumn:@"npi"];
    qliqGroup.taxonomyCode  = [resultSet stringForColumn:@"taxonomy_code"];
    qliqGroup.canBroadcast  = [resultSet boolForColumn:@"can_broadcast"];
    qliqGroup.canMessage    = [resultSet boolForColumn:@"can_message"];
    qliqGroup.isDeleted     = [resultSet boolForColumn:@"deleted"];
    qliqGroup.belongs       = [resultSet boolForColumn:@"belongs"];
    qliqGroup.openMembership= [resultSet boolForColumn:@"open_membership"];
    return qliqGroup;
}

- (NSUInteger)getPendingCount{
    uint count = 0;
    NSArray * contacts = [self getContacts];
    for (Contact *contact in contacts){
        if (contact.contactStatus == ContactStatusNew) count++;
    }
    return count;
}

- (NSArray *)getNewContacts{
    NSMutableArray * newContacts = [[NSMutableArray alloc] init];
    NSArray * contacts = [self getContacts];
    for (Contact * contact in contacts){
        if (contact.contactStatus == ContactStatusNew)
            [newContacts addObject:contact];
    }
    
    if ([newContacts count] == 0) {
        newContacts = nil;
    }
    
    return newContacts;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"QliqGroup %@ %@", self.qliqId, self.name]; //[self autoDescription];
}

#pragma mark -
#pragma mark Serialization

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.qliqId forKey:@"qliqId"];
    [encoder encodeObject:self.parentQliqId forKey:@"parentQliqId"];
    [encoder encodeObject:self.name forKey:@"name"];
    [encoder encodeObject:self.acronym forKey:@"acronym"];
    [encoder encodeObject:self.address forKey:@"address"];
    [encoder encodeObject:self.city forKey:@"city"];
    [encoder encodeObject:self.state forKey:@"state"];
    [encoder encodeObject:self.zip forKey:@"zip"];
    [encoder encodeObject:self.phone forKey:@"phone"];
    [encoder encodeObject:self.npi forKey:@"npi"];
    [encoder encodeObject:self.taxonomyCode forKey:@"taxonomy_code"];
    [encoder encodeObject:[NSNumber numberWithBool:self.canBroadcast] forKey:@"can_broadcast"];
    [encoder encodeObject:[NSNumber numberWithBool:self.canMessage] forKey:@"can_message"];
    [encoder encodeObject:[NSNumber numberWithBool:self.isDeleted] forKey:@"deleted"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if((self = [super init]))
    {
        self.qliqId = [decoder decodeObjectForKey:@"qliqId"];
        self.parentQliqId = [decoder decodeObjectForKey:@"parentQliqId"];
        self.name = [decoder decodeObjectForKey:@"name"];
        self.acronym = [decoder decodeObjectForKey:@"acronym"];
        self.address = [decoder decodeObjectForKey:@"address"];
        self.city = [decoder decodeObjectForKey:@"city"];
        self.state = [decoder decodeObjectForKey:@"state"];
        self.zip = [decoder decodeObjectForKey:@"zip"];
        self.phone = [decoder decodeObjectForKey:@"phone"];
        self.fax = [decoder decodeObjectForKey:@"fax"];
        self.npi = [decoder decodeObjectForKey:@"npi"];
		self.taxonomyCode = [decoder decodeObjectForKey:@"taxonomy_code"];
        self.canBroadcast = [[decoder decodeObjectForKey:@"can_broadcast"] boolValue];
        self.canMessage = [[decoder decodeObjectForKey:@"can_message"] boolValue];
        self.isDeleted = [[decoder decodeObjectForKey:@"deleted"] boolValue];
    }
    return self;
}

#pragma mark - Util

- (BOOL)hasPagerUsers
{
   return [[QliqGroupDBService sharedService] isPagerUsersContainsInGroup:self];
}

- (NSUInteger)countOfParticipants
{
    return [[QliqGroupDBService sharedService] getCountOfParticipantsFor:self];
}

#pragma mark -
#pragma mark ContactQliqGroup

- (NSArray *)getOnlyContacts
{
    NSArray *rezult = [[QliqGroupDBService sharedService] getOnlyUsersOfGroup:self];
    return rezult;
}

- (NSString *)searchDescription{
    return [NSString stringWithFormat:@"%@ %@",name,acronym];
}

- (NSArray *)getContactsWithLimitFrom:(NSUInteger)startIndex to:(NSUInteger)countIndex andIsVisible:(BOOL)onlyVisible {
    
    return [self getContacts];
}

- (NSArray *) getVisibleContacts{
    return [self getContacts];
}

-(NSArray*) getContacts
{
    NSArray *rez = [[QliqGroupDBService sharedService] getUsersOfGroup:self];
    return rez;
}

-(void) addContact:(Contact *)contact
{
    //we can not add some contacts to qliqGroup (iPhoneContact for example)
    //to add User to qliqGroup use QliqGroupService addUserToQliqGroup method
}

#pragma mark - Recepient protocol

- (NSString *) recipientTitle{

    if ([parentQliqId length] > 0) {
        // Check if the name was prefixed with the acronym
        NSRange range = [name rangeOfString:@" • "];
        if (range.location == NSNotFound) {
            QliqGroup *parentGroup = [[QliqGroupDBService sharedService] getGroupWithId:parentQliqId];
            if (parentGroup != nil) {
                return [parentGroup.acronym stringByAppendingFormat:@" • %@", name];
            }
        }
    }
    
    return name;
}

- (NSString *)recipientSubtitle{
    return acronym;
}

- (BOOL)isRecipientEnabled{
    return YES;
}

- (NSString *)recipientQliqId{
    return self.qliqId;
}

- (SipContactType) sipContactType
{
    return SipContactTypeGroup;
}

#pragma mark - DBCoding

- (id)initWithDBCoder:(DBCoder *)decoder{
    
    self = [super init];
    if (self){
        // TODO: Missing:
        // self.contactId
        // self.locked
        self.parentQliqId = [decoder decodeObjectForColumn:@"parent_qliq_id"];
        self.name = [decoder decodeObjectForColumn:@"name"];
        self.acronym = [decoder decodeObjectForColumn:@"acronym"];
        self.address = [decoder decodeObjectForColumn:@"address"];
        self.city = [decoder decodeObjectForColumn:@"city"];
        self.state = [decoder decodeObjectForColumn:@"state"];
        self.zip = [decoder decodeObjectForColumn:@"zip"];
        self.phone = [decoder decodeObjectForColumn:@"phone"];
        self.fax = [decoder decodeObjectForColumn:@"fax"];
        self.npi = [decoder decodeObjectForColumn:@"npi"];
        self.taxonomyCode = [decoder decodeObjectForColumn:@"taxonomy_code"];
        self.accessType = [decoder decodeObjectForColumn:@"access_type"];
        self.canBroadcast = [[decoder decodeObjectForColumn:@"can_broadcast"] boolValue];
        self.canMessage = [[decoder decodeObjectForColumn:@"can_message"] boolValue];
        self.isDeleted = [[decoder decodeObjectForColumn:@"deleted"] boolValue];
    }
    return self;
}

- (void) encodeWithDBCoder:(DBCoder *)coder{
    // TODO: Missing:
    // self.contactId
    // self.locked
    coder.skipZeroValues = NO;
    coder.skipNilValues = NO;
    
    [coder encodeObject:self ofClass:[Contact class] forColumn:@"contact_id"];
    [coder encodeObject:self.parentQliqId forColumn:@"parent_qliq_id"];
    [coder encodeObject:self.name forColumn:@"name"];
    [coder encodeObject:self.acronym forColumn:@"acronym"];
    [coder encodeObject:self.address forColumn:@"address"];
    [coder encodeObject:self.city forColumn:@"city"];
    [coder encodeObject:self.state forColumn:@"state"];
    [coder encodeObject:self.zip forColumn:@"zip"];
    [coder encodeObject:self.phone forColumn:@"phone"];
    [coder encodeObject:self.fax forColumn:@"fax"];
    [coder encodeObject:self.npi forColumn:@"npi"];
    [coder encodeObject:self.taxonomyCode forColumn:@"taxonomy_code"];
    [coder encodeObject:self.accessType forColumn:@"access_type"];
    [coder encodeObject:[NSNumber numberWithBool:self.canBroadcast] forColumn:@"can_broadcast"];
    [coder encodeObject:[NSNumber numberWithBool:self.canMessage] forColumn:@"can_message"];
    [coder encodeObject:[NSNumber numberWithBool:self.isDeleted] forColumn:@"deleted"];
}

- (NSString *)dbPKProperty{
    return @"qliqId";
}

+ (NSString *)dbPKColumn{
    return @"qliq_id";
}

+ (NSString *)dbTable{
    return @"qliq_group";
}

@end
