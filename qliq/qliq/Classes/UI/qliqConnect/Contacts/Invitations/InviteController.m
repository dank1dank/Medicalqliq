//
//  InviteController.m
//  qliq
//
//  Created by Aleksey Garbarev on 29.06.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "InviteController.h"

#import "InvitationAPIService.h"


#import "Contact.h"
#import "Invitation.h"
#import "QliqConnectModule.h"

#import <MessageUI/MessageUI.h>

#import "QliqUserDBService.h"
#import "ContactDBService.h"
#import "InvitationService.h"
#import "SVProgressHUD.h"
#import "AlertController.h"
#import "QliqSignHelper.h"

@implementation InviteController
{
    UIViewController *initiatedViewController;
}

+ (NSString *)getInviteText {
    return QliqLocalizedString(@"2148-TitleInviteText");
}

- (id)initFromViewController:(UIViewController *)viewController {
    self = [super init];
    if (self){
        initiatedViewController = viewController;
    }
    return self;
}

+ (id)inviteControllerFromViewController:(UIViewController *)viewController {
    return [[InviteController alloc] initFromViewController:viewController];
}

#pragma mark - Public Methods

- (void)inviteContact:(Contact *)contact withCompletitionBlock:(void(^)(InviteControllerState state, NSError * error, Invitation *invitation))completeBlock {
    [self inviteContact:contact withReason:@"new" withCompletitionBlock:completeBlock];
}

- (void)inviteContact:(Contact *)contact withReason:(NSString *)invitationReason withCompletitionBlock:(void (^)(InviteControllerState, NSError *, Invitation *))completeBlock {
    
    //This block needs to handle completiton before call sender's block. To set correct status for contact and call 'Cancel' action for invitation service
    void(^complete)(InviteControllerState state, NSError *error, Invitation *invitation) = ^(InviteControllerState state, NSError *error, Invitation *invitation) {
        
        if (state == InviteControllerStateSuccess) { //if invite sended
            invitation.contact.contactStatus = ContactStatusInvited;
        }
        else {                                      //If cancelled or error
            invitation.contact.contactStatus = ContactStatusDefault;
            
            if (invitation) {
                [[InvitationAPIService sharedService] cancelInvitation:invitation complete:nil];
            }
        }
        
        [[ContactDBService sharedService] saveContact:invitation.contact];
        
        if (completeBlock) {
            completeBlock(state, error, invitation);
        }
    };
    
    static void (^doInviteBlock)(); doInviteBlock = ^() {
        
        dispatch_async_main(^{
            if ([SVProgressHUD isVisible]) {
                [SVProgressHUD dismiss];
            }
            
            [SVProgressHUD showWithStatus:NSLocalizedString(@"1910-StatusInviting", nil) maskType:SVProgressHUDMaskTypeBlack];
        });
        
        //Call invite service
        [[InvitationAPIService sharedService] inviteUser:contact withReason:invitationReason complete:^(NSError *error, Invitation *result) {
            
            if (!error) {
                if (result.contact.contactType == ContactTypeQliqUser) {
                    [self inviteQliqWithInvitation:result withCompletitionBlock:complete];
                }
                else {
                    [self inviteNonQliqWithInvitation:result withCompletitionBlock:complete];
                }
            }
            else {
                [SVProgressHUD dismiss];
                complete(InviteControllerStateError, error, result);
            }
        }];
    };
    
    //check if we don't have mail and phone
    
//    if (/*contact.contactType != ContactTypeQliqUser && */![[QliqUserDBService sharedService] getUserForContact:contact]){//If we will invite by email/phone
//        //        if (contact.email.length == 0 && contact.mobile.length == 0){       //and email and mail is empty
//        //            if (complete) complete(InviteControllerStateError, [NSError errorWithDomain:errorDomainForModule(@"invitationController") code:4 userInfo:userInfoWithDescription(@"No email or mobile defined for this contact")],nil);
//        //            return;
//        //        }
    
    if (![[QliqUserDBService sharedService] getUserForContact:contact]){ //If we will invite by email/phone
        if (contact.email.length == 0) {
            if (contact.mobile.length == 0) {
                
                NSError *error =  [NSError errorWithDomain:errorDomainForModule(@"invitationController")
                                                      code:4 userInfo:userInfoWithDescription(@"Please provide email before sending invitation")];
                
                if (complete) {
                    complete(InviteControllerStateProvideEmail, error, nil);
                }
                return;
            }
            else {
                
                [SVProgressHUD dismiss];
                
                [AlertController showActionSheetAlertWithTitle:NSLocalizedString(@"1119-TextSendInvitationTo", nil)
                                                       message:nil
                                              withTitleButtons:@[contact.mobile]
                                             cancelButtonTitle:NSLocalizedString(@"4-ButtonCancel", nil)
                                                    completion:^(NSUInteger buttonIndex) {
                                                        
                                                        if (buttonIndex == @[contact.mobile].count) {
                                                            //No need to save contact in DB from iPhone Contacts if user canceled invite
                                                            //Valerii Lider, 06/01/18
                                                            /*
                                                            contact.contactStatus = ContactStatusDefault;
                                                            [[ContactDBService sharedService] saveContact:contact];
                                                            [[NSNotificationCenter defaultCenter] postNotificationName:kUpdateContactsListNotificationName object:nil userInfo:nil];
                                                             */
                                                            complete(InviteControllerStateCancelled, nil, nil);
                                                        } else {
                                                            doInviteBlock();
                                                        }
                                                    }];
            }
        }
        else {
            doInviteBlock();
        }
    }
    else {
        if (completeBlock) {
            completeBlock(InviteControllerStateAlreadyInvited, nil, nil);
        }
        return;
    }
    
    if (completeBlock) {
        completeBlock(InviteControllerStateProgressChanged, nil, nil);
    }
}

