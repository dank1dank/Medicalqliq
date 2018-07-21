//
//  SecuritySettings.h
//  qliq
//
//  Created by Paul Bar on 4/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SecuritySettings : NSObject <NSCoding>

@property (nonatomic, assign) NSTimeInterval maxInactivityTime;
@property (nonatomic, assign) BOOL enforcePinLogin;

//now they are wrappers to Keychain service
@property (nonatomic, readwrite, strong) NSString * password;
@property (nonatomic, readwrite, strong) NSString * pin;
@property (nonatomic, readwrite) BOOL usePin;


+(SecuritySettings*) securitySettingsWithDictionary:(NSDictionary*)dict;

@end
