//
//  GetContactsPaged.m
//  qliq
//
//  Created by Valerii Lider on 07.03.14.
//
//

#import "GetContactsPaged.h"
#import "JSONSchemaValidator.h"
#import "RestClient.h"
#import "QliqJsonSchemaHeader.h"
#import "JSONKit.h"
#import "QliqUser.h"
#import "QliqUserDBService.h"
#import "QliqGroup.h"
#import "QliqGroupDBService.h"
#import "QliqSip.h"
#import "UserSessionService.h"
#import "UserSession.h"
#import "SipAccountSettings.h"
#import "Contact.h"
#import "ContactDBService.h"
#import "AvatarDownloadService.h"
#import "AppDelegate.h"
#import "DBUtil.h"
#import "SipContact.h"
#import "SipContactDBService.h"
#import "UIDevice+UUID.h"
#import "ABTimeCounter.h"
#import "NotificationUtils.h"

#define errorDomain @"com.qliq.GetContactsPaged"
		
static BOOL s_isInProgress = NO;

@interface GetContactsPaged ()

@property (nonatomic, strong) NSMutableSet *activeUserIds;
@property (nonatomic, assign) BOOL isComplete;

@property (nonatomic, strong) NSOperationQueue *getContactsPagedOperationQueue;

@end

@implementation GetContactsPaged

+ (GetContactsPaged *)sharedService
{
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        
        shared = [[GetContactsPaged alloc] init];
    });
    return shared;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.activeUserIds = [NSMutableSet set];
        
        self.getContactsPagedOperationQueue = [[NSOperationQueue alloc] init];
        self.getContactsPagedOperationQueue.name = @"com.qliq.contactsPagedService.queue";
        self.getContactsPagedOperationQueue.qualityOfService = NSQualityOfServiceDefault;
        self.getContactsPagedOperationQueue.maxConcurrentOperationCount = 1;
        
        BOOL wasStopped = NO;
        [GetContactsPaged setPageContactsOperationState:wasStopped forQliqId:[UserSessionService currentUserSession].user.qliqId];
        
        s_isInProgress = NO;
        
        self.isComplete = YES;
        
        /*
         observing of app termination while PagedContacts Downloaded
         */
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopProgress) name:UIApplicationWillTerminateNotification object:nil];
    }
    return self;
}

/*
 set state of getPagedContacts operation to stopped
 */
- (void)stopProgress {
    
    BOOL wasStopped = YES;
    [GetContactsPaged setPageContactsOperationState:wasStopped forQliqId:[UserSessionService currentUserSession].user.qliqId];
    
    s_isInProgress = NO;
    
    [self.activeUserIds removeAllObjects];
}

- (void)dealloc {
    
    self.activeUserIds = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.getContactsPagedOperationQueue cancelAllOperations];
    [self.getContactsPagedOperationQueue waitUntilAllOperationsAreFinished];
    self.getContactsPagedOperationQueue = nil;
}

#pragma mark - Public

