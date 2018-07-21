//
//  QliqUser.m
//  qliq
//
//
//  Created by Ravi Ada on 06/05/12.
//  Copyright (c) 2012 qliqSoft Inc. All rights reserved.
//

#import "QliqUser.h"
#import "NSObject+AutoDescription.h"
#import "FMResultSet.h"
#import "UserSessionService.h"
#import "UserSession.h"
#import "TaxonomyDbService.h"
#import "QliqGroupDBService.h"
#import "QliqGroup.h"
#import "ContactDBService.h"
#import "QliqJsonSchemaHeader.h"
#import "KeychainService.h"

#import "ContactAvatarService.h"

#import "DBCoder.h"
#import "DBCoder_DBService.h"

#import "DBUtil.h"

//tweak for groupName getter as it has custom realization
@interface QliqUser ()
@property (nonatomic, strong) NSString *groupString;
@end

@implementation QliqUser

@synthesize credentials;
@synthesize profession;
@synthesize npi;
@synthesize taxonomyCode;
@synthesize specialty;
@synthesize status;
@synthesize presenceStatus;
@synthesize presenceMessage;
@synthesize forwardingQliqId;
@synthesize organization;
@synthesize isPagerUser;
@synthesize pagerInfo;
//@synthesize contact;

NSString * QliqUserStateInvitationPending = @"Invitation_pending";  //users that not visible but we can send sip messages to them (they are active but not accepted invitation yet)
//NSString * QliqUserStateActivationPending = @"Pending";
//NSString * QliqUserStateLocked = @"Locked";
NSString * QliqUserStateActive = @"active";                         //active users that already connected with current user. We can send sip to them
NSString * QliqUserStateInactive = @"inactive";                     //users that can't receive sip.
NSString * QliqUserStateQliqStor = @"qliqstor";                     // qliqStor special user

///TODO: need to fix autoDescription
- (NSString *) description {
    return [NSString stringWithFormat:@"QliqUser %@ %@", self.qliqId,[self nameDescription] ]; //[self autoDescription];
}

- (id) init{
    self = [super init];
    if (self){
        self.contact = [[Contact alloc] init];
        self.contactType = ContactTypeQliqUser;
    }
    return self;
}

#pragma mark - Setter -

- (void)setContactId:(NSInteger)contactId {
    self.contact.contactId = contactId;
}

- (void)setQliqId:(NSString *)qliqId {
    self.contact.qliqId = qliqId;
}

- (void)setFirstName:(NSString *)firstName {
    self.contact.firstName = firstName;
}

- (void)setLastName:(NSString *)lastName {
    self.contact.lastName = lastName;
}

- (void)setGroupName:(NSString *)groupName {
    self.contact.groupName = groupName;
}

- (void)setListName:(NSString *)listName {
    self.contact.listName = listName;
}

- (void)setMiddleName:(NSString *)middleName {
    self.contact.middleName = middleName;
}

- (void)setMobile:(NSString *)mobile {
    self.contact.mobile = mobile;
}

- (void)setPhone:(NSString *)phone {
    self.contact.phone = phone;
}

- (void)setFax:(NSString *)fax {
    self.contact.fax = fax;
}

- (void)setEmail:(NSString *)email  {
    self.contact.email = email;
}

- (void)setAddress:(NSString *)address  {
    self.contact.address = address;
}

- (void)setCity:(NSString *)city  {
    self.contact.city = city;
}

- (void)setState:(NSString *)state  {
    self.contact.state = state;
}

- (void)setZip:(NSString *)zip  {
    self.contact.zip = zip;
}

- (void)setAvatarFilePath:(NSString *)avatarFilePath  {
    self.contact.avatarFilePath = avatarFilePath;
}

- (void)setContactType:(ContactType)contactType  {
    self.contact.contactType = contactType;
}

- (void)setContactStatus:(ContactStatus)contactStatus {
    self.contact.contactStatus = contactStatus;
}

- (void)setAvatar:(UIImage *)avatar {
    self.contact.avatar = avatar;
}

#pragma mark - Getter -

- (NSInteger)contactId {
    return self.contact.contactId;
}

- (NSString *)qliqId {
    return self.contact.qliqId;
}

- (NSString *)firstName {
    return self.contact.firstName ;
}

- (NSString *)lastName {
    return self.contact.lastName ;
}

- (NSString *)groupName {
    return self.contact.groupName;
}

- (NSString *)listName {
    return self.contact.listName;
}

