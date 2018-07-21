//
//  InviteContactsViewController.m
//  qliq
//
//  Created by Valeriy Lider on 11.11.14.
//
//

#import "InviteContactsViewController.h"
#import "Invitation.h"
#import "GetContactInfoService.h"
#import "QliqContactsProvider.h"
#import "ContactGroup.h"
#import "QliqUserDBService.h"
#import "InviteController.h"
#import "WEPopoverController+LockScreenFix.h"
#import "UIButton+Blocks.h"
#import "QliqModelServiceFactory.h"
#import "QliqSignHelper.h"
#import "AlertController.h"

#import "DetailContactInfoViewController.h"

#define kAvatarTag  0xA5
#define kBackgroundButtonTag    0xB0
#define kFirstNameFieldTag      0xC1
#define kLastNameFieldTag       0xC2

@interface InviteContactsViewController ()

@property (weak, nonatomic) IBOutlet UILabel *navigationLeftTitleLabel;

@property (weak, nonatomic) IBOutlet UILabel *title1;
@property (weak, nonatomic) IBOutlet UILabel *title2;
@property (weak, nonatomic) IBOutlet UILabel *title3;

//Popover UI
@property (strong, nonatomic) IBOutlet UIView *popoverInvite;
@property (weak, nonatomic) IBOutlet UILabel *contactLabel;
@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UITextField *surnameField;
@property (weak, nonatomic) IBOutlet UIButton *cancelPopoverButton;
@property (weak, nonatomic) IBOutlet UIButton *invitePopoverButton;

//Invitation routine
@property (nonatomic, strong) QliqContactsProvider *contactsProvider;
@property (nonatomic, strong) NSObject<ContactGroup> *addressBookContactsGroup;
@property (nonatomic, strong) QliqUser *invitedUser;
@property (nonatomic, strong) InviteController *inviteController;

@property (nonatomic, strong) UIViewController *presentingInViewController;
@property (nonatomic, strong) WEPopoverController *contactDetailsPopover;

//Checking weather contact can be invited
- (CanNotBeInvitedReason)canSendInvitationToContact:(Contact *)user;
- (BOOL)canSendSMS;

- (Invitation *)getInvitationForContact:(Contact *)user;
- (QliqUser *)getQliqUserForContact:(Contact *)user;
- (Contact *)getContactFromAddressBookForContact:(Contact *)contact;

@end

@implementation InviteContactsViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.inputField = nil;
    self.inviteButton = nil;
    self.inviteController = nil;
    
    self.contactsProvider = nil;
    self.addressBookContactsGroup = nil;
    self.invitedUser = nil;
    
    self.presentingInViewController = nil;
    self.contactDetailsPopover = nil;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        
        self.contactsProvider = [QliqModelServiceFactory contactsProviderForObject:self];
        self.addressBookContactsGroup = [self.contactsProvider getIPhoneContactsGroup];
        self.presentingInViewController = self;
        self.inviteController = [InviteController inviteControllerFromViewController:self.presentingInViewController];
    }
    return self;
}

- (id)initForViewController:(UIViewController *)controller {
    
    self = [self init];
    if (self) {
        
        self.presentingInViewController = controller;
        self.inviteController = [InviteController inviteControllerFromViewController:self.presentingInViewController];
    }
    
    return self;
}

