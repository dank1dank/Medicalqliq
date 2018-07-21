//
//  Group.m
//  qliq
//
//  Created by Paul Bar on 2/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Group.h"
#import "NSObject+AutoDescription.h"
#import "FMResultSet.h"
#import "QliqGroupService.h"
#import "QliqUserService.h"

@implementation Group

@synthesize guid;
@synthesize name;
@synthesize type;
@synthesize npi;
@synthesize state;
@synthesize city;
@synthesize zip;
@synthesize address;

+(Group*)groupWithResultSet:(FMResultSet *)resultSet
{
    Group *group = [[Group alloc] init];
    
    group.guid = [resultSet stringForColumn:@"guid"];
    group.name = [resultSet stringForColumn:@"name"];
    group.type = [resultSet stringForColumn:@"type"];
    group.npi = [NSNumber numberWithInt:[resultSet intForColumn:@"npi"]];
    group.state = [resultSet stringForColumn:@"state"];
    group.city = [resultSet stringForColumn:@"city"];
    group.zip = [resultSet stringForColumn:@"zip"];
    group.address = [resultSet stringForColumn:@"address"];
    
    return [group autorelease];
}

-(void) dealloc
{
    [self.guid release];
    [self.name release];
    [self.type release];
    [self.npi release];
    [self.state release];
    [self.city release];
    [self.zip release];
    [self.address release];
    [super dealloc];
}

-(NSString*)description
{
    return [self autoDescription];
}

#pragma mark -
#pragma mark Serialization

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.guid forKey:@"guid"];
    [encoder encodeObject:self.name forKey:@"name"];
    [encoder encodeObject:self.type forKey:@"type"];
    [encoder encodeObject:self.npi forKey:@"npi"];
    [encoder encodeObject:self.state forKey:@"state"];
    [encoder encodeObject:self.city forKey:@"city"];
    [encoder encodeObject:self.zip forKey:@"zip"];
    [encoder encodeObject:self.address forKey:@"address"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if((self = [super init]))
    {
        self.guid = [decoder decodeObjectForKey:@"guid"];
        self.name = [decoder decodeObjectForKey:@"name"];
        self.type = [decoder decodeObjectForKey:@"type"];
        self.npi = [decoder decodeObjectForKey:@"npi"];
        self.state = [decoder decodeObjectForKey:@"state"];
        self.city = [decoder decodeObjectForKey:@"city"];
        self.zip = [decoder decodeObjectForKey:@"zip"];
        self.address = [decoder decodeObjectForKey:@"address"];
    }
    return self;
}

#pragma mark -
#pragma mark ContactGroup

-(NSArray*) getContacts
{
    QliqGroupService *groupService = [[QliqGroupService alloc] init];
    NSArray *rez = [groupService getUsersOfGroup:self];
    [groupService release];
    return rez;
}

-(void) addContact:(id<Contact>)contact
{
    //we can not add some contacts to group (iPhoneContact for example)
    //to add User to group use GroupService addUserToGroup method
}

@end
