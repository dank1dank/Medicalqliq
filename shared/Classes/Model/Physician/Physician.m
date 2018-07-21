//
//  Physician.m
//  CCiPhoneApp
//
//  Created by Ravi Ada on 4/12/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import "Physician.h"
#import "DBPersist.h"
#import "QliqKeychainUtils.h"
#import "PhysicianSchema.h"
#import "Helper.h"
#import "DBUtil.h"

@implementation Physician
@synthesize physicianNpi,groupId,groupName,groupFlag,name,initials,specialty,state,zip,mobile,phone,fax,email,address,city;
@synthesize classification,specialization;
@synthesize isDirty,isDetailViewHydrated;

+ (double) addPhysician:(Physician *)physician
{
    return [[DBPersist instance] addPhysician:physician];
}
+ (double) getPhysicianId:(Physician *) physician
{
	return [[DBPersist instance] getPhysicianId:physician];
}
+ (Physician *) getPhysician:(NSString*)emailid {
	return [[DBPersist instance] getPhysician:emailid];
}

+ (BOOL) deleteAllCharges
{
	return [[DBPersist instance] deleteAllCharges];
}

+ (Physician *) currentPhysician
{
    NSError *error = nil;
	NSString *username = [QliqKeychainUtils getItemForKey:KS_KEY_USERNAME error:&error];
	if ([username length] > 0)
		return [Physician getPhysician:username];
	else
		return nil;
}

+ (NSArray*) getGroupmatesForPhysicianWithNPI:(double)npi
{
    return [[DBPersist instance] getGroupmatesForPhysicianWithNPI:npi]; 
}

+(Physician*) getPhysicianWithNPI:(double)npi
{
    return [[DBPersist instance] getPhysicianWithNPI:npi];
}

+ (id) physicianFromDict:(NSDictionary *)dict
{
	Physician *physician = [[[Physician alloc] init] autorelease];
	
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
		physician.physicianNpi = [npi doubleValue];
	
	return physician;
}

- (BOOL) isValid
{
    return ([name length] > 0) && (physicianNpi > 0);
}

- (NSMutableDictionary *) toDict
{
    NSMutableDictionary *dict = [[[NSMutableDictionary alloc] init] autorelease];
    [dict setObject:name forKey:PHYSICIAN_NAME];
    [dict setObject:[NSString stringWithFormat:@"%0.0f", physicianNpi] forKey:PHYSICIAN_NPI];
    
    if (email)
        [dict setObject:email forKey:PHYSICIAN_EMAIL];
    
    if (specialty)
        [dict setObject:specialty forKey:PHYSICIAN_SPECIALTY];
    
    if (phone)
        [dict setObject:phone forKey:PHYSICIAN_PHONE];
    
    if (fax)
        [dict setObject:fax forKey:PHYSICIAN_FAX];
    
    if (mobile)
        [dict setObject:mobile forKey:PHYSICIAN_MOBILE];
    
    if (address)
        [dict setObject:address forKey:PHYSICIAN_ADDRESS];
    
    if (city)
        [dict setObject:city forKey:PHYSICIAN_CITY];
    
    if (state)
        [dict setObject:state forKey:PHYSICIAN_STATE];
    
    if (zip)
        [dict setObject:zip forKey:PHYSICIAN_ZIP];
	
    return dict;
}

- (id) initPhysicianWithPrimaryKey:(double) pk {
    
    [super init];
    physicianNpi = pk;
    isDetailViewHydrated = NO;
    
    return self;
}

