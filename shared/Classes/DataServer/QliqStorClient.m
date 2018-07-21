//
//  DataServerClient.m
//  qliq
//
//  Created by Adam Sowa on 1/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqStorClient.h"
#import "QliqSip.h"
#import "Log.h"
#import "JSONKit.h"
#import "QliqStorDBService.h"
#import "SipContactDBService.h"

#define DONT_WAIT_FOR_UPDATE_RESPONSE 1
#define RESPONSE_TIMEOUT_INTERVAL 60 // 1 minute

#define KEY_METADATA @"metadata"
#define KEY_RESULT @"result"
#define KEY_ERROR @"error"
#define KEY_ERROR_CODE @"code"
#define KEY_ERROR_MESSAGE @"message"
#define KEY_DATABASE_INFO @"databaseInfo"
#define KEY_DATABASE_UUID @"databaseUuid"

static BOOL areNotificationsAdded = NO;

@interface QliqStorClient ()

- (void) finishRequest: (RequestDescriptor *)rd;
- (void) finishRequestAndDequeAnother: (RequestDescriptor *)rd;
- (void) onSipMessageStatusChanged: (NSNotification *)notification;
- (void) processDataServerUpdateStatusChange: (int)status forSubject:(NSString *)subject fromQliqId:(NSString *)qliqId;
- (NSString *) generateUpdateJson:(NSDictionary *)doc forUuid:(NSString *)uuid requestId:(NSString *)aRequestId requireResponse:(BOOL)aRequireRespnonse;
- (void) sendRequest: (RequestDescriptor *)rd;
- (void) sendCancelRequest: (RequestDescriptor *)rd;
- (void) onResponseTimedOut:(NSTimer *)theTimer;
- (void) scheduleResponseTimeOutTimerForRequest:(RequestDescriptor *)rd;
- (void)removeNotificationObserver;
- (void) addNotificationObserver;
- (NSString *) formatMessage: (NSString *)type :(NSString *)command :(NSString *)subject :(NSString *)data;
- (NSString *) callIdForRequest:(RequestDescriptor *)rd;

@end

@implementation QliqStorClient
@synthesize recentDatabaseUuid;
@synthesize qliqStorUser;

- (id) init
{
    if (self = [super init])
    {
        queuedQueryRequests = [[NSMutableDictionary alloc] init];
        queuedUpdateRequests = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void) addNotificationObserver
{
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(onSipMessageStatusChanged:)
                                                 name: SIPMessageStatusNotification
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(removeNotificationObserver) 
                                                 name:@"RemoveNotifications" object:nil];
    areNotificationsAdded = YES;
}

- (void)removeNotificationObserver
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    areNotificationsAdded = NO;
}

- (void) dealloc
{
    [self removeNotificationObserver];
}

+ (QliqStorClient *) sharedDataServerClient
{
    static QliqStorClient *instance = nil;
    if (!instance)
        instance = [[QliqStorClient alloc] init];
 
    // If the 'Log out' feature was used the notifications were removed
    // due to "RemoveNotifications" notification
    if (!areNotificationsAdded)
        [instance addNotificationObserver];
    
    return instance;
}

