//
//  Click2CallService.h
//  qliq
//
//  Created by Valerii Lider on 5/16/16.
//
//

#import <Foundation/Foundation.h>
#import "QliqAPIService.h"

@interface Click2CallService : NSObject

- (void)requestCallbackForCallerNumber:(NSString *)callerPhoneNumber toCalle:(NSString *)callePhoneNumber withCompletionBlock:(CompletionBlock)completion;

@end
