//
//  ContactBase.m
//  qliqConnect
//
//  Created by Paul Bar on 12/6/11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//

#import "Contact.h"
#import "QliqListService.h"
#import "ContactList.h"
#import "NSObject+AutoDescription.h"

#import "GetContactInfoService.h"

@implementation Contact

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        self.contactId      = [aDecoder decodeIntegerForKey:@"contactId"];
        self.firstName      = [aDecoder decodeObjectForKey:@"firstName"];
        self.middleName     = [aDecoder decodeObjectForKey:@"middleName"];
        self.lastName       = [aDecoder decodeObjectForKey:@"lastName"];
        self.groupName      = [aDecoder decodeObjectForKey:@"groupName"];
        self.mobile         = [aDecoder decodeObjectForKey:@"mobile"];
        self.phone          = [aDecoder decodeObjectForKey:@"phone"];
        self.email          = [aDecoder decodeObjectForKey:@"email"];
        self.address        = [aDecoder decodeObjectForKey:@"address"];
        self.city           = [aDecoder decodeObjectForKey:@"city"];
        self.state          = [aDecoder decodeObjectForKey:@"state"];
        self.avatar         = [UIImage imageWithData:[aDecoder decodeObjectForKey:@"avatar"]];
        self.avatarFilePath = [[aDecoder decodeObjectForKey:@"avatar_file_path"] stringByExpandingTildeInPath];
        self.contactStatus  = [aDecoder decodeIntegerForKey:@"contactStatus"];
        self.contactType    = [aDecoder decodeIntegerForKey:@"type"];
        self.qliqId         = [aDecoder decodeObjectForKey:@"qliq_id"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInteger:_contactId                        forKey:@"contactId"];
    [aCoder encodeObject:_firstName                         forKey:@"firstName"];
    [aCoder encodeObject:_middleName                        forKey:@"middleName"];
    [aCoder encodeObject:_lastName                          forKey:@"lastName"];
    [aCoder encodeObject:_groupName                         forKey:@"groupName"];
    [aCoder encodeObject:self.listName                      forKey:@"listName"];
    [aCoder encodeObject:_mobile                            forKey:@"mobile"];
    [aCoder encodeObject:_phone                             forKey:@"phone"];
    [aCoder encodeObject:_email                             forKey:@"email"];
    [aCoder encodeObject:_address                           forKey:@"address"];
    [aCoder encodeObject:_city                              forKey:@"city"];
    [aCoder encodeObject:_state                             forKey:@"state"];
    [aCoder encodeObject:_zip                               forKey:@"zip"];
    [aCoder encodeObject:UIImagePNGRepresentation(_avatar)  forKey:@"avatar"];
    [aCoder encodeObject:[_avatarFilePath stringByAbbreviatingWithTildeInPath] forKey:@"avatar_file_path"];
    [aCoder encodeInteger:_contactStatus                    forKey:@"contactStatus"];
    [aCoder encodeInteger:_contactType                      forKey:@"type"];
    [aCoder encodeObject:_qliqId                            forKey:@"qliq_id"];
}

#pragma mark - DBCoding

- (id)initWithDBCoder:(DBCoder *)decoder
{
    return [self initContactWithDBCoder:decoder];
}

- (id)initContactWithDBCoder:(DBCoder *)decoder
{
    self = [super init];
    if (self) {
        self.firstName      = [decoder decodeObjectForColumn:@"first_name"];
        self.middleName     = [decoder decodeObjectForColumn:@"middle_name"];
        self.lastName       = [decoder decodeObjectForColumn:@"last_name"];
        self.groupName      = [decoder decodeObjectForColumn:@"group_name"];
        self.mobile         = [decoder decodeObjectForColumn:@"mobile"];
        self.phone          = [decoder decodeObjectForColumn:@"phone"];
        self.email          = [decoder decodeObjectForColumn:@"email"];
        self.address        = [decoder decodeObjectForColumn:@"address"];
        self.city           = [decoder decodeObjectForColumn:@"city"];
        self.state          = [decoder decodeObjectForColumn:@"state"];
        self.avatar         = [UIImage imageWithData:[decoder decodeObjectForColumn:@"avatar"]];
        self.avatarFilePath = [[decoder decodeObjectForColumn:@"avatar_file_path"] stringByExpandingTildeInPath];
        self.contactStatus  = [[decoder decodeObjectForColumn:@"status"] integerValue];
        self.contactType    = [[decoder decodeObjectForColumn:@"type"] integerValue];
        self.qliqId         = [decoder decodeObjectForColumn:@"qliq_id"];
    }
    return self;
}

