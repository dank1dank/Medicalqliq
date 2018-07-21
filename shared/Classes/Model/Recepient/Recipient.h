//
//  Recepient.h
//  qliq
//
//  Created by Aleksey Garbarev on 11/23/12.
//
//

#import <Foundation/Foundation.h>
#import "SearchOperation.h"

@protocol Recipient <NSObject, Searchable>

- (BOOL)isRecipientEnabled;

- (NSString *)recipientTitle;

@optional

- (UIImage *)recipientAvatar;

- (NSString *)recipientSubtitle;

- (NSString *)recipientQliqId;

@end
