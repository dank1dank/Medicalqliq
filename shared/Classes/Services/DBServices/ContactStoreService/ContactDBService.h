//
//  ContactStoreService.h
//  qliq
//
//  Created by Aleksey Garbarev on 25.06.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QliqDBService.h"
#import "Contact.h"

@interface ContactDBService : QliqDBService

extern NSString * ContactServiceNewContactNotification;

+ (ContactDBService *) sharedService;

- (BOOL) saveContact:(Contact *) contact;

- (Contact*) getContactById:(NSInteger) contactId;
- (Contact*) getContactByEmail:(NSString*) email;
- (Contact *) getContactByMobile:(NSString *) mobile;
- (Contact *) getContactByQliqId:(NSString*) qliqId;

- (BOOL) deleteContact:(Contact *) contact;
- (BOOL) updateStatusAsDeletedForContactsWithoutSharedGroups:(NSString *)myQliqId;

- (NSUInteger) getNewContactsCount;

- (void) notifyAboutNewContact:(id) contact;

@end
