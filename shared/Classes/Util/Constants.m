//
//  Constants.m
//  CCiPhoneApp
//
//  Created by Ravi Ada on 4/17/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import "Constants.h"


//@implementation Constants

NSInteger const HEADER_HEIGHT = 50;
NSInteger const DEFAULT_ROW_HEIGHT_CENSUS = 50;
NSInteger const DEFAULT_ROW_HEIGHT_APPTS = 100;
NSString * const CCIPHONE_LOGIN_PIN_METHOD = @"cciphoneapppin";
NSString * const CCIPHONE_USERNAME_PIN_USED = @"cciphoneapppinusername";
NSString * const CCIPHONE_PASSWORD_PIN_USED = @"cciphoneapppinpassword";
NSString * const CCIPHONE_LOGIN_PASSWORD_METHOD = @"cciphoneapppassword";

NSString * const SAVED_ROUND_NOTIFICATION = @"SavedRoundNotification";
#ifdef DEBUG
NSInteger const IDLE_TIME = 0;
#else
NSInteger const IDLE_TIME = 900;
#endif


NSString *QliqConnectModuleName = @"QliqConnectModule";
//NSString *QliqCareModuleName = @"QliqCareModule";
//NSString *QliqChargeModuleName = @"QliqChargeModule";

NSString * LocalNotificationType = @"LocalNotificationType";
NSString * LocalNotificationTypeCall = @"LocalNotificationTypeCall";
NSString * LocalNotificationTypeNotify = @"LocalNotificationTypeNotify";
NSString * LocalNotificationTypeChime = @"LocalNotificationTypeChime";
NSString * LocalNotificationTypeScheduledChime = @"LocalNotificationTypeScheduledChime";

NSString * LocalNotificationRingtoneType = @"LocalNotificationRingtoneType";
NSString * LocalNotificationRingtonePriority = @"LocalNotificationRingtonePriority";
NSString * LocalNotificationInterval = @"LocalNotificationInterval";
NSString * LocalNotificationMessagePriority = @"LocalNotificationMessagePriority";
NSString * LocalNotificationAlertBody = @"LocalNotificationAlertBody";

NSString *OpenPDFInMediaControllerNotification = @"OpenPDFInMediaControllerNotification";
NSString *RemoveMediaFileAndAttachmentNotification = @"RemoveMediaFileAndAttachmentNotification";
NSString *OpenMediaControllerNotification = @"OpenMediaControllerNotification";
NSString *UpdateMediaBadgeNumberNotification = @"UpdateMediaBadgeNumberNotification";
NSString *removeAllMediaFilesNotification = @"RemoveAllMediaFilesNotification";
NSString *ReuploadMediaFileNotification = @"ReuploadMediaFileNotification";

//@end
