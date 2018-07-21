//
//  SipAccountSettings.h
//  qliq
//
//  Created by Paul Bar on 2/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SipContact.h"

@class SipServerInfo;

@interface SipAccountSettings : NSObject <NSCoding>

@property (nonatomic, strong) SipServerInfo *serverInfo;
@property (nonatomic, strong) NSString *sipUri;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;

@end