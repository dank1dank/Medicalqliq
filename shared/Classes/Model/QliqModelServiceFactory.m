//
//  QliqModelServiceFactory.m
//  qliqConnect
//
//  Created by Paul Bar on 12/7/11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//

#import "QliqModelServiceFactory.h"
#import "QliqContactsProvider.h"

@implementation QliqModelServiceFactory

+(id<ContactsProvider>) contactsProviderForObject:(NSObject *)requestSender
{
    return [[[QliqContactsProvider alloc] init] autorelease];
}

@end
