//
//  QliqList.h
//  qliq
//
//  Created by Vita on 7/18/12.
//  Copyright (c) 2012 Al Digit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMResultSet.h"
#import "ContactGroup.h"

@interface ContactList : NSObject <ContactGroup>

@property (nonatomic, assign) NSInteger contactListId;
@property (nonatomic, assign) NSString *qliqId;
@property (nonatomic, retain) NSString *name;

+(ContactList*)listWithResultSet:(FMResultSet*)resultSet;

- (NSString *)recipientQliqId;

@end