- (void)configureDefaultText {
    self.navigationLeftTitleLabel.text = QliqLocalizedString(@"2100-TitleInviteContacts");
    
    self.title1.text = QliqLocalizedString(@"2136-TitleInviteVc1");
    self.title2.text = QliqLocalizedString(@"2137-TitleInviteVc2");
    self.title3.text = QliqLocalizedString(@"2138-TitleInviteVc3");
    
    self.contactLabel.text = QliqLocalizedString(@"2139-TitleContactName");
    
    [self.inviteButton setTitle:QliqLocalizedString(@"15-ButtonInvite") forState:UIControlStateNormal];
    
    [self.cancelPopoverButton setTitle:QliqLocalizedString(@"4-ButtonCancel") forState:UIControlStateNormal];
    [self.invitePopoverButton setTitle:QliqLocalizedString(@"15-ButtonInvite") forState:UIControlStateNormal];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureDefaultText];
    
    self.contactsProvider = [QliqModelServiceFactory contactsProviderForObject:self];
    self.addressBookContactsGroup = [self.contactsProvider getIPhoneContactsGroup];
    
    self.inputField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.inputField.autocorrectionType = UITextAutocorrectionTypeNo;
    
    self.presentingInViewController = self;
    self.inviteController = [InviteController inviteControllerFromViewController:self.presentingInViewController];
    
    self.contactLabel.numberOfLines = 2;
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self.view addGestureRecognizer:singleTap];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onUpdateContactAvatarNotification:)
                                                 name:kUpdateContactsAvatarNotificationName
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO];
    [self.inputField becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Public Methods

- (void)inviteContact:(Contact *)contact isAddressBookContact:(BOOL)checkAddressBook completionBlock:(void (^)(Invitation *, NSError *))completionBlock {
    
    dispatch_async_main(^{
        [SVProgressHUD showProgress:-1 status:NSLocalizedString(@"1909-StatusSearching", nil)];
    });
    
    __weak typeof(self) weakSelf = self;
    [self checkIfContactCanBeInvited:contact completionBlock:^(CanNotBeInvitedReason reason, id object) {
    
        __weak typeof(weakSelf) strongSelf = weakSelf;
        DDLogSupport(@"Invite contact, reason - %u", reason);
        
        dispatch_async_main(^{
            [SVProgressHUD dismiss];
            [self.view endEditing:YES];
        });
        
        switch (reason) {
            case CanBeInvited:
            {
                __block QliqUser *registeredUser = (QliqUser *)object;
                if (registeredUser && [registeredUser isKindOfClass:[QliqUser class]]) {
                    [registeredUser mergeWith:(QliqUser *)contact];
                } else {
                    registeredUser = (QliqUser *)contact;
                }
                
                void (^createInvitationBlock)(void) = ^{
                    
                    if (0 == registeredUser.firstName.length || 0 == registeredUser.lastName.length) {
                        
                        [strongSelf showPopoverForSpecifyingNameForContact:(Contact*)registeredUser withCompletionBlock:^(BOOL wasCancelled, NSString *firstName, NSString *lastName) {
                            
                            if (wasCancelled) {
                                NSError *error = [NSError errorWithDomain:@"InviteViewController" code:CanNotBeInvitedAsUserCancelledAction userInfo:nil];
                                completionBlock(nil, error);
                            } else {
                                registeredUser.firstName = firstName;
                                registeredUser.lastName = lastName;
                                [strongSelf createInvitationForContact:(Contact*)registeredUser withCompletion:completionBlock];
                            }
                        }];
                    } else {
                        [strongSelf createInvitationForContact:(Contact*)registeredUser withCompletion:completionBlock];
                    }
                };
                
                if (!checkAddressBook) {
                    
                    Contact *foundInAddressBook = [strongSelf getContactFromAddressBookForContact:contact];
                    if (foundInAddressBook) {
                        
                        [strongSelf showContactDetailsPopup:(QliqUser *)foundInAddressBook isAddressBookContact:YES completionBlock:^(BOOL wasCancelled) {
                            
                            if (wasCancelled) {
                                
                                NSError *error = [NSError errorWithDomain:@"InviteViewController" code:CanNotBeInvitedAsUserCancelledAction userInfo:nil];
                                completionBlock(nil, error);
                            } else {
                                
                                [strongSelf createInvitationForContact:foundInAddressBook withCompletion:completionBlock];
                            }
                        }];
                    } else {
                        createInvitationBlock();
                    }
                } else {
                    createInvitationBlock();
                }
                
                break;
            }
            case CanNotBeInvitedAsContactIsAlreadyAContact:
            {
                //show popup with contact details, contact = object;
                
                QliqUser *registeredUser = (QliqUser *)object;
                if (!registeredUser || ![registeredUser isKindOfClass:[QliqUser class]]) {
                    registeredUser = (QliqUser *)contact;
                } else {
                    [registeredUser mergeWith:(QliqUser *)contact];
                }
                
                NSString *title = NSLocalizedString(@"2012-TitleMobile", nil);
                NSString *selected = registeredUser.mobile;
                if (registeredUser.email.length) {
                    
                    title = NSLocalizedString(@"2013-TitleEmail", nil);
                    selected = registeredUser.email;
                }
                

                [AlertController showAlertWithTitle:QliqFormatLocalizedString2(@"1096-TextUserWith{mobile or email}{data}Exist", title, selected)
                                            message:nil
                                        buttonTitle:QliqLocalizedString(@"21-ButtonContactDetails")
                                  cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel")
                                         completion:^(NSUInteger buttonIndex) {
                                             if (buttonIndex ==0) {
                                                 
                                                 [strongSelf showContactDetailsController:registeredUser];
                                             }
                                         }];
                
                
                NSError *error = [NSError errorWithDomain:@"InviteViewController" code:reason userInfo: registeredUser ? @{@"QliqUser":registeredUser} : NULL];
                completionBlock(nil, error);
                break;
            }
            case CanNotBeInvitedAsContactIsAlreadyInvited:
            {
                //show popup with invitation details, invitation = object;
                
                Invitation *invitation = (Invitation *)object;
                NSString *recipientName = [NSString stringWithFormat:@"%@ %@", invitation.contact.firstName ?: @"", invitation.contact.lastName ?: @""];
                
                NSString *alertTitle = nil;
                if (InvitationOperationReceived == invitation.operation)
                    alertTitle = QliqFormatLocalizedString1(@"1097-TextYouHaveAlreadyReceivedInvitationFrom{RecipientName}", recipientName);
                else
                    alertTitle = QliqFormatLocalizedString1(@"1098-TextYouHaveAlreadyInvited{RecipientName}", recipientName);
                
                [AlertController showAlertWithTitle:alertTitle
                                            message:nil
                                        buttonTitle:QliqLocalizedString(@"22-ButtonViewInvitation")
                                  cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                         completion:^(NSUInteger buttonIndex) {
                                             if (buttonIndex==0) {
                                                 [strongSelf showContactDetailsController:invitation];
                                             }
                                         }];
                
                NSError *error = [NSError errorWithDomain:@"InviteViewController" code:reason userInfo:@{@"Invitation":object}];
                completionBlock(nil, error);
                break;
            }
            case CanNotBeInvitedAsContactRecordIncomplete:
                //show alert that contact does not have email, nor mobile or qliqId, so can not be invited
            case CanNotBeInvitedDueToDeviceCapabilities:
            {
                //show alert that contact can not be invited due to device capabilities(can not send SMS)
                
                [AlertController showAlertWithTitle:QliqLocalizedString(@"1099-TextUnableToSendInvitationToSpecifiedContact")
                                            message:QliqLocalizedString(@"1100-TextCheckEmailOrMobileSendSMS")
                                        buttonTitle:nil
                                  cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel")
                                         completion:nil];
                
                NSError *error = [NSError errorWithDomain:@"InviteViewController" code:reason userInfo:nil];
                completionBlock(nil, error);
                break;
            }
            case CanNotBeInvitedDefaultReason:
            default: {
                //show alert that contact can not be invited
                
                [AlertController showAlertWithTitle:QliqLocalizedString(@"1099-TextUnableToSendInvitationToSpecifiedContact")
                                            message:QliqLocalizedString(@"1076-TextTryLater")
                                        buttonTitle:nil
                                  cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel")
                                         completion:nil];
                
                NSError *error = [NSError errorWithDomain:@"InviteViewController" code:reason userInfo:nil];
                completionBlock(nil, error);
                break;
            }
        }
    }];
}

- (void)checkIfContactCanBeInvited:(Contact *)contact completionBlock:(void (^)(CanNotBeInvitedReason reason, id object))completionBlock {
    
    __block CanNotBeInvitedReason reason = [self canSendInvitationToContact:contact];
    
    /* Check if Contact Can not be Invited
     */
    if (CanBeInvited != reason) {
        return completionBlock(reason, nil);
    }
    
    /* Check if Contact Already Invited
     */
    Invitation *invitation = [self getInvitationForContact:contact];
    if (invitation) {
        return completionBlock(CanNotBeInvitedAsContactIsAlreadyInvited, invitation);
    }
    
    /* Check if Contact Already QliqUser
     */
    QliqUser *user = [self getQliqUserForContact:contact];
    if (user) {
        return completionBlock(CanNotBeInvitedAsContactIsAlreadyAContact, user);
    }
    [[GetContactInfoService sharedService] getInfoForContact:contact withReason:nil conpletionBlock:^(QliqUser *contact, NSError *error) {
        
        if (error) {
            DDLogSupport(@"Error for get infor for contact - %@, error code - %ld", contact.qliqId, (long)error.code);
            switch (error.code) {
                case ErrorCodeNotContact: {
                    [user mergeWith:(QliqUser *)contact];
                    reason = CanBeInvited;
                    break;
                }
                case ErrorCodeStaleData: {
                    reason = CanBeInvited;
                    break;
                }
                default: {
                    reason = CanNotBeInvitedDefaultReason;
                    break;
                }
            }
        } else {
            reason = CanNotBeInvitedAsContactIsAlreadyAContact;
        }
        
        completionBlock(reason, user);
    }];
}

#pragma mark - Private methods

- (void)createInvitationForContact:(Contact *)contact withCompletion:(void (^)(Invitation *invitation, NSError *error))completionBlock {
    [self createInvitationForContact:contact withReason:@"new" withCompletion:completionBlock];
}

- (void)createInvitationForContact:(Contact *)contact withReason:(NSString *)invitationReason withCompletion:(void (^)(Invitation *invitation, NSError *error))completionBlock {
    
    dispatch_async_main(^{
        if ([SVProgressHUD isVisible]) {
            [SVProgressHUD dismiss];
        }
        
        [SVProgressHUD showWithStatus:NSLocalizedString(@"1910-StatusInviting", nil) maskType:SVProgressHUDMaskTypeBlack];
    });
    
    __weak typeof(self) weakSelf = self;
    [self.inviteController inviteContact:contact withReason:invitationReason withCompletitionBlock:^(InviteControllerState state, NSError *error, Invitation *invitation) {
        
        __weak typeof(weakSelf) strongSelf = weakSelf;
        
        switch (state) {
            case InviteControllerStateSuccess: {
                
                [SVProgressHUD dismiss];
                
                //must be call from main thread
                [[NSNotificationCenter defaultCenter] postNotificationName:kUpdateContactsListNotificationName
                                                                    object:nil
                                                                  userInfo:nil];
                
                completionBlock(invitation, nil);
                
                if (weakSelf.presentingInViewController == strongSelf)
                    [weakSelf.navigationController popViewControllerAnimated:YES];
                
                break;
            }
            case InviteControllerStateAlreadyInvited: {
                
                [SVProgressHUD dismiss];
                
                NSError *error = [NSError errorWithDomain:@"InviteViewController" code:CanNotBeInvitedAsContactIsAlreadyInvited userInfo:nil];
                completionBlock(nil, error);
                
                if (weakSelf.presentingInViewController == strongSelf)
                    [weakSelf.navigationController popViewControllerAnimated:YES];
                break;
            }
            case InviteControllerStateError: {
                
                [SVProgressHUD dismiss];
                
                NSError *error = [NSError errorWithDomain:@"InviteViewController" code:CanNotBeInvitedDefaultReason userInfo:nil];
                completionBlock(nil, error);
                
                if (weakSelf.presentingInViewController == strongSelf)
                    [weakSelf.navigationController popViewControllerAnimated:YES];
                break;
            }
            case InviteControllerStateCancelled: {
                
                NSError *error = [NSError errorWithDomain:@"InviteViewController" code:CanNotBeInvitedAsUserCancelledAction userInfo:nil];
                completionBlock(nil, error);
                break;
            }
            case InviteControllerStateProvideEmail: {
                
                [SVProgressHUD dismiss];
                
                NSError *error = [NSError errorWithDomain:@"InviteViewController" code:CanNotBeInvitedAsContactRecordIncomplete userInfo:nil];
                completionBlock(nil, error);
                
                if (weakSelf.presentingInViewController == strongSelf)
                    [weakSelf.navigationController popViewControllerAnimated:YES];
                break;
            }
            case InviteControllerStateProgressChanged:
            default: {
//                NSError *error = [NSError errorWithDomain:@"InviteViewController" code:CanNotBeInvitedDefaultReason userInfo:nil];
//                completionBlock(nil, error);
                break;
            }
        }
    }];
}

- (void)showContactDetailsPopup:(QliqUser *)contact isAddressBookContact:(BOOL)isAddressBookContact completionBlock:(void (^)(BOOL wasCancelled))completionBlock {
    
    if (self.contactDetailsPopover) {
        
                UIButton *button = (UIButton *)[self.view viewWithTag:kBackgroundButtonTag];
                [button removeFromSuperview];
        
                [self.contactDetailsPopover hidePopoverAnimated:YES];
                self.contactDetailsPopover = nil;
        
                self.invitedUser = nil;
    } else {
        
        self.invitedUser = (QliqUser *)contact;
        
        UIViewController *controller = [[UIViewController alloc] init];
        controller.view.frame = CGRectMake(0.f, 0.f, 300.f, 130.f);
        controller.view.backgroundColor = [UIColor clearColor];
        
        UIImageView *background = [[UIImageView alloc] initWithFrame:controller.view.bounds];
        background.image = [UIImage imageNamed:@"Invite-Contacts-Page.png"];
        [controller.view addSubview:background];
        
        UIImageView *avatarImage = [[UIImageView alloc] initWithFrame:CGRectMake(10.f, 10.f, 60.f, 60.f)];
        avatarImage.tag = kAvatarTag;
        avatarImage.image = (contact.avatar ? contact.avatar : [UIImage imageNamed:@"avatar_default_blue"]);
        [controller.view addSubview:avatarImage];
        
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(75.f, 10.f, 230.f, 15.f)];
        NSString *fName = contact.firstName.length ? contact.firstName : nil;
        NSString *lName = contact.lastName.length ? contact.lastName : (fName ? @"" : @"Not specified");
        nameLabel.textColor = [UIColor whiteColor];
        nameLabel.text = [NSString stringWithFormat:@"%@, %@", lName, fName];
        [controller.view addSubview:nameLabel];
        
        UILabel *occupationLabel = [[UILabel alloc] initWithFrame:CGRectMake(75.f, 25.f, 230.f, 15.f)];
        if (isAddressBookContact) {
            occupationLabel.text = ([contact.email isKindOfClass:[NSString class]] && 0 != contact.email.length ? contact.email : @"");
        } else {
            occupationLabel.text = ([contact.profession isKindOfClass:[NSString class]] && 0 != contact.profession.length ? contact.profession : @"");
        }
        
        occupationLabel.textColor = [UIColor whiteColor];
        [controller.view addSubview:occupationLabel];
        
        UILabel *groupLabel = [[UILabel alloc] initWithFrame:CGRectMake(75.f, 40.f, 230.f, 15.f)];
        if (isAddressBookContact) {
            groupLabel.text = (( [contact.mobile isKindOfClass:[NSString class]] && 0 != contact.mobile.length) ? contact.mobile : @"");
        } else {
            groupLabel.text = (([contact.organization isKindOfClass:[NSString class]] && 0 != contact.organization.length) ? contact.organization : @"");
        }
        
        groupLabel.textColor = [UIColor whiteColor];
        [controller.view addSubview:groupLabel];
        
        UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        cancelButton.frame = CGRectMake(0.f, 85.f, 150.f, 45.f);
        cancelButton.backgroundColor = [UIColor clearColor];
        [cancelButton setTitle:QliqLocalizedString(@"4-ButtonCancel") forState:UIControlStateNormal];
        [cancelButton addBlock:^(UIButton *sender) {
            
            [self.presentingInViewController.view endEditing:YES];
            
            if (completionBlock)
                completionBlock(YES);
            
            [self showContactDetailsPopup:nil isAddressBookContact:NO completionBlock:NULL];
        } forControlEvents:UIControlEventTouchUpInside];
        [controller.view addSubview:cancelButton];
        
        UIButton *inviteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        inviteButton.frame = CGRectMake(150.f, 85.f, 150.f, 45.f);
        [inviteButton setTitle:QliqLocalizedString(@"15-ButtonInvite") forState:UIControlStateNormal];
        inviteButton.backgroundColor = [UIColor clearColor];
        [inviteButton addBlock:^(UIButton *sender) {
            
            [self.presentingInViewController.view endEditing:YES];
            
            if (completionBlock)
                completionBlock(NO);
            
            [self showContactDetailsPopup:nil isAddressBookContact:NO completionBlock:NULL];
        } forControlEvents:UIControlEventTouchUpInside];
        
        [controller.view addSubview:inviteButton];
        
        [controller setPreferredContentSize:CGSizeMake(300.f, 130.f)];
        
        self.contactDetailsPopover = [[WEPopoverController alloc] initWithContentViewController:controller];
        self.contactDetailsPopover.containerViewProperties = [[WEPopoverContainerViewProperties alloc] init];
        [self.contactDetailsPopover setPopoverContentSize:controller.view.frame.size];
        [self.contactDetailsPopover showPopoverFromRect:CGRectMake(0.f, 190.f, 320.f, 0.f)
                                                 inView:self.presentingInViewController.view
                               permittedArrowDirections:UIPopoverArrowDirectionDown
                                               animated:YES];
    }
}

