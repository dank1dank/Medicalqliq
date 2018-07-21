//
//  CallAlertService.m
//  qliq
//
//  Created by Valerii Lider on 6/2/16.
//
//

#import "CallAlertService.h"
#import "Click2CallService.h"
#import "AlertController.h"

@interface CallAlertService ()

@property (strong, nonatomic) UIViewController *presenterViewController;

@end

@implementation CallAlertService

#pragma mark - Life Cycle

- (void)dealloc {
    self.presenterViewController = nil;
    self.customAlertsPreShowBlock = nil;
    self.customAlertsAfterDismissBlock = nil;
}

- (instancetype)initWithPresenterViewController:(UIViewController *)presenterViewController {
    self = [super init];
   
    if (self) {
        self.presenterViewController = presenterViewController;
        
        self.customAlertsPreShowBlock = nil;
        self.customAlertsAfterDismissBlock = nil;
    }
    return self;
}
#pragma mark - Setters

- (void)setCustomAlertsPreShowBlock:(VoidBlock)customAlertsPreShowBlock {
    _customAlertsPreShowBlock = customAlertsPreShowBlock;
}

- (void)setCustomAlertsAfterDismissBlock:(VoidBlock)customAlertsAfterDismissBlock {
    _customAlertsAfterDismissBlock = customAlertsAfterDismissBlock;
}

#pragma mark - Calls

- (void)onQliqAssistedCallTo:(NSString *)calleePhoneNumber {
    /*
     check for block_callerId
     */
    DDLogSupport(@"onQliqAssistedCallTo called");
   
    BOOL blockCallerId = [UserSessionService currentUserSession].userSettings.securitySettings.blockCallerId;

    if (blockCallerId) {
        /*
         show Qliq Assisted Alert
         */
        [self showQliqAssistedAlertWithPhoneNumber:calleePhoneNumber];
    } else {
        [self showBlockQliqAssistedAlert];
    }
}

- (void)onDirectCallTo:(NSString *)calleePhoneNumber {

    DDLogSupport(@"onDirectCallTo: called");

    NSString *phone = calleePhoneNumber;
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[^0-9]"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    phone = [regex stringByReplacingMatchesInString:phone
                                            options:0
                                              range:NSMakeRange(0, phone.length)
                                       withTemplate:@""];
    if ([phone length]) {
        NSString *phoneNumber = [@"tel://" stringByAppendingString:phone];
        NSURL *url = [NSURL URLWithString:phoneNumber];
        if (![[UIApplication sharedApplication] openURL:url]) {
            [self showWrongNumberForQliqAssistedAlertCaller:NO];
        }
    }
}

- (void)requestCallBackForCaller:(NSString *)callerPhoneNumber toCallee:(NSString *)calleePhoneNumber {

    if (isValidPhone(calleePhoneNumber)) {
        if (isValidPhone(callerPhoneNumber)) {
            /*
             Qliq Assisted calling click2Call service
             */
            if (![[UserSessionService currentUserSession].userSettings.usersCallbackNumber isEqualToString:callerPhoneNumber]) {
                [UserSessionService currentUserSession].userSettings.usersCallbackNumber = callerPhoneNumber;
                [[UserSessionService currentUserSession].userSettings write];
            }

            DDLogSupport(@"Calling click2Call service");
            Click2CallService *requestCallService = [[Click2CallService alloc] init];

            [SVProgressHUD showWithStatus:QliqLocalizedString(@"1953-TextSendingRequest") maskType:SVProgressHUDMaskTypeGradient];

            [requestCallService requestCallbackForCallerNumber:callerPhoneNumber toCalle:calleePhoneNumber withCompletionBlock:^(CompletitionStatus status, id result, NSError *error) {

                if (error) {
                    DDLogError(@"%@", [error localizedDescription]);
                    if ([error code] == 103) {
                        [self showServiceNotAvailableAlert:[error localizedDescription]];
                    }
                } else if (status == CompletitionStatusSuccess) {
                    DDLogSupport(@"Callback requested");
                }
                
                [SVProgressHUD dismiss];
            }];
        } else {

            [self showWrongNumberForQliqAssistedAlertCaller:YES];
        }
    }
    else {
        [self showWrongNumberForQliqAssistedAlertCaller:NO];
    }
}

#pragma mark - Alerts


