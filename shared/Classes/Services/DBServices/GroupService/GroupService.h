//
//  GroupService.h
//  qliq
//
//  Created by Paul Bar on 2/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DBServiceBase.h"
#import "Group.h"
#import "QliqUser.h"

@class Facility;

@interface GroupService : DBServiceBase

-(BOOL) saveGroup:(Group*)group;
-(NSArray*) getGroups;
-(Group*) getGroupWithName:(NSString*)groupName;

-(BOOL) addUser:(QliqUser*)user toGroup:(Group*)group;
-(NSArray*) getUsersOfGroup:(Group*)group;
-(NSArray*) getGroupsOfUser:(QliqUser*)user;
-(NSArray*) getGroupsOfFacility:(Facility*)facility;
-(NSArray*) getGroupmatesOfUser:(QliqUser*)user inGroup:(Group*)group;

@end