-(id) initPhysicianWithResultSet:(FMResultSet *)resultSet
{
    self = [super init];
    if(self)
    {
        self.physicianNpi = [resultSet doubleForColumn:@"npi"];
        self.groupId = [resultSet intForColumn:@"group_id"];
        self.name = [resultSet stringForColumn:@"name"];
        self.initials = [resultSet stringForColumn:@"initials"];
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

+(NSArray*) getPhysiciansForGroupWithId:(NSInteger)groupId
{
    NSMutableArray *mutableRez = [[NSMutableArray alloc] init];
    NSString *username = [Helper getUsername];
	
    NSString *selectQuery =
    @"SELECT npi "
    "FROM physician "
	"WHERE group_id=? "
	"AND trim(email) != ? ";
    FMDatabase *db = [DBUtil sharedDBConnection];
    FMResultSet *resultSet = [db executeQuery:selectQuery,[NSNumber numberWithInt:groupId],username];
    while ([resultSet next])
    {
		double physicinNPI = [resultSet doubleForColumn:@"npi"];
		if(physicinNPI>0)
        {
			Physician *obj = [Physician getPhysicianWithNPI:[resultSet doubleForColumn:@"npi"]];
            if(obj)
            {
                [mutableRez addObject:obj];
            }
		}
    }
    NSArray *rez = [NSArray arrayWithArray:mutableRez];
    [mutableRez release];
    return rez;
}

-(NSString*)credentials
{
    NSArray *chunks = [self.name componentsSeparatedByString: @" "];
    if([chunks count]>=3)
    {
        return [chunks objectAtIndex:0];
    }
    return @"";
}


- (void) dealloc {
 	[name release];
	[groupName release];
    [initials release];
	[specialty release];
	[classification release];
	[specialization release];
    [state release];
    [zip release];
    [mobile release];
    [phone release];
    [fax release];
    [email release];
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
    self.firstName = [self firstName];
}

-(NSString*) lastName
{
    NSString * name_;
    NSInteger commaLocation = [self.name rangeOfString:@","].location;
    if (commaLocation != NSNotFound)
        name_ = [self.name substringToIndex:commaLocation];
    else
        name_ = self.name;
    NSArray *chunks = [name_ componentsSeparatedByString: @" "];
    if([chunks count]>=2)
    {
        if([chunks count]>=3)
        {
            return [chunks objectAtIndex:2];
        }
        return [chunks objectAtIndex:1];
    }
    return @"";
}

-(void) setLastName:(NSString *)lastName
{
    self.lastName = [self lastName];
}

-(NSString*) mobile
{
    return self.mobile;
}

-(void) setmobile:(NSString *)mobile
{
    self.mobile = mobile;
}

//phone synthesized
//email synthesized
//specialty synthesized
//group name synthesized

//@synthesize hospital;

-(NSString*) nameDescription
{
    return self.name;
}

-(NSComparisonResult) firstNameAck:(id<Contact>)contact
{
    return [self.firstName localizedCaseInsensitiveCompare:[contact firstName]];
}

-(NSComparisonResult) lastNameAck:(id<Contact>)contact
{
    return [self.lastName localizedCaseInsensitiveCompare:[contact lastName]];
}

-(BOOL) isQliqMember
{
    return YES;
}

-(QliqContactType) contactType
{
    return -1;
}

-(NSNumber*) contactId
{
    return [NSNumber numberWithDouble:self.physicianNpi];
}

@end



//Physician Superbill Implementation
@implementation PhysicianSuperbill
@synthesize physicianNpi,taxonomyCode,preferred;
@synthesize isDirty,isDetailViewHydrated;


+ (BOOL) assignPhysicianSuperbill:(PhysicianSuperbill *) physicianSuperbill
{
	return [[DBPersist instance] assignPhysicianSuperbill:physicianSuperbill];
}
+ (NSString *) getTaxonomyCodeForSpecialty:(NSString*)specialty {
	return [[DBPersist instance] getTaxonomyCodeForSpecialty:specialty];
}


- (id) initPhysicianSuperbillWithPrimaryKey:(double) pkPhysicianSuperbill {
    
    [super init];
    physicianNpi = pkPhysicianSuperbill;
    isDetailViewHydrated = NO;
    
    return self;
}

- (void) dealloc {
	[super dealloc];
}

@end


//Physician Preferences Implementation
@implementation PhysicianPref
@synthesize physicianNpi,defactoFacilityId,lastUsedPatientSortOrder,numberOfDaysToBill,faxToPrimary;
@synthesize lastOpenedFacilityId,lastUsedSuperbillId,lastUsedFacilityId,lastUsedCptCode;
@synthesize isDirty,isDetailViewHydrated;
@synthesize lastSelectedCptGroupIndex,lastSelectedCptCodeIndex,lastSelectedModifierIndex;

+ (PhysicianPref *) getPhysicianPrefs:(double) physicianNpi;
{
	return [[DBPersist instance] getPhysicianPrefs:physicianNpi];
}
+ (BOOL) updatePhysicianPrefs:(PhysicianPref*) physicianPrefObj
{
	return [[DBPersist instance] updatePhysicianPrefs:physicianPrefObj];
}

- (id) initPhysicianPrefWithPrimaryKey:(double) pkPhysicianPref {
    
    [super init];
    physicianNpi = pkPhysicianPref;
    isDetailViewHydrated = NO;
    
    return self;
}

- (void) dealloc {
	[super dealloc];
}

@end

