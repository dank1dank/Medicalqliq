//
//  Nurse.m
//  CCiPhoneApp
//
//  Created by Ravi Ada on 11/30/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import "Nurse.h"
#import "DBHelperNurse.h"
#import "FMDatabase.h"
#import "DBPersist.h"
#import "DBUtil.h"

@implementation Nurse

@synthesize nurseId;
@synthesize nurseNpi;
@synthesize facilityNpi;
@synthesize facilityName;
@synthesize prefix;
@synthesize name;
@synthesize suffix;
@synthesize initials;
@synthesize taxonomyCode;
@synthesize credentials;
@synthesize mobile;
@synthesize phone;
@synthesize fax;
@synthesize email;
@synthesize groupId;

+ (Nurse *) getNurseWithUsername:(NSString *)username
{
	return [DBHelperNurse getNurseWithUsername:username];
}

+ (BOOL) addOrUpdateNurse:(Nurse *)nurseObj
{
    return [DBHelperNurse addOrUpdateNurse:nurseObj];
}

+ (Nurse*) getNurseWithId:(NSNumber *)entity_id
{
    NSString *selectNurseQuery = @"SELECT "
	" id as entity_id, "
	" npi as npi, "
	" facility_npi facility_npi, "
	" name as name, "
	" initials as initials, "
	" prefix as prefix, "
	" suffix as suffix, "
	" credentials as credentials, "
	" mobile as mobile, "
	" phone as phone, "
	" fax as fax, "
	" email as email, "
	" taxonomy_code as taxonomy_code, "
    " group_id as group_id "
	" FROM nurse WHERE nurse.id = ?";
    
    FMResultSet *nurse_rs = [[DBUtil sharedDBConnection]  executeQuery:selectNurseQuery, entity_id];
    
    Nurse *result = nil;
    
    if([nurse_rs next])
    {
        result  = [[Nurse alloc] init];
        NSString *primaryKey = [nurse_rs stringForColumn:@"entity_id"];
		result.nurseId = primaryKey;
		result.nurseNpi = [nurse_rs stringForColumn:@"npi"];
		result.facilityNpi = [nurse_rs stringForColumn:@"facility_npi"];
		result.name = [nurse_rs stringForColumn:@"name"];
		result.initials = [nurse_rs stringForColumn:@"initials"];
		result.prefix = [nurse_rs stringForColumn:@"prefix"];
		result.suffix = [nurse_rs stringForColumn:@"suffix"];
		result.mobile = [nurse_rs stringForColumn:@"mobile"];
		result.phone = [nurse_rs stringForColumn:@"phone"];
		result.fax = [nurse_rs stringForColumn:@"fax"];
		result.email = [nurse_rs stringForColumn:@"email"];
		result.credentials= [nurse_rs stringForColumn:@"credentials"];
		result.taxonomyCode	= [nurse_rs stringForColumn:@"taxonomy_code"];
        result.groupId = [nurse_rs intForColumn:@"group_id"];
    }
    
    return [result autorelease];
}

+(NSArray*) getAllNurses
{
    NSString *selectNurseQuery = @"SELECT "
	" nurse.id as nurse_id, "
	" nurse.npi as nurse_npi, "
	" nurse.facility_npi, "
	" nurse.name as nurse_name, "
	" nurse.initials, "
	" nurse.prefix, "
	" nurse.suffix, "
	" nurse.credentials, "
	" nurse.mobile, "
	" nurse.phone, "
	" nurse.fax, "
	" nurse.email, "
	" nurse.taxonomy_code, "
    " nurse.group_id as group_id "
	" FROM nurse ";
    
    NSMutableArray *mutableRez = [[NSMutableArray alloc] init];
    
    FMResultSet *nurse_rs = [[DBUtil sharedDBConnection]  executeQuery:selectNurseQuery];
    
    while([nurse_rs next])
    {
        Nurse *nurse  = [[Nurse alloc] init];
        NSString *primaryKey = [nurse_rs stringForColumn:@"nurse_id"];
		nurse.nurseId = primaryKey;
		nurse.nurseNpi = [nurse_rs stringForColumn:@"nurse_npi"];
		nurse.facilityNpi = [nurse_rs stringForColumn:@"facility_npi"];
		nurse.name = [nurse_rs stringForColumn:@"nurse_name"];
		nurse.initials = [nurse_rs stringForColumn:@"initials"];
		nurse.prefix = [nurse_rs stringForColumn:@"prefix"];
		nurse.suffix = [nurse_rs stringForColumn:@"suffix"];
		nurse.mobile = [nurse_rs stringForColumn:@"mobile"];
		nurse.phone = [nurse_rs stringForColumn:@"phone"];
		nurse.fax = [nurse_rs stringForColumn:@"fax"];
		nurse.email = [nurse_rs stringForColumn:@"email"];
		nurse.credentials= [nurse_rs stringForColumn:@"credentials"];
		nurse.taxonomyCode	= [nurse_rs stringForColumn:@"taxonomy_code"];
        nurse.groupId = [nurse_rs intForColumn:@"group_id"];
        [mutableRez addObject:nurse];
        [nurse release];
    }
    
    NSArray *rez = [NSArray arrayWithArray:mutableRez];
    [mutableRez release];
    return rez;
}