- (NSString *)middleName {
    return self.contact.middleName;
}


- (NSString *)avatarFilePath {
    return self.contact.avatarFilePath;
}

- (ContactType)contactType {
    return self.contact.contactType;
}

- (ContactStatus)contactStatus {
    return self.contact.contactStatus;
}

- (NSString *)zip {
    return self.contact.zip ;
}

- (NSString *)state {
    return self.contact.state;
}

- (NSString *)city {
    return self.contact.city;
}

- (NSString *)address {
    return self.contact.address;
}

- (NSString *)email {
    return self.contact.email;
}

- (NSString *)fax {
    return self.contact.fax;
}

- (NSString *)phone {
    return self.contact.phone;
}

- (NSString *)mobile {
    return self.contact.mobile;
}

- (UIImage *)avatar {
    return self.contact.avatar;
}

- (PresenceStatus)presenceStatus {
    if (self.isPagerUser) {
        self.presenceStatus = [QliqUser presenceStatusFromString:@"pager_only"];
    }
    return presenceStatus;
}


#pragma mark - Serialization

- (void)encodeWithCoder:(NSCoder *)encoder{
    
	[self.contact encodeWithCoder:encoder];
    // qliqId comes from Contact superclass
    [encoder encodeObject:self.profession forKey:@"profession"];
    [encoder encodeObject:self.credentials forKey:@"credentials"];
    [encoder encodeObject:self.npi forKey:@"npi"];
    [encoder encodeObject:self.taxonomyCode forKey:@"taxonomyCode"];
    [encoder encodeObject:self.status forKey:@"status"];
    [encoder encodeObject:[NSNumber numberWithInt:self.presenceStatus] forKey:@"presence_status"];
    [encoder encodeObject:self.presenceMessage forKey:@"presence_message"];
    [encoder encodeObject:self.forwardingQliqId forKey:@"forwarding_qliq_id"];
    [encoder encodeObject:self.organization forKey:@"organization"];
    [encoder encodeObject:[NSNumber numberWithBool:self.isPagerUser] forKey:@"is_pager_only_user"];
    [encoder encodeObject:self.pagerInfo forKey:@"pager_info"];
}

- (id)initWithCoder:(NSCoder *)decoder{
    
    if((self = [super init])){
        // qliqId comes from Contact superclass
        self.contact = [[Contact alloc] initWithCoder:decoder];
        self.contactType = ContactTypeQliqUser;
        self.profession = [decoder decodeObjectForKey:@"profession"];
        self.credentials = [decoder decodeObjectForKey:@"credentials"];
        self.npi = [decoder decodeObjectForKey:@"npi"];
        self.taxonomyCode = [decoder decodeObjectForKey:@"taxonomyCode"];
        self.status = [decoder decodeObjectForKey:@"status"];
        self.presenceStatus = [[decoder decodeObjectForKey:@"presence_status"] intValue];
        self.presenceMessage = [decoder decodeObjectForKey:@"presence_message"];
        self.forwardingQliqId = [decoder decodeObjectForKey:@"forwarding_qliq_id"];
        self.organization = [decoder decodeObjectForKey:@"organization"];
        self.isPagerUser = [[decoder decodeObjectForKey:@"is_pager_only_user"] boolValue];
        self.pagerInfo = [decoder decodeObjectForKey:@"pager_info"];
    }
    return self;
}

#pragma mark - DBCoding

- (id)initWithDBCoder:(DBCoder *)decoder
{
    self = [super init];
    if (self){
        // qliqId comes from Contact superclass
        self.contact = [[Contact alloc] init];
        [decoder decodeObject:self.contact asClass:[Contact class] fromColumn:@"contact_id"];
        self.profession = [decoder decodeObjectForColumn:@"profession"];
        self.credentials = [decoder decodeObjectForColumn:@"credentials"];
        self.npi = [decoder decodeObjectForColumn:@"npi"];
        self.taxonomyCode = [decoder decodeObjectForColumn:@"taxonomy_code"];
        self.status = [decoder decodeObjectForColumn:@"status"];
        self.presenceStatus = [[decoder decodeObjectForColumn:@"presence_status"] intValue];
        self.presenceMessage = [decoder decodeObjectForColumn:@"presence_message"];
        self.forwardingQliqId = [decoder decodeObjectForColumn:@"forwarding_qliq_id"];
        self.organization = [decoder decodeObjectForColumn:@"organization"];
        self.isPagerUser = [[decoder decodeObjectForColumn:@"is_pager_only_user"] boolValue];
        self.pagerInfo = [decoder decodeObjectForColumn:@"pager_info"];
    }
    return self;
}

