//
//  JSONSchemaValidator.h
//  CCiPhoneApp
//
//  Created by Adam Sowa on 8/9/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

extern int SchemeUnavailable;

//If you change order here you need to change embeddedSchema() also
typedef enum {
    RegisterAccountRequestSchema,
    RegisterAccountResponseSchema,
    UpdateGroupMembershipRequestSchema,
    UpdateGroupMembershipResponseSchema,
    GetQuickMessagesRequestSchema,
    GetQuickMessagesResponseSchema,
    GetSecuritySettingsRequestSchema,
    GetSecuritySettingsResponseSchema,
    GetPresenceStatusRequestSchema,
    GetPresenceStatusResponseSchema,
    SetPresenceStatusRequestSchema,
    SetPresenceStatusResponseSchema,
    CreateMultiPartyRequestSchema,
    CreateMultiPartyResponseSchema,
    GetMultiPartyRequestSchema,
    GetMultiPartyResponseSchema,
    ModifyMultiPartyRequestSchema,
    ModifyMultiPartyResponseSchema,
	ReportIncidentRequestSchema,
	ReportIncidentResponseSchema,
    SendFeedbackRequestSchema,
    SendFeedbackResponseSchema,
	GetGroupKeyPairRequestSchema,
	GetGroupKeyPairResponseSchema,
    ResetPasswordRequestSchema,
    ResetPasswordResponseSchema,
    GetContactPubkeyRequestSchema,
    GetContactPubkeyResponseSchema,
	GetKeyPairRequestSchema,
	GetKeyPairResponseSchema,
	ChangeNotificationsSchema,
	GetContactInfoRequestSchema,
	GetContactInfoResponseSchema,
	GetGroupInfoRequestSchema,
	GetGroupInfoResponseSchema,
	GetGroupContactsRequestSchema,
	GetGroupContactsResponseSchema,
	GetDeviceStatusRequestSchema,
	GetDeviceStatusResponseSchema,
	SetDeviceStatusRequestSchema,
	SetDeviceStatusResponseSchema,
	PutFileRequestSchema,
	PutFileResponseSchema,
	GetFileRequestSchema,
	LoginRequestSchema,
	LoginResponseSchema,
	LogoutRequestSchema,
	LogoutesponseSchema,
	GetUserConfigRequestSchema,
	GetUserConfigResponseSchema,
	GetAllContactsRequestSchema,
	GetAllContactsResponseSchema,
    GetPagedContactsRequestSchema,
	GetPagedContactsResponseSchema,
	GetAvatarRequestSchema,
	GetAvatarResponseSchema,
	SetAvatarRequestSchema,
	SetAvatarResponseSchema,
	FindQliqUserRequestSchema,
	FindQliqUserResponseSchema,
	FindAllQliqUsersRequestSchema,
	FindAllQliqUsersResponseSchema,
	CreateInvitationRequestSchema,
	CreateInvitationResponseSchema,
	InvitationActionRequestSchema,
	InvitationActionResponseSchema,
	GetPublicKeysRequestSchema,
	GetPublicKeysResponseSchema,
	SetPublicKeyRequestSchema,
	SetPublicKeyResponseSchema,
	PublicKeyChangedNotificationSchema,
	MessageSchema,
	ChatMessageSchema,
    UpdateProfileRequestSchema,
    UpdateProfileResponseSchema,
    UpdatePasswordRequestSchema,
    UpdatePasswordResponseSchema,
    GetEscalatedCallnotifyInfoRequestSchema,
    GetEscalatedCallnotifyInfoResponseSchema,
    UpdateEscalatedCallnotifyInfoRequestSchema,
    UpdateEscalatedCallnotifyInfoResponceSchema,
    GetAppFirstLaunchInfoRequestSchema,
    GetAppFirstLaunchInfoResponceSchema,
    Click2CallRequestSchema,
	SchemaCount
} Schema;

@interface JSONSchemaValidator : NSObject {

}
+ (BOOL)validate:(NSString *)json embeddedSchemaString:(NSString *)schema;
+ (BOOL)validate:(NSString *)json embeddedSchema:(Schema)schema;
+ (NSString *)embeddedSchema:(Schema)schema;
+ (BOOL) errorInReply:(NSString *) jsonReply;
@end
