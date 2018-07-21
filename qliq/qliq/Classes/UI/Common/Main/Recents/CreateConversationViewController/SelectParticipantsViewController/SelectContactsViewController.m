//
//  SelectContactsViewController.m
//  qliq
//
//  Created by Valerii Lider on 11.11.14.
//

#import "SelectContactsViewController.h"
#import "SelectParticipantsTableViewCell.h"

#import "ContactGroup.h"

#import "QliqContactsProvider.h"
#import "QliqContactsGroup.h"
#import "QliqAddressBookContactGroup.h"
#import "QliqFavoritesContactGroup.h"
#import "QliqMembersContactGroup.h"

#import "QliqGroup.h"
#import "QliqUser.h"
#import "QliqModelServiceFactory.h"
#import "QliqListService.h"
#import "QliqConnectModule.h"
#import "QliqAvatar.h"

#import "Conversation.h"
#import "ConversationDBService.h"

#import "UIDevice-Hardware.h"
#import "CreateMultiPartyService.h"
#import "ModifyMultiPartyService.h"
#import "Presence.h"
#import "SearchContactsService.h"

//Fax
#import "GetFaxContactsWebService.h"
#import "FaxContactDBService.h"
#import "CallAlertService.h"

// Controllers
#import "MainViewController.h"
#import "InviteContactsViewController.h"
#import "DetailContactInfoViewController.h"
#import "CreateFaxContactViewController.h"
#import "SelectFaxContactTableViewCell.h"
#import "AlertController.h"

#define kKeySectionTitle    @"SectionTitle"
#define kKeyRecipients      @"Contacts"
#define searchViewTopConstraintPortrait 35.f
#define searchViewTopConstraintLandscape 10.f

@interface SelectContactsViewController ()
<
SearchOperationDelegate,
UITableViewDataSource,
UITableViewDelegate,
UISearchBarDelegate,
CreateFaxContactsViewControllerDelegate,
SelectFaxContactCellDelegate
>


#define kValueDelayForShowingProgressHUD 0.5f

/**
 IBOutlet
 */
@property (nonatomic, weak) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBarController;
@property (weak, nonatomic) IBOutlet UIView *headerController;
@property (weak, nonatomic) IBOutlet UIView *toolbarView;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *addFaxRecipientView;


@property (weak, nonatomic) IBOutlet UIButton *rightNavigationButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UIButton *addFaxRecipient;

/*Constraint for iPhone X*/
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *searchViewTopConstraint;

/* Constraint */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomTableViewConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightHeaderControllerConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightToolbarViewConstraint;

/**
 Data
 */

@property (nonatomic, strong) NSArray *startParticipants;
@property (nonatomic, strong) NSMutableArray *selectedParticipants;
@property (nonatomic, strong) NSMutableArray *contacts;
@property (nonatomic, strong) NSMutableArray *faxContactArray;
@property (nonatomic, strong) NSMutableArray *groups;
@property (nonatomic, strong) NSArray *dataSourceArray;
@property (nonatomic, strong) NSMutableArray *searchArray;

@property (nonatomic, strong) InviteContactsViewController  *inviteController;
@property (nonatomic, strong) QliqFavoritesContactGroup *favoritesContactGroup;

@property (strong, nonatomic) CallAlertService *callAlertService;

@property (nonatomic, strong) NSOperationQueue *searchOperationsQueue;
@property (nonatomic, strong) NSOperationQueue *refreshOperationQueue;

//Searching
@property (nonatomic, assign) BOOL isSearching;
@property (nonatomic, strong) NSString *searchText;
@property (nonatomic, assign) BOOL searchOperationDone;

@property (nonatomic, assign) BOOL needToAddKeyboardNotifications;
@property (nonatomic, assign) BOOL isNotFirstAppearance;
@property (nonatomic, assign) BOOL searchBarWasFirstResponder;

@end


@implementation SelectContactsViewController