- (void)showPopoverForSpecifyingNameForContact:(Contact *)contact withCompletionBlock:(void (^)(BOOL wasCancelled, NSString *firstName, NSString *lastName))completionBlock {
    
    if (self.popoverInvite.hidden == NO) {
        
        self.popoverInvite.hidden = YES;

        if (completionBlock)
            completionBlock(NO, contact.firstName, contact.lastName);
    } else {
    
        self.popoverInvite.hidden = NO;
        
        self.invitedUser = (QliqUser *)contact;
        
        NSString *text = QliqFormatLocalizedString1(@"2140-TitleEnterNameFor{Email.Mobile}", (self.invitedUser.mobile.length ? self.invitedUser.mobile : self.invitedUser.email) );
        self.contactLabel.text = text;
        
        if (contact.firstName.length) {
            self.nameField.text = contact.firstName;
        }
        
        if (contact.lastName.length) {
            self.surnameField.text = contact.lastName;
        }
        
        [self.nameField becomeFirstResponder];
        
        [self.cancelPopoverButton addBlock:^(UIButton *sender) {
            
//            [self.presentingInViewController.view endEditing:YES];
            
            if (completionBlock)
                completionBlock(YES, nil, nil);
            
            [self showPopoverForSpecifyingNameForContact:nil withCompletionBlock:NULL];
        } forControlEvents:UIControlEventTouchUpInside];

        [self.invitePopoverButton addBlock:^(UIButton *sender) {
            
            NSString *firstName = self.nameField.text;
            NSString *lastName = self.surnameField.text;
            
//            [self.presentingInViewController.view endEditing:YES];
            
            if (completionBlock)
                completionBlock(NO, firstName, lastName);
            
            [self showPopoverForSpecifyingNameForContact:nil withCompletionBlock:NULL];
        } forControlEvents:UIControlEventTouchUpInside];
    }
    
    [self.view endEditing:YES];
}

