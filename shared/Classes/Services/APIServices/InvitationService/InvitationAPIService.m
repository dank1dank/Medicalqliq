//
//  CreateInvitation.m
//  qliq
//
//  Created by Ravi Ada on 05/29/12.
//  Copyright (c) 2012 qliqSoft Inc. All rights reserved.
//

#import "InvitationAPIService.h"
#import "JSONSchemaValidator.h"
#import "RestClient.h"
#import "QliqJsonSchemaHeader.h"
#import "JSONKit.h"
#import "UserSession.h"
#import "UserSessionService.h"
#import "InvitationService.h"
#import "NSDate+Helper.h"
#import "QliqUserDBService.h"
#import "ContactDBService.h"
#import "QliqConnectModule.h"
#import "SipContactDBService.h"
#import <MessageUI/MFMessageComposeViewController.h>

@interface InvitationAPIService()

- (Invitation *) createInvitationFromDict:(NSDictionary *) dataDict andRecipient:(Contact*)recipient;
-(BOOL) createInvitationValid:(NSString *)createInvitationJson;


@end

@implementation InvitationAPIService

@synthesize delegate;

+ (NSError *) errorWithCode:(NSInteger) code localizedDescription:(NSString *) description{
    
    return [NSError errorWithDomain:errorDomainForModule(@"invitation_service") code:code userInfo:userInfoWithDescription(description)];
}


+ (InvitationAPIService *) sharedService{
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [[InvitationAPIService alloc] init];
        
    });
    return shared;
}

- (void) acceptInvitation:(Invitation *) invitation complete:(void(^)(NSError * error))completeBlock{
    [self inviteAction:invitation andAction:@"accept" completion:completeBlock];
}

- (void) declineInvitation:(Invitation *) invitation complete:(void(^)(NSError * error))completeBlock{
    [self inviteAction:invitation andAction:@"deny" completion:completeBlock];
}

- (void) cancelInvitation:(Invitation *) invitation complete:(void(^)(NSError * error))completeBlock{
    [self inviteAction:invitation andAction:@"cancel" completion:completeBlock];
}

- (void) remindInvitation:(Invitation *) invitation complete:(void(^)(NSError * error))completeBlock{
    
    if (completeBlock) completeBlock(nil);
    
    if (invitation.contact.contactType == ContactTypeQliqUser){
        [[QliqConnectModule sharedQliqConnectModule] sendInvitation:invitation action:InvitationActionInvite completitionBlock:^(NSError *error) {
            if (!error){
                if (completeBlock) completeBlock(nil);
            }else{
                if (completeBlock) completeBlock(error);
            }
        }];
    }else{
        DDLogWarn(@"WARNING: remindInvitation is not implemented yet..");
        if (completeBlock) completeBlock(nil);
    }
    
}

- (void)inviteUser:(Contact *)recipient withReason:(NSString *)reason complete:(void (^)(NSError * error,Invitation * result))completeBlock {
    
    QliqUser * sender = [UserSessionService currentUserSession].user;
    UserSession *currentSession = [UserSessionService currentUserSession];
    NSString *username = currentSession.sipAccountSettings.username;
    NSString *password = currentSession.sipAccountSettings.password;
	
    NSMutableDictionary * recipientDict = [[NSMutableDictionary alloc] init];
    [recipientDict setValue:recipient.firstName forKey:FIRST_NAME];
    [recipientDict setValue:recipient.middleName forKey:MIDDLE];
    [recipientDict setValue:recipient.lastName forKey:LAST_NAME];
    [recipientDict setValue:recipient.email forKey:EMAIL];
    
    if (recipient.mobile.length) {
        
        NSError *error = NULL;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[^0-9]"
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:&error];
        NSString *contactMobile = [regex stringByReplacingMatchesInString:recipient.mobile
                                                                  options:0
                                                                    range:NSMakeRange(0, recipient.mobile.length)
                                                             withTemplate:@""];
        
        [recipientDict setValue:contactMobile forKey:MOBILE];
    }
    
    NSMutableDictionary *contentDict = [[NSMutableDictionary alloc] init];
    [contentDict setValue:password forKey:PASSWORD];
    [contentDict setValue:username forKey:USERNAME];
    [contentDict setValue:sender.qliqId forKey:SENDER_ID];
	[contentDict setValue:@"individual" forKey:INVITATION_TYPE];
    [contentDict setValue:reason forKey:INVITATION_REASON];//message_waiting, new
    
    
    BOOL invitationNotify = YES;
    if (recipient.mobile.length > 0) {
        invitationNotify = ![MFMessageComposeViewController canSendText];
    }
    else if (recipient.email.length > 0) {
        invitationNotify = ![MFMailComposeViewController canSendMail];
    }
    
    [contentDict setValue:@(invitationNotify) forKey:INVITATION_NOTIFY];
    
    //[contentDict setValue:![MFMessageComposeViewController canSendText]? @(YES) : @(NO) forKey:INVITATION_NOTIFY];
    
	QliqUser *qliqUser = [[QliqUserDBService sharedService] getUserWithId:recipient.qliqId];
	if(qliqUser != nil)
		[contentDict setValue:qliqUser.qliqId forKey:RECIPIENT_QLIQ_ID];
	else
        [contentDict setValue:recipientDict forKey:RECIPIENT_DETAILS];
    
	
    NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:
							  contentDict, DATA,
							  nil];
	NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									 dataDict, MESSAGE,
									 nil];
	DDLogInfo(@"%@",[jsonDict JSONString]);