- (void) encodeWithDBCoder:(DBCoder *)coder{
    
    coder.skipZeroValues = NO;
    coder.skipNilValues = NO;
    
    // qliqId comes from Contact superclass
    [coder encodeObject:self.contact ofClass:[Contact class] forColumn:@"contact_id"];
    [coder encodeObject:self.profession forColumn:@"profession"];
    [coder encodeObject:self.credentials forColumn:@"credentials"];
    [coder encodeObject:self.npi forColumn:@"npi"];
    [coder encodeObject:self.taxonomyCode forColumn:@"taxonomy_code"];
    [coder encodeObject:self.status forColumn:@"status"];
    [coder encodeObject:[NSNumber numberWithInt:self.presenceStatus] forColumn:@"presence_status"];
    [coder encodeObject:self.presenceMessage forColumn:@"presence_message"];
    [coder encodeObject:self.forwardingQliqId forColumn:@"forwarding_qliq_id"];
    [coder encodeObject:self.organization forColumn:@"organization"];
    [coder encodeObject:[NSNumber numberWithBool:self.isPagerUser] forColumn:@"is_pager_only_user"];
    [coder encodeObject:self.pagerInfo forColumn:@"pager_info"];
}

- (NSString *)dbPKProperty{
    return @"qliqId";
}

+ (NSString *)dbPKColumn{
    return @"qliq_id";
}

+ (NSString *)dbTable{
    return @"qliq_user";
}


#pragma mark -
#pragma mark Contact


- (NSString*)appendString:(NSString*)string toString:(NSString*)existingString {
    NSString *appendedString = nil;
    
    if (existingString) {
        appendedString = [existingString stringByAppendingString:[NSString stringWithFormat:@", %@", string]];
    } else {
        appendedString = string;
    }
    
    return appendedString;
}

- (NSString *)nameDescription
{
	NSMutableString *contactNameDescription = [[NSMutableString alloc] initWithCapacity:(self.firstName.length
																						 + self.lastName.length
                                                                                         + self.middleName.length
                                                                                         + self.credentials.length
																						 + 12)];


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
    if(self.credentials && self.credentials.length > 0) {
        NSString *space = contactNameDescription.length > 0 ? @", " : @"";
        [contactNameDescription appendFormat:@"%@%@", space, self.credentials];
    }
    
    NSString *rez = [NSString stringWithString:contactNameDescription];
    return rez;
}
- (NSString *) simpleName
{
	NSMutableString *contactNameDescription = [[NSMutableString alloc] initWithCapacity:([self.firstName length]
																						 + [self.lastName length]
																						 + 2)];
    if(self.lastName != nil && [self.lastName length] > 0)
    {
        [contactNameDescription appendFormat:@"%@", self.lastName];
    }
    if(self.firstName != nil && [self.firstName length] >0)
    {
        NSString *space = contactNameDescription.length > 0 ? @", " : @"";
        
        [contactNameDescription appendFormat:@"%@%@", space, self.firstName];
        
        [contactNameDescription appendFormat:@"%@",self.firstName];
    }

   
    NSString *rez = [NSString stringWithString:contactNameDescription];
    return rez;
}

- (BOOL)isActive {
    return [status isEqualToString:@"active"];
}

- (void)mergeWith:(QliqUser *)contact {
    
    if ((!self.qliqId || ([self.qliqId isKindOfClass:[NSString class]] && !self.qliqId.length)) && ([contact.qliqId isKindOfClass:[NSString class]] && contact.qliqId.length)) {
        self.qliqId = contact.qliqId;
    }
    
    if ((!self.firstName || ([self.firstName isKindOfClass:[NSString class]] && !self.firstName.length)) && contact.firstName.length) {
        self.firstName = contact.firstName;
    }
    
    if ((!self.lastName || ([self.lastName isKindOfClass:[NSString class]] && !self.lastName.length)) && contact.lastName.length) {
        self.lastName = contact.lastName;
    }
    
    if ((!self.email || ([self.email isKindOfClass:[NSString class]] && !self.email.length)) && contact.email.length) {
        self.email = contact.email;
    }
    
    if ((!self.mobile || ([self.mobile isKindOfClass:[NSString class]] && !self.mobile.length)) && contact.mobile.length) {
        self.mobile = contact.mobile;
    }
    
    if ((!self.profession || ([self.profession isKindOfClass:[NSString class]] && !self.profession.length))
        && ([contact isKindOfClass:[QliqUser class]] && contact.profession.length)) {
        self.profession = contact.profession;
    }
    
    if ((!self.zip || ([self.zip isKindOfClass:[NSString class]] && !self.zip.length)) && contact.zip.length) {
        self.zip = contact.zip;
    }
    
    if ((!self.state || ([self.state isKindOfClass:[NSString class]] && !self.state.length)) && contact.state.length) {
        self.state = contact.state;
    }
    
    if ((!self.city || ([self.city isKindOfClass:[NSString class]] && !self.city.length)) && contact.city.length) {
        self.city = contact.city;
    }
}