- (CanNotBeInvitedReason)canSendInvitationToContact:(Contact *)user {
    
    CanNotBeInvitedReason reason = CanNotBeInvitedDefaultReason;
    
    BOOL condition = ([user.qliqId isKindOfClass:[NSString class]] && user.qliqId.length > 0);
    condition |= user.email.length > 0;
    condition |= user.mobile.length > 0;
    reason = condition ? CanBeInvited : CanNotBeInvitedAsContactRecordIncomplete; 
    
    /*
    if (!condition && (user.mobile.length > 0)) {
        condition = [self canSendSMS];
        
        reason = (!condition ? CanNotBeInvitedDueToDeviceCapabilities : CanBeInvited);
    }
     */
    
    return reason;
}

- (BOOL)canSendSMS {
    return [MFMessageComposeViewController canSendText];
}

- (void)showContactDetailsController:(id)object {
    
    DetailContactInfoViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([DetailContactInfoViewController class])];
    controller.contact = object;
    
    [appDelegate.navigationController pushViewController:controller animated:YES];
}

- (Invitation *)getInvitationForContact:(Contact *)user
{
    /*
     * 1. Validate mobile number
     */
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[^0-9]"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    
    NSString *mobilePattern = nil;
    if (user.mobile.length) {
        
        mobilePattern = [regex stringByReplacingMatchesInString:user.mobile
                                                        options:NSMatchingReportCompletion
                                                          range:NSMakeRange(0, user.mobile.length)
                                                   withTemplate:@""];
    }
    
    Invitation *invitation = nil;
    NSObject<InvitationGroup> *invitationsGroup = (NSObject<InvitationGroup> *)[_contactsProvider getInvitationGroup];
    
    /*
     * 2. Look over sent invitations
     */
    NSArray *invitations = [invitationsGroup getSentInvitations];
    for (Invitation *item in invitations) {
        
        if (item.contact.mobile.length) {
            
            NSString *normalized = [regex stringByReplacingMatchesInString:item.contact.mobile
                                                                   options:NSMatchingReportCompletion
                                                                     range:NSMakeRange(0, item.contact.mobile.length)
                                                              withTemplate:@""].lowercaseString;
            
            if ([normalized isEqualToString:mobilePattern]) {
                
                invitation = item;
                break;
            }
        }
        
        if (item.contact.email && [item.contact.email.lowercaseString isEqualToString:user.email.lowercaseString]) {
            
            invitation = item;
            break;
        }
    }
    
    if (nil == invitation) {
        
        /*
         * 3. Look over received invitations
         */
        invitations = [invitationsGroup getReceivedInvitations];
        for (Invitation *item in invitations) {
            
            if (item.contact.mobile.length) {
                
                NSString *normalized = [regex stringByReplacingMatchesInString:item.contact.mobile
                                                                       options:NSMatchingReportCompletion
                                                                         range:NSMakeRange(0, item.contact.mobile.length)
                                                                  withTemplate:@""].lowercaseString;
                
                if ([normalized isEqualToString:mobilePattern]) {
                    
                    invitation = item;
                    break;
                }
                
            }
            
            if (item.contact.email && [item.contact.email.lowercaseString isEqualToString:user.email.lowercaseString]) {
                
                invitation = item;
                break;
            }
        }
    }
    
    return invitation;
}

