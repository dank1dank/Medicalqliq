//
//  Staff.m
//  qliq
//
//  Created by Paul Bar on 12/26/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Staff.h"
#import "FMDatabase.h"
#import "DBUtil.h"

#define ARC4RANDOM_MAX      0x100000000

@interface Staff()

-(id) initWithResultSet:(FMResultSet*)result_set;

@end

@implementation Staff

@synthesize facility_npi;
@synthesize prefix;
@synthesize name;
@synthesize suffix;
@synthesize credentials;
@synthesize initials;
@synthesize mobile;
@synthesize phone;
@synthesize fax;
@synthesize email;
@synthesize groupId;

+(Staff*) getStaffWithUsername:(NSString *)username
{
    NSString *selectQuery = @"SELECT "
    " id as entity_id, "
    " facility_npi as facility_npi, "
    " prefix as prefix, "
    " name as name, "
    " suffix as suffix, "
    " credentials as credentials, "
    " initials as initials, "
    " mobile as mobile, "
    " phone as phone, "
    " fax as fax, "
    " email as email, "
    " group_id as group_id "
    " FROM staff "
    " WHERE trim(upper(staff.email)) = trim(upper(?))";
    
    FMDatabase *db = [DBUtil sharedDBConnection];
    FMResultSet *result_set = [db executeQuery:selectQuery, username];
    
    Staff *result = nil;
    if([result_set next])
    {
        result = [[Staff alloc] initWithResultSet:result_set];
    }
    
    [result_set close];
    return [result autorelease];
}

+(Staff*) getStaffWithId:(NSNumber *)entity_id
{
    NSString *selectQuery = @"SELECT "
    " id as entity_id, "
    " facility_npi as facility_npi, "
    " prefix as prefix, "
    " name as name, "
    " suffix as suffix, "
    " credentials as credentials, "
    " initials as initials, "
    " mobile as mobile, "
    " phone as phone, "
    " fax as fax, "
    " email as email, "
    " group_id as group_id "
    " FROM staff "
    " WHERE staff.id = ?";
    
    FMDatabase *db = [DBUtil sharedDBConnection];
    FMResultSet *result_set = [db executeQuery:selectQuery, entity_id];
    
    Staff *result = nil;
    
    if([result_set next])
    {
        result = [[Staff alloc] initWithResultSet:result_set];
    }
    
    [result_set close];
    
    return [result autorelease];
}


+(NSArray*) getAllStaff
{
    NSMutableArray *mutableRez = [[NSMutableArray alloc] init];
    
    FMDatabase *db = [DBUtil sharedDBConnection];
    
    NSString *selectQuery = @"SELECT "
    " id as entity_id, "
    " facility_npi as facility_npi, "
    " prefix as prefix, "
    " name as name, "
    " suffix as suffix, "
    " credentials as credentials, "
    " initials as initials, "
    " mobile as mobile, "
    " phone as phone, "
    " fax as fax, "
    " email as email, "
    " group_id as group_id "
    " FROM staff";
    FMResultSet *result_set = [db executeQuery:selectQuery];
    while([result_set next])
    {
        Staff *staff = [[Staff alloc] initWithResultSet:result_set];
        [mutableRez addObject:staff];
        [staff release];
    }
    
    [result_set close];
    NSArray *rez = [NSArray arrayWithArray:mutableRez];
    [mutableRez release];
    
    return rez;
}

+(NSArray *)getStaffForGroupWithId:(NSInteger)groupId
{
    NSMutableArray *mutableRez = [[NSMutableArray alloc] init];
    
    FMDatabase *db = [DBUtil sharedDBConnection];
    
    NSString *selectQuery = @"SELECT "
    " id as entity_id, "
    " facility_npi as facility_npi, "
    " prefix as prefix, "
    " name as name, "
    " suffix as suffix, "
    " credentials as credentials, "
    " initials as initials, "
    " mobile as mobile, "
    " phone as phone, "
    " fax as fax, "
    " email as email, "
    " group_id as group_id "
    " FROM staff "
    " WHERE group_id = ? ";
    
    FMResultSet *result_set = [db executeQuery:selectQuery, [NSNumber numberWithInt:groupId]];
    while([result_set next])
    {
        Staff *staff = [[Staff alloc] initWithResultSet:result_set];
        [mutableRez addObject:staff];
        [staff release];
    }
    
    [result_set close];
    NSArray *rez = [NSArray arrayWithArray:mutableRez];
    [mutableRez release];
    
    return rez;

}

