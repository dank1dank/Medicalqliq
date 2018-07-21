//
//  ReferringProvider.m
//  qliqConnect
//
//  Created by Ravi Ada on 12/10/11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//
#import "ReferringProvider.h"
#import "TaxonomyDbService.h"
#import "UserSession.h"
#import "UserSessionService.h"

//Referring Physician Implementation
@implementation ReferringProvider
@synthesize npi,firstName,lastName,middleName,groupName,prefix,suffix,credentials,address,city,state,zip,mobile,phone,fax,email,taxonomyCode,sipUri;
@synthesize avatar;
@synthesize speciality;

- (id) initReferringProviderWithResultSet:(FMResultSet*)resultSet
{
    self = [super init];
    if(self)
    {
		self.npi = [resultSet doubleForColumn:@"npi"];
		self.firstName = [resultSet stringForColumn:@"first_name"];
		self.lastName = [resultSet stringForColumn:@"last_name"];
		self.middleName = [resultSet stringForColumn:@"middle_name"];
		self.prefix = [resultSet stringForColumn:@"prefix"];
		self.suffix = [resultSet stringForColumn:@"suffix"];
		self.credentials = [resultSet stringForColumn:@"credentials"];
		self.address = [resultSet stringForColumn:@"address"];
		self.city = [resultSet stringForColumn:@"city"];
		self.state = [resultSet stringForColumn:@"state"];
		self.zip = [resultSet stringForColumn:@"zip"];
		self.mobile = [resultSet stringForColumn:@"mobile"];
		self.phone = [resultSet stringForColumn:@"phone"];
		self.fax = [resultSet stringForColumn:@"fax"];
		self.email = [resultSet stringForColumn:@"email"];
		self.taxonomyCode = [resultSet stringForColumn:@"taxonomy_code"];
		self.sipUri = [resultSet stringForColumn:@"sip_uri"];
		NSString *rphTaxonomyCode = [resultSet stringForColumn:@"taxonomy_code"];
		self.taxonomyCode=rphTaxonomyCode;

		/*
		TaxonomyDbService *tDbSvc = [[TaxonomyDbService alloc] init];
		NSString *rphSpecialty = [tDbSvc getSpeacilityForTaxonomyCode:rphTaxonomyCode];
		self.specialty = rphSpecialty;
		[tDbSvc	release];*/
	}
	return self;
}

- (void) dealloc
{
    [speciality release];
 	[firstName release];
 	[lastName release];
 	[middleName release];
 	[prefix release];
 	[suffix release];
 	[credentials release];
	[address release];
	[city release];
	[state release];
	[zip release];
	[mobile release];
	[phone release];
	[fax release];
	[email release];
	[taxonomyCode release];
	[sipUri release];
	[super dealloc];
}

#pragma mark -
#pragma mark Contact

-(BOOL) isQliqMember
{
	if([self.email length] > 0 && [self.sipUri length] > 0)
    {
		return YES;
    }
	else
    {
		return NO;
    }
}


-(NSString*) nameDescription
{
    return [NSString stringWithFormat:@"%@, %@", self.lastName,self.firstName];
}
-(NSString*) simpleName
{
    return [NSString stringWithFormat:@"%@ %@", self.firstName,self.lastName];
}


-(NSComparisonResult) firstNameAck:(id<Contact>)contact
{
    return [self.firstName localizedCaseInsensitiveCompare:[contact firstName]];
}

-(NSComparisonResult) lastNameAck:(id<Contact>)contact
{
    return [self.lastName localizedCaseInsensitiveCompare:[contact lastName]];
}

-(QliqContactType) contactType
{
    return QliqContactTypeReferringProvider;
}

-(NSString *) contactId
{
    return [[NSNumber numberWithDouble:self.npi] stringValue];
}

-(NSString*) speciality
{
    if(speciality == nil)
    {
        if([self.taxonomyCode length] != 0)
        {
            TaxonomyDbService *tDbSvc = [[TaxonomyDbService alloc] init];
            speciality = [tDbSvc getSpeacilityForTaxonomyCode:self.taxonomyCode];
            [tDbSvc release];
        }
        [speciality retain];
    }
    return speciality;
}

-(UIImage*) avatar
{
    NSString *qliqId = [UserSessionService currentUserSession].user.email;
    if(qliqId == nil) //in case when we got no current user (login for example)
    {
        UserSessionService *service = [[UserSessionService alloc] init];
        QliqUser *lastLoggedInUser = [service getLastLoggedInUser];
        qliqId = lastLoggedInUser.email;
        [service release];
    }
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *userAvatarsDir = [documentsDirectory stringByAppendingFormat:@"/%@/Avatars", qliqId];
    
    NSString *avatarFileName = [NSString stringWithFormat:@"%@/%@.png",userAvatarsDir,self.email];
    UIImage *rez = [UIImage imageWithContentsOfFile:avatarFileName];
    return rez;
}


@end
