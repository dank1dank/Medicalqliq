//
//  UpdatePasswordService.h
//  qliq
//
//  Created by Developer on 15.11.13.
//
//

#import "QliqAPIService.h"

typedef enum {UpdatePasswordErrorCodeWebserverError, UpdatePasswordeErrorCodeInvalidRequest, UpdatePasswordErrorCodeInvalidInfo} UpdatePasswordErrorCode;

@interface UpdatePasswordService : QliqAPIService

+ (instancetype) sharedService;
- (void)setNewPassword:(NSString *)newPassword withCompletion:(void(^)(NSError *))completionBlock;

@end