+(NSArray*) getNursesForGroupWithId:(NSInteger)groupId
{
    NSString *selectNurseQuery = @"SELECT "
	" nurse.id as nurse_id, "
	" nurse.npi as nurse_npi, "
	" nurse.facility_npi, "
	" nurse.name as nurse_name, "
	" nurse.initials, "
	" nurse.prefix, "
	" nurse.suffix, "
	" nurse.credentials, "
	" nurse.mobile, "
	" nurse.phone, "
	" nurse.fax, "
	" nurse.email, "
	" nurse.taxonomy_code, "
    " nurse.group_id as group_id "
	" FROM nurse "
    " WHERE group_id = ?";
    
    NSMutableArray *mutableRez = [[NSMutableArray alloc] init];
    
    FMResultSet *nurse_rs = [[DBUtil sharedDBConnection]  executeQuery:selectNurseQuery, [NSNumber numberWithInt:groupId]];
    
    while([nurse_rs next])
    {
        Nurse *nurse  = [[Nurse alloc] init];
        NSString *primaryKey = [nurse_rs stringForColumn:@"nurse_id"];
		nurse.nurseId = primaryKey;
		nurse.nurseNpi = [nurse_rs stringForColumn:@"nurse_npi"];
		nurse.facilityNpi = [nurse_rs stringForColumn:@"facility_npi"];
		nurse.name = [nurse_rs stringForColumn:@"nurse_name"];
		nurse.initials = [nurse_rs stringForColumn:@"initials"];
		nurse.prefix = [nurse_rs stringForColumn:@"prefix"];
		nurse.suffix = [nurse_rs stringForColumn:@"suffix"];
		nurse.mobile = [nurse_rs stringForColumn:@"mobile"];
		nurse.phone = [nurse_rs stringForColumn:@"phone"];
		nurse.fax = [nurse_rs stringForColumn:@"fax"];
		nurse.email = [nurse_rs stringForColumn:@"email"];
		nurse.credentials= [nurse_rs stringForColumn:@"credentials"];
		nurse.taxonomyCode	= [nurse_rs stringForColumn:@"taxonomy_code"];
        nurse.groupId = [nurse_rs intForColumn:@"group_id"];
        [mutableRez addObject:nurse];
        [nurse release];
    }
    
    NSArray *rez = [NSArray arrayWithArray:mutableRez];
    [mutableRez release];
    return rez;
}

- (id) initNurseWithPrimaryKey:(NSString *) pk
{    
    [super init];
    nurseId = pk;
    return self;
}

- (void) dealloc
{
	[nurseId release];
	[nurseNpi release];
	[facilityNpi release];
	[facilityName release];
	[prefix release];
 	[name release];
	[suffix release];
    [initials release];
    [taxonomyCode release];
    [credentials release];
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
    return [NSNumber numberWithDouble:[self.nurseId doubleValue]];
}

-(NSString*) specialty
{
    return @"Nurse";
}

-(void) setSpecialty:(NSString *)specialty
{
    
}

-(NSString*) groupName
{
    return @"";
}
-(void) setGroupName:(NSString *)groupName
{
    
}

@end