+ (void)getAllPagesStartingFrom:(unsigned int)startPage completion:(CompletionBlock)completetion
{
     __block GetContactsPaged *getAllContactsService = [GetContactsPaged sharedService];
   
    [getAllContactsService.getContactsPagedOperationQueue addOperationWithBlock:^{
      
        if (s_isInProgress) {
            DDLogError(@"Cannot execute get_paged_contacts process because it is already in progress");
            
            NSError *error = [NSError errorWithDomain:errorDomain
                                                 code:GetContactsPagedAlreadyRun
                                             userInfo:nil];
            if (completetion) {
                completetion(CompletitionStatusError, nil, error);
            }
            return;
        }
        
        NSString *qliqId = [UserSessionService currentUserSession].user.qliqId;
        
        if (qliqId == nil) {
            DDLogError(@"Cannot execute get_paged_contacts process because currentUser have not qliqID");
            
            NSError *error = [NSError errorWithDomain:errorDomain
                                                 code:GetContactsPagedCurrentUserHaveNotQliqId
                                             userInfo:nil];
            if (completetion) {
                completetion(CompletitionStatusError, nil, error);
            }
            return;
        }
        
        s_isInProgress = YES;
        
        getAllContactsService.isComplete = NO;
        
        ABTimeCounter *counter = [ABTimeCounter new];
        [counter restart];
        
        static void (^fetchBlock)(NSUInteger page, NSUInteger count);
        
        fetchBlock = ^(NSUInteger page, NSUInteger count) {
            
            [getAllContactsService getContactsForPage:page count:count completion:^(CompletitionStatus status, id result, NSError *error) {
                
                if (error || CompletitionStatusError == status) {
                    if (completetion) {
                        completetion(CompletitionStatusError, nil, error);
                    }
                    s_isInProgress = NO;
                }
                else {
                    NSDictionary *temp = result;
                    int currentPage = [temp[@"current_page"] intValue];
                    int totalPages = [temp[@"total_pages"] intValue];
                    
                    if (currentPage > 0 && currentPage >= totalPages) {
                        DDLogSupport(@"Time to get all contact pages: %f", [counter measuredTime]);
                        [[QliqUserDBService sharedService] printCounterTimes];
                        
                        if (startPage == 0) {
                            [getAllContactsService markAllOtherContactsAsDeleted];
                        }
                        [GetContactsPaged setLastSavedPage:0 forQliqId:qliqId];
                        
                        // success
                        if (completetion) {
                            completetion(CompletitionStatusSuccess, nil, nil);
                        }
                        s_isInProgress = NO;
                        getAllContactsService.isComplete = YES;
                    }
                    else {
                        if (currentPage > 0 && currentPage < totalPages) {
                            
                            [GetContactsPaged setLastSavedPage:currentPage forQliqId:qliqId];
                        }
                        //fetchBlock(page+1, count);
                    }
                }
            } retryCount:0];
        };
        
        [[QliqUserDBService sharedService] resetCounterTimes];
        fetchBlock(startPage, 200);
    }];
//    });
}

/**
 *  Send request to server for getting contacts
 *
 *  @param page         page number
 *  @param count        count how many should get contacts
 */