- (void)dealloc {
    
    [self.searchOperationsQueue cancelAllOperations];
    [self.searchOperationsQueue waitUntilAllOperationsAreFinished];
    
    [self.refreshOperationQueue cancelAllOperations];
    [self.refreshOperationQueue waitUntilAllOperationsAreFinished];
    
    self.searchOperationsQueue = nil;
    self.refreshOperationQueue = nil;
    
    self.startParticipants = nil;
    self.contacts = nil;
    self.groups = nil;
    self.faxContactArray = nil;
    self.dataSourceArray = nil;
    self.searchArray = nil;
    self.inviteController = nil;
    self.favoritesContactGroup = nil;
    self.searchText = nil;
    self.faxSearch = nil;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Searchbar
    {
        if (self.firstFilterCharacter)
            self.searchBar.text = self.firstFilterCharacter;
        else
            self.searchBar.text = @"";
        
        self.needToAddKeyboardNotifications = NO;
        self.isNotFirstAppearance = NO;
        [self addKeyboardNotifications];
        [self.searchBar becomeFirstResponder];
        self.searchBarWasFirstResponder = YES;
        
        self.searchBar.hidden = NO;
        self.searchBar.frame = self.view.bounds;
    }
    
    {
        if (self.typeController == STForInviting || self.typeController == STForForwarding) {
            self.rightNavigationButton.hidden = YES;
        }
        
        if (self.typeController == STForQliqSign)
        {
            self.searchBarController.delegate = self;
            self.headerController.hidden = NO;
            self.cancelButton.hidden = NO;
            
            [self.cancelButton setBackgroundImage:[UIImage imageNamed:@"Close_button_blackColor.png"] forState:UIControlStateNormal];
            [self.cancelButton setBackgroundImage:[UIImage imageNamed:@"Close_button_lightGrayColor.png"] forState:UIControlStateHighlighted];
            [self.cancelButton addTarget:self action:@selector(onCancelButton:) forControlEvents:UIControlEventTouchUpInside];
        }
        else
        {
            if(!self.faxSearch){
                self.heightHeaderControllerConstraint.constant = 0.f;
            } else {
                self.addFaxRecipient.hidden = NO;
                self.navigationController.navigationBarHidden = YES;
                self.headerController.backgroundColor = RGBa(224, 224, 224, 1.f);
                
                int skip = nil; // can be used for pagination
                int limit = nil; // this too
                self.faxContactArray = [FaxContactDBService getWithLimit:limit skip:skip];
                
                self.addFaxRecipientView.backgroundColor = [UIColor whiteColor];
                
                //register nib
                UINib *nib = [UINib nibWithNibName:@"SelectFaxContactTableViewCell" bundle:nil];
                [self.tableView registerNib:nib forCellReuseIdentifier:@"SELECT_FAX_CONTACT_CELL"];
            }
        }
    }
    
    //Tableview
    {
        self.tableView.sectionIndexColor = kColorAvatarBackground;
    }
    
    //ToolbarView
    {
        self.toolbarView.hidden = YES;
        self.heightToolbarViewConstraint.constant = 0.f;
    }
    //Init
    {
        self.contacts = [NSMutableArray new];
        self.searchArray = [NSMutableArray new];
        self.selectedParticipants = [NSMutableArray new];
        
        if (!self.participants)
            self.participants = [NSMutableArray new];
        
        self.favoritesContactGroup = [[QliqFavoritesContactGroup alloc] init];
        self.inviteController = [[InviteContactsViewController alloc] initForViewController:self];
        
        self.searchOperationsQueue = [[NSOperationQueue alloc] init];
        self.searchOperationsQueue.maxConcurrentOperationCount = 1;
        self.searchOperationsQueue.name = @"com.qliq.selectContactsViewController.searchQueue";
        
        self.refreshOperationQueue = [[NSOperationQueue alloc] init];
        self.refreshOperationQueue.maxConcurrentOperationCount = 1;
        self.refreshOperationQueue.name = @"com.sliq.selectContactsViewController.refreshQueue";
    }
    
    /**
     Get Content Data
     */
    
    __weak __block typeof(self) welf = self;
    [self.refreshOperationQueue addOperationWithBlock: ^{
        //load contacts
        [welf loadContacts];
        
        //load groups
        QliqContactsProvider *contactProvider = [[QliqContactsProvider alloc] init];
        welf.groups = [NSMutableArray arrayWithArray:[contactProvider getUserGroups]];
       
        {
            if(welf.typeController == STForNewConversation) {
                NSMutableIndexSet *hideContacts = [NSMutableIndexSet new];
                for (QliqGroup *group in welf.groups) {
                    if ([group hasPagerUsers]) {
                        NSUInteger index = [welf.groups indexOfObject:group];
                        [hideContacts addIndex:index];
                    }
                }
                
                [welf.groups removeObjectsAtIndexes:hideContacts];
            }
            
        }

        //Set startParticipants
        if (welf.participants) {
            welf.startParticipants = [welf.participants copy];
        }
        else {
            welf.startParticipants = nil;
        }
        
        dispatch_async_main(^{
            [welf doSearchWithText:self.searchBar.text];
        });
        
        
        if (!welf.isNotFirstAppearance)
            welf.isNotFirstAppearance = YES;
    }];
    
    //Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onPresenceChangeNotification:)
                                                 name:@"PresenceChangeStatusNotification"
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    /*Change constraint for iPhone X*/
    isIPhoneX {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rotated:) name:UIDeviceOrientationDidChangeNotification object:nil];
        
        __block __weak typeof(self) weakSelf = self;
        dispatch_async_main(^{
            [weakSelf rotated:nil];
            [weakSelf.view layoutIfNeeded];
        });
        
    }
    
    self.searchBarController.hidden = YES;
    
    if (self.needToAddKeyboardNotifications)
        [self addKeyboardNotifications];
    
    [self performSelector:@selector(showProgressHUD) withObject:nil afterDelay:kValueDelayForShowingProgressHUD];
    
    if (self.faxSearch) {
        self.addFaxRecipient.hidden = NO;
        self.navigationController.navigationBarHidden = YES;
        
        GetFaxContactsWebService *getFaxContactsService = [[GetFaxContactsWebService alloc] init];
        [getFaxContactsService callWithCompletition:^(CompletitionStatus status, id result, NSError *error) {
            if (error) {
                
                DDLogSupport(@"Fax contacts did not updated. Error:%@ description:%@", error, error.localizedDescription);
                
                [AlertController showAlertWithTitle:QliqLocalizedString(@"1023-TextError")
                                            message:error.localizedDescription
                                        buttonTitle:nil
                                  cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                         completion:nil];
            } else {
                
                // Contacts are inserted/updated (by service code) in database at this point
                DDLogSupport(@"Fax contacts updated successfully");
            }
        }];
    }
    __block __weak typeof(self) qeakSelf = self;
    dispatch_async_main(^{
        if (![SVProgressHUD isVisible])
            [NSObject cancelPreviousPerformRequestsWithTarget:qeakSelf selector:@selector(showProgressHUD) object:nil];
        else
            [SVProgressHUD dismiss];
    });
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self hideKeyBoard];
    
    [self removeKeyboardNotifications];
    
    self.searchText = nil;
    self.searchBar.text = @"";
    [self doSearchWithText:self.searchBar.text];
    [self.view endEditing:YES];
    
    isIPhoneX {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    dispatch_async_main(^{
        if ([SVProgressHUD isVisible]) {
            [SVProgressHUD dismiss];
        }
    });
    
    __weak __block typeof(self) welf = self;
    dispatch_async_background(^{
        
        [welf.searchOperationsQueue cancelAllOperations];
        [welf.searchOperationsQueue waitUntilAllOperationsAreFinished];
        
        [welf.refreshOperationQueue cancelAllOperations];
        [welf.refreshOperationQueue waitUntilAllOperationsAreFinished];
        
        [NSObject cancelPreviousPerformRequestsWithTarget:welf selector:@selector(showProgressHUD) object:nil];
        [welf performSelector:@selector(showProgressHUD) withObject:nil afterDelay:kValueDelayForShowingProgressHUD];
        
        [NSObject cancelPreviousPerformRequestsWithTarget:welf selector:@selector(reloadData) object:nil];
        [welf performSelector:@selector(reloadData) withObject:nil afterDelay:.3];
        
        DDLogSupport(@"Conversation Refresh Called from didReceiveMemoryWarning");
    });
}

