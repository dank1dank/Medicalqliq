//
//  QliqFavoritesContactGroup.h
//  qliqConnect
//
//  Created by Paul Bar on 12/12/11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ContactGroup.h"

@interface QliqFavoritesContactGroup : NSObject <ContactGroup>

- (BOOL)containsContact:(Contact *)contact;
- (void)removeContact:(Contact *)contact;

@end
