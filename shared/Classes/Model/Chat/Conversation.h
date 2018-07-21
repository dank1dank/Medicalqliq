//
//  Conversation.h
//  qliq
//
//  Created by Paul Bar on 2/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"
#import "DBCoder.h"
#import "SearchOperation.h"
#import "Recipients.h"

@class ChatMessage;
@class Recipients;
@class FhirEncounter;

typedef NS_ENUM(NSInteger, BroadcastType) {
    NotBroadcastType = 0,
    EncryptedBroadcastType,
    PlainTextBroadcastType, // when group includes pager users
    ReceivedBroadcastType
};

@interface Conversation : NSObject <Searchable, DBCoding>
{
	NSInteger conversationId;
	NSString *subject;
	NSString *fromQliqId;
	NSString *toQliqId;
	NSString *toUserSipUri;
	NSString *legQliqId;
	NSString *legUserName;
	BOOL isRead;
    NSInteger numberUnreadMessages;
    NSInteger numberUndeliveredMessages;
	NSString *lastMsg;
	NSTimeInterval createdAt;
	NSTimeInterval lastUpdated;
    
    NSString *uuid;
    NSString *redirectQliqId;
    BroadcastType broadcastType;
}

@property (nonatomic, readwrite) NSInteger conversationId;
@property (nonatomic, retain) NSString  *subject;
@property (nonatomic, retain) NSString  *fromQliqId UNAVAILABLE_ATTRIBUTE;
@property (nonatomic, retain) NSString  *toQliqId UNAVAILABLE_ATTRIBUTE;
@property (nonatomic, retain) NSString  *toUserSipUri UNAVAILABLE_ATTRIBUTE;
@property (nonatomic, retain) NSString  *legUserName UNAVAILABLE_ATTRIBUTE;
@property (nonatomic, retain) NSString  *legQliqId UNAVAILABLE_ATTRIBUTE;
@property (nonatomic, readwrite) BOOL  isRead;
@property (nonatomic, readwrite) NSInteger numberUnreadMessages;
@property (nonatomic, readwrite) NSInteger numberUndeliveredMessages;
@property (nonatomic, retain) NSString  *lastMsg;
@property (nonatomic, readwrite) NSTimeInterval createdAt;
@property (nonatomic, readwrite) NSTimeInterval lastUpdated;
@property (nonatomic, retain) NSString  *uuid;
@property (nonatomic, readwrite) BOOL archived;
@property (nonatomic, readwrite) BOOL deleted;
@property (nonatomic, retain) NSString  *redirectQliqId;
@property (nonatomic, readwrite) BroadcastType broadcastType;
@property (nonatomic, readwrite) BOOL isMuted;

@property (nonatomic, retain) Recipients *recipients;
@property (nonatomic, retain) FhirEncounter *encounter;

//Static methods.
-(NSComparisonResult) lastMsgTimestampAsc:(Conversation*)otherConversaton;

//Instance methods.
- (id) initWithPrimaryKey:(NSInteger)pk;
- (NSArray *)allRecipients;
- (BOOL) isCareChannel;
- (void) setIsCareChannel:(BOOL)value;
- (BOOL) isSentBroadcast;
- (BOOL) isReceivedBroadcast;
- (BOOL) isBroadcast;
@end