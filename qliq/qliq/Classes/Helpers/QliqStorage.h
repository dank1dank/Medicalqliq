//
//  QliqStorage.h
//  qliq
//
//  Created by Valerii Lider on 01/02/16.
//
//

#import <Foundation/Foundation.h>

@interface QliqStorage : NSObject

+ (QliqStorage *)sharedInstance;

/* Device values
 */
@property (nonatomic, weak) NSString *deviceToken;
@property (nonatomic, weak) NSString *voipDeviceToken;


/* Application States
 */
@property (nonatomic, weak) NSNumber *dontShowAlertsOffPopup;

/* Iddle Lock
 */
@property (nonatomic, weak) NSDate *lastUserTouchTime;

@property (nonatomic, assign) BOOL appIdleLockedState;

/* UserInfo
 */
@property (nonatomic, assign) BOOL userLoggedOut;

/* Expire values
 */
@property (nonatomic, weak) NSNumber *deleteMediaUponExpiryKey;

/*
 Login Credentials
 */
@property (nonatomic, assign) BOOL wasLoginCredentintialsChanged;
@property (nonatomic, assign) BOOL failedToDecryptPushPayload;

/*
 App Info
 */
- (void)storeAppCrashEventWithStackTrace:(NSString *)stackTrace;
- (void)restoreAppCrashEvent;
- (void)storeAppMemoryWarningEvent;
- (void)restoreAppMemoryWarning;
- (BOOL)appWasCrashed;
- (NSArray *)bufferedAppCrashes;
- (NSString *)appStackTraceForCrashInfoDictionary:(NSDictionary *)crashInfoDict;
- (NSDate *)dateInLastAppCrash:(BOOL)isLastCrash;

@end
