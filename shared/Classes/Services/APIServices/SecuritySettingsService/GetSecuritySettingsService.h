//
//  GetSecuritySettings.h
//  qliq
//
//  Created by Ravi Ada on 01/09/2013.
//  Copyright (c) 2012 qliqSoft Inc. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "QliqAPIService.h"

@interface GetSecuritySettingsService : QliqAPIService

- (id) initWithDeviceUuid:(NSString *) deviceUuid;


@end
