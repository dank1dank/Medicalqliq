//
//  Conversation.m
//  qliq
//
//  Created by Paul Bar on 2/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Conversation.h"
#import "DBHelperConversation.h"
#import "ChatMessage.h"
#import "FMDatabase.h"
#import "DBUtil.h"
#import "NSDate+Helper.h"
#import "Recipients.h"
#import "ConversationDBService.h"
#import "ChatMessageService.h"
#import "FhirResources.h"

@implementation Conversation {
    NSInteger _isCareChannel;
}

@synthesize conversationId;
@synthesize fromQliqId;
@synthesize toQliqId;
@synthesize legQliqId;
@synthesize legUserName;
@synthesize toUserSipUri;
@synthesize isRead;
@synthesize numberUnreadMessages;
@synthesize numberUndeliveredMessages;
@synthesize lastMsg;
@synthesize createdAt;
@synthesize lastUpdated;
@synthesize uuid;
@synthesize subject;
@synthesize archived;
@synthesize deleted;
@synthesize redirectQliqId;
@synthesize broadcastType;
@synthesize isMuted;
@synthesize recipients;

- (NSString *) description{
    return [NSString stringWithFormat:@"id: %ld, lastMsg: %@, isRead: %d, dates: (%g, %g), subject: %@",(long)conversationId,lastMsg,isRead,createdAt,lastUpdated, subject];
}

- (NSComparisonResult)lastMsgTimestampAsc:(Conversation *)otherConversaton
{
    NSComparisonResult rez = NSOrderedSame;

    if(otherConversaton.lastUpdated == self.lastUpdated)
        rez = NSOrderedSame;
    
    else if(self.lastUpdated < otherConversaton.lastUpdated)
        rez = NSOrderedDescending;
    
    else if(self.lastUpdated > otherConversaton.lastUpdated)
        rez = NSOrderedAscending;
    
    return rez;
}

- (id) init{
    self = [super init];
    if (self) {
        self.recipients = [[Recipients alloc] init];
        
        /* When object created - use current date as 'createdAt'. When loaded from db, it override by db */
        self.createdAt = [[NSDate date] timeIntervalSince1970];
    }
    return self;
}

- (id) initWithPrimaryKey:(NSInteger) pk
{    
    self = [self init];
    if(self)
    {
        conversationId = pk;
    }
    return self;
}

- (NSTimeInterval)lastUpdated{

    if (!lastUpdated)
        lastUpdated = createdAt;
    
    return lastUpdated;
}


- (void)setConversationId:(NSInteger)_conversationId{
    
    conversationId = _conversationId;
    
}

#pragma mark - DBCoding protocol

- (id)initWithDBCoder:(DBCoder *)decoder{
    
    self = [super init];
    if (self) {
        self.recipients     = [decoder decodeObjectOfClass:[Recipients class] forColumn:@"recipients_id"];
        self.uuid           = [decoder decodeObjectForColumn:@"conversation_uuid"];
        self.subject        = [decoder decodeObjectForColumn:@"subject"];
        self.redirectQliqId = [decoder decodeObjectForColumn:@"redirect_qliq_id"];
        self.createdAt      = [[decoder decodeObjectForColumn:@"created_at"]    doubleValue];
        self.lastUpdated    = [[decoder decodeObjectForColumn:@"last_updated"]  doubleValue];
        self.archived       = [[decoder decodeObjectForColumn:@"archived"]      boolValue];
        self.deleted        = [[decoder decodeObjectForColumn:@"deleted"]       boolValue];
        self.broadcastType  = [[decoder decodeObjectForColumn:@"is_broadcast"]  integerValue];
        self.isMuted        = [[decoder decodeObjectForColumn:@"is_muted"]      boolValue];
        self.conversationId = [[decoder decodeObjectForColumn:@"id"]            integerValue];

        //FIXME: some old staff migrated here
        ChatMessage * lastMessage = [[ChatMessageService sharedService] getLatestMessageInConversation:self.conversationId];
        self.lastUpdated = lastMessage.createdAt;
        self.lastMsg = lastMessage.text;

        self.isRead = [[ConversationDBService sharedService] isRead:self];
        
        self.numberUnreadMessages       = [[ConversationDBService sharedService] countOfUnreadMessages:self];
        self.numberUndeliveredMessages  = [[ConversationDBService sharedService] countOfUndeliveredMessages:self];
    }
    return self;
}

- (void)encodeWithDBCoder:(DBCoder *)coder{
    
    BOOL shouldInsert = (self.conversationId == 0);
    if (shouldInsert){
        
        if (!self.createdAt)
            self.createdAt = [[NSDate date] timeIntervalSince1970];
        
        if (!self.lastUpdated)
            self.lastUpdated = self.createdAt;
    }
    
    if (!self.subject)
        self.subject = @"";
    
    [coder encodeObject:self.recipients forColumn:@"recipients_id"];
    [coder encodeObject:self.subject forColumn:@"subject"];
    [coder encodeObject:[NSNumber numberWithDouble:self.createdAt] forColumn:@"created_at"];
    [coder encodeObject:[NSNumber numberWithDouble:self.lastUpdated] forColumn:@"last_updated"];
    [coder encodeObject:self.uuid forColumn:@"conversation_uuid"];
    [coder encodeObject:[NSNumber numberWithBool:self.archived] forColumn:@"archived"];
    [coder encodeObject:[NSNumber numberWithBool:self.deleted] forColumn:@"deleted"];
    [coder encodeObject:[NSNumber numberWithInteger:self.broadcastType] forColumn:@"is_broadcast"];
    [coder encodeObject:[NSNumber numberWithBool:self.isMuted] forColumn:@"is_muted"];
    [coder encodeObject:self.redirectQliqId forColumn:@"redirect_qliq_id"];
    
    /* Disable skiping zero values from querys to save empty subject in db */
    coder.skipZeroValues = NO;
}

- (NSString *)dbPKProperty{
    return @"conversationId";
}

+ (NSString *)dbPKColumn{
    return @"id";
}

+ (NSString *)dbTable{
    return @"conversation";
}

- (NSArray *)allRecipients {
    return [self.recipients allRecipients];
}

- (BOOL) isCareChannel {
    if (_isCareChannel == 0) {
        BOOL exists = [FhirEncounterDao existsWithUuid:self.uuid];
        [self setIsCareChannel:exists];
    }
    return (_isCareChannel == 1);
}

- (void) setIsCareChannel:(BOOL)value
{
    _isCareChannel = value ? 1 : -1;
}

- (BOOL) isSentBroadcast
{
    return broadcastType == EncryptedBroadcastType || broadcastType == PlainTextBroadcastType;
}

- (BOOL) isReceivedBroadcast
{
    return broadcastType == ReceivedBroadcastType;
}

- (BOOL) isBroadcast
{
    return broadcastType != NotBroadcastType;
}

#pragma mark - Searchable protocol

- (NSString *)searchDescription{
    return [NSString stringWithFormat:@"%@ %@ %@", self.recipients.displayName, lastMsg, subject];
}

@end
