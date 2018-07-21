//
//  Login.h
//  qliq
//
//  Created by Valerii Lider on 5/28/14.
//
//

#import <Foundation/Foundation.h>

#import "FailedAttemptsController.h"

@class FailedAttemptsController;
@class QliqGroup;

#define kNotificationUserDidLogin @"NotificationUserDidLogin"

typedef enum {
    LoginStatusShowFirstLaunch,
    LoginStatusShowLogin,
    LoginStatusShowSetNewPin,
    LoginStatusShowEnterPin
}LoginStatus;

typedef NS_ENUM(NSInteger, StartViewType) {
    StartViewTypeNone = 0,
    StartViewTypeFirstLaunch,
    StartViewTypeLock,
    StartViewTypeWipe,
    StartViewTypeAttemptsLock,
    StartViewTypeEnterPassword,
    StartViewTypeEnterPin,
    StartViewTypeForgotPassword,
    StartViewTypeCreateAccount,
    StartViewTypeSwitchUser,
    StartViewTypeMainView
};

typedef NS_ENUM(NSInteger, LoginWithPinErrorCode) {
    LoginWithPinErrorCodePinExpired = 100,
    LoginWithPinErrorCodePinBlocked = 101,
    LoginWithPinErrorCodeEnteredWrongPin = 102,
    LoginWithPinErrorCodePin1NotEqualPin2 = 103
};

typedef void (^Completion)(NSError * error, id result);

@protocol LoginDelegate <NSObject>

@optional

- (void)loginWithPin;
- (void)loginWithPassword;
- (void)loginNewPinQuestion;
- (void)loginIsSuccessful:(id)result;
- (void)loginError:(NSError*)error title:(NSString*)title message:(NSString*)message;

@end

@interface Login : NSObject

@property (nonatomic, weak) id<LoginDelegate> delegate;

@property (nonatomic, assign) BOOL shouldSkipAutoLogin;
@property (nonatomic, assign) BOOL loginWithPin;
@property (nonatomic, assign) BOOL manualLogin;
@property (nonatomic, assign) BOOL isLoginRunning;

@property (nonatomic, strong) QliqUser *lastLoggedUser;
@property (nonatomic, strong) QliqGroup *lastLoggedUserGroup;
@property (nonatomic, strong) UserSessionService *userSessionService;

@property (nonatomic, strong) FailedAttemptsController *failedAttemptsController;

@property (nonatomic, assign) StartViewType shouldStartView;

typedef void (^LoginWithPinCompletionBlock)(BOOL loginStarted, NSError *error);
typedef void (^ConfirmationBlock)(BOOL confirmed, NSError *error);

+ (Login *)sharedService;

//Choose
- (StartViewType)showStartViewForIdleLock;

+(void)touchIdVerification:(void(^)(BOOL success, NSError * error))completion;

//Register
- (void)registerUserWithFirstName:(NSString*)firstName
                       middleName:(NSString*)middleName
                            email:(NSString*)email
                         lastName:(NSString*)lastName
                            phone:(NSString*)phone
                       profession:(NSString*)profession
                     organization:(NSString*)organization
                          website:(NSString*)website
                            block:(void(^)(NSError *error))block;

- (BOOL)continueLoginWithResponseFromServerWithCompletion:(CompletionBlock)completion;

//LogOut
- (void)startLogoutWithCompletition:(void(^)(void))completition;

//Login
- (void)beginLogin;
//- (void)didLogin;
- (void)tryAutologinOrPreopenDB;
- (void)openCrypto:(BOOL)login;

- (BOOL)startLoginInResponseToRemotePush;
- (void)startManualLoginWithUsername:(NSString *)username password:(NSString *)password;
- (void)startLoginWithUsername:(NSString *)username password:(NSString *)password autoLogin:(BOOL)isAutoLogin forceLocalLogin:(BOOL)forceLocal;

- (BOOL)localLogin:(NSString *)username password:(NSString *)password error:(NSError **)error;
- (BOOL)shouldAutoLogin;
- (void)settingShouldSkipAutoLogin:(BOOL)shouldSkipAutoLogin;
- (BOOL)gettingShouldSkipAutoLogin;
- (void)loadLoginObjectsForLastUserWithCompletion:(void (^)(BOOL success))completion;

//Pin
- (BOOL)pinConfirmed:(NSString *)pin;
- (BOOL)isPinExpired;
- (void)setPinLater;
- (void)saveNewPin:(NSString *)pin;
- (void)confirmNewPin:(NSString *)newPin andConfirmedNewPin:(NSString *)confirmedNewPin withBlock:(ConfirmationBlock)confirmationBlock;

- (void)startLoginWithPin:(NSString *)pin withCompletionBlock:(LoginWithPinCompletionBlock)compleationBlock;

//FailedAttemptsController configuration
- (void)loginFailedWithInvalidCredentials;

@end