//    DDLogInfo(@"will send invitation from: %@ to: %@", sender, recipient);
	if ([JSONSchemaValidator validate:[jsonDict JSONString] embeddedSchema:CreateInvitationRequestSchema]) {
        
		RestClient *restClient = [RestClient clientForCurrentUser];
        [restClient postDataToServer:RegularWebServerType
                                path:@"services/create_invitation"
						  jsonToPost:jsonDict
						onCompletion:^(NSString *responseString) {
                            
             NSError *error = nil;
			 Invitation * invitation = [self processResponseString:responseString andSender:sender andRecipient:recipient error:&error];
             if (invitation)
                 completeBlock(nil, invitation);
             else
                 completeBlock(error, nil);
		 } onError:^(NSError* error) {
             if (completeBlock) {
                 completeBlock(error, nil);
             }
		 }];
	}
    else {
		DDLogError(@"CreateInvitation: Invalid request sent to server");
	}
}

- (void) inviteUser:(Contact *) recipient complete:(void (^)(NSError * error,Invitation * result))completeBlock{

    [self inviteUser:recipient withReason:@"new" complete:completeBlock];
}

#pragma mark -
#pragma mark Private

- (Invitation *) processResponseString:(NSString *)responseString andSender:(QliqUser*)sender andRecipient:(Contact*)recipient error:(NSError **)error
{
    NSData *jsonData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
    JSONDecoder *jsonKitDecoder = [JSONDecoder decoder];
    NSMutableDictionary *message = [[jsonKitDecoder objectWithData:jsonData error:error] objectForKey:MESSAGE];
    
	if(![self createInvitationValid:responseString])
	{
		NSString *reason = [NSString stringWithFormat:@"Invalid create invitation response"];
		DDLogError(@"%@",reason);
        
        if (error != nil) {
            *error = [NSError errorWithCode:1 description:@"Invalid create invitation response"];
        }
		return nil;
	}
	
	NSDictionary *dataDict = [message objectForKey:DATA];
    if (dataDict)
    {
        DDLogInfo(@"dataDict: %@", dataDict);
        Invitation * invitation = [self createInvitationFromDict:dataDict andRecipient:recipient];
        [[InvitationService sharedService] saveInvitation:invitation];
        
        if (error != nil) {
            *error = nil;
        }
        return invitation;
    }
    else {
		
		NSDictionary *errorDict = [message objectForKey:ERROR];
        
        if (error != nil) {
            *error = [NSError errorWithDomain:@"InvitationAPIService" code:[errorDict[ERROR_CODE] intValue] userInfo:errorDict];
        }
        DDLogError(@"errorDict: %@", errorDict);
	}
    return nil;
}

-(BOOL) createInvitationValid:(NSString *)createInvitationJson
{
    BOOL rez = YES;
    rez &= [createInvitationJson length] > 0;
    BOOL validJson = [JSONSchemaValidator validate:createInvitationJson embeddedSchema:CreateInvitationResponseSchema];
    rez &= validJson;
	
    return rez;
}

- (Invitation *) createInvitationFromDict:(NSDictionary *) dataDict andRecipient:(Contact*)recipient{
    
    Invitation *invitation = [[Invitation alloc] init];
	invitation.url = dataDict[INVITATION_URL];
    if (nil == invitation.url) {
        invitation.url = @"";
    }
	invitation.uuid = dataDict[INVITATION_GUID];

    QliqUser *user = [InvitationAPIService createAndSaveInvitatedUserFromDict:dataDict andContact:recipient];
    
    recipient.qliqId = user.qliqId;

    invitation.contact = (Contact*)user;
	invitation.invitedAt = [NSDate timeIntervalSinceReferenceDate];
	invitation.operation = InvitationOperationSent;
    return invitation;
}