//sorting

-(NSComparisonResult) firstNameAck:(Contact *)contact
{
    return [self.firstName localizedCaseInsensitiveCompare:[contact firstName]];
}

-(NSComparisonResult) lastNameAck:(Contact *)contact
{
    return [self.lastName localizedCaseInsensitiveCompare:[contact lastName]];
}

- (NSString *) displayName
{
    return [self nameDescription];
}

-(NSString*)specialty
{
    if(specialty == nil)
    {
        if([self.taxonomyCode length] != 0)
        {
            TaxonomyDbService *tDbSvc = [[TaxonomyDbService alloc] init];
            specialty = [tDbSvc getSpeacilityForTaxonomyCode:self.taxonomyCode];
        }
        else
        {
            //specialty = kind;
        }
    }
    return specialty;
}

- (NSMutableDictionary *) toDict
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    // Required fields
    [dict setObject:self.qliqId forKey:QLIQ_ID];
    [dict setObject:self.email forKey:PRIMARY_EMAIL];
    [dict setObject:self.firstName forKey:FIRST_NAME];
    [dict setObject:self.lastName forKey:LAST_NAME];
    
    if ([self.middleName length] > 0)
        [dict setObject:self.middleName forKey:MIDDLE_NAME];
    
    if ([self.address length] > 0)
        [dict setObject:self.address forKey:CITY];        

    if ([self.city length] > 0)
        [dict setObject:self.city forKey:CITY];        

    if ([self.state length] > 0)
        [dict setObject:self.state forKey:STATE];        

    if ([self.mobile length] > 0)
        [dict setObject:self.mobile forKey:MOBILE];        

    if ([self.phone length] > 0)
        [dict setObject:self.phone forKey:PHONE];        

    if ([self.fax length] > 0)
        [dict setObject:self.fax forKey:FAX];        

    if ([self.profession length] > 0)
        [dict setObject:self.profession forKey:PROFESSION];        

    if ([self.credentials length] > 0)
        [dict setObject:self.credentials forKey:CREDENTIALS];        

    if ([self.taxonomyCode length] > 0)
        [dict setObject:self.taxonomyCode forKey:TAXONOMY_CODE];        

    if ([self.npi length] > 0)
        [dict setObject:self.npi forKey:NPI];        

    return dict;
}

+ (QliqUser *) userFromDict:(NSDictionary *)dict;
{
    QliqUser *user = [[QliqUser alloc] init] ;
    user.qliqId = [dict objectForKey:QLIQ_ID];
    user.email = [dict objectForKey:PRIMARY_EMAIL];
    user.firstName = [dict objectForKey:FIRST_NAME];
	user.middleName = [dict objectForKey:MIDDLE];
	user.lastName = [dict objectForKey:LAST_NAME];
	user.profession = [dict objectForKey:PROFESSION];
	user.credentials = [dict objectForKey:CREDENTIALS];
	user.address = [dict objectForKey:ADDRESS];
	user.city = [dict objectForKey:CITY];
	user.state = [dict objectForKey:STATE];
	user.zip = [dict objectForKey:ZIP];
	user.mobile = [dict objectForKey:MOBILE];
	user.phone = [dict objectForKey:PHONE];
	user.fax = [dict objectForKey:FAX];
	user.taxonomyCode = [dict objectForKey:TAXONOMY_CODE];
	user.npi = [dict objectForKey:NPI];
    user.presenceMessage = [dict objectForKey:PRESENCE_MESSAGE];
    user.presenceStatus = [QliqUser presenceStatusFromString: [dict objectForKey:PRESENCE_STATUS]];
    user.forwardingQliqId = [dict objectForKey:FORWARDING_QLIQ_ID];
    user.organization = [dict objectForKey:ORGANIZATION];
    user.isPagerUser = [dict objectForKey:PAGER_USER];
    user.pagerInfo = [dict objectForKey:PAGER_INFO];
    return user;
}