- (QliqUser *)getQliqUserForContact:(Contact *)user {
    
    QliqUser *foundUser = nil;
    if ([user.qliqId isKindOfClass:[NSString class]] && user.qliqId.length)
        foundUser = [[QliqUserDBService sharedService] getUserWithId:user.qliqId];
    
    if (nil == foundUser && user.email.length)
        foundUser = [[QliqUserDBService sharedService] getUserWithEmail:user.email];
    
    if (nil == foundUser && user.mobile.length)
        foundUser = [[QliqUserDBService sharedService] getUserWithMobile:user.mobile];
    
    if (foundUser) {
        //Need to check the found user has the same contact info or not.
        //Need to reset the found user if he does not have the same qliqId, email, mobile
        //Valerii Lider, 05/05/18
        if (![foundUser.qliqId isEqualToString:user.qliqId] ||
            ![foundUser.email isEqualToString:user.email] ||
            ![foundUser.mobile isEqualToString:user.mobile]) {
            foundUser = nil;
        }
    }
    return foundUser;
}

- (Contact *)getContactFromAddressBookForContact:(Contact *)contact {
    
    Contact *foundContact = nil;
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[^0-9]"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    
    NSString *mobilePattern = nil;
    if (contact.mobile.length) {
        mobilePattern = [regex stringByReplacingMatchesInString:contact.mobile
                                                        options:0
                                                          range:NSMakeRange(0, contact.mobile.length)
                                                   withTemplate:@""].lowercaseString;
    }
    
    for (Contact *item in [self.addressBookContactsGroup getContacts]) {
        
        if (item.email.length && contact.email.length) {
            
            if ([item.email.lowercaseString isEqualToString:contact.email.lowercaseString]) {
                
                foundContact = item;
                break;
            }
        } else if (item.mobile.length && mobilePattern) {
            
            NSString *contactMobile = [regex stringByReplacingMatchesInString:item.mobile
                                                                      options:0
                                                                        range:NSMakeRange(0, item.mobile.length)
                                                                 withTemplate:@""];
            
            if ([contactMobile.lowercaseString isEqualToString:mobilePattern]) {
                
                foundContact = item;
                break;
            }
        }
    }
    
    return foundContact;
}

