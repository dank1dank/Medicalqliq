//
//  ReferringPhysician.m
//  qliqConnect
//
//  Created by Ravi Ada on 12/10/11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//
#import "ReferringPhysician.h"
#import "DBPersist.h"
#import "QliqKeychainUtils.h"
#import "PhysicianSchema.h"
#import "Helper.h"

//Referring Physician Implementation
@implementation ReferringPhysician
@synthesize referringPhysicianNpi,name,address,city,state,zip,mobile,phone,fax,email,specialty;
@synthesize classification,specialization;
@synthesize isDirty,isDetailViewHydrated;


+ (NSMutableArray *) getReferralPhysiciansToDisplay
{
	return [[DBPersist instance] getReferralPhysiciansToDisplay];
}
+ (double) addReferringPhysician :(ReferringPhysician *) referringPhysician
{
	return [[DBPersist instance] addReferringPhysician:referringPhysician];
}

+ (double) getReferringPhysicianId:(ReferringPhysician *) referringPhysician
{
	return [[DBPersist instance] getReferringPhysicianId:referringPhysician];
}

+ (ReferringPhysician *) getReferringPhysician:(double) referringPhysicianNpi
{
	return [[DBPersist instance] getReferringPhysician:referringPhysicianNpi];
}

+ (id) referringPhysicianFromDict:(NSDictionary *)dict
{
	ReferringPhysician *physician = [[[ReferringPhysician alloc] init] autorelease];
	
	physician.name = [dict objectForKey:PHYSICIAN_NAME];
	physician.email = [dict objectForKey:PHYSICIAN_EMAIL];
	physician.specialty = [dict objectForKey:PHYSICIAN_SPECIALTY];	
	physician.phone = [dict objectForKey:PHYSICIAN_PHONE];
	physician.fax = [dict objectForKey:PHYSICIAN_FAX];
	physician.mobile = [dict objectForKey:PHYSICIAN_MOBILE];
	physician.address = [dict objectForKey:PHYSICIAN_ADDRESS];
	physician.city = [dict objectForKey:PHYSICIAN_CITY];
	physician.state = [dict objectForKey:PHYSICIAN_STATE];
	physician.zip = [dict objectForKey:PHYSICIAN_ZIP];
	
	NSString *npi = [dict objectForKey:PHYSICIAN_NPI];
	if ([npi length] > 0)
		physician.referringPhysicianNpi = [npi doubleValue];
	
	return physician;
} 

- (id) initReferringPhysicianWithPrimaryKey:(double) pk {
    
    [super init];
    referringPhysicianNpi = pk;
    isDetailViewHydrated = NO;
    
    return self;
}
- (id) initReferringPhysicianWithResultSet:(FMResultSet*)resultSet
{
    self = [super init];
    if(self)
    {
		self.referringPhysicianNpi = [resultSet doubleForColumn:@"npi"];
		self.name = [resultSet stringForColumn:@"name"];
		self.address = [resultSet stringForColumn:@"address"];
		self.city = [resultSet stringForColumn:@"city"];
		self.state = [resultSet stringForColumn:@"state"];
		self.zip = [resultSet stringForColumn:@"zip"];
		self.mobile = [resultSet stringForColumn:@"mobile"];
		self.phone = [resultSet stringForColumn:@"phone"];
		self.fax = [resultSet stringForColumn:@"fax"];
		self.email = [resultSet stringForColumn:@"email"];
		self.classification= [resultSet stringForColumn:@"classification"];
		self.specialization= [resultSet stringForColumn:@"specialization"];
		if(self.specialization != nil && [self.specialization length]>0)
			self.specialty = self.specialization;
		else
			self.specialty = self.classification;
	}
	return self;
}

- (void) dealloc {
 	[name release];
	[address release];
	[city release];
	[state release];
	[zip release];
	[mobile release];
	[phone release];
	[fax release];
	[email release];
	[specialty release];
	[classification release];
	[specialization release];
	[super dealloc];
}

#pragma mark -
#pragma mark Contact

-(NSString*) firstName
{
    NSArray *chunks = [self.name componentsSeparatedByString: @" "];
    if([chunks count]>=2)
    {
        return [chunks objectAtIndex:0];
    }
    return @"";
}

-(void) setFirstName:(NSString *)firstName
{
    
}

-(NSString*) lastName
{
    NSArray *chunks = [self.name componentsSeparatedByString: @" "];
    if([chunks count]>=2)
    {
        return [chunks objectAtIndex:1];
    }
    return @"";
}

-(void) setLastName:(NSString *)lastName
{
    
}

-(NSString*) mobile
{
    return self.mobile;
}

-(void) setmobile:(NSString *)mobile
{
    self.mobile = mobile;
}


//@synthesize hospital;
//phone synthesized
//email synthesized
//specialty synthesized
//group name synthesized

-(NSString*) nameDescription
{
    return self.name;
}

-(BOOL) isQliqMember
{
    return NO;
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

-(NSNumber *) contactId
{
    return [NSNumber numberWithDouble:self.referringPhysicianNpi];
}

@end