- (void)inviteQliqWithInvitation:(Invitation *)invitation withCompletitionBlock:(void(^)(InviteControllerState state, NSError * error, Invitation * invitation)) completeBlock {
    
    [[QliqConnectModule sharedQliqConnectModule] sendInvitation:invitation action:InvitationActionInvite completitionBlock:^(NSError *error) {
        if (!error) {
            [SVProgressHUD dismiss];
            completeBlock(InviteControllerStateSuccess, nil, invitation);
        }
        else {
            if (error.code == qliqErrorCodeUserNotActive) {
                [self inviteNonQliqWithInvitation:invitation withCompletitionBlock:completeBlock];
            }
            else {
                [SVProgressHUD dismiss];
                completeBlock(InviteControllerStateError, error, invitation);
            }
        }
    }];
}

- (void)inviteNonQliqWithInvitation:(Invitation *)invitation withCompletitionBlock:(void(^)(InviteControllerState state, NSError *error, Invitation *invitation)) completeBlock {
    
    [SVProgressHUD dismiss];
    
    if (invitation.contact.email.length == 0 && invitation.contact.mobile.length == 0) {
        completeBlock(InviteControllerStateError, [NSError errorWithDomain:errorDomainForModule(@"invitationController")
                                                                      code:4 userInfo:userInfoWithDescription(@"No email or mobile defined for this contact")], invitation);
        return;
    }
    else if (invitation.contact.mobile.length > 0) {
        [self inviteViaSMS:invitation withCompletitionBlock:completeBlock];
        return;
    }
    else if (invitation.contact.email.length > 0) {
        [self inviteViaEmail:invitation withCompletitionBlock:completeBlock];
        return;
    }
}

#pragma mark Work with Ivitation

