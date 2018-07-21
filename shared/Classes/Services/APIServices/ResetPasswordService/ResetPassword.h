//
//  ResetPassword.h
//  qliq
//
//  Created by Vita on 7/19/12.
//  Copyright (c) 2012 Al Digit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ResetPassword : NSOperation
+ (ResetPassword *) sharedService;

- (void)resetPassword:(NSString*) email onCompletion:(void(^)(BOOL success, NSError * error)) block;

@end
