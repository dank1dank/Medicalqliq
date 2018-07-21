//
//  Recipients.h
//  qliq
//
//  Created by Aleksey Garbarev on 23.11.12.
//
//
#import <Foundation/Foundation.h>

@protocol Recipient;

@interface Recipients : NSObject <DBCoding, NSCopying>

@property (nonatomic, strong) NSMutableArray *recipientsArray;

@property (nonatomic, assign) BOOL isPersonalGroup;

@property (nonatomic, strong) NSString *qliqId;
@property (nonatomic, strong) NSString *name;


- (BOOL)isSingleUser;
- (BOOL)isMultiparty;
- (BOOL)isMultipartyWithoutCurrentUser;
- (BOOL)isGroup;


- (NSString *)displayName;
- (NSString *)displayNameWrappedToWidth:(CGFloat)width font:(UIFont *)font;

- (BOOL)containsRecipient:(id<Recipient>)recipient;

// For one-to-one chatting
- (void)setRecipient:(id<Recipient>)recipient;
- (id<Recipient>)recipient;

// For multiparty chatting
- (id<Recipient>)recipientAtIndex:(NSUInteger)index;
- (NSArray *)allRecipients;
- (NSArray *)allRecipientsWithoutCurrentUser;
- (NSUInteger)count;

- (void)addRecipient:(id<Recipient>)recipient;
- (void)addRecipientsFromArray:(NSArray *)recipients;

- (void)removeRecipient:(id<Recipient>)recipient;
- (void)removeAllRecipients;

@end
