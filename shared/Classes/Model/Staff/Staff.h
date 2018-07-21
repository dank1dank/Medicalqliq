//
//  Staff.h
//  qliq
//
//  Created by Paul Bar on 12/26/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Contact.h"

@interface Staff : NSObject
{
    NSInteger entityID;
}

@property (nonatomic, retain) NSString *facility_npi;
@property (nonatomic, retain) NSString *prefix;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *suffix;
@property (nonatomic, retain) NSString *credentials;
@property (nonatomic, retain) NSString *initials;
@property (nonatomic, retain) NSString *mobile;
@property (nonatomic, retain) NSString *phone;
@property (nonatomic, retain) NSString *fax;
@property (nonatomic, retain) NSString *email;
@property (nonatomic, assign) NSInteger groupId;

+(Staff*) getStaffWithUsername:(NSString*) username;
+(Staff*) getStaffWithId:(NSNumber*)entity_id;
+(NSArray*) getAllStaff;
+(NSArray*) getStaffForGroupWithId:(NSInteger)groupId;

-(BOOL) save;

@end
