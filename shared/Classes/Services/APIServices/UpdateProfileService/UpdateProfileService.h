//
//  UpdateProfileService.h
//  qliq
//
//  Created by Developer on 12.11.13.
//
//

#import "QliqAPIService.h"

typedef enum {UpdateProfileErrorCodeWebserverError, UpdateProfileErrorCodeInvalidRequest, UpdateProfileErrorCodeInvalidInfo} UpdateProfileErrorCode;
@interface UpdateProfileService : QliqAPIService

+ (instancetype)sharedService;

- (void)sendUpdateInfoWithCompletion:(void(^)(NSError *))completionBlock;

@end
