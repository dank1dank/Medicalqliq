//
//  SecuritySettings.m
//  qliq
//
//  Created by Paul Bar on 4/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SecuritySettings.h"
#import "QliqJsonSchemaHeader.h"

#import "KeychainService.h"

static NSString *key_MaxInactivityTime = @"key_maxInactivityTime";
static NSString *key_EnforcePinLogin   = @"key_EnforcePinLogin";
static NSString *key_UsePin            = @"key_UsePin";

@implementation SecuritySettings

@synthesize maxInactivityTime;
@synthesize enforcePinLogin;


//@property (nonatomic, readwrite, strong) NSString * password;
//@property (nonatomic, readwrite, strong) NSString * pin;
//@property (nonatomic, readwrite) BOOL usePin;

@synthesize usePin;

- (void)setPassword:(NSString *)password{
    [[KeychainService sharedService] savePassword:password];
}

- (NSString *)password{
    return [[KeychainService sharedService] getPassword];
}

- (void)setPin:(NSString *)pin{
    [[KeychainService sharedService] savePin:pin];
}

- (NSString *)pin{
    return [[KeychainService sharedService] getPin];
}

- (void)setUsePin:(BOOL)_usePin{
    usePin = _usePin;
    if (!usePin) [self setPin:nil];
} 

- (BOOL)usePin{
    return self.pin.length > 0;
}


+(SecuritySettings *)securitySettingsWithDictionary:(NSDictionary *)dict
{
    SecuritySettings *securitySettings = [[SecuritySettings alloc] init];
    securitySettings.maxInactivityTime = ([[dict objectForKey:INACTIVITY_TIME] intValue]) * 60;
	securitySettings.enforcePinLogin = [[dict objectForKey:ENFORCE_PIN] boolValue];
    securitySettings.usePin = securitySettings.enforcePinLogin;
    
    [[NSUserDefaults standardUserDefaults] setDouble:[[dict objectForKey:@"lock_out_time"] doubleValue]*60 forKey:@"login_failed_max_attemps"];
    [[NSUserDefaults standardUserDefaults] setInteger:[[dict objectForKey:@"login_failure_attempts"] integerValue] forKey:@"login_failed_max_attemps"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    return [securitySettings autorelease];
}

-(id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if(self){
        self.maxInactivityTime = [aDecoder decodeDoubleForKey:key_MaxInactivityTime];
        self.enforcePinLogin   = [aDecoder containsValueForKey:key_EnforcePinLogin] ? [aDecoder decodeBoolForKey:key_EnforcePinLogin] : NO;
        
        self.usePin = [aDecoder containsValueForKey:key_UsePin] ? [aDecoder decodeBoolForKey:key_UsePin] : [[[KeychainService sharedService] getPin] length] > 0;
    }
    return self;
}

-(void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeDouble:self.maxInactivityTime forKey:key_MaxInactivityTime];
    [aCoder encodeBool:self.enforcePinLogin forKey:key_EnforcePinLogin];
    [aCoder encodeBool:self.usePin forKey:key_UsePin];
}

@end
