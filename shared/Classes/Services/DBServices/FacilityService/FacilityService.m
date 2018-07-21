//
//  FacilityService.m
//  qliq
//
//  Created by Paul Bar on 2/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FacilityService.h"
#import "Group.h"
#import "Floor.h"

@interface FacilityService()


-(BOOL) facilityExists:(Facility*)facility;
-(BOOL) insertFacility:(Facility*)facility;
-(BOOL) updateFacility:(Facility*)facility;
-(BOOL) user:(QliqUser*)user isMemberOfFacility:(Facility*)facility;
-(BOOL) floorExists:(Floor*)floor;
-(BOOL) insertFloor:(Floor*)floor;
-(BOOL) updateFloor:(Floor*)floor;

@end

@implementation FacilityService

-(BOOL) saveFacility:(Facility *)facility
{
    BOOL rez = NO;
    if([self facilityExists:facility])
    {
        rez = [self updateFacility:facility];
    }
    else
    {
        rez = [self insertFacility:facility];
    }
    return rez;
}

-(Facility*) getFacilityWithNpi:(NSNumber *)npi
{
    Facility *rez = nil;
    
    NSString *selectQuery = @""
    " SELECT * FROM facility WHERE npi = ?";
    
    FMResultSet *rs = [self.db executeQuery:selectQuery,npi];
    
    if([rs next])
    {
        rez = [Facility facilityWithResultSet:rs];
    }
    
    return rez;
}

-(NSArray*) getFacilities
{
    NSMutableArray *mutableRez = [[NSMutableArray alloc] init];
    
    NSString *selectQuery = @""
    @"SELECT * FROM facility";
    
    FMResultSet *rs = [self.db executeQuery:selectQuery];
    
    while ([rs next])
    {
        [mutableRez addObject:[Facility facilityWithResultSet:rs]];
    }
    
    NSArray *rez = [NSArray arrayWithArray:mutableRez];
    [mutableRez release];
    
    return rez;
}

-(BOOL) addUser:(QliqUser *)user toFacility:(Facility *)facility
{
    if([self user:user isMemberOfFacility:facility])
    {
        return YES;
    }
    
    NSString *insertQuery = @""
    "INSERT INTO user_facility(user_id, facility_npi) values(?,?)";
    
    [self.db beginTransaction];
    BOOL rez = [self.db executeUpdate:insertQuery, user.email, facility.npi];
    if(!rez)
    {
        [self.db rollback];
    }
    else
    {
        [self.db commit];
    }
    
    return rez;
}

-(NSArray*) getFacilitiesOfUser:(QliqUser *)user
{
    NSMutableArray *mutableRez = [[NSMutableArray alloc] init];
    
    NSString *selectQuery = @""
    " SELECT * FROM facility WHERE npi IN  "
    " (SELECT facility_npi FROM user_facility WHERE user_id = ?)";
    
    FMResultSet *rs = [self.db executeQuery:selectQuery, user.email];
    
    while ([rs next])
    {
        [mutableRez addObject:[Facility facilityWithResultSet:rs]];
    }
    
    [rs close];
    NSArray *rez = [NSArray arrayWithArray:mutableRez];
    [mutableRez release];
    return rez;
}

-(NSArray*) getUsersOfFacility:(Facility *)facility
{
    NSMutableArray *mutableRez = [[NSMutableArray alloc] init];
    
    NSString *selectQuery = @""
    " SELECT * FROM user WHERE email IN "
    " (SELECT user_id FROM user_facility WHERE facility_npi = ?) ";
    
    FMResultSet *rs = [self.db executeQuery:selectQuery, facility.npi];
    while ([rs next])
    {
        [mutableRez addObject:[QliqUser userWithResultSet:rs]];
    }
    
    [rs close];
    NSArray *rez = [NSArray arrayWithArray:mutableRez];
    [mutableRez release];
    return rez;    
}

-(BOOL) addGroup:(Group *)group toFacility:(Facility *)facility
{
    BOOL rez = NO;
    NSString *selectQuery = @""
    "SELECT * FROM group_facility WHERE facility_npi = ? AND group_id = ?";
    FMResultSet *rs = [self.db executeQuery:selectQuery,facility.npi, group.guid];
    if([rs next])
    {
        rez = YES;
    }
    [rs close];
    if(rez)
    {
        return rez;
    }
    
    NSString *insertQuery = @""
    "INSERT INTO group_facility(facility_npi,group_id) values (?,?)";
    rez = [self.db executeUpdate:insertQuery, facility.npi, group.guid];
    
    return rez;
}

-(BOOL) addFloor:(Floor *)floor toFacility:(Facility *)facility
{
    BOOL rez = NO;
    floor.facilityNpi = facility.npi;
    if([self floorExists:floor])
    {
        rez = [self updateFloor:floor];
    }
    else
    {
        rez = [self insertFloor:floor];
    }
    if(!rez)
    {
        floor.facilityNpi = nil;
    }
    return rez;
}

-(Floor*) getFloor:(Floor *) floor inFacility:(Facility*)facility //why we need to get FLOOR when we got one already? o_O
{
	Floor *flr = nil;
    
    NSString *selectQuery = @""
    "SELECT * FROM floor WHERE facility_npi = ? AND name = ?";
    
    FMResultSet *rs = [self.db executeQuery:selectQuery, facility.npi,floor.name];
    
    while ([rs next])
    {
        flr = [Floor floorWithResultSet:rs];
    }
    [rs close];
    return flr;

}

-(NSArray*) getFloorsOfFacility:(Facility *)facility
{
    NSMutableArray *mutableRez = [[NSMutableArray alloc] init];
    
    NSString *selectQuery = @""
    "SELECT * FROM floor WHERE facility_npi = ?";
    
    FMResultSet *rs = [self.db executeQuery:selectQuery, facility.npi];
    
    while ([rs next])
    {
        [mutableRez addObject:[Floor floorWithResultSet:rs]];
    }
    [rs close];
    
    NSArray *rez = [NSArray arrayWithArray:mutableRez];
    [mutableRez release];
    return rez;
}

#pragma mark -
#pragma mark Private

-(BOOL)facilityExists:(Facility *)facility
{
    BOOL rez = NO;
    
    NSString *selectQuery = @""
    "SELECT * FROM facility WHERE npi = ?";
    
    FMResultSet *rs = [self.db executeQuery:selectQuery,facility.npi];
    
    if([rs next])
    {
        rez = YES;
    }
    
    return rez;
}

-(BOOL)insertFacility:(Facility *)facility
{
    NSString *insertQuery = @""
    " INSERT INTO facility "
    " (npi, "
    " name, "
    " type, "
    " country, "
    " state, "
    " city, "
    " zip, "
    " address, "
    " phone) "
    " VALUES (?,?,?,?,?,?,?,?,?)";
    
    [self.db beginTransaction];
    
    BOOL rez = [self.db executeUpdate:insertQuery, 
                facility.npi,
                facility.name,
                facility.type,
                facility.country,
                facility.state,
                facility.city,
                facility.zip,
                facility.address,
                facility.phone];
    
    if(!rez)
    {
        [self.db rollback];
    }
    else
    {
       [self.db commit];
    }
    
    return rez;
}

-(BOOL) updateFacility:(Facility *)facility
{
    NSString *updateRequest = @""
    "UPDATE facility SET "
    " name = ?, "
    " type = ?, "
    " country = ?, "
    " state = ?, "
    " city = ?, "
    " zip = ?, "
    " address = ?, "
    " phone = ? "
    " WHERE npi = ? ";
    
    [self.db beginTransaction];
    
    BOOL rez = [self.db executeUpdate:updateRequest,
                facility.name,
                facility.type,
                facility.country,
                facility.state,
                facility.city,
                facility.zip,
                facility.address,
                facility.phone,
                facility.npi];
    
    if(!rez)
    {
        [self.db rollback];
    }
    else
    {
        [self.db commit];
    }
    
    return rez;
}

-(BOOL) user:(QliqUser *)user isMemberOfFacility:(Facility *)facility
{
    BOOL rez = NO;
    
    NSString *selectQuery = @""
    "SELECT * FROM user_facility WHERE user_id = ? AND facility_npi = ?";
    
    FMResultSet *rs = [self.db executeQuery:selectQuery, user.email, facility.npi];
    
    if([rs next])
    {
        rez = YES;
    }
    return rez;
}


-(BOOL) floorExists:(Floor *)floor
{
    NSString *selectQuery = @""
    "SELECT * FROM floor WHERE facility_npi = ? AND name = ?";
    
    FMResultSet *rs = [self.db executeQuery:selectQuery, floor.facilityNpi, floor.name];
    BOOL rez = NO;
    if([rs next])
    {
        floor.floorId = [NSNumber numberWithInt:[rs intForColumn:@"id"]];
        rez = YES;
    }

    [rs close];
    return rez;
}

-(BOOL) insertFloor:(Floor *)floor
{
    NSString *insertQuery = @""
    "INSERT INTO floor("
    " facility_npi, "
    " name, "
    " display_order, "
    " description "
    ") VALUES (?,?,?,?)";
    
    [self.db beginTransaction];
    BOOL rez = [self.db executeUpdate:insertQuery,
                floor.facilityNpi,
                floor.name,
                floor.displayOrder,
                floor.floorDescription];
    if(rez)
    {
        floor.floorId = [NSNumber numberWithInt:[self.db lastInsertRowId]];
        [self.db commit];
    }
    else
    {
       [self.db rollback];
    }
    return rez;
}

-(BOOL) updateFloor:(Floor *)floor
{
    NSString *updateQuery = @""
    "UPDATE floor SET"
    " facility_npi = ?, "
    " name = ?, "
    " display_order = ?, "
    " description = ? "
    " WHERE id = ? ";
    
    BOOL rez = [self.db executeUpdate:updateQuery,
                floor.facilityNpi,
                floor.name,
                floor.displayOrder,
                floor.floorDescription,
                floor.floorId];
    
    return rez;
}

@end
