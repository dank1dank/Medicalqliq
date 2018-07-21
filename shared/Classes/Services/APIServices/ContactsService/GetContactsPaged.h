//
//  GetContactsPaged.h
//  qliq
//
//  Created by Valerii Lider on 07.03.14.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, GetContactsPagedErrors) {
    GetContactsPagedInvalidRequest = 0,
    GetContactsPagedAlreadyRun = 1,
    GetContactsPagedCurrentUserHaveNotQliqId = 20
};

@interface GetContactsPaged : NSObject

+ (GetContactsPaged *)sharedService;

- (void)getContactsForPage:(NSInteger)page count:(NSInteger)count completion:(CompletionBlock)completetion retryCount:(NSInteger)retryCount;
- (void)markAllOtherContactsAsDeleted;

+ (void)setLastSavedPage:(NSInteger)page forQliqId:(NSString *)qliqId;
+ (void)setPageContactsOperationState:(BOOL)wasStopped forQliqId:(NSString *)qliqId;
+ (NSInteger)lastSavedPageForQliqId:(NSString *)qliqId;
+ (BOOL)getPageContactsOperationStateForQliqId:(NSString *)qliqId;

+ (void)getAllPagesStartingFrom:(unsigned int)page completion:(CompletionBlock)completetion;
+ (BOOL)isInProgress;
+ (BOOL)isComplete;

- (void)stopProgress;

@end