- (void)getContactsForPage:(NSInteger)page count:(NSInteger)count completion:(CompletionBlock)completetion retryCount:(NSInteger)retryCount {
    
    NSString *username      = [UserSessionService currentUserSession].sipAccountSettings.username;
    NSString *password      = [UserSessionService currentUserSession].sipAccountSettings.password;
    NSString *qliqId        = [UserSessionService currentUserSession].user.qliqId;
    NSString *deviceUUID    = [[UIDevice currentDevice] qliqUUID];
    
    // If the user name or password does not exist, user might have
    // logged out
    if (!username || !password)
        return;
    
//     get the appversion from user defaults or plist, and device UUID, current timestamp on the device
    NSDictionary *contentDict = @{PASSWORD : password,
                                  USERNAME : username,
                                  DEVICE_UUID : deviceUUID,
                                  PAGE : @(page),
                                  PER_PAGE : @(count)};
    
    NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithObjectsAndKeys: @{DATA : contentDict}, MESSAGE, nil];
    
    ABTimeCounter *counter = [ABTimeCounter new];
    [counter restart];
    
    if ([JSONSchemaValidator validate:[jsonDict JSONString] embeddedSchema:GetPagedContactsRequestSchema])
    {
        RestClient *restClient = [RestClient clientForCurrentUser];
        [restClient postDataToServer:RegularWebServerType path:@"services/get_paged_contacts" jsonToPost:jsonDict onCompletion:^(NSString *responseString) {
            
            //            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{ //AII Get Paged Contacts
            [self.getContactsPagedOperationQueue addOperationWithBlock:^{
                
                [counter pause];
                DDLogSupport(@"Time to send and retrieve page from webserver: %f sec", [counter measuredTime]);
                
                // Fragment to retrieve next page before processing this one
                NSStringEncoding dataEncoding = NSUTF8StringEncoding;
                NSError *error = nil;
                NSData *jsonData = [responseString dataUsingEncoding:dataEncoding];
                JSONDecoder *jsonKitDecoder = [JSONDecoder decoder];
                NSDictionary *getAllContactsMessage = [jsonKitDecoder objectWithData:jsonData error:&error];
                NSDictionary *errorDict = [[getAllContactsMessage valueForKey:MESSAGE] valueForKey:ERROR];
                NSDictionary *dataDict = [[getAllContactsMessage valueForKey:MESSAGE] valueForKey:DATA];
                
                int currentPage = [dataDict[@"current_page"] intValue];
                int totalPages  = [dataDict[@"total_pages"] intValue];
                
                dispatch_async_background(^{
                    [self processResponseString:responseString completition:completetion page:page myQliqId:qliqId];
                });
                
                
                BOOL wasStopped = [GetContactsPaged getPageContactsOperationStateForQliqId:[UserSessionService currentUserSession].user.qliqId];
                
                if (errorDict == nil && totalPages > 0 && currentPage < totalPages && !wasStopped) {
                    [self getContactsForPage:page + 1 count:count completion:completetion retryCount:0];
                }
            }];
            //            });
            
        } onError:^(NSError* error) {
            
            [self.getContactsPagedOperationQueue addOperationWithBlock:^{
                
                NSInteger code = error.code;
                if (retryCount < 3 && (code == kCFURLErrorTimedOut ||
                                       code == kCFURLErrorCannotFindHost ||
                                       code == kCFURLErrorCannotConnectToHost ||
                                       code == kCFURLErrorNetworkConnectionLost))
                {
                    DDLogError(@"get_paged_contacts request error: %ld, retry count: %ld, retrying", (long)code, (long)retryCount);
                    
                    //                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                    [self getContactsForPage:page count:count completion:completetion retryCount:retryCount + 1];
                    
                    //                });
                }
                else {
                    if (completetion) {
                        completetion(CompletitionStatusSuccess, nil, error);
                    }
                }
                
            }];
        }];
    }
    else {
        if (completetion) {
            completetion(CompletitionStatusSuccess, nil, [NSError errorWithDomain:errorDomain code:GetContactsPagedInvalidRequest userInfo:userInfoWithDescription(@"GetAllContacts: Invalid request sent to server")]);
        }
    }
}

- (void)markAllOtherContactsAsDeleted {
    [[QliqUserDBService sharedService] setAllOtherUsersAsDeleted:self.activeUserIds];
    [self.activeUserIds removeAllObjects];
}

+ (NSInteger)lastSavedPageForQliqId:(NSString *)qliqId {
    return [[NSUserDefaults standardUserDefaults] integerForKey:[self userDefaultKeyForLastPageForQliqId:qliqId]];
}

+ (BOOL)getPageContactsOperationStateForQliqId:(NSString *)qliqId {
    return [[NSUserDefaults standardUserDefaults] boolForKey:[self userDefaultKeyForOperationStateForQliqId:qliqId]];
}