- (void)phoneNumberWasSelectedForAction:(NSString *)calleePhoneNumber {
    
    DDLogSupport(@"phoneNumberWasSelectedForAction: called");
    
    CustomAlertView *alert = [[CustomAlertView alloc] initWithTitle:QliqFormatLocalizedString1(@"2322-TitleCallTo{Number}", formatPhoneNumber(calleePhoneNumber))
                                                            message:QliqLocalizedString(@"1948-TextWouldYouLikeToCallQliqAssisted")
                                                           delegate:nil
                                                          needTextField:NO
                                                requestButtonTitles:@[QliqLocalizedString(@"108-ButtonQliqAssisted"),
                                                                      QliqLocalizedString(@"109-ButtonDirectCall")]];
    if (self.customAlertsPreShowBlock) {
        self.customAlertsPreShowBlock();
    }
    
    __weak __block typeof(self) welf = self;
    [alert showInView:self.presenterViewController.view withDismissBlock:^(NSInteger buttonIndex, NSString *textFieldText) {
        if (buttonIndex == 1) {
            [welf onQliqAssistedCallTo:calleePhoneNumber];
        }
        if (buttonIndex == 2) {
            [welf onDirectCallTo:calleePhoneNumber];
        }
        
        if (welf.customAlertsAfterDismissBlock) {
            welf.customAlertsAfterDismissBlock();
        }
    }];
}


- (void)showBlockQliqAssistedAlert {
    
    [AlertController showAlertWithTitle:QliqLocalizedString(@"1951-TextQliqAssistedIsNotActivated")
                                message:nil buttonTitle:nil
                      cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                             completion:nil];
}

- (void)showWrongNumberForQliqAssistedAlertCaller:(BOOL)isCaller {
    
    NSString *alertString = nil;
    if (isCaller)
        alertString = QliqFormatLocalizedString1(@"1224-TextPhoneNumberInvalid{Caller/Callee}", QliqLocalizedString(@"1225-Caller"));
    else
        alertString = QliqFormatLocalizedString1(@"1224-TextPhoneNumberInvalid{Caller/Callee}", QliqLocalizedString(@"1226-Callee"));
    
    [self.presenterViewController dismissViewControllerAnimated:YES completion:nil];
    
    [AlertController showAlertWithTitle:alertString
                                message:nil
                            buttonTitle:nil
                      cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                             completion:nil];
    
//    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:alertString
//                                                                             message:nil
//                                                                      preferredStyle:UIAlertControllerStyleAlert];
//    UIAlertAction *okAction = [UIAlertAction actionWithTitle:QliqLocalizedString(@"1-ButtonOK")
//                                                       style:UIAlertActionStyleCancel
//                                                     handler:nil];
//    [alertController addAction:okAction];
//    [self.presenterViewController presentViewController:alertController animated:YES completion:nil];
}

- (void)showQliqAssistedAlertWithPhoneNumber:(NSString *)calleePhoneNumber {

    DDLogSupport(@"showQliqAssistedAlertWithPhoneNumber: called");
   
    CustomAlertView *alert = [[CustomAlertView alloc] initWithTitle:QliqFormatLocalizedString1(@"2323-TitleQliqAssistedCall{Number}", formatPhoneNumber(calleePhoneNumber))
                                                            message:QliqLocalizedString(@"1949-TextCallBackNumber")
                                                           delegate:nil
                                                          needTextField:YES
                                                requestButtonTitles:@[QliqLocalizedString(@"110-ButtonRequestCallback")]];
    if (self.customAlertsPreShowBlock) {
        self.customAlertsPreShowBlock();
    }
    __weak __block typeof(self) welf = self;
    [alert showInView:self.presenterViewController.view withDismissBlock:^(NSInteger buttonIndex, NSString *textFieldText) {
       
        if (buttonIndex == 1) {
            if (textFieldText.length != 0) {
                [welf requestCallBackForCaller:textFieldText toCallee:calleePhoneNumber];
            }
        }
       
        if (welf.customAlertsAfterDismissBlock) {
            welf.customAlertsAfterDismissBlock();
        }
    }];
}

- (void)showServiceNotAvailableAlert:(NSString *)responseMessage {
    NSString *alertMessage = nil;
    if (responseMessage)
        alertMessage = responseMessage;
    else
        alertMessage = QliqLocalizedString(@"2324-TitleServiceNotAvailable");
    
    [AlertController showAlertWithTitle:nil
                                message:alertMessage
                            buttonTitle:nil
                      cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                             completion:nil];
}

@end