- (void)reloadData {
    
    __weak __block typeof(self) welf = self;
    [self.refreshOperationQueue addOperationWithBlock:^{
        
        [welf.contacts removeAllObjects];
        [welf.searchArray removeAllObjects];
        
        //load contacts
        [welf loadContacts];
        //load groups
        QliqContactsProvider *contactProvider = [[QliqContactsProvider alloc] init];
        welf.groups = [NSMutableArray arrayWithArray:[contactProvider getUserGroups]];
        
        if (welf.typeController == STForNewConversation) {
            
            NSMutableIndexSet *hideContacts = [NSMutableIndexSet new];
            
            for (QliqGroup *group in welf.groups) {
                
                if ([group hasPagerUsers]) {
                    NSUInteger index = [welf.groups indexOfObject:group];
                    [hideContacts addIndex:index];
                }
            }
            [welf.groups removeObjectsAtIndexes:hideContacts];
        }
        
        welf.isNotFirstAppearance = NO;
        [welf doSearchWithText:welf.searchBar.text];
        welf.isNotFirstAppearance = YES;
    }];
}

#pragma mark - Managing Notifications

- (void)onPresenceChangeNotification:(NSNotification *)notification
{
    @synchronized(self)
    {
        if ([notification.userInfo[@"isForMyself"] boolValue] == NO)
        {
            __block __weak typeof(self) weakSelf = self;
            [self.refreshOperationQueue addOperationWithBlock:^{
                __strong typeof(self) strongSelf = weakSelf;
                
                NSString *qliqId = notification.userInfo[@"qliqId"];
                for (NSUInteger index = 0; index < strongSelf.contacts.count; index++)
                {
                    if (strongSelf.contacts.count == 0)
                        break;
                    
                    id contactType = [strongSelf.contacts objectAtIndex:index];
                    if ([contactType isKindOfClass:[Contact class]] || [contactType isKindOfClass:[QliqUser class]])
                    {
                        Contact *contact = contactType;
                        if ([contact.qliqId isEqualToString:qliqId])
                        {
                            id item = [[QliqAvatar sharedInstance] contactIsQliqUser:contact];
                            if ([item isKindOfClass:[QliqUser class]])
                            {
                                QliqUser *user = item;
                                user.presenceStatus = [notification.userInfo[@"presenceStatus"] integerValue];
                                [strongSelf.contacts replaceObjectAtIndex:index withObject:user];
                                break;
                            }
                        }
                    }
                }
                
                if (strongSelf.isSearching)
                {
                    for (NSUInteger index = 0; index < strongSelf.searchArray.count; index++)
                    {
                        if (strongSelf.searchArray.count == 0)
                            break;
                        
                        id contactType = [strongSelf.searchArray objectAtIndex:index];
                        if ([contactType isKindOfClass:[Contact class]] || [contactType isKindOfClass:[QliqUser class]])
                        {
                            Contact *contact = contactType;
                            if ([contact.qliqId isEqualToString:qliqId])
                            {
                                id item = [[QliqAvatar sharedInstance] contactIsQliqUser:contact];
                                if ([item isKindOfClass:[QliqUser class]])
                                {
                                    QliqUser *user = item;
                                    user.presenceStatus = [notification.userInfo[@"presenceStatus"] integerValue];
                                    [strongSelf.searchArray replaceObjectAtIndex:index withObject:user];
                                    break;
                                }
                            }
                        }
                    }
                }
                
                dispatch_async_main(^{
                    [strongSelf.tableView reloadData];
                });
            }];
        }
    }
}

- (void)addKeyboardNotifications
{
    DDLogSupport(@"Adding Keyboard Notifications");
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeShown:)
                                                 name:UIKeyboardWillShowNotification object:nil];
}

- (void)removeKeyboardNotifications
{
    DDLogSupport(@"Removing Keyboard Notifications");
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
 
    self.needToAddKeyboardNotifications = YES;
}

#pragma mark - Keyboard