+ (PresenceStatus) presenceStatusFromString:(NSString *)status
{
    PresenceStatus ret = OfflinePresenceStatus;
    status = [status lowercaseString];
    if ([@"online" isEqualToString:status]) {
        ret = OnlinePresenceStatus;
    } else if ([@"away" isEqualToString:status]) {
        ret = AwayPresenceStatus;
    } else if ([@"dnd" isEqualToString:status]) {
        ret = DoNotDisturbPresenceStatus;
    } else if ([@"offline" isEqualToString:status]) {
        ret = OfflinePresenceStatus;
    } else if ([@"pager_only" isEqualToString:status]){
        ret = PagerOnlyPresenceStatus;
    }
    return ret;
}

+ (NSString *) presenceStatusToString:(PresenceStatus) status
{
    switch (status) {
        case OnlinePresenceStatus:
            return @"online";
            break;
        case AwayPresenceStatus:
            return @"away";
            break;
        case DoNotDisturbPresenceStatus:
            return @"dnd";
            break;
        case PagerOnlyPresenceStatus:
            return @"pager_only";
            break;
        default:
            return @"offline";
            break;
    }
}

- (BOOL)isEqualToQliqUser:(QliqUser *)other
{
    if (!other || ![self.qliqId isEqualToString:other.qliqId]) {
        return NO;
    } else {
        return YES;
    }
}

- (BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[QliqUser class]]) {
        return NO;
    }
    
    return [self isEqualToQliqUser:(QliqUser *)object];
}

- (NSUInteger)hash
{
    return [self.qliqId hash];
}

#pragma mark - Recepient protocol

- (NSString *)recipientTitle {
    
    NSMutableString * name = [[NSMutableString alloc] init];
    
    if (self.lastName.length > 0) {
        [name appendString:self.lastName];
    }
    if (self.lastName.length > 0 && self.firstName.length > 0) {
        [name appendString:@", "];
    }
    if (self.firstName.length > 0) {
        [name appendString:self.firstName];
    }
    
    if (name.length == 0) {
        if (self.mobile.length) {
            [name appendString:self.mobile];
        }
        else if (self.email.length) {
            [name appendString:self.email];
        }
    }
    return name;
}

- (NSString *)recipientSubtitle {
    
    NSString * subtitle = self.specialty;
    if (!subtitle)
        subtitle = self.groupName;
    
    return subtitle;
}

- (UIImage *)recipientAvatar{

    UIImage * avatarImage = [[ContactAvatarService sharedService] getAvatarForContact:self.contact];
    if (!avatarImage)
    {
        UIView *renderView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, 60.f, 60.f)];
        renderView.backgroundColor =  kColorAvatarBackground;//  [UIColor colorWithRed:53.f/255.f green:88.f/255.f blue:152.f/255.f alpha:1.0f];
        
        NSString *firstLetter = [[[self recipientTitle] substringToIndex:1] uppercaseString];
        
        UILabel *letterLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.f, 0.f, 60.f, 60.f)];
        letterLabel.textAlignment   = NSTextAlignmentCenter;
        letterLabel.font            = [UIFont fontWithName:letterLabel.font.fontName size:40.f];
        letterLabel.textColor       = kColorAvatarTittle;
        letterLabel.text            = firstLetter;
        renderView.clipsToBounds    = YES;
        [renderView addSubview:letterLabel];
        
        UIGraphicsBeginImageContextWithOptions(renderView.bounds.size, renderView.opaque, 0.0);
        [renderView.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        avatarImage = viewImage;
    }
    
    return avatarImage;
}

- (BOOL)isRecipientEnabled{
    return [self isActive] || (self.isPagerUser && self.pagerInfo.length > 0);
}

- (NSString *)recipientQliqId{
    return self.qliqId;
}

#pragma mark - SipContact protocol
- (NSString *) privateKey
{
    return nil;
    
}

- (SipContactType) sipContactType
{
    return SipContactTypeUser;
}

- (NSString *) searchDescription {
    
//    return [NSString stringWithFormat:@"%@ %@ %@", [self.contact searchDescription], self.specialty, self.profession];
    return [self.contact searchDescription];
}


@end