-(NSString *) sendQuery:(NSString *)qliqStorQliqId forSubject:(NSString *)subject delegate:(id<QliqStoreQueryDelegate>)callback extraQuery:(NSMutableDictionary *)extraQueryDict limit:(int)limit lastSeq:(int)lastSeq
{
    assert(callback != NULL);
    
    if ([qliqStorQliqId length] != 0)
    {
        DDLogVerbose(@"Cannot send query: no qliqStor specified.");
        return nil;
    }
    
    if ([self hasQueryInProgress:subject])
    {
        DDLogVerbose(@"Already have an outstanding query for: %@", subject);
        return nil;
    }
    
	NSString *requestId = [QliqStorClient generateRequestId];
	
    if (lastSeq < 0)
        lastSeq = [QliqStorDBService lastSubjectSeq:subject forUser:qliqStorQliqId andOperation:PullOperation];
    
	NSDictionary *conditionDict = [NSDictionary dictionaryWithObjectsAndKeys:
								   [NSNumber numberWithInt:lastSeq], @"$gt",
                                   nil];	
	
	NSMutableDictionary *dollarQueryDict = extraQueryDict ? extraQueryDict : [NSMutableDictionary dictionary];
    [dollarQueryDict setObject:conditionDict forKey:@"metadata.seq"];
    
	NSDictionary *dollarOrderByDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                       [NSNumber numberWithInt:1], @"metadata.seq",
                                       nil];
	
	NSDictionary *queryDict = [NSDictionary dictionaryWithObjectsAndKeys:
							   dollarQueryDict, @"$query",
							   dollarOrderByDict, @"$orderby",							   
							   nil];
	
	NSMutableDictionary *dataDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     requestId, @"requestId",
                                     queryDict, @"query",
                                     nil];
    
    if (limit > 0)
        [dataDict setObject:[NSNumber numberWithInt:limit] forKey:@"limit"];
    
	
	NSDictionary* messageDict = [NSDictionary dictionaryWithObjectsAndKeys:
								 dataDict, @"Data",
								 @"request", @"Type",
								 @"query", @"Command",
								 subject, @"Subject",
								 nil];               
	
	NSDictionary *jsonDict = [NSDictionary dictionaryWithObjectsAndKeys:
							  messageDict, @"Message",
							  nil];
	
    RequestDescriptor *rd = [[RequestDescriptor alloc] init];
    rd.requestType = QueryRequestType;
    rd.qliqStorQliqId = qliqStorQliqId;
    rd.subject = subject;
    rd.requestId = requestId;
    rd.pageCount = 0;
    rd.previousPage = 0;
    rd.delegate = callback;
    rd.status = TryingRequestStatus;
    rd.json = [jsonDict JSONString];
    rd.databaseUuid = [QliqStorDBService lastSubjectDatabaseUuid:subject forUser:rd.qliqStorQliqId andOperation:PullOperation];

    if (sentRequest)
    {
        DDLogVerbose(@"The query for %@ has been queued", subject);
        [queuedQueryRequests setObject:rd forKey:subject];
    }
    else
    {
        DDLogVerbose(@"The query for %@ has been sent", subject);
        sentRequest = rd;
        [[QliqSip sharedQliqSip] sendMessage:rd.json toQliqId:rd.qliqStorQliqId withContext:rd];
    }
    
    return requestId;
}

-(BOOL) hasQueryInProgress:(NSString *)subject
{
    return [self hasSentQuery:subject] || [self hasQueuedQuery:subject];
}

-(BOOL) hasSentQuery:(NSString *)subject
{
    return (sentRequest && (sentRequest.requestType == QueryRequestType) && [sentRequest.subject isEqualToString:subject]);
}

-(BOOL) hasQueuedQuery:(NSString *)subject
{
    return ([queuedQueryRequests objectForKey:subject] != nil);
}

- (NSString *) generateUpdateJson:(NSDictionary *)doc forUuid:(NSString *)uuid requestId:(NSString *)aRequestId requireResponse:(BOOL)aRequireRespnonse
{
    NSMutableDictionary *conditionDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                          [NSString stringWithFormat:@"ObjectId(\"%@\")", uuid], @"_id",
                                          nil];
    
    
    NSMutableDictionary *modifierDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                         doc, @"$set",
                                         nil];
    
    NSMutableDictionary *dataDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                     aRequestId, @"requestId",
                                     conditionDict, @"condition",
                                     modifierDict, @"modifier",
                                     @"upsert", @"flags",
                                     nil];
    
    if (aRequireRespnonse == NO)
        [dataDict setObject:[NSNumber numberWithBool:NO] forKey:@"response_required"];
    
    NSString *dataJson = [dataDict JSONString];
    
    return dataJson;
}