- (void)keyboardWillBeShown:(NSNotification *)notification
{
    if (self.typeController != STForQliqSign)
    {
        UIViewAnimationCurve curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
        UIViewAnimationOptions options = (curve << 16) | UIViewAnimationOptionBeginFromCurrentState;
        NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        
        CGSize keyboardSize = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
        
        __weak __block typeof(self) weakSelf = self;
        [UIView animateWithDuration:duration delay:0.0 options:options animations:^{
            weakSelf.bottomTableViewConstraint.constant = keyboardSize.height;
            [weakSelf.view layoutSubviews];
        } completion:nil];
    }
    
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    if (self.typeController != STForQliqSign)
    {
        UIViewAnimationCurve curve = [aNotification.userInfo[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
        UIViewAnimationOptions options = (curve << 16) | UIViewAnimationOptionBeginFromCurrentState;
        NSTimeInterval duration = [aNotification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        
        
        __weak __block typeof(self) weakSelf = self;
        [UIView animateWithDuration:duration delay:0.0 options:options animations:^{
            weakSelf.bottomTableViewConstraint.constant = 0.f;
            [weakSelf.view layoutSubviews];
        } completion:nil];
        
        self.searchBarWasFirstResponder = [self.searchBar isFirstResponder];
    }
}

#pragma mark - Private Methods

- (void)hideKeyBoard
{
    if ([self.searchBar isFirstResponder]) {
        [self.searchBar resignFirstResponder];
    }
}

- (void)editContactList
{
    if (self.list)
    {
        NSArray *oldParticipants = [[QliqListService sharedService] getUsersOfList:self.list];
        
        for (Contact *participant in oldParticipants) {
            if (![self.participants containsObject:participant]) {
                [[QliqListService sharedService] removeUserWithContactId:((Contact *)participant).contactId fromList:self.list];
            }
        }
     
        for (Contact *participant in self.participants) {
            if (![oldParticipants containsObject:participant]) {
                [[QliqListService sharedService] addUserWithContactId:((Contact *)participant).contactId toList:self.list];
            }
        }
    }
}

- (void)editFavorites {
    if (self.startParticipants.count != 0) {
        for (Contact *participant in self.startParticipants) {
            if (![self.participants containsObject:participant]) {
                [self.favoritesContactGroup removeContact:participant];
            }
        }
        
        for (Contact *participant in self.participants) {
            if (![self.startParticipants containsObject:participant]) {
                [self.favoritesContactGroup addContact:participant];
            }
        }
    } else {
        
        for (Contact *participant in self.participants) {
            [self.favoritesContactGroup addContact:participant];
        }
    }
}

- (void)rotated:(NSNotification*)notification {
    
    __weak __block typeof(self) weakSelf = self;
    dispatch_async_main(^{
        
        if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)) {
            
            weakSelf.searchViewTopConstraint.constant = searchViewTopConstraintLandscape;
        }  else {
            
            weakSelf.searchViewTopConstraint.constant  = searchViewTopConstraintPortrait;
        }
    });
}

#pragma mark - Reloading Controller

- (void) loadContacts
{
    id <ContactGroup> targetContactsGrop = nil;
    
    switch (self.typeController) {
        case STForInviting: {
            
            targetContactsGrop = [[QliqAddressBookContactGroup alloc] init];
            break;
        }
        case STForFavorites: {
            
            targetContactsGrop = [[QliqContactsGroup alloc] init];
            break;
        }
        case STForPersonalGroup: {
            
            QliqContactsProvider *qliqContactsProvider = [QliqModelServiceFactory contactsProviderForObject:self];
            targetContactsGrop = (NSObject<ContactGroup>*)[qliqContactsProvider getOnlyQliqUsersGroup];
            
            
            self.participants = [NSMutableArray arrayWithArray:[self.list getOnlyContacts]];
            
            break;
        }
        case STForConversationEditParticipants:
        case STForNewConversation: {
            
            targetContactsGrop = [[QliqContactsGroup alloc] init];
            break;
        }
            case STForQliqSign:
        case STForCareChannelEditPaticipants:
        case STForForwarding: {
            
            targetContactsGrop = [[QliqContactsGroup alloc] init];
            
            break;
        }
        default:
            break;
    }
    
    //Set Content data
    if ([targetContactsGrop respondsToSelector:@selector(getOnlyContacts)])
        self.contacts = [[targetContactsGrop getOnlyContacts] mutableCopy];
    else
        self.contacts = [[targetContactsGrop getContacts] mutableCopy];
    
    if(self.typeController == STForCareChannelEditPaticipants || self.typeController == STForConversationEditParticipants) {
        NSMutableIndexSet *hideContacts = [NSMutableIndexSet new];
        for (id recipient in self.participants) {
            if ([recipient isKindOfClass:[QliqUser class]]) {
                if ([self.contacts containsObject:((QliqUser *)recipient).contact]) {
                    NSUInteger index = [self.contacts indexOfObject:((QliqUser *)recipient).contact];
                    [hideContacts addIndex:index];
                }   
            }
        }
        
        [self.contacts removeObjectsAtIndexes:hideContacts];
    }
}

- (void)sortContentForTableView:(NSMutableArray*)contactsArray withFilteredString:(NSString *)filteredString
{
    NSArray *contacts   = [contactsArray copy];
    NSArray *groups     = [self.groups copy];
    
    if (contacts.count > 0)
    {
        __block NSMutableArray *prepareSortedArray = [NSMutableArray new];
        __block NSString *sectionIndexTitle = @"";
        __block NSInteger firstIndexOfCurrentSection = 0;
        __block NSInteger firstIndexOfNextSection = 0;
        
        //copy array to section array
        void (^sortingBlock)(void) = ^{
            NSMutableArray *recipientsInSection = [NSMutableArray new];
            
            if (firstIndexOfCurrentSection <= firstIndexOfNextSection) {
                
                NSUInteger count = firstIndexOfNextSection - firstIndexOfCurrentSection;
                NSRange range = NSMakeRange(firstIndexOfCurrentSection, count);
                
                if (count == 0) {
                    recipientsInSection = [NSMutableArray arrayWithObject:[contacts objectAtIndex:firstIndexOfNextSection]];
                } else {
                    recipientsInSection = [NSMutableArray arrayWithArray:[contacts subarrayWithRange:range]];
                }
            } else {
                DDLogError(@"\n\n\n\nERROR firstSectionIndex > lastSectionIndex\n\n\n\n");
            }
            
            NSMutableDictionary *section = [@{kKeySectionTitle : sectionIndexTitle,
                                              kKeyRecipients : recipientsInSection} mutableCopy];
            [prepareSortedArray addObject:section];
        };
        
        __block NSString *sectionIndexTitleForObject = @"?";
        [contacts enumerateObjectsUsingBlock:^(Contact *contact, NSUInteger idx, BOOL *stop) {
            
            if (!filteredString)
            {
                NSString *title = nil;
                if (contact.lastName) {
                    title = contact.lastName;
                }
                else if (contact.firstName) {
                    title = contact.firstName;
                }
                
                NSInteger nessesaryLength = 1;
                if (title.length >= nessesaryLength) {
                    sectionIndexTitleForObject = [[title substringToIndex:nessesaryLength] uppercaseString];
                }
            } else {
                
                if ([contact.firstName rangeOfString:filteredString options:NSCaseInsensitiveSearch].location == 0 &&
                    [contact.lastName rangeOfString:filteredString options:NSCaseInsensitiveSearch].location == 0)
                {
                    sectionIndexTitleForObject = @"0";
                }
                else if ([contact.firstName rangeOfString:filteredString options:NSCaseInsensitiveSearch].location == 0)
                {
                    sectionIndexTitleForObject = @"2";
                }
                else if ([contact.lastName rangeOfString:filteredString options:NSCaseInsensitiveSearch].location == 0)
                {
                    sectionIndexTitleForObject = @"1";
                }
                else
                {
                    sectionIndexTitleForObject = @"3";
                }
            }
            
            //        Add contact to Sorted content
            if (![sectionIndexTitleForObject isEqualToString:sectionIndexTitle]) {
                if (idx != 0) {
                    firstIndexOfNextSection = idx;
                    
                    sortingBlock();
                    
                    //reseting of next section range
                    firstIndexOfCurrentSection = idx ;
                    sectionIndexTitle = sectionIndexTitleForObject;
                } else {
                    firstIndexOfCurrentSection = idx;
                    sectionIndexTitle = sectionIndexTitleForObject;
                }
            }
            
            if ((contacts.count - 1) == idx) {
                firstIndexOfNextSection = contacts.count;
                sortingBlock();
            }
            
            
        }];
        
        if (filteredString) {
            NSSortDescriptor *sortDeskriptorBySecurityTitle = [NSSortDescriptor sortDescriptorWithKey:kKeySectionTitle ascending:YES];
            prepareSortedArray = [[prepareSortedArray sortedArrayUsingDescriptors:@[sortDeskriptorBySecurityTitle]] mutableCopy];
        }
        
        //Add 'Selected' section to data source array
        if (!filteredString && ((self.participants.count && self.typeController != STForInviting && self.typeController != STForCareChannelEditPaticipants && self.typeController != STForConversationEditParticipants) || ((self.typeController == STForCareChannelEditPaticipants || self.typeController == STForConversationEditParticipants) && self.selectedParticipants.count)))
        {
            NSArray *selectedParticipants = (self.typeController != STForCareChannelEditPaticipants && self.typeController != STForConversationEditParticipants) ? [self.participants mutableCopy] : [self.selectedParticipants mutableCopy];
            
            self.participants = [NSMutableArray arrayWithArray:[selectedParticipants sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"lastName" ascending:YES selector:@selector(caseInsensitiveCompare:)],
                                                                                                                [NSSortDescriptor sortDescriptorWithKey:@"firstName" ascending:YES selector:@selector(caseInsensitiveCompare:)]]]];
            
            NSMutableDictionary *section = [@{kKeySectionTitle : @"Selected",
                                              kKeyRecipients : selectedParticipants} mutableCopy];
            [prepareSortedArray insertObject:section atIndex:0];
        }
        
        //Add Groups
        {
            if (self.typeController == STForNewConversation || self.typeController == STForConversationEditParticipants)
            {
                if (!filteredString)
                {
                    if (groups.count)
                    {
                        NSMutableDictionary *section = [@{kKeySectionTitle : @"Groups",
                                                          kKeyRecipients : [groups mutableCopy]} mutableCopy];
                        [prepareSortedArray addObject:section];
                    }
                }
                else
                {
                    __block NSMutableDictionary *section = nil;
                    section = prepareSortedArray.lastObject;
                    
                    [groups enumerateObjectsUsingBlock:^(QliqGroup *group, NSUInteger idx, BOOL *stop) {
                        
                        NSString *name = group.acronym ? group.acronym : ( group.name ? group.name : @"");
                        
                        
                        if ([name rangeOfString:filteredString options:NSCaseInsensitiveSearch].location == 0)
                        {
                            
                            if ([section[kKeySectionTitle] isEqualToString:@"Groups"])
                            {
                                NSMutableArray *itemContents = section[kKeyRecipients];
                                [itemContents addObject:group];
                            }
                            else
                            {
                                section = [@{kKeySectionTitle : @"Groups",
                                             kKeyRecipients : [@[group] mutableCopy]} mutableCopy];
                                [prepareSortedArray addObject:section];
                            }
                        }
                    }];
                }
            }
        }
        
        self.dataSourceArray = nil;
        self.dataSourceArray = prepareSortedArray;
        
    } else {
        self.dataSourceArray = nil;
    }
}