// This method is shared with SendMessageToNonQliqUserService
+ (QliqUser *) createAndSaveInvitatedUserFromDict:(NSDictionary *) dataDict andContact:(Contact*)recipient
{
    QliqUser *user = [[QliqUser alloc] init];
    
    user.qliqId = dataDict[@"receiver_qliq_id"];
    
    if (recipient.firstName.length > 0 && recipient.lastName.length > 0) {
        user.firstName = recipient.firstName;
        user.lastName = recipient.lastName;
    } else {
        if (recipient.email.length > 0) {
            user.firstName = @"Email";
            user.lastName = recipient.email;
        } else {
            user.firstName = @"Mobile";
            user.lastName = recipient.mobile;
        }
    }
    user.email = recipient.email;
    user.mobile = recipient.mobile;
    user.contactStatus = ContactStatusInvitationInProcess;
    
    [[QliqUserDBService sharedService] saveUser:user];
    
    SipContactDBService *sipContactService = [[SipContactDBService alloc] init];
    SipContact *sipContact = [[SipContact alloc] init];
    sipContact.qliqId = user.qliqId;
    sipContact.sipUri = dataDict[@"sip_uri"];
    sipContact.sipContactType = SipContactTypeUser;
    sipContact.publicKey = dataDict[@"receiver_public_key"];
    [sipContactService save:sipContact completion:nil];
    return user;
}

//-(Invitation *) storeSentInvitation:(NSDictionary *)dataDict andSender:(QliqUser*)sender andRecipient:(Contact*)recipient
//{
//	DDLogSupport(@"STROE CREATE INVITATION : processing started");
//	
//    InvitationService *invitationService = [[InvitationService alloc] init];
//	
//	NSLog(@"Data %@",dataDict);
//	
//	
//	//saving invitation
//	Invitation *invitation = [[Invitation alloc] init];
//	invitation.url = [dataDict objectForKey:INVITATION_URL];
//	invitation.uuid = [dataDict objectForKey:INVITATION_GUID];
//    invitation.contact = recipient;
////    invitation.contact.contactStatus = ContactStatusInvited;
//	invitation.invitedAt = [NSDate timeIntervalSinceReferenceDate];
//	invitation.operation = InvitationOperationSent;
//	
//
//	
//	if(![invitationService saveInvitation:invitation])
//	{
//		NSLog(@"Cant save invitation: %@", invitation);
//        invitation = nil;
//	}
//	
//	DDLogSupport(@"CREATE INVITATION : processing finished");
//	return invitation;
//}



- (void) inviteAction:(Invitation *) invitation andAction:(NSString *) action completion:(void (^)(NSError *error))completeBlock
{
    UserSession *currentSession = [UserSessionService currentUserSession]; 
    NSString *username = currentSession.sipAccountSettings.username;
    NSString *password = currentSession.sipAccountSettings.password;  
    NSString *userId   = currentSession.user.qliqId;
    
    NSMutableDictionary *contentDict = [[NSMutableDictionary alloc] init];
    [contentDict setValue:password forKey:PASSWORD];
    [contentDict setValue:username forKey:USERNAME];
    [contentDict setValue:invitation.uuid forKey:INVITATION_GUID];
    [contentDict setValue:action forKey:ACTION];
    [contentDict setValue:userId forKey:SENDER_ID];
    
    NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:
							  contentDict, DATA,
							  nil];
	NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									 dataDict, MESSAGE,
									 nil];
	DDLogInfo(@"json: %@",jsonDict);
	if ([JSONSchemaValidator validate:[jsonDict JSONString] embeddedSchema:InvitationActionRequestSchema]){
		RestClient *restClient = [RestClient clientForCurrentUser];
        [restClient postDataToServer:RegularWebServerType path:@"services/invitation_action" jsonToPost:jsonDict onCompletion:^(NSString *responseString) {
            
            NSError *error = nil;
            NSData *jsonData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
            JSONDecoder *jsonKitDecoder = [JSONDecoder decoder];
            NSMutableDictionary *message = [[jsonKitDecoder objectWithData:jsonData error:&error] objectForKey:MESSAGE];
            NSDictionary *errorDict = [message objectForKey:ERROR];
            if (errorDict){
                DDLogError(@"errorDict: %@", errorDict);
                NSString *reason = [errorDict objectForKey:ERROR_MSG];
                DDLogError(@"reason: %@", reason);
                
                if (completeBlock)
                    completeBlock([NSError errorWithDomain:@"InvitationAPIService" code:0 userInfo:errorDict]);
                
                return;
            }
            
            if (completeBlock)
                completeBlock(nil);
            
		 } 
			 onError:^(NSError* error)
		 {
             if (completeBlock)
                 completeBlock(error);
		 }];
	}else{
		DDLogError(@"CreateInvitation: Invalid request sent to server");
	}
}

@end
