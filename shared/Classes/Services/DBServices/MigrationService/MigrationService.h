//
//  MigrationService.h
//  qliq
//
//  Created by Ravi Ada on 07/10/2012
//  Copyright (c) 2012 qliqSoft All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Contact.h"


@interface MigrationService : NSObject 


+ (MigrationService *) sharedService;

- (BOOL) migrateConversationsFromOldDatabase;

@end