#pragma mark - Search

- (void)doSearchWithText:(NSString *)searchText
{
    if (self.faxSearch) {
        
        self.faxContactArray = [FaxContactDBService searchByFilter:searchText limit:nil skip:nil];
        
        self.faxContactArray = [NSMutableArray arrayWithArray:[self.faxContactArray sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"organization" ascending:YES selector:@selector(caseInsensitiveCompare:)],
                                                                                                                  [NSSortDescriptor sortDescriptorWithKey:@"contactName" ascending:YES selector:@selector(caseInsensitiveCompare:)]]]];
        
        __block __weak typeof(self) weakSelf = self;
        dispatch_async_main(^{
            if (![SVProgressHUD isVisible])
                [NSObject cancelPreviousPerformRequestsWithTarget:weakSelf selector:@selector(showProgressHUD) object:nil];
            else
                [SVProgressHUD dismiss];
            [weakSelf.tableView reloadData];
        });
    } else {
        __weak __block typeof(self) weakSelf = self;
        dispatch_async_main(^{
            if (![SVProgressHUD isVisible] && weakSelf.isNotFirstAppearance) {
                [weakSelf performSelector:@selector(showProgressHUD) withObject:nil afterDelay:kValueDelayForShowingProgressHUD];
            }
        });
        
        [self.searchOperationsQueue cancelAllOperations];
        
        if ([searchText containsString:@" "]) {
            NSRange range;
            range.location = 0;
            range.length = 1;
            NSString *firstWordSpace = [searchText substringWithRange:range];
            if ([firstWordSpace isEqualToString:@" "]) {
                firstWordSpace = [firstWordSpace stringByReplacingOccurrencesOfString:@" " withString:@""];
                searchText = [firstWordSpace stringByAppendingString: [searchText substringWithRange:NSMakeRange(range.length, searchText.length - 1)]];
            }
        }
        
        NSArray *tempSearchArray = [NSArray new];
        if (self.searchText.length < searchText.length && searchText.length != 1 && self.searchOperationDone) {
            tempSearchArray = [self.searchArray copy];
        } else {
            tempSearchArray = [self.contacts copy];
        }
        
        self.searchOperationDone = NO;
        self.searchText = searchText;
        
        [self.searchArray removeAllObjects];
        
        SearchOperation *searchContactsOperation = [[SearchOperation alloc] initWithArray:tempSearchArray andSearchString:searchText withPrioritizedAlphabetically:NO];
        searchContactsOperation.delegate = self;
        searchContactsOperation.batchSize = 0;
        
        self.isSearching = searchContactsOperation.isPredicateCorrect;
        
        if (!self.isSearching)
        {
            self.searchOperationDone = YES;
            
            [self.searchArray removeAllObjects];
            
            __weak __block typeof(self) weakSelf = self;
            dispatch_async_main(^{
                if (![SVProgressHUD isVisible])
                    [NSObject cancelPreviousPerformRequestsWithTarget:weakSelf selector:@selector(showProgressHUD) object:nil];
                else
                    [SVProgressHUD dismiss];
                
                [weakSelf.tableView reloadData];
            });
        } else {
            [self.searchOperationsQueue addOperation:searchContactsOperation];
        }
    }
}