- (NSString *) sendUpdate:(NSString *)qliqStorQliqId document:(NSDictionary *)doc forUuid:(NSString *)uuid forSubject:(NSString *)subject delegate:(id<QliqStoreUpdateDelegate>)aDelegate requireResponse:(BOOL)aRequireRespnonse
{
    assert(aDelegate != NULL);
    
    if ([qliqStorQliqId length] == 0)
    {
        DDLogError(@"Cannot send query for %@, no qliqStor specified.", subject);
        return nil;
    }

//    if ([self hasSentUpdate:subject forUuid:uuid] && (delegate == sentRequest.delegate))
//    {
//        NSString *dataJson = [self generateUpdateJson:doc forUuid:uuid requestId:sentRequest.requestId];
//        NSString *json = [Outbound formatMessage:@"request" :@"update" :subject :dataJson];
//        if ([json compare:sentRequest.json] == NSOrderedSame)
//        {
//            DDLogVerbose(@"Already sent an update request for %@ uuid %@ and the same data value skipping duplicate", subject, uuid);
//            return sentRequest.requestId;
//        }
//    }
    
    NSString *requestId = nil;
    
    // If there is already a queued update for this document, then replace it with the current one,
    // but keep the same requestId
    RequestDescriptor *existingRequest = [queuedUpdateRequests objectForKey:uuid];
    if (existingRequest)
    {
        DDLogVerbose(@"There is already an existing update request for %@, overwriting it", subject);
        requestId = existingRequest.requestId;
    }
    else
    {
        requestId = [QliqStorClient generateRequestId];
    }

    NSString *dataJson = [self generateUpdateJson:doc forUuid:uuid requestId:requestId requireResponse:aRequireRespnonse];
    
    RequestDescriptor *rd = [[RequestDescriptor alloc] init];
    rd.requestType = UpdateRequestType;
    rd.qliqStorQliqId = qliqStorQliqId;
    rd.subject = subject;
    rd.uuid = uuid;
    rd.requestId = requestId;
    rd.delegate = aDelegate;
    rd.status = TryingRequestStatus;
    rd.json = [self formatMessage:@"request" :@"update" :subject :dataJson];
    rd.databaseUuid = [QliqStorDBService lastSubjectDatabaseUuid:subject forUser:qliqStorQliqId andOperation:PushOperation];
    
    if (sentRequest)
    {
        DDLogVerbose(@"The update for %@ uuid %@ has been queued", subject, uuid);
        [queuedUpdateRequests setObject:rd forKey:uuid];
    }
    else
    {
        DDLogVerbose(@"The update for %@ uuid %@ has been sent", subject, uuid);
        sentRequest = rd;
#ifdef DONT_WAIT_FOR_UPDATE_RESPONSE
        NSString *callId = [self callIdForRequest:rd];
        [[QliqSip sharedQliqSip] sendMessage:rd.json toQliqId:rd.qliqStorQliqId withUUId:callId withContext:rd offlineMode:YES pushNotify:NO];
#else
        [[QliqSip sharedQliqSip] sendMessage:rd.json toQliqId:rd.qliqStorQliqId withUserData:rd];
#endif
    }
    
    return requestId;
}

-(BOOL) hasUpdateInProgress:(NSString *)subject forUuid:(NSString *)uuid
{
    return [self hasSentUpdate:subject forUuid:uuid] || [self hasQueuedUpdate:subject forUuid:uuid];
}
            
-(BOOL) hasSentUpdate:(NSString *)subject forUuid:(NSString *)uuid
{
    BOOL has = NO;
    
    if (sentRequest)
    {
        if ((sentRequest.requestType == UpdateRequestType) && ([sentRequest.uuid isEqualToString:uuid]))
            has = YES;
    }
    return has;
}