- (void)cancelInvitation:(Invitation *)invitation withCompletitionBlock:(void(^)(InviteControllerState state, NSError *error))completeBlock {
    
    void(^complete)(InviteControllerState state, NSError *error) = ^(InviteControllerState state, NSError *error) {
        
        if (state == InviteControllerStateSuccess) { //if invite sended
            invitation.contact.contactStatus = ContactStatusDeleted;
            
            QliqUser *user = [[QliqUserDBService sharedService] getUserWithId:invitation.contact.qliqId];
            [[QliqUserDBService sharedService] setUserDeleted:user];
            [[QliqUserDBService sharedService] saveUser:user];
            [[ContactDBService sharedService] saveContact:invitation.contact];
            [[InvitationService sharedService] deleteInvitation:invitation];
        }
        
        if (completeBlock) {
            completeBlock(state, error);
        }
    };
    
    
    UIAlertView_Blocks * alert = [[UIAlertView_Blocks alloc] initWithTitle:nil
                                                                   message:NSLocalizedString(@"1103-TextAskCancelingInvitation", nil)
                                                                  delegate:nil
                                                         cancelButtonTitle:NSLocalizedString(@"2-ButtonNO", nil)
                                                         otherButtonTitles:NSLocalizedString(@"3-ButtonYES", nil), nil];
    [alert showWithDissmissBlock:^(NSInteger buttonIndex) {
        
        if (buttonIndex != alert.cancelButtonIndex) {
            [[InvitationAPIService sharedService] cancelInvitation:invitation complete:^(NSError *error) {
                
                if (!error) {
                    complete(InviteControllerStateSuccess, nil);
                }
                else {
                    complete(InviteControllerStateError, error);
                }
            }];
        }
        else {
            complete(InviteControllerStateCancelled, nil);
        }
    }];
}

- (void)remindInvitation:(Invitation *)invitation withCompletitionBlock:(void(^)(InviteControllerState state, NSError * error))completeBlock {
    
    __block NSString *text = [NSString stringWithFormat:@"%@\n%@", [InviteController getInviteText], invitation.url];
    
    void (^showMessageComposeBlock)() = ^() {
        
        MFMessageComposeViewController_Blocks *controller = [[MFMessageComposeViewController_Blocks alloc] init];
        if (invitation.contact.mobile.length)
            [controller setRecipients:@[invitation.contact.mobile]];
        
        [controller setSubject:QliqLocalizedString(@"2146-TitleReminderJoinQliq")];
        [controller setBody:text];
        
        [controller presentFromViewController:appDelegate.navigationController animated:YES finish:^(MessageComposeResult result) {
            switch (result) {
                case MessageComposeResultSent: {
                    
                    completeBlock(InviteControllerStateSuccess, nil);
                    [AlertController showAlertWithTitle:NSLocalizedString(@"1104-TextInvitationSuccessfullySent", nil)
                                                message:nil
                                            buttonTitle:nil
                                      cancelButtonTitle:NSLocalizedString(@"1-ButtonOK", nil)
                                             completion:NULL];
                    break;
                }
                case MessageComposeResultCancelled: {
                    completeBlock(InviteControllerStateCancelled, nil);
                    break;
                }
                case MessageComposeResultFailed: {
                    
                    completeBlock(InviteControllerStateError, nil);
                    [AlertController showAlertWithTitle:NSLocalizedString(@"1105-TextUnableToSendInvitation", nil)
                                                message:nil
                                            buttonTitle:nil
                                      cancelButtonTitle:NSLocalizedString(@"1-ButtonOK", nil)
                                             completion:NULL];
                    break;
                }
            }
            
            dispatch_async_main(^{
                [controller dismissViewControllerAnimated:NO completion:nil];
            });
        }];
    };
    
    void (^showMailComposeBlock)() = ^() {
        
        MFMailComposeViewController_Blocks *controller = [[MFMailComposeViewController_Blocks alloc] init];
        [controller setSubject:QliqLocalizedString(@"2146-TitleReminderJoinQliq")];
        [controller setMessageBody:text isHTML:NO];
        
        if (invitation.contact.email.length) {
            [controller setToRecipients:@[invitation.contact.email]];
        }

        [controller presentFromViewController:appDelegate.navigationController animated:YES finish:^(MFMailComposeResult result, NSError *error){
            switch (result) {
                case MFMailComposeResultSent: {
                    completeBlock(InviteControllerStateSuccess, nil);
                    
                    [AlertController showAlertWithTitle:NSLocalizedString(@"1104-TextInvitationSuccessfullySent", nil)
                                                message:nil
                                            buttonTitle:nil
                                      cancelButtonTitle:NSLocalizedString(@"1-ButtonOK", nil)
                                             completion:NULL];
                    break;
                }
                case MFMailComposeResultFailed: {
                    completeBlock(InviteControllerStateError, nil);
                    
                    [AlertController showAlertWithTitle:NSLocalizedString(@"1105-TextUnableToSendInvitation", nil)
                                                message:NSLocalizedString(@"1106-TextCheckInternetSettings", nil)
                                            buttonTitle:nil
                                      cancelButtonTitle:NSLocalizedString(@"1-ButtonOK", nil)
                                             completion:NULL];
                    break;
                }
                case MFMailComposeResultSaved:
                case MFMailComposeResultCancelled: {
                    completeBlock(InviteControllerStateCancelled, nil);
                    break;
                }
            }
            
            dispatch_async_main(^{
                [controller dismissViewControllerAnimated:NO completion:nil];
            });
        }];
    };
    
    BOOL emailAvailable = [MFMailComposeViewController canSendMail];
    BOOL smsAvailable = [MFMessageComposeViewController canSendText];

    NSString *kEmailTitle = NSLocalizedString(@"Email", nil);
    NSString *kSMSTitle = NSLocalizedString(@"SMS", nil);
    
    if (emailAvailable && smsAvailable) {
        
        [AlertController showActionSheetAlertWithTitle:NSLocalizedString(@"1120-TextRemindBy", nil)
                                    message:nil
                                withTitleButtons:@[kEmailTitle, kSMSTitle]
                          cancelButtonTitle:NSLocalizedString(@"4-ButtonCancel", nil)
                                 completion:^(NSUInteger buttonIndex) {
                                     
                                     if (buttonIndex == @[kEmailTitle, kSMSTitle].count) {
                                         return;
                                     } else if (buttonIndex == 0) {
                                         showMailComposeBlock();
                                     } else {
                                         showMessageComposeBlock();
                                     }
                                 }];
    }
    
    else if (emailAvailable && !smsAvailable) {
        showMailComposeBlock();
    }
    else if (smsAvailable) {
        showMessageComposeBlock();
    }
    else {
        //no sms nor mail can be sent, so remind using server
        [[InvitationAPIService sharedService] remindInvitation:invitation complete:^(NSError *error) {
            if(!error){
                if (completeBlock) {
                    completeBlock(InviteControllerStateSuccess, nil);
                }
            }
            else {
                if (completeBlock) {
                    completeBlock(InviteControllerStateError, error);
                }
            }
        }];
    }
}

