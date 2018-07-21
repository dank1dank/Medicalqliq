//
//  QliqModelServiceFactory.h
//  qliqConnect
//
//  Created by Paul Bar on 12/7/11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ContactsProvider;

@interface QliqModelServiceFactory : NSObject

+(id<ContactsProvider>) contactsProviderForObject:(NSObject*)requestSender;

@end
