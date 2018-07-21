//
//  UpdateSipCredentials.h
//  qliq
//
//  Created by Adam Sowa on 30/12/2013.
//
//

#import <Foundation/Foundation.h>
#import "QliqAPIService.h"

@interface UpdateSipCredentialsService : QliqAPIService

- (void)update:(void(^)(NSError *))completionBlock;

@end