- (void)encodeWithDBCoder:(DBCoder *)coder
{
    coder.skipNilValues = NO;
    /* Disable skiping zero values from querys to save empty subject in db */
    coder.skipZeroValues = NO;
    
    [coder encodeObject:_firstName  forColumn:@"first_name"];
    [coder encodeObject:_middleName forColumn:@"middle_name"];
    [coder encodeObject:_lastName   forColumn:@"last_name"];
    [coder encodeObject:_groupName  forColumn:@"group_name"];
    [coder encodeObject:_mobile     forColumn:@"mobile"];
    [coder encodeObject:_phone      forColumn:@"phone"];
    [coder encodeObject:_email      forColumn:@"email"];
    [coder encodeObject:_address    forColumn:@"address"];
    [coder encodeObject:_city       forColumn:@"city"];
    [coder encodeObject:_state      forColumn:@"state"];
    [coder encodeObject:_zip        forColumn:@"zip"];
    [coder encodeObject:UIImagePNGRepresentation(_avatar)                       forColumn:@"avatar"];
    [coder encodeObject:[_avatarFilePath stringByAbbreviatingWithTildeInPath]   forColumn:@"avatar_file_path"];
    [coder encodeObject:@(_contactStatus)                                       forColumn:@"status"];
    [coder encodeObject:@(_contactType)                                         forColumn:@"type"];
    [coder encodeObject:_qliqId     forColumn:@"qliq_id"];
}

- (NSString *)dbPKProperty{
    return @"contactId";
}

+ (NSString *)dbPKColumn{
    return @"contact_id";
}

+ (NSString *)dbTable{
    return @"contact";
}


#pragma mark - Geters -

- (UIImage *)avatar {
    UIImage *result = nil;
    
    // This was added to avoid bug with avatars in ios8
    //AIII Get Avatars (For find were set avatar, enter in search "AIII Set Avatars")
    
    NSString *newAvatarPath = @"";
    NSString *avatarBasePath = [kDecryptedDirectory stringByAppendingPathComponent:@"avatars"];
    if (self.qliqId.length !=0) {
        newAvatarPath = [avatarBasePath stringByAppendingPathComponent:self.qliqId];
    }
    
    if (_avatar) {
        result = _avatar;
    }
    else if (newAvatarPath.length != 0) {
        result = [[UIImage alloc] initWithContentsOfFile:newAvatarPath];
    }
    
    return result;
}

#pragma mark -

- (id) init
{
    self = [super init];
    if (self){
        self.contactType = ContactTypeUnknown;
    }
    return self;
}

- (BOOL)isEqual:(Contact *)object
{
    if ([object isKindOfClass:[Contact class]]) {
        return self.contactId == object.contactId;
    } else {
        return NO;
    }
}

- (NSString *) searchDescription
{
    NSString *fullName = @"";
    if (![_middleName isEqualToString:@""] && _middleName != nil) {
        fullName = [NSString stringWithFormat:@"%@ %@ %@", _firstName, _middleName, _lastName];
    } else {
        fullName = [NSString stringWithFormat:@"%@ %@", _firstName, _lastName];
    }
    
//    return [NSString stringWithFormat:@"%@ %@ %@", fullName, _email, _groupName];
    return fullName;
}

- (NSString *)nameDescription
{
    NSMutableString *contactNameDescription = [[NSMutableString alloc] initWithCapacity:(self.lastName.length
                                                                                         + self.firstName.length
                                                                                         + self.middleName.length
                                                                                         + 3)];

    
    if(self.lastName && self.lastName.length > 0) {
        [contactNameDescription appendFormat:@"%@", self.lastName];
    }
    if(self.firstName && self.firstName.length > 0)
    {
        NSString *space = contactNameDescription.length > 0 ? @", " : @"";
        
        [contactNameDescription appendFormat:@"%@%@", space, self.firstName];
        
        if (self.middleName && self.middleName.length > 0) {
            [contactNameDescription appendFormat:@" %@.", [self.middleName substringToIndex:1]];
        }
    }
    
    NSString *rez = [NSString stringWithString:contactNameDescription];
    return rez;
}

- (NSString *)simpleName
{
    NSMutableString *contactNameDescription = [[NSMutableString alloc] initWithCapacity:([[self firstName] length]
																						 + [[self lastName] length]
																						 + 2)];
    
    if([self lastName] != nil && [[self lastName] length] > 0)
    {
        [contactNameDescription appendFormat:@"%@", [self lastName]];
    }
    
    if([self firstName] != nil && [[self firstName] length] >0)
    {
        NSString *space = contactNameDescription.length > 0 ? @", " : @"";
        
        [contactNameDescription appendFormat:@"%@%@", space, self.firstName];
    }
    
    NSString *rez = [NSString stringWithString:contactNameDescription];
    return rez;
}


- (NSString *) displayName
{
 return [self nameDescription];
}

-(NSComparisonResult) firstNameAck:(Contact *)contact
{
   return [self.firstName localizedCaseInsensitiveCompare:[contact firstName]];
}

-(NSComparisonResult) lastNameAck:(Contact *)contact
{
    return [self.lastName localizedCaseInsensitiveCompare:[contact lastName]];
}

-(NSString*) listName
{
    NSMutableString *rez = [NSMutableString string];
    NSArray *lists = [[QliqListService sharedService] getListsOfUser:self.contactId];
    for (ContactList * list in lists)
    {
        [rez appendFormat:@"%@, ", list.name];
    }
    if ([rez length] >= 2)
        [rez deleteCharactersInRange:NSMakeRange(rez.length-2, 2)];

    return rez;
}

-(void) setListName:(NSString *)listName
{
    
}

- (NSString *)description
{
    return [self autoDescription];
}

@end
