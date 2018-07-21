//
//  SendMessageToNonQliqUserService.h
//  qliq
//
//  Created by Adam Sowa on 31/12/15.
//
//

#import <Foundation/Foundation.h>
#import "QliqAPIService.h"

@interface SendMessageToNonQliqUserService : QliqAPIService

- (id)initWithEmail:(NSString *)email orMobile:(NSString *)mobile withSubject:(NSString *)subject message:(NSString *)message;

@end
