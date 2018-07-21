//
//  QxPlatfromIOS.h
//  qliq
//
//  Created by Adam Sowa on 09/05/16.
//
//

#import <Foundation/Foundation.h>

@class QliqUser;

@interface QxPlatfromIOS : NSObject

+ (BOOL) openDatabase:(NSString *)path withKey:(NSString *)key;
+ (void) closeDatabase;

+ (void) onUserSessionStarted;
+ (void) onUserSessionFinishing;
+ (void) onUserSessionFinished;
+ (BOOL) isUserSessionStarted;

+ (void) setMyUser:(QliqUser *)user;
+ (void) setKeyPair:(void *)pubKey publicKeyString:(NSString *)publicKeyString privateKey:(void *)privKey;

+ (BOOL) processFhirAttachment:(NSString *)json;

+ (int) maybeLogWebRequestMethod:(NSString *)httpMethod url:(NSString *)url json:(NSDictionary *)jsonDict;
+ (void) maybeUpdateWebResponseWithId:(int)requestId duration:(int)duration responseCode:(int)responseCode jsonError:(int)jsonError response:(NSString *)response;
+ (void) maybeUpdateWebResponseJsonErrorWithId:(int)requestId jsonError:(int)jsonError;

+ (void) savePushNotificationToLogDatabase:(NSDictionary *)apns;

+ (BOOL) decryptDatabase:(NSString *)encryptedPath to:(NSString *)decryptedPath withKey:(NSString *)key;

@end