- (void)getContactsFromSearch:(NSArray*)results {
    
    [self.searchArray removeAllObjects];
    [self.searchArray addObjectsFromArray:[results copy]];
    self.searchOperationDone = YES;
    BOOL needToWaitResponceFromServer = NO;
    
    if (results.count == 0)
    {
        /*
         Searching if sychronization is not finished.
         Calls once with every filter(searchText) instance *see deeper by methods call stack*
         */
        __weak __block typeof(self) weakSelf = self;
        dispatch_async_main(^{
            BOOL needToWaitResponceFromServer = NO;
            needToWaitResponceFromServer = [SearchContactsService searchContactsIfNeeded:weakSelf.searchBar.text
                                                                                   count:30
                                                                              completion:^(CompletitionStatus status, id result, NSError *error) {
                                                                                  if (status == CompletitionStatusSuccess)
                                                                                  {
                                                                                      NSArray *users = (NSArray *)result;
                                                                                      if (users.count > 0)
                                                                                      {
                                                                                          dispatch_async_main(^{
                                                                                              if (![SVProgressHUD isVisible])
                                                                                                  [weakSelf performSelector:@selector(showProgressHUD) withObject:nil afterDelay:kValueDelayForShowingProgressHUD];
                                                                                          });
                                                                                          [weakSelf.refreshOperationQueue addOperationWithBlock: ^{
                                                                                              [weakSelf loadContacts];
                                                                                              [weakSelf doSearchWithText:weakSelf.searchText];
                                                                                          }];
                                                                                      }
                                                                                  } else {
                                                                                      dispatch_async_main(^{
                                                                                          if (![SVProgressHUD isVisible])
                                                                                              [NSObject cancelPreviousPerformRequestsWithTarget:weakSelf selector:@selector(showProgressHUD) object:nil];
                                                                                          else
                                                                                              [SVProgressHUD dismiss];
                                                                                      });
                                                                                  }
                                                                              }];
        });
    }
    
    __block __weak typeof(self) weakSelf = self;
    dispatch_async_main(^{
        if (!needToWaitResponceFromServer)
        {
            if (![SVProgressHUD isVisible])
                [NSObject cancelPreviousPerformRequestsWithTarget:weakSelf selector:@selector(showProgressHUD) object:nil];
            else
                [SVProgressHUD dismiss];
        }
        [weakSelf.tableView reloadData];
    });
}

#pragma mark - Utilities/Helpers -

- (void)inviteContact:(Contact*)contact withComlitionBlock:(VoidBlock)completionBlock {
    
    __weak __block typeof(self) weakSelf = self;
    [self.inviteController inviteContact:contact isAddressBookContact:YES completionBlock:^(Invitation *invitation, NSError *error) {
        dispatch_async_main(^{
            if (nil == error)
                [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"1905-TextInvited", nil)];
            else
                [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"1906-TextInvitationFailed", nil)];
            
            [weakSelf performSelector:@selector(hideProgressHUD) withObject:nil afterDelay:1.0f];
        });
        completionBlock();
    }];
}

- (void)showProgressHUD {
    
    if (!self.searchOperationDone) {
        
        dispatch_async_main(^{
            [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
        });
        
        [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidChangeStatusBarOrientationNotification object:nil userInfo:nil];
    }
}

- (void)hideProgressHUD {
    
    [SVProgressHUD dismiss];
}

#pragma mark - IBActions

- (IBAction)onBack:(id)sender {
    [self.searchBar resignFirstResponder];
    
    __block __weak typeof(self) weakSelf = self;
    
    switch (self.typeController) {
        case STForPersonalGroup: {
            
            NSArray *controllers = [weakSelf.navigationController viewControllers];
            for (NSInteger index = controllers.count - 1; index >= 0; index--)
            {
                UIViewController *vc = [controllers objectAtIndex:index];
                
                if ([vc isMemberOfClass:[DetailContactInfoViewController class]])
                {
                    [weakSelf.navigationController popToViewController:vc animated:YES];
                    break;
                }
                
                if ([vc isMemberOfClass:[MainViewController class]])
                {
                    [weakSelf.navigationController popToViewController:vc animated:YES];
                    break;
                }
            }
            
            break;
        }
        case STForNewConversation: {
            
            [self.participants removeAllObjects];
            [self.participants addObjectsFromArray:self.startParticipants];
            
            [self.navigationController popViewControllerAnimated:YES];
            
            break;
        }
        case STForQliqSign:
        {
            [self dismissViewControllerAnimated:YES completion:nil];
            break;
        }
        default: {
            [self.navigationController popViewControllerAnimated:YES];
            break;
        }
    }
}

- (IBAction)onNextButton:(id)sender {
    
    DDLogSupport(@"On Next button");
    
    switch (self.typeController)
    {
        case STForFavorites:
        {
            
            [self editFavorites];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ReloadFavoritesCollectionViewControllerNotification" object:nil];
            
            [self.navigationController popViewControllerAnimated:YES];
            
            break;
        }
        case STForPersonalGroup:
        {
            [self editContactList];
            
            NSArray *controllers = [self.navigationController viewControllers];
            for (NSInteger index = controllers.count - 1; index >= 0; index--)
            {
                UIViewController *vc = [controllers objectAtIndex:index];
                
                if ([vc isMemberOfClass:[DetailContactInfoViewController class]])
                {
                    [self.navigationController popToViewController:vc animated:YES];
                    break;
                }
                
                if ([vc isMemberOfClass:[MainViewController class]])
                {
                    [self.navigationController popToViewController:vc animated:YES];
                    break;
                }
            }
            
            break;
        }
        case STForNewConversation:
        {
            if (self.delegate && [self.delegate respondsToSelector:@selector(didSelectedParticipants:)]) {
                [self.delegate didSelectedParticipants:self.participants];
            }
            
            [self.navigationController popViewControllerAnimated:YES];
            break;
        }
        case STForInviting:
        {
            break;
        }
        default: {
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(didSelectedParticipants:)]) {
                [self.delegate didSelectedParticipants:self.participants];
            }
            
            [self.navigationController popViewControllerAnimated:YES];
            break;
        }
    }
}

