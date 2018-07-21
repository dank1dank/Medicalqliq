//
//  PhysicianGroup.h
//  qliqConnect
//
//  Created by Ravi Ada on 12/10/11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ContactGroup.h"

@interface PhysicianGroup : NSObject <ContactGroup> 
{
	NSInteger physicianGroupId;
	NSString *name;
    NSString *address;
    NSString *city;
    NSString *state;
    NSString *zip;
    NSString *phone;
    NSString *fax;
	
	BOOL isDirty;
	BOOL isDetailViewHydrated;
    
}
@property (nonatomic, readwrite) NSInteger physicianGroupId;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *address;
@property (nonatomic, retain) NSString *state;
@property (nonatomic, retain) NSString *city;
@property (nonatomic, retain) NSString *zip;
@property (nonatomic, retain) NSString *phone;
@property (nonatomic, retain) NSString *fax;
@property (nonatomic, readwrite) BOOL isDirty;
@property (nonatomic, readwrite) BOOL isDetailViewHydrated;

//Static methods.
+ (NSInteger) addPhysicianGroup: (PhysicianGroup *) physicianGroup;
+ (BOOL) updatePhysicianGroup:(PhysicianGroup *) physicianGroup;
+ (NSMutableArray *) getPhysicianGroupsToDisplay;
+ (NSArray*) getAllPhysicianGroups;
//Instance methods.
- (id) initWithPrimaryKey:(NSInteger)pk;
//- (id) initPhysicianGroupWithResultSet:(FMResultSet*)resultSet;

@end
