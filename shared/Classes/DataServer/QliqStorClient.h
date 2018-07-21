//
//  DataServerClient.h
//  qliq
//
//  Created by Adam Sowa on 1/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Metadata.h"
#import "QliqUser.h"

@protocol QliqStoreQueryDelegate
- (BOOL) onQueryPageReceived: (NSString *)qliqId :
(NSString *)subject :
(NSString *)requestId : (NSArray *)results : (int)page : (int)pageCount : (int)totalPages;



- (BOOL) onQueryResultReceived: (NSString *)qliqId : (NSString *)subject : (NSString *)requestId : (NSDictionary *)result;

- (void) onQuerySent: (NSString *)qliqId : (NSString *)subject : (NSString *)requestId;
- (void) onQuerySendingFailed: (NSString *)qliqId : (NSString *)subject : (NSString *)requestId;
- (void) onQueryFinished: (NSString *)qliqId : (NSString *)subject : (NSString *)requestId withStatus:(int)status;
@end

@protocol QliqStoreUpdateDelegate
- (void) onUpdateSuccessful: (NSString *)qliqId forSubject:(NSString *)subject forRequestId:(NSString *)requestId forUuid:(NSString *)uuid metadata:(Metadata *)aMetadata;
- (void) onUpdateFailed: (NSString *)qliqId forSubject:(NSString *)subject forRequestId:(NSString *)requestId forUuid:(NSString *)uuid errorCode:(int)anErrorCode errorMessage:(NSString *)anErrorMessage;
- (void) onUpdateSendingFailed: (NSString *)qliqId forSubject:(NSString *)subject forRequestId:(NSString *)requestId forUuid:(NSString *)uuid withSipStatus:(int)status;
// Called when the request is finished (after a successful response or error)
- (void) onUpdateFinished: (NSString *)qliqId forSubject:(NSString *)subject forRequestId:(NSString *)requestId forUuid:(NSString *)uuid withStatus:(int)status;
@end

enum RequestStatus {
    CompletedRequestStatus = 1,
    InvalidResponseRequestStatus = 2,
    CallbackErrorRequestStatus = 3,
    RequestSendingFailedStatus = 4, // the request couldn't be send to the server
    ResponseTimedOutStatus = 5,     // the server didn't respond in time
    ResponseErrorStatus = 6,        // the server returned error in the response
    DatabaseUuidMismatchErrorStatus = 7, // the database id has changed (the db is out of sync)
    RequestCancelledStatus = 8,
    TryingRequestStatus = 100,
    WaitingForResponseStatus = 200  // the request has been delivered, waiting for the response
};

enum RequestType {
    QueryRequestType,
    UpdateRequestType
};

@interface RequestDescriptor : NSObject {
    NSString *qliqStorQliqId;
    NSString *subject;
    NSString *uuid;         // for update or put
    NSString *requestId;
    int pageCount;          // for query
    int previousPage;       //
    int status;
    int requestType;
    NSString *json;
    NSString *databaseUuid;
}

@property (nonatomic, retain) NSString *qliqStorQliqId;
@property (nonatomic, retain) NSString *subject;
@property (nonatomic, retain) NSString *uuid;
@property (nonatomic, retain) NSString *requestId;
@property (nonatomic, assign) int pageCount;
@property (nonatomic, assign) int previousPage;
@property (nonatomic, assign) int status;
@property (nonatomic, assign) id delegate;
@property (nonatomic, assign) int requestType;
@property (nonatomic, retain) NSString *json;
@property (nonatomic, retain) NSString *databaseUuid;
@end

@interface QliqStorClient : NSObject {
    // The outstanding request
    RequestDescriptor *sentRequest;
    // Query requests by subject
    NSMutableDictionary *queuedQueryRequests;
    // Update requests by uuid
    NSMutableDictionary *queuedUpdateRequests;
    
    NSTimer *responseTimeoutTimer;
    NSString *recentDatabaseUuid;
    QliqUser *qliqStorUser;
}
@property (nonatomic, retain) NSString *recentDatabaseUuid;
@property (nonatomic, retain) QliqUser *qliqStorUser;

// Called when the user logs out. 
-(void) logout;

-(NSString *) sendQuery:(NSString *)qliqStorQliqId forSubject:(NSString *)subject delegate:(id<QliqStoreQueryDelegate>)callback extraQuery:(NSMutableDictionary *)extraQueryMap limit:(int)aLimit lastSeq:(int)aLastSeq;
-(BOOL) hasQueryInProgress:(NSString *)subject;
-(BOOL) hasSentQuery:(NSString *)subject;
-(BOOL) hasQueuedQuery:(NSString *)subject;

-(NSString *) sendUpdate:(NSString *)qliqStorQliqId document:(NSDictionary *)doc forUuid:(NSString *)uuid forSubject:(NSString *)subject delegate:(id<QliqStoreUpdateDelegate>)aDelegate requireResponse:(BOOL)aRequireRespnonse;
-(BOOL) hasSentUpdate:(NSString *)subject forUuid:(NSString *)uuid;
-(BOOL) hasQueuedUpdate:(NSString *)subject forUuid:(NSString *)uuid;
-(BOOL) hasUpdateInProgress:(NSString *)subject forUuid:(NSString *)uuid;

- (void) cancelAllRequestsForSubject:(NSString *)subject;
- (void) cancelAllRequests;

// temporary: move to module controller?
+ (QliqStorClient *) sharedDataServerClient;
+ (BOOL) defaultOnQueryPageReceived: (id<QliqStoreQueryDelegate>)callback : (NSString *)qliqId : (NSString *)subject : (NSString *)requestId : (NSArray *)results : (int)page : (int)pageCount : (int)totalPages;
+ (NSString *) generateRequestId;

@end