- (void)acceptInvitation:(Invitation *)invitation withCompletitionBlock:(void(^)(InviteControllerState state, NSError * error))completeBlock {
    [[InvitationAPIService sharedService] acceptInvitation:invitation complete:^(NSError *error) {

        if(!error) {
            invitation.contact.contactStatus = ContactStatusNew;
            [[InvitationService sharedService] saveInvitation:invitation];
            
            if (completeBlock) {
                completeBlock(InviteControllerStateSuccess, nil);
            }
        }
        else {
            if (completeBlock) {
                completeBlock(InviteControllerStateError, error);
            }
        }
    }];
}

- (void)declineInvitation:(Invitation *) invitation withCompletitionBlock:(void(^)(InviteControllerState state, NSError * error)) completeBlock {
    [[InvitationAPIService sharedService] declineInvitation:invitation complete:^(NSError *error) {
        
        if(!error) {
            invitation.contact.contactStatus = ContactStatusDeleted;
            [[InvitationService sharedService] saveInvitation:invitation];
            
            if (completeBlock) {
                completeBlock(InviteControllerStateSuccess, nil);
            }
        }
        else {
            if (completeBlock) {
                completeBlock(InviteControllerStateError, error);
            }
        }
    }];
}

#pragma mark - Private Methods

- (void)inviteViaEmail:(Invitation *)invitation withCompletitionBlock:(void(^)(InviteControllerState state, NSError *error, Invitation *invitation))completeBlock
{
    if (![MFMailComposeViewController canSendMail]) {
        NSError * error = [NSError errorWithDomain:errorDomainForModule(@"invitationController")
                                              code:1 userInfo:userInfoWithDescription(@"The device isn't configured to send mail")];
        completeBlock(InviteControllerStateError, error, invitation);
        return;
    }
    
    NSString *text = [NSString stringWithFormat:@"%@\n%@", [InviteController getInviteText], invitation.url];
    
    MFMailComposeViewController_Blocks * mailComposer = [[MFMailComposeViewController_Blocks alloc] init];
    [mailComposer setMessageBody:text isHTML:NO];
    [mailComposer setSubject:QliqLocalizedString(@"2147-TitleJoinQliq")];
    
    if (invitation.contact.email.length > 0) {
        [mailComposer setToRecipients:[NSArray arrayWithObject:invitation.contact.email]];
    }
    
    [SVProgressHUD dismiss];
    
    [mailComposer presentFromViewController:appDelegate.navigationController animated:YES finish:^(MFMailComposeResult result, NSError *error) {
        switch (result) {
            case MFMailComposeResultSent: {
                completeBlock(InviteControllerStateSuccess, nil, invitation);
                break;
            }
            case MFMailComposeResultFailed: {
                completeBlock(InviteControllerStateError, error, invitation);
                break;
            }
            case MFMailComposeResultSaved:
            case MFMailComposeResultCancelled: {
                completeBlock(InviteControllerStateCancelled, nil, invitation);
                break;
            }
        }
        
        dispatch_async_main(^{
            [mailComposer dismissViewControllerAnimated:NO completion:nil];
        });
    }];
}

