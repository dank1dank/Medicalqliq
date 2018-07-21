//
//  RoleService.h
//  qliq
//
//  Created by Paul Bar on 2/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DBServiceBase.h"
#import "Role.h"
#import "QliqUser.h"

@interface RoleService : DBServiceBase

-(BOOL) addRole:(Role*)role toUser:(QliqUser*)user;
-(NSArray*) getRolesOfUser:(QliqUser*)user;
-(BOOL) user:(QliqUser*)user haveRoleWithName:(NSString*)roleName;

@end