+ (void)setLastSavedPage:(NSInteger)page forQliqId:(NSString *)qliqId {
    [[NSUserDefaults standardUserDefaults] setInteger:page forKey:[self userDefaultKeyForLastPageForQliqId:qliqId]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)setPageContactsOperationState:(BOOL)wasStopped forQliqId:(NSString *)qliqId {
    [[NSUserDefaults standardUserDefaults] setBool:wasStopped forKey:[self userDefaultKeyForOperationStateForQliqId:qliqId]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Private

+ (NSString *)userDefaultKeyForLastPageForQliqId:(NSString *)qliqId
{
    NSString *deviceUUID = [[UIDevice currentDevice] qliqUUID];
    return [@"lastPagedContactsPage-" stringByAppendingFormat:@"%@-%@", qliqId, deviceUUID];
}

+ (NSString *)userDefaultKeyForOperationStateForQliqId:(NSString *)qliqId
{
    NSString *deviceUUID = [[UIDevice currentDevice] qliqUUID];
    return [@"pagedContactsOperationState-" stringByAppendingFormat:@"%@-%@", qliqId, deviceUUID];
}

- (BOOL)processResponseString:(NSString *)responseString completition:(CompletionBlock)completetion page:(NSInteger)currentPage myQliqId:(NSString *)qliqId
{
	NSStringEncoding dataEncoding = NSUTF8StringEncoding;
	NSError *error = nil;
	NSData *jsonData = [responseString dataUsingEncoding:dataEncoding];
	JSONDecoder *jsonKitDecoder = [JSONDecoder decoder];
	NSDictionary *getAllContactsMessage = [jsonKitDecoder objectWithData:jsonData error:&error];
	NSDictionary *errorDict = [[getAllContactsMessage valueForKey:MESSAGE] valueForKey:ERROR];
	NSDictionary *getAllContacts = [[getAllContactsMessage valueForKey:MESSAGE] valueForKey:DATA];
    
	if(errorDict != nil) {
		DDLogSupport(@"Error returned from webservice: %@", [errorDict objectForKey:ERROR_MSG]);
        
		NSString *reason = [NSString stringWithFormat:@"Server error:%@", [errorDict objectForKey:ERROR_MSG]];
        if (completetion) {
            completetion(CompletitionStatusError, nil, [NSError errorWithDomain:errorDomain code:GetContactsPagedAlreadyRun userInfo:userInfoWithDescription(reason)]);
        }
        
		return NO;
	}
	
	
	if(![self allContactsValid:responseString]) {
        
		NSString *reason = [NSString stringWithFormat:@"Invalid group info"];
        
        if (completetion) {
            completetion(CompletitionStatusError, nil, [NSError errorWithDomain:errorDomain code:2 userInfo:userInfoWithDescription(reason)]);
        }
		return NO;
	}
    
    BOOL ret = [self storeAllContacts:getAllContacts page:currentPage];
    if (ret) {
        [GetContactsPaged setLastSavedPage:currentPage forQliqId:qliqId];
        
        //Need to post notification for updating contacts with current page
        //Valerii Lider 07/06/17
        [NSNotificationCenter postNotificationToMainThread:kUpdateContactsListNotificationName userInfo:nil];
    }
    if (completetion) {
        completetion(CompletitionStatusSuccess, getAllContacts, nil);
    }
    
    return ret;
}

- (BOOL)allContactsValid:(NSString *)allContactsJson
{
    BOOL rez = YES;
    rez &= [allContactsJson length] > 0;
    BOOL validJson = [JSONSchemaValidator validate:allContactsJson embeddedSchema:GetPagedContactsResponseSchema];
    rez &= validJson;
	
    return rez;
}

- (BOOL)storeAllContacts:(NSDictionary *)dataDict page:(NSInteger)currentPage {
	DDLogSupport(@"GET PAGED CONTACTS : processing started, currentPage:%ld", (long)currentPage);
	
    BOOL success = YES;
	
	DDLogVerbose(@"Data %@",dataDict);
    
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        
        ABTimeCounter *counter = [ABTimeCounter new];
        [counter restart];
        
        [db beginTransaction];
        
        for (NSDictionary *item in dataDict[QLIQ_USERS]) {
            
            QliqUser *user = [[QliqUserDBService sharedService] saveContactFromJsonDictionary:item andNotifyAboutNew:NO];
            if (user) {
                [self.activeUserIds addObject:user.qliqId];
            }
        }
        
        [db commit];
        
        [counter pause];
        DDLogSupport(@"Time to store %d users was %f sec", (int)[dataDict[QLIQ_USERS] count], [counter measuredTime]);
    }];
	
	DDLogSupport(@"GET PAGED CONTACTS : processing finished");
	return success;
}

+ (BOOL)isInProgress {
    return s_isInProgress;
}

+ (BOOL)isComplete {
    return [GetContactsPaged sharedService].isComplete;
}

@end