- (void)onCancelButton:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onDoneButton:(id)sender {
    
    __weak __block typeof(self) welf = self;
    [welf.presentingViewController dismissViewControllerAnimated:YES completion:^{
        self.selectParticipantsCallBack(self.participants, welf);
    }];
}

- (IBAction)onAddFaxRecipient:(id)sender {
    
    DDLogSupport(@"On add fax recipient button");
    
    CreateFaxContactViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([CreateFaxContactViewController class])];
    controller.delegate = self;
    
    [self.navigationController pushViewController:controller animated:YES];
    
}

#pragma mark - Delegates -

- (void)onPhoneButton:(NSString *)calleePhoneNumber
{
    CallAlertService *callAlertService = [self getCallAlertService];
    [callAlertService phoneNumberWasSelectedForAction:calleePhoneNumber];
}

#pragma mark - TableViewDataSource/Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger *count = 0;
    if (self.faxSearch) {
        count = 1;
    } else {
    
        if (self.isSearching)
            [self sortContentForTableView:self.searchArray withFilteredString:self.firstFilterCharacter];
        else
            [self sortContentForTableView:self.contacts withFilteredString:nil];
        
        count = self.dataSourceArray.count;
    }
    
    return count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat height = 0;
    
    if (!self.faxSearch) {
        NSString *string = @"";
        NSDictionary *info = self.dataSourceArray[section];
        string = info[kKeySectionTitle];
        
        if (self.typeController != STForQliqSign ? [self.searchBar.text isEqualToString:@""] : [self.searchBarController.text isEqualToString:@""]  || [string isEqualToString:@"Groups"])
            height = 30.f;
    }
    
    return height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{

    if (self.faxSearch) {
        return 67.f;
    }
    return 35.f;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell respondsToSelector:@selector(setSeparatorInset:)])
        [cell setSeparatorInset:UIEdgeInsetsZero];
    
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)])
        [cell setPreservesSuperviewLayoutMargins:NO];
    
    if ([cell respondsToSelector:@selector(setLayoutMargins:)])
        [cell setLayoutMargins:UIEdgeInsetsZero];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *tittle = @"";
    
    NSDictionary *info = self.dataSourceArray[section];
    
    if (!self.isSearching)
        tittle = info[kKeySectionTitle];;
    
    return tittle;
}