- (void)inviteViaSMS:(Invitation *)invitation withCompletitionBlock:(void(^)(InviteControllerState state, NSError *error, Invitation *invitation))completeBlock
{
    if(![MFMessageComposeViewController canSendText]) {
        NSError * error = [NSError errorWithDomain:errorDomainForModule(@"invitationController")
                                              code:2 userInfo:userInfoWithDescription(@"The device isn't configured to send messages")];
        completeBlock(InviteControllerStateError, error, invitation);
        return;
    }
    
    NSString *text = [NSString stringWithFormat:@"%@\n%@", [InviteController getInviteText], invitation.url];
    
    MFMessageComposeViewController_Blocks * messageComposer = [[MFMessageComposeViewController_Blocks alloc] init];
    messageComposer.body = text;
    
    if (invitation.contact.mobile.length > 0) {
        messageComposer.recipients = [NSArray arrayWithObject:invitation.contact.mobile];
    }
        
    [SVProgressHUD dismiss];
    [messageComposer presentFromViewController:[QliqSignHelper currentTopViewController].navigationController animated:YES finish:^(MessageComposeResult result) {
        switch (result) {
            case MessageComposeResultSent:{
                completeBlock(InviteControllerStateSuccess, nil, invitation);
                break;
            }
            case MessageComposeResultCancelled:{
                completeBlock(InviteControllerStateCancelled, nil, invitation);
                break;
            }
            case MessageComposeResultFailed:{
                NSError * error_sms = [NSError errorWithDomain:errorDomainForModule(@"invitationController")
                                                          code:3 userInfo:userInfoWithDescription(@"Error during sending message")];
                completeBlock(InviteControllerStateError, error_sms, invitation);
                break;
            }
        }
        
        if (result == MessageComposeResultSent) {
            dispatch_async_main(^{
                [messageComposer dismissViewControllerAnimated:NO completion:^{
                    [AlertController showAlertWithTitle:nil
                                                message:QliqLocalizedString(@"1104-TextInvitationSuccessfullySent")
                                            buttonTitle:nil
                                      cancelButtonTitle:QliqLocalizedString (@"1-ButtonOk")
                                             completion:nil];
                }];
            });
        } else {
            dispatch_async_main(^{
                [messageComposer dismissViewControllerAnimated:NO completion:nil];
            });
        }
    }];
}

@end
