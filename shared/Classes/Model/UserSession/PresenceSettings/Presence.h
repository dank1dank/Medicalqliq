//
//  Presence.h
//  qliq
//
//  Created by Aleksey Garbarev on 16.11.12.
//
//

#import <Foundation/Foundation.h>

static BOOL s_shouldAsk = YES;
@protocol Recipient;
@class QliqUser;

@interface Presence : NSObject<NSCoding, NSCopying>

@property (nonatomic, strong) NSString * presenceType;
@property (nonatomic, strong) NSString * message;
@property (nonatomic, strong) id<Recipient> forwardingUser;

@property (nonatomic, readwrite) BOOL allowEditMessage;

- (id) initWithType:(NSString *) presenceType;

- (void) setShouldAsk:(BOOL)asked;
+ (void) askForwardingIfNeededForRecipient:(id<Recipient>) recipient completeBlock:(void(^)(id<Recipient> selectedRecipient))completeBlock;
+ (BOOL) shouldAskForwardingIfNeededForRecipient:(id<Recipient>)recipient;

@end