-(BOOL) hasQueuedUpdate:(NSString *)subject forUuid:(NSString *)uuid;
{
    return ([queuedUpdateRequests objectForKey:uuid] != nil);
}

+ (NSString *) generateRequestId
{
    static unsigned int seq = 0;
    return [NSString stringWithFormat:@"dsci-%lu-%u", time(0), ++seq];
}

#pragma mark -
#pragma mark Private

- (void) finishRequest: (RequestDescriptor *)rd
{
    if (rd)
    {
        if (sentRequest == rd)
        {
            sentRequest = nil;
        }
        
        if (responseTimeoutTimer)
        {
            [responseTimeoutTimer invalidate];
            responseTimeoutTimer = nil;
        }
        
        if (rd.requestType == QueryRequestType)
        {
            id<QliqStoreQueryDelegate> delegate = rd.delegate;            
            [delegate onQueryFinished:rd.qliqStorQliqId :rd.subject :rd.requestId withStatus:rd.status];
        }
        else if (rd.requestType == UpdateRequestType)
        {
            id<QliqStoreUpdateDelegate> delegate = rd.delegate;
            [delegate onUpdateFinished:rd.qliqStorQliqId forSubject:rd.subject forRequestId:rd.requestId forUuid:rd.uuid withStatus:rd.status];
        }
    }
}

- (void) finishRequestAndDequeAnother: (RequestDescriptor *)rd
{
    [self finishRequest: rd];
    rd = nil;
        
    // TODO: refactor by introducing one queue for all request types
    BOOL sent = NO;
    for (NSString *subject in queuedQueryRequests)
    {
        DDLogVerbose(@"Dequeing a request from query queue");
        // Retain before removing from the container
        // will be released in finishRequest            
        rd = [queuedQueryRequests objectForKey:subject];            

        if (rd)
        {
            [queuedQueryRequests removeObjectForKey:subject];                
            [self sendRequest:rd];
            sent = YES;
            break;
        }
    }
    
    if (!sent)
    {
        for (NSString *uuid in queuedUpdateRequests)
        {
            DDLogVerbose(@"Dequeing a request from update queue");
            // Retain before removing from the container
            // will be released in finishRequest                
            rd = [queuedUpdateRequests objectForKey:uuid];
            
            if (rd)
            {
                DDLogVerbose(@"request: %@", rd);
                DDLogVerbose(@"request.uuid: %@", rd.uuid);              
                [queuedUpdateRequests removeObjectForKey:uuid];
                [self sendRequest:rd];
                //sent = YES;
                break;
            }
        }                
    }
}

- (void) sendRequest: (RequestDescriptor *)rd
{
    assert(rd);
    
    if (!sentRequest)
    {
        if (!rd.qliqStorQliqId)
        {
            DDLogError(@"Cannot send query for %@, no qliqStor configured.", rd.subject);
        }
        else
        {
            DDLogVerbose(@"The queued request for %@ of type %d has been sent", rd.subject, rd.requestType);
            sentRequest = rd;
#ifdef DONT_WAIT_FOR_UPDATE_RESPONSE
            NSString *callId = [self callIdForRequest:rd];
            [[QliqSip sharedQliqSip] sendMessage:rd.json toQliqId:rd.qliqStorQliqId withUUId:callId withContext:rd offlineMode:YES pushNotify:NO];
#else
            [[QliqSip sharedQliqSip] sendMessage:rd.json toQliqId:rd.qliqStorQliqId withUserData:rd];
#endif
            
        }
    }
    else
    {
        DDLogError(@"Trying to send a request while already have an outstanding one");
    }
}