-(id) init
{
    self = [super init];
    if(self)
    {
        entityID = 0;
    }
    return self;
}

-(id) initWithResultSet:(FMResultSet *)result_set
{
    self = [super init];
    if(self)
    {
        entityID = [result_set doubleForColumn:@"entity_id"];
        self.facility_npi = [result_set stringForColumn:@"facility_npi"];
        self.prefix = [result_set stringForColumn:@"prefix"];
        self.name = [result_set stringForColumn:@"name"];
        self.suffix = [result_set stringForColumn:@"suffix"];
        self.credentials = [result_set stringForColumn:@"credentials"];
        self.initials = [result_set stringForColumn:@"initials"];
        self.mobile = [result_set stringForColumn:@"mobile"];
        self.phone = [result_set stringForColumn:@"phone"];
        self.fax = [result_set stringForColumn:@"fax"];
        self.email = [result_set stringForColumn: @"email"];
        self.groupId = [result_set intForColumn:@"group_id"];
    }
    return self;
}

-(void) dealloc
{
    [facility_npi release];
    [prefix release];
    [name release];
    [suffix release];
    [credentials release];
    [initials release];
    [mobile release];
    [phone release];
    [fax release];
    [email release];
    [super dealloc];
}

-(BOOL) save
{
    //email == qliqId. so we can search records by email
    NSString *selectQuery = @"SELECT id as entity_id FROM staff WHERE trim(upper(staff.email)) = trim(upper(?))";
    
    FMDatabase *db = [DBUtil sharedDBConnection];
    
    [db beginTransaction];
    
    BOOL recordFound = NO;
    
    FMResultSet *result_set = [db executeQuery:selectQuery, self.email];
    
    if([result_set next])
    {
        recordFound = YES;
    }
    
    [result_set close];
    
    NSString *updateQuery = @"UPDATE staff SET "
    " facility_npi = ?, "
    " prefix = ?, "
    " name = ?, "
    " suffix = ?, "
    " credentials = ?, "
    " initials = ?, "
    " mobile = ?, "
    " phone = ?, "
    " fax = ?, "
    " group_id = ? "
    " WHERE trim(upper(staff.email)) = trim(upper(?)) ";
    
    NSString *insertQuery = @"INSERT INTO staff"
    "(id,"
    "facility_npi,"
    "prefix,"
    "name,"
    "suffix,"
    "credentials,"
    "initials,"
    "mobile,"
    "phone,"
    "fax,"
    "email,"
    "group_id) VALUES "
    "(?,?,?,?,?,?,?,?,?,?,?,?)";
    
    BOOL result = NO;
    
    if(recordFound)
    {
        result = [db executeUpdate:updateQuery,
                  self.facility_npi,
                  self.prefix,
                  self.name,
                  self.suffix,
                  self.credentials,
                  self.initials,
                  self.mobile,
                  self.phone,
                  self.fax,
                  [NSNumber numberWithInt: self.groupId],
                  self.email];
    }
    else
    {
        double val = floorf(((double)arc4random() / ARC4RANDOM_MAX) * 90000.0f);
        NSString *randomId = [NSString stringWithFormat:@"%.0f", val];
        result = [db executeUpdate:insertQuery,
                  randomId,
                  self.facility_npi,
                  self.prefix,
                  self.name,
                  self.suffix,
                  self.credentials,
                  self.initials,
                  self.mobile,
                  self.phone,
                  self.fax,
                  self.email,
                  [NSNumber numberWithInt:self.groupId]];
        entityID = [db lastInsertRowId];
    }
    
    if(result)
    {
        [db commit];
    }
    else
    {
        [db rollback];
    }
    
    return result;
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
    self.name = firstName;
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
    return [NSNumber numberWithInt:entityID];
}

-(NSString*) specialty
{
    return @"Staff";
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