- (NSArray*)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    NSMutableArray *indexes = [NSMutableArray new];
    
    if (!self.isSearching)
    {
        for (NSDictionary *info in self.dataSourceArray)
        {
            NSString *tittle = [info objectForKey:kKeySectionTitle];
            if ([tittle isEqualToString:@"Groups"])
                tittle = @"Gr";
            else if ([tittle isEqualToString:@"Selected"])
                tittle = @"√";
            
            [indexes addObject:tittle];
        }
    }
    return indexes;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return  index;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    if (self.faxSearch) {

        count = self.faxContactArray.count;
    } else {
        
        NSDictionary *info = self.dataSourceArray[section];
        NSArray *items = info[kKeyRecipients];
        count = items.count;
    }
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.faxSearch) {
        
        static NSString *cellIdentifier = @"SELECT_FAX_CONTACT_CELL";
        SelectFaxContactTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        QliqAvatar* avatar = [QliqAvatar new];
        for (int i=0; i<self.faxContactArray.count; i++) {
            
            FaxContact *faxContact = [self.faxContactArray objectAtIndex:indexPath.row];
            
            cell.contactIcon.hidden  = [faxContact.contactName isEqualToString:@""] ? YES : NO;
            cell.onCallButton.hidden = [faxContact.voiceNumber isEqualToString:@""] ? YES : NO;
            
            cell.nameContactLabel.text = faxContact.contactName;
            cell.organizationLabel.text = ([faxContact.organization isEqualToString:@""]) ? @" " :faxContact.organization;
            cell.faxLabel.text = faxContact.faxNumber;
            cell.phoneNumberLabel.text = faxContact.voiceNumber;
            
            cell.delegate = self;
            cell.avatarImage.image = ([faxContact.organization isEqualToString:@""]) ? [avatar makeAvatarWithLetter:@"?"] : [avatar getDefaultAvatarFromFirstLetters:@[[[faxContact.organization substringToIndex:1] uppercaseString]]];
            
            [self.participants containsObject:faxContact] ? [cell setCheckedBox:YES] : [cell setCheckedBox:NO];

            return cell;
        }
        return nil;
    } else {
        
        static NSString *cellIdentifier = @"SELECT_PARTICIPANTS_CELL_ID";
        SelectParticipantsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        NSArray *items = [((NSDictionary*)self.dataSourceArray[indexPath.section]) valueForKey:kKeyRecipients];
        id participant = items[indexPath.row];
        
        BOOL setCheck = NO;
        
        setCheck = self.participants.count && [self.participants containsObject:participant];
        
        participant = [[QliqAvatar sharedInstance] contactIsQliqUser:participant];
        [cell setData:participant];
        
        [self.participants containsObject:participant] ? [cell setCheckedBox:YES] : [cell setCheckedBox:NO];
        
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    __block __weak typeof(self) weakSelf = self;
    
    [self hideKeyBoard];
    
    if (self.faxSearch) {
        
        FaxContact *faxContact = [self.faxContactArray objectAtIndex:indexPath.row];
        
        if ([self.participants containsObject:faxContact]) {
            
           [self.participants removeObject:faxContact];
        } else {
            
            [self.participants removeAllObjects];
            [self.participants addObject:faxContact];
        }
        
        [self.tableView reloadData];
  
    } else {
        
        if (self.dataSourceArray.count <= indexPath.section)
            return;
        
        NSDictionary *sectionContent = self.dataSourceArray[indexPath.section];
        NSArray *items = sectionContent[kKeyRecipients];
        
        if (items.count <= indexPath.row)
            return;
        
        __block id participant = items[indexPath.row];
        
        {
            id originalParticipant = participant;
            participant = [[QliqAvatar sharedInstance] contactIsQliqUser:participant];
            
            if ([self.participants containsObject:originalParticipant])
            {
                [self.participants removeObject:originalParticipant];
                [self.participants addObject:participant];
            }
        }
        
        __block BOOL shouldAddItem = ![self.participants containsObject:participant];
        
        switch (self.typeController) {
            case STForCareChannelEditPaticipants:
            case STForConversationEditParticipants:{
//                participant = items[indexPath.row];
//                participant = [self.participants objectAtIndex:indexPath.row];

                if ([self.selectedParticipants containsObject:participant]) {

                    [self.selectedParticipants removeObject:participant];
                } else {
                    [self.selectedParticipants addObject:participant];
                }

                [self.tableView reloadData];
                break;
            }
            case STForQliqSign:
            case STForForwarding: {
                
                if (self.delegate && [self.delegate respondsToSelector:@selector(didSelectRecipient:)]) {
                    [self.delegate didSelectRecipient:participant];
                }
                
                if (self.selectParticipantsCallBack)
                {
                    if (shouldAddItem) {
                        [self.participants addObject:participant];
                    }
                    else {
                        [self.participants removeObject:participant];
                    }
                    
                    if (self.participants.count > 0 || self.toolbarView.hidden) {
                        self.toolbarView.hidden = NO;
                        self.heightToolbarViewConstraint.constant = 44.f;
                    }
                    else {
                        self.toolbarView.hidden = YES;
                        self.heightToolbarViewConstraint.constant = 0.f;
                    }
                    
                    [self.tableView reloadData];
                    return;
                }
                
                if (self.navigationController.presentingViewController && [[self.navigationController viewControllers].firstObject isEqual:self]) {
                    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
                } else {
                    [self.navigationController popViewControllerAnimated:YES];
                }
                [self.tableView reloadData];
                return;
                break;
            }
            case STForFavorites:
            case STForNewConversation:
            case STForInviting:
            case STForPersonalGroup:
            default:
                break;
        }
        
        
        if ([participant isKindOfClass:[Contact class]] || [participant isKindOfClass:[QliqUser class]])
        {
            if (self.participants.count > 0) {
                if ([self.participants.firstObject isKindOfClass:[QliqGroup class]] || self.typeController == STForInviting) {
                    [self.participants removeAllObjects];
                }
            }

            if (shouldAddItem) {
                [[[Presence alloc] init] setShouldAsk:YES];

                if ([Presence shouldAskForwardingIfNeededForRecipient:participant] && self.typeController == STForNewConversation) {

                    [Presence askForwardingIfNeededForRecipient:participant completeBlock:^(id<Recipient> selectedRecipient) {
                        [self showProgressHUD];

                        for (QliqUser *user in weakSelf.participants)
                        {
                            if ([user.qliqId isEqualToString:((QliqUser *)selectedRecipient).qliqId]) {
                                [weakSelf.participants removeObject:user];
                            }
                        }
                        
                        [self.participants addObject:selectedRecipient];

                        [SVProgressHUD dismiss];

                        [weakSelf.tableView reloadData];
                    }];
                }
                else {
                    [self.participants addObject:participant];
                }
            }
            else {
                [self.participants removeObject:participant];
            }
        }
        else
        {
            //        NSMutableArray *array = [self.participants copy];
            if (![self.participants containsObject:participant]) {
                [self.participants removeAllObjects];
                [self.participants addObject:participant];
            } else {
                [self.participants removeAllObjects];
            }
        }
        
        
        if (self.typeController == STForInviting) {
            
            [AlertController showActionSheetAlertWithTitle:QliqLocalizedString(@"1119-TextSendInvitationTo") message:nil withTitleButtons:@[[participant nameDescription]] cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel") completion:^(NSUInteger buttonIndex) {
                
                __weak typeof(weakSelf) strongSelf = weakSelf;
                if (buttonIndex != @[[participant nameDescription]].count) {
                    [weakSelf.participants enumerateObjectsUsingBlock:^(Contact *contact, NSUInteger idx, BOOL *stop) {
                        [strongSelf inviteContact:contact withComlitionBlock:^{
                            [strongSelf.navigationController popViewControllerAnimated:YES];
                        }];
                    }];
                } else {
                    [weakSelf.participants removeAllObjects];
                    dispatch_async_main(^{
                        [weakSelf.tableView reloadData];
                    });
                }
            }];
        }
        [self.tableView reloadData];
    }
}

- (void)didSelectedNewParticipant:(NSMutableArray *)participants {
    
    [self.delegate didSelectedParticipants:participants];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Getters -

- (CallAlertService *)getCallAlertService {
    
    if (!self.callAlertService) {
        self.callAlertService = [[CallAlertService alloc] initWithPresenterViewController:self.navigationController];
    }
    
    return self.callAlertService;
}

#pragma mark - UIScrollDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self hideKeyBoard];
}

#pragma mark * UISearchBarDelegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    self.firstFilterCharacter = searchText;
    __weak __block typeof(self) welf = self;
    [self.refreshOperationQueue addOperationWithBlock:^{
       [welf doSearchWithText:searchText];
    }];
}

#pragma mark * SearchContactsOperationDelegate

- (void)searchOperation:(SearchOperation *)operation didFoundResults:(NSArray *)array {
    __weak __block typeof(self) welf = self;
    [self.refreshOperationQueue addOperationWithBlock: ^{
        [welf getContactsFromSearch:array];
    }];
}

- (void)foundResultsPart:(NSArray *)results {
    __weak __block typeof(self) welf = self;
    [self.refreshOperationQueue addOperationWithBlock: ^{
        [welf getContactsFromSearch:results];
    }];
}

@end
