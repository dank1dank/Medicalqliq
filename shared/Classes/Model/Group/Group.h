//
//  Group.h
//  qliq
//
//  Created by Paul Bar on 2/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ContactGroup.h"

@class FMResultSet;

@interface Group : NSObject <ContactGroup>

@property (nonatomic, retain) NSString *guid;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *type;
@property (nonatomic, retain) NSNumber *npi;
@property (nonatomic, retain) NSString *state;
@property (nonatomic, retain) NSString *city;
@property (nonatomic, retain) NSString *zip;
@property (nonatomic, retain) NSString *address;

+(Group*) groupWithResultSet:(FMResultSet*)resultSet;

@end