- (void) sendCancelRequest: (RequestDescriptor *)rd
{
    if (rd)
    {
        if ([rd.qliqStorQliqId length] == 0)
        {
            DDLogError(@"Cannot send cancel for %@, no qliqStor configured.", rd.subject);
        }
        else
        {
            DDLogVerbose(@"The cancel for request for %@ of type %d has been sent", rd.subject, rd.requestType);
            
            NSMutableDictionary *dataDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                             rd.requestId, @"requestId",
                                             nil];
           
            NSString *dataJson = [dataDict JSONString];
            
            NSString *json = [self formatMessage:@"request" :@"cancel" :rd.subject :dataJson];
            [[QliqSip sharedQliqSip] sendMessage:json toQliqId:rd.qliqStorQliqId withContext:nil];
        }
    }
}

- (void) scheduleResponseTimeOutTimerForRequest:(RequestDescriptor *)rd
{
    rd.status = WaitingForResponseStatus;
    responseTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:RESPONSE_TIMEOUT_INTERVAL target:self selector:@selector(onResponseTimedOut:) userInfo:nil repeats:NO];
}

- (BOOL) isRequestDescriptorNotification:(NSNotification *)notification
{
    id context = [notification userInfo][@"context"];
    return context && [context isKindOfClass:[RequestDescriptor class]];
}

- (void) onSipMessageStatusChanged: (NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    id context = userInfo[@"context"];
    
    if ([self isRequestDescriptorNotification:notification])
    {
        int status = [userInfo[@"Status"] intValue];
        RequestDescriptor *rd = context;
        
        if (sentRequest == rd)
        {
            if (status == 200)
            {
                if (responseTimeoutTimer)
                {
                    // Shouldn't happen - a bug
                    DDLogError(@"BUG: response responseTimeoutTimer isn't nil");
                    [responseTimeoutTimer invalidate];
                    responseTimeoutTimer = nil;
                }
                
                [self scheduleResponseTimeOutTimerForRequest:rd];
            }
#ifdef DONT_WAIT_FOR_UPDATE_RESPONSE
            if (status / 100 == 2 && rd.requestType == UpdateRequestType)
            {
                [self processDataServerUpdateStatusChange:status forSubject:rd.subject fromQliqId:rd.qliqStorQliqId];
            }
#endif
            else if (status != 200)
            {
                if (rd.requestType == QueryRequestType)
                {
                    id<QliqStoreQueryDelegate> delegate = rd.delegate;
                    [delegate onQuerySendingFailed:rd.qliqStorQliqId :rd.subject :rd.requestId];
                }
                else if (rd.requestType == UpdateRequestType)
                {
                    id<QliqStoreUpdateDelegate> delegate = rd.delegate;
                    [delegate onUpdateSendingFailed:rd.qliqStorQliqId forSubject:rd.subject forRequestId:rd.requestId forUuid:rd.uuid withSipStatus:status];
                }
                rd.status = RequestSendingFailedStatus;
                [self finishRequestAndDequeAnother:rd];
            }
        }
    }
    
}

- (void) processDataServerUpdateStatusChange: (int)status forSubject:(NSString *)subject fromQliqId:(NSString *)qliqId
{
    RequestDescriptor *rd = sentRequest;
    if (!rd)
        return;

    assert (rd.delegate != nil);   
    assert(status / 100 == 2);

    if (rd.requestType != UpdateRequestType)
    {
        DDLogError(@"The active request isn't of update type");
        return;
    }
     
    Metadata *md = [[Metadata alloc] init];
    md.uuid = rd.uuid;
    
    id<QliqStoreUpdateDelegate> delegate = rd.delegate;    
    [delegate onUpdateSuccessful:qliqId forSubject:rd.subject forRequestId:rd.requestId forUuid:rd.uuid metadata:md];
    rd.status = CompletedRequestStatus;
    
    [self finishRequestAndDequeAnother:rd];    
}
                 
- (void) onResponseTimedOut:(NSTimer *)theTimer
{
    if ((theTimer == responseTimeoutTimer) && sentRequest && (sentRequest.status = WaitingForResponseStatus))
    {
        DDLogError(@"Response timedout for subject %@ for query type %d", sentRequest.subject, sentRequest.requestType);
        sentRequest.status = ResponseTimedOutStatus;
        [self finishRequestAndDequeAnother:sentRequest];
    }
}

