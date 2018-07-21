//
//  LoginService.h
//  qliq
//
//  Created by Ravi Ada on 05/29/12.
//  Copyright (c) 2012 qliqSoft Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QliqAPIService.h"

//enum {LoginErrorCodeInvalidRequest, LoginErrorCodeInvalidCredentials, LoginErrorCodeInvalidResponse, LoginErrorCodeRequestTimout = -1001, LoginErrorCodeCantConnect = -1004};

enum {
    ErrorCodeLoginAccessDenied          = 107,
    ErrorCodeLoginInvalidCredentials    = 100,
    ErrorCodeLoginClientHasOldVersion   = 101,
    ErrorCodeLoginServerSideProblem     = 102,
    ErrorCodeLoginStaleInformation      = 103,
    ErrorCodeLoginNotContact            = 104,
    ErrorCodeLoginServerIsBeingUpgraded = 503
};

@interface LoginService : QliqAPIService

@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;

- (id)initWithUsername:(NSString *)username andPassword:(NSString *)password;

@end