#pragma mark -
#pragma mark NSNotification observing
#pragma mark -

- (void)onUpdateContactAvatarNotification:(NSNotification *)notification {
    
    if (self.contactDetailsPopover && self.invitedUser) {
        UIImageView *imageView = (UIImageView *)[self.contactDetailsPopover.view viewWithTag:kAvatarTag];
        
        QliqUser *user = notification.userInfo[@"contact"];
        
        imageView.image = [[QliqAvatar sharedInstance] getAvatarForItem:user withTitle:nil];
    }
}

#pragma mark - IBActions

- (IBAction)onBackButton:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onInviteButton:(id)sender {
    [self.inputField resignFirstResponder];
    
    QliqUser *user = [[QliqUser alloc] init];
    
    if (isValidEmail(self.inputField.text)) {
        user.email = self.inputField.text;
    } else if (isValidPhone(self.inputField.text)) {
        user.mobile = self.inputField.text;
    } else if ([self.inputField.text length] == 0) {

        [AlertController showAlertWithTitle:QliqLocalizedString(@"1101-TextEnterValidEmailOrMobile")
                                    message:nil
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                 completion:nil];
        return;
    } else {
        
        [AlertController showAlertWithTitle:QliqFormatLocalizedString1(@"1102-Text{Contact name}", self.inputField.text)
                                    message:nil
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                 completion:nil];
        return;
    }
    
    [self inviteContact:(Contact *)user isAddressBookContact:NO completionBlock:^(Invitation *invitation, NSError *error) {
        
        if (nil == error && invitation) {
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kInviteControllerDidInvitedContactNotificationName object:self userInfo:@{@"Invitation":invitation}];
            
            [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"1905-TextInvited", nil)];
        } else {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"1906-TextInvitationFailed", nil)];
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void) {
            
            [SVProgressHUD dismiss];
            
            if (nil == error)
                [self.navigationController popViewControllerAnimated:YES];
        });
    }];
}

#pragma mark - Gesture

- (void)handleTap:(UITapGestureRecognizer *)recognizer {
    [self.inputField resignFirstResponder];
    [self.nameField resignFirstResponder];
    [self.surnameField resignFirstResponder];
}

@end