+ (BOOL) defaultOnQueryPageReceived: (id<QliqStoreQueryDelegate>)callback : (NSString *)qliqId : (NSString *)subject : (NSString *)requestId : (NSArray *)results :  (int)page : (int)pageCount : (int)totalPages
{
    BOOL success = YES;
    
    for (NSDictionary *result in results)
    {
        if ([callback onQueryResultReceived:qliqId :subject :requestId :result])
        {
            NSDictionary *metadataDict = [result objectForKey:@"metadata"];
            if (metadataDict)
            {
                Metadata *md = [Metadata metadataFromDict:metadataDict];
                if ([md.uuid length] > 0 && md.seq > 0)
                {
                    [QliqStorDBService setLastSubjectSeqIfGreater:md.seq forSubject:subject forUser:qliqId andOperation:PullOperation];
                }
            }
        }
        else
        {
            success = NO;
            break;
        }
    }
    return success;
}

- (void) cancelAllRequestsForSubject:(NSString *)subject
{
    NSMutableArray *requestsForSubject = [[NSMutableArray alloc] init];
    
    // Fist remove requests from queues
    
    // TODO: refactor by introducing one queue for all request types
    for (NSString *queuedSubject in queuedQueryRequests)
    {
        if ([queuedSubject isEqualToString:subject])
        {
            RequestDescriptor *rd = [queuedQueryRequests objectForKey:subject];
            [requestsForSubject addObject:rd];
            [queuedQueryRequests removeObjectForKey:subject];                
        }
    }
    
    for (NSString *uuid in queuedUpdateRequests)
    {
        RequestDescriptor *rd = [queuedUpdateRequests objectForKey:uuid];
        
        if ([rd.subject isEqualToString:subject])
        {
            [requestsForSubject addObject:rd];
            [queuedUpdateRequests removeObjectForKey:uuid];
        }
    }
    
    for (RequestDescriptor *rd in requestsForSubject)
    {
        [self sendCancelRequest: rd];
        
        rd.status = RequestCancelledStatus;
        [self finishRequest:rd];
    }
    
    if (sentRequest && ([sentRequest.subject isEqualToString:subject]))
    {
        [self finishRequest: sentRequest];
    }
}

- (void) cancelAllRequests
{
    NSMutableArray *allRequests = [NSMutableArray arrayWithArray: [queuedQueryRequests allValues]];
    [allRequests addObjectsFromArray: [queuedUpdateRequests allValues]];
     
    [queuedQueryRequests removeAllObjects];
    [queuedUpdateRequests removeAllObjects];
    
    for (RequestDescriptor *rd in allRequests)
    {
        // We need to retain, because finishRequest will call release and later requestsForSubject array will also release
        rd.status = RequestCancelledStatus;
        [self finishRequest:rd];
    }
    
    if (sentRequest)
    {
        [self finishRequest: sentRequest];
    }  
}

-(void) logout
{
    [self cancelAllRequests];
    self.recentDatabaseUuid = nil;
}

- (NSString *) formatMessage: (NSString *)type :(NSString *)command :(NSString *)subject :(NSString *)data
{
    return [NSString stringWithFormat:@"{\"Message\":{\"Type\":\"%@\",\"Command\":\"%@\",\"Subject\":\"%@\",\"Data\":%@ }}",
            type, command, subject, data];
}

- (NSString *) callIdForRequest:(RequestDescriptor *)rd
{
    if ([rd.uuid length] > 0) {
        return [@"qsp-" stringByAppendingString:rd.uuid];
    } else {
        return nil;
    }
}

@end

@implementation RequestDescriptor
@synthesize qliqStorQliqId, subject, uuid, requestId, pageCount, previousPage, status, delegate, requestType, json, databaseUuid;

- (void) dealloc
{

}

@end
