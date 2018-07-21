//
//  SipAccountSettings.m
//  qliq
//
//  Created by Paul Bar on 2/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SipAccountSettings.h"

@implementation SipAccountSettings

@synthesize serverInfo;
@synthesize sipUri;
@synthesize username;
@synthesize password;

#pragma mark -
#pragma mark serialization

static NSString *key_serverInfo = @"key_serverInfo";
static NSString *key_sipUri = @"key_sipUri";
static NSString *key_username = @"key_username";
static NSString *key_password = @"key_password";

-(void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.serverInfo forKey:key_serverInfo];
    [aCoder encodeObject:self.sipUri forKey:key_sipUri];
    [aCoder encodeObject:self.username forKey:key_username];
    [aCoder encodeObject:self.password forKey:key_password];
}

-(id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if(self)
    {
        self.serverInfo = [aDecoder decodeObjectForKey:key_serverInfo];
        self.sipUri = [aDecoder decodeObjectForKey:key_sipUri];
        self.username = [aDecoder decodeObjectForKey:key_username];
        self.password = [aDecoder decodeObjectForKey:key_password];
    }
    return self;
}

@end