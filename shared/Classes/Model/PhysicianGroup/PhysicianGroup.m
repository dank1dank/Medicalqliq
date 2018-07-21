//
//  PhysicianGroup.m
//  qliqConnect
//
//  Created by Ravi Ada on 12/10/11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//

#import "PhysicianGroup.h"
#import "DBPersist.h"
#import "Nurse.h"
#import "Staff.h"

//Physician Group Implementation
@implementation PhysicianGroup
@synthesize physicianGroupId,name,address,city,state,zip,phone,fax;
@synthesize isDirty,isDetailViewHydrated;


+ (NSInteger) addPhysicianGroup :(PhysicianGroup *) physicianGroup
{
	return [[DBPersist instance] addPhysicianGroup:physicianGroup];
}

+ (BOOL) updatePhysicianGroup:(PhysicianGroup *) physicianGroup
{
	return [[DBPersist instance] updatePhysicianGroup:physicianGroup];
}

+ (NSMutableArray *) getPhysicianGroupsToDisplay
{
	return [[DBPersist instance] getPhysicianGroupsToDisplay];
}
- (id) initWithPrimaryKey:(NSInteger) pk {
    
    [super init];
    physicianGroupId = pk;
    isDetailViewHydrated = NO;
    return self;
}

+(NSArray*)getAllPhysicianGroups
{
    //TIP: SQL query for all groups;
    NSArray *rez = [NSArray arrayWithArray:[self getPhysicianGroupsToDisplay]];
	return rez;
}

- (void) dealloc {
 	[name release];
	[address release];
	[city release];
	[state release];
	[zip release];
	[phone release];
	[fax release];
	[super dealloc];
}

#pragma mark -
#pragma mark ContactGroup

-(void) addContact:(id<Contact>)contact
{
    
}

-(NSArray*) getContacts
{
    
    NSMutableArray *mutableRez = [[NSMutableArray alloc] init];
    
    //TIP: query all group members
    //TIP:
    [mutableRez addObjectsFromArray: [Physician getPhysiciansForGroupWithId: self.physicianGroupId]];
    [mutableRez addObjectsFromArray: [Nurse getNursesForGroupWithId:self.physicianGroupId]];
    [mutableRez addObjectsFromArray: [Staff getStaffForGroupWithId:self.physicianGroupId]];
    
    NSArray *rez = [NSArray arrayWithArray:mutableRez];
    [mutableRez release];
    return  rez;
}

@end

