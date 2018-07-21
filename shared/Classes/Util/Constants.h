//
//  Constants.h
//  CCiPhoneApp
//
//  Created by Ravi Ada on 4/17/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


//@interface Constants : NSObject {
//    
//}

extern NSInteger const HEADER_HEIGHT;
extern NSInteger const DEFAULT_ROW_HEIGHT_CENSUS;
extern NSInteger const DEFAULT_ROW_HEIGHT_APPTS;
extern NSString * const CCIPHONE_LOGIN_PIN_METHOD;
extern NSString * const CCIPHONE_USERNAME_PIN_USED;
extern NSString * const CCIPHONE_PASSWORD_PIN_USED;
extern NSString * const CCIPHONE_LOGIN_PASSWORD_METHOD;

extern NSString * const SAVED_ROUND_NOTIFICATION;

extern NSInteger const IDLE_TIME;

extern NSString *LocalNotificationType;
extern NSString *LocalNotificationTypeCall;
extern NSString *LocalNotificationTypeNotify;
extern NSString *LocalNotificationTypeChime;
extern NSString *LocalNotificationTypeScheduledChime;

extern NSString *LocalNotificationRingtoneType;
extern NSString *LocalNotificationRingtonePriority;
extern NSString *LocalNotificationInterval;
extern NSString *LocalNotificationMessagePriority;
extern NSString *LocalNotificationAlertBody;

extern NSString *OpenPDFInMediaControllerNotification;
extern NSString *OpenMediaControllerNotification;

extern NSString *UpdateMediaBadgeNumberNotification;
extern NSString *removeAllMediaFilesNotification;
extern NSString *ReuploadMediaFileNotification;

#define kUpdateContactsListNotificationName @"UpdateContactsListNotificationName"
#define kUpdateContactsAvatarNotificationName @"UpdateContactsAvatarNotificationName"

//Blocks types
typedef enum {CompletitionStatusSuccess, CompletitionStatusError, CompletitionStatusCancel } CompletitionStatus;

typedef void (^CompletionBlock)(CompletitionStatus status, id result, NSError *error);

#define NSStringFromCompletitionStatus(status) status == CompletitionStatusSuccess ? @"CompletitionStatusSuccess" : \
                                               status == CompletitionStatusError ? @"CompletitionStatusError" : \
                                               status == CompletitionStatusCancel ? @"CompletitionStatusCancel" : @"CompletitionStatusUnknown"

typedef enum {
    QliqModelViewModeUnknown = 0,
    QliqModelViewModeAdd,
    QliqModelViewModeEdit,
    QliqModelViewModeView,
	QliqModelViewModeSelectedEdit
} QliqModelViewMode;

extern NSString *QliqConnectModuleName;
//extern NSString *QliqCareModuleName;
//extern NSString *QliqChargeModuleName;

