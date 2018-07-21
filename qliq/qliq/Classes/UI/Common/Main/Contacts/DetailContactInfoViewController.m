//
//  DetailContactInfoViewController.m
//  qliq
//
//  Created by Valerii Lider on 10/21/14.
//
//

#import "DetailContactInfoViewController.h"
#import "SetDeviceStatus.h"
#import "UIDevice-Hardware.h"
#import "AlertController.h"

/**
 Type
 */
#import "Invitation.h"
#import "Recipients.h"
#import "Conversation.h"
#import "CareChannel.h"
#import "ChatMessage.h"
#import "ContactList.h"
#import "QliqGroup.h"
#import "QliqSip.h"
#import "Helper.h"
#import "OnCallGroup.h"

/**
 Services
 */
#import "AvatarUploadService.h"
#import "InvitationService.h"
#import "ConversationDBService.h"
#import "ChatMessageService.h"
#import "QliqUserDBService.h"
#import "QliqGroupDBService.h"
#import "ContactDBService.h"
#import "QliqListService.h"
#import "QliqConnectModule.h"
#import "QliqFavoritesContactGroup.h"
#import "RecipientsDBService.h"
#import "GetContactInfoService.h"
#import "Multiparty.h"

/**
 Controllers
 */
#import "AddToListViewController.h"
#import "ConversationViewController.h"
#import "InviteContactsViewController.h"
#import "InviteController.h"
#import "ImageCaptureController.h"
#import "SelectContactsViewController.h"
#import "ConversationsListViewController.h"
#import "ProfileViewController.h"

/**
 Cell
 */
#import "DetailContactInfoCell.h"
#import "DetailNotesTableViewCell.h"
#import "RecentTableViewCell.h"
#import "ContactTableCell.h"

/**
 Sub View
 */
#import "ContactHeaderView.h"
#import "CallAlertService.h"

/**
 Defines
 */

#define kNotificationCreatedNewConversation @"CreatedNewConversation"

#define kContentProviderInformation     QliqLocalizedString(@"2332-TitleProviderDetails")
#define kContentMoreInformation         QliqLocalizedString(@"2333-TitleMoreInformation")
#define kContentAction                  QliqLocalizedString(@"2334-TitleAction")
#define kContentContact                 QliqLocalizedString(@"2335-TitleContacts")
#define kContentRecentConversation      QliqLocalizedString(@"2336-TitleRecentConversations")
#define kContentRecentCareChannels      QliqLocalizedString(@"2337-TitleRecentCareChannels")
#define kContentCareChannelVisitInfo    QliqLocalizedString(@"2338-TitleCareChannelVisitInfo")
#define kContentLocation                QliqLocalizedString(@"2339-TitleLocation")
#define kContentCareTeam                QliqLocalizedString(@"2340-TitleCareTeam")
#define kContentOnCallNotes             QliqLocalizedString(@"2354-TitleNotes")

//Patient Info
#define kKeyDateOfBirdth                QliqLocalizedString(@"3001-TitleDateOfBirdth")
#define kKeyRace                        QliqLocalizedString(@"3002-TitleRace")
#define kKeyDriversLicenceNumber        QliqLocalizedString(@"3003-TitleDriversLicenceNumber")
#define kKeyFhirId                      QliqLocalizedString(@"3004-TitleFhirID")
#define kKeyDateOfDeath                 QliqLocalizedString(@"3007-TitleDateOfDeath")
#define kKeyDeceased                    QliqLocalizedString(@"3008-TitleDeceased")
#define kKeyPhoneHome                   QliqLocalizedString(@"3009-TitlePhoneHome")
#define kKeyPhoneWork                   QliqLocalizedString(@"3010-TitlePhoneWork")
#define kKeyEmail                       QliqLocalizedString(@"3019-TitleEmail")
#define kKeyInsuarance                  QliqLocalizedString(@"3011-TitleInsurance")
#define kKeyAddress                     QliqLocalizedString(@"3012-TitleAddress")
#define kKeyPatientAccountNumber        QliqLocalizedString(@"3013-TitlePatientAccountNumber")
#define kKeySocialSecurityNumber        QliqLocalizedString(@"3014-TitleSocialSecurityNumber")
#define kKeyNationality                 QliqLocalizedString(@"3015-TitleNationality")
#define kKeyLanguage                    QliqLocalizedString(@"3016-TitleLanguage")
#define kKeyMaritalStatus               QliqLocalizedString(@"3017-TitleMaritalStatus")
#define kKeyStartCareChannel            QliqLocalizedString(@"3006-TitleStartCareChannel")
#define kKeyMasterPatientIndex          QliqLocalizedString(@"3020-TitleMasterPatientIndex")
#define kKeyMedicalRecordNumber         QliqLocalizedString(@"3021-TitleMedicalRecordNumber")

//Care Channel Info
#define kKeyAdmitDate                   QliqLocalizedString(@"2341-TitleAdmitDate")
#define kKeyLocationBuilding            QliqLocalizedString(@"2342-TitleBuilding")
#define kKeyLocationFloor               QliqLocalizedString(@"2343-TitleFloor")
#define kKeyLocationRoom                QliqLocalizedString(@"2344-TitleRoom")
#define kKeyLocationBed                 QliqLocalizedString(@"2345-TitleBed")
#define kKeyLocationFacility            QliqLocalizedString(@"2346-TitleFacility")

//On Call Member Notes

//Contact
#define kKeyMobile                      QliqLocalizedString(@"2153-TitleMobile")
#define kKeyPhone                       QliqLocalizedString(@"2154-TitlePhone")
#define kKeyQliqId                      @"qliq ID"
#define kKeyStartConversation           QliqLocalizedString(@"2155-TitleStartConversation")
#define kKeyTitle                       QliqLocalizedString(@"2156-TitleTitle")
#define kKeySpeciality                  QliqLocalizedString(@"2157-TitleSpeciality")
#define kKeyOnCallShedule               QliqLocalizedString(@"2160-TitleOnCallShedule")
#define kKeyTitleOrgGroups              QliqLocalizedString(@"2120-TitleOrgGroups")
#define kKeyPersonalGroup               QliqLocalizedString(@"2158-TitleMemberPersonalGroups")
#define kKeyInviteToQliq                QliqLocalizedString(@"2159-titleInviteToQliq")
#define kKeyStartBroadcastConversation  QliqLocalizedString(@"2170-TitleStartBroadcast")
#define kKeyStartGroupConversation      QliqLocalizedString(@"2171-TitleStartGroupConversation")
#define kKeyDelete                      QliqLocalizedString(@"1046-TextDelete")
#define kKeyRemind                      QliqLocalizedString(@"2174-TitleRemind")
#define kKeyCancel                      QliqLocalizedString(@"4-ButtonCancel")
#define kKeyAccept                      QliqLocalizedString(@"2175-TitleAccept")
#define kKeyDecline                     QliqLocalizedString(@"2176-TitleDecline")
#define kKeyEdit                        QliqLocalizedString(@"46-ButtonEdit")
#define kQliqUserRelatedRecent          @"QliqUserRelatedRecent"
#define kCreateAvatarTitle              @"24-ButtonCreateAvatar"
#define kRemoveAvatarTitle              @"23-ButtonRemoveAvatar"

#define kValueHeightForHeaderInSectionDefault   25.0f
#define kValueHeightRowDefault                  50.0f
#define kValueHeightRowDefaultInline            30.0f
#define kValueHeightRowAction                   44.0f
#define kValueHeightRowRecent                   74.0f
#define kValueHeightRowContact                  74.0f
#define kValueContactHeaderViewHeightConstraint 75.f
#define kValueSubjectHeaderViewHeightConstraint 81.f
#define kValueDelayForProgressHUDShowing        0.4f

#define kAvatarLeadingConstraintProtrait 15.f
#define kAvatarLeadingConstraintLandscape 50.f
#define kArrowViewTrailingCostraintPortrait 10.f
#define kArrowViewTrailingCostraintLandscape 50.f
#define kAddToFavoriteTrailingConstraintPortrait 5.f
#define kAddToFavoriteTrailingConstraintLandscape 45.f

#define kHeaderViewHeight 75.f

typedef NS_ENUM(NSInteger, ContentType) {
    ContentTypeProvider = 0,
    ContentTypeMore,
    ContentTypeAction,
    ContentTypeRecent,
    ContentTypeGroupUsers,
    ContentTypeOnCallNotes
};

@interface DetailContactInfoViewController ()
<
UITableViewDataSource,
UITableViewDelegate,
UISearchBarDelegate,
UIScrollViewDelegate,
UITextFieldDelegate,
ContactHeaderViewDelegate,
ImageCaptureControllerDelegate,
DetailContactInfoCellDelegate,
RecentCellDelegate,
SearchOperationDelegate,
ContactsCellDelegate,
SelectContactsViewControllerDelegate
>

//IBOutlet
@property (weak, nonatomic) IBOutlet ContactHeaderView *contactHeaderView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleViewNavigationBar;

@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@property (weak, nonatomic) IBOutlet UILabel *backButtonTitle;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *searchBarHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contactHeaderViewHeightConstraint;

@property (weak, nonatomic) IBOutlet UILabel *subjectTitle;
@property (weak, nonatomic) IBOutlet UITextField *subjectTextField;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *subjectHeaderViewHeightConstraint;
@property (weak, nonatomic) IBOutlet UIView *subjectHeaderView;
@property (weak, nonatomic) IBOutlet UILabel *chooseParticipants;
@property (weak, nonatomic) IBOutlet UIView *subjectTextFieldView;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;

/* Constraints for iPhoneX */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *avatarLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *addToFavoriteTrailingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *arrowTrailingConstraint;

//UI
@property (nonatomic, strong) ImageCaptureController *imageCaptureController;
@property (nonatomic, strong) InviteContactsViewController *inviteController;

@property (assign, nonatomic) CGFloat constantForChatButtonWidthConstraint;
@property (assign, nonatomic) CGFloat constantForChatButtonLeadingConstraint;

//Data
@property (nonatomic, strong) QliqFavoritesContactGroup *favoritesContactGroup;

@property (nonatomic, assign) BOOL isBlockScrollViewDelegate;
@property (nonatomic, assign) BOOL isSearching;

@property (nonatomic, strong) Conversation *selectedConversation;

@property (nonatomic, strong) NSMutableArray *content;
@property (nonatomic, strong) NSMutableArray *providerInformationKeyValuePairs;
@property (nonatomic, strong) NSMutableArray *moreInformationKeyValuePairs;
@property (nonatomic, strong) NSMutableArray *actions;
@property (nonatomic, strong) NSArray *conversations;
@property (nonatomic, strong) NSMutableArray *memberNotesKeyValuePairs;
@property (nonatomic, strong) NSMutableArray *searchGroupUsers;

//@property (nonatomic, retain) dispatch_queue_t refreshQueue;

@property (nonatomic, strong) NSOperationQueue *searchOperationsQueue;
@property (nonatomic, strong) NSOperationQueue *refreshOperationsQueue;

@property (assign, nonatomic) BOOL isConstraintsForChatButtonChecked;

@property (strong, nonatomic) CallAlertService *callAlertService;

@property (strong, nonatomic) NSMutableArray *groupUsers;
@property (strong, nonatomic) NSMutableArray *startGroupUsers;


@property (assign, nonatomic) BOOL isGroupConversation;
@property (assign, nonatomic) BOOL isContactPickerPushed;
@property (assign, nonatomic) BOOL isCurrentUserInParticipants;
@property (strong, nonatomic) NSMutableDictionary *roles;
@property (strong, nonatomic) NSDictionary *startRoles;
@property (strong, nonatomic) NSString *subject;

@property (nonatomic, strong) UITapGestureRecognizer *gestureRecognizerKeyboard;
@property (strong, nonatomic) NSIndexPath *indexPathForActiveCell;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewBottomConstraint;

@end

@implementation DetailContactInfoViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
        // As it is leaking about 1690 bytes per call.
        /*
        self.inviteController = [[InviteContactsViewController alloc] initForViewController:self];
        self.favoritesContactGroup = [[QliqFavoritesContactGroup alloc] init];
        
        //Image Capture
        {
            self.imageCaptureController = [[ImageCaptureController alloc] init];
            self.imageCaptureController.delegate = self;
        }
         */
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    /*Change constraint for iPhone X*/
    __block __weak typeof(self) weakSelf = self;
    dispatch_async_main(^{
        isIPhoneX {
            [[NSNotificationCenter defaultCenter]addObserver:weakSelf selector:@selector(rotated:) name:UIDeviceOrientationDidChangeNotification object:nil];
        }
    });

    if (self.contactType != DetailInfoContactTypeConversation &&
        self.contactType != DetailInfoContactTypeQliqGroup &&
        self.contactType != DetailInfoContactTypePersonalGroup &&
        self.contactType != DetailInfoContactTypeCareChannel &&
        self.contactType != DetailInfoContactTypeOnCallDayNotes &&
        self.contactType != DetailInfoContactTypeOnCallMemberNotes &&
        self.contactType != DetailInfoContactTypeInvitation &&
        self.contactType != DetailInfoContactTypeFhirPatient) {
        
        __weak __block typeof(self) welf = self;
        dispatch_async_background(^{
            [[GetContactInfoService sharedService] getInfoForContact:welf.contact withReason:@"Contact Details" conpletionBlock:^(QliqUser *contact, NSError *error) {
                
                if (error) {
                    DDLogSupport(@"Can't to update contact: %@, error code - %ld, error - %@", contact, (long)error.code, error.localizedDescription);
                    
                    if (error.code == ErrorCodeStaleData || error.code == ErrorCodeNotContact) {
                        DDLogSupport(@"User should been deleted from DB because error - %ld", (long)error.code);
                        
                        [AlertController showAlertWithTitle:QliqLocalizedString(@"1023-TextError")
                                                    message:QliqFormatLocalizedString1((@"10666-TextRecipientNoLongerContact"), [welf.contact displayName])
                                                buttonTitle:nil
                                          cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                                 completion:^(NSUInteger buttonIndex) {
                                                     [[ContactDBService sharedService] deleteContact:welf.contact];
                                                     [welf onBack:nil];
                                                 }];
                    }
                }
            }];
        });
    }
    
    self.inviteController = [[InviteContactsViewController alloc] initForViewController:self];
    self.favoritesContactGroup = [[QliqFavoritesContactGroup alloc] init];
    
    //Image Capture
    {
        self.imageCaptureController = [[ImageCaptureController alloc] init];
        self.imageCaptureController.delegate = self;
    }
    
    if (self.backButtonTitleString) {
        self.backButtonTitle.text = self.backButtonTitleString;
    }
    
    self.isContactPickerPushed = NO;
    
    //Set Navigation Bar
    {
        self.titleViewNavigationBar.numberOfLines = 1;
        self.titleViewNavigationBar.minimumScaleFactor = 10.f / self.titleViewNavigationBar.font.pointSize;
        self.titleViewNavigationBar.adjustsFontSizeToFitWidth = YES;
    }
    
    //Set Header
    {
        self.contactHeaderView.delegate = self;
        self.contactHeaderView.hidden = YES;
    }
    
    //Table
    {
        self.tableView.tableFooterView = [[ UIView alloc ] initWithFrame:CGRectZero];
        self.tableView.backgroundColor = [UIColor whiteColor];
        
        self.isConstraintsForChatButtonChecked = NO;
    }
    
    // SearchBar
    {
        [self showSearchBar:NO withAnimation:NO];
        self.searchBar.placeholder = QliqLocalizedString(@"2107-TitleSearch");
        self.searchBar.delegate = self;
        self.searchBar.autocorrectionType = UITextAutocorrectionTypeYes;
        self.searchBar.spellCheckingType = UITextSpellCheckingTypeYes;
        self.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.searchBar.keyboardType = UIKeyboardTypeAlphabet;
        self.isSearching = NO;
        [self changeFrameHeaderView];
    }
    
    //Init
    {
        //initializing BG Queues
        {
            self.searchOperationsQueue = [[NSOperationQueue alloc] init];
            self.searchOperationsQueue.maxConcurrentOperationCount = 1;
            self.searchOperationsQueue.name = @"com.qliq.detailContactInfoViewController.searchQueue";
            
            self.refreshOperationsQueue = [[NSOperationQueue alloc] init];
            self.refreshOperationsQueue.maxConcurrentOperationCount = 1;
            self.refreshOperationsQueue.name = @"com.qliq.detailContactInfoViewController.refreshQueue";
        }
        
        if (self.contactType != DetailInfoContactTypeOnCallMemberNotes && self.contactType != DetailInfoContactTypeOnCallDayNotes) {
            self.providerInformationKeyValuePairs   = [[ NSMutableArray alloc ] init];
            self.moreInformationKeyValuePairs       = [[ NSMutableArray alloc ] init];
            self.conversations                      = [[ NSMutableArray alloc ] init];
            self.actions                            = [[ NSMutableArray alloc ] init];
            self.groupUsers                         = [[ NSMutableArray alloc ] init];
            self.searchGroupUsers                   = [[ NSMutableArray alloc ] init];
        } else {
            self.memberNotesKeyValuePairs           = [[ NSMutableArray alloc ] init];
        }
        
        self.content = [[ NSMutableArray alloc ] init];
    }
    
    //Set Title
    {
        self.titleViewNavigationBar.text = @"";
    }
    //Prepare Information about User
    [self updateInformation];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //Set UI
    {
        if (self.navigationController.navigationBarHidden) {
            [self.navigationController setNavigationBarHidden:NO];
        }
    }
    
    //Notifications
    {
        [self addNotifications];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self removeKeyboardNotifications];
    
    //Set UI
    {
        [self.navigationController setNavigationBarHidden:YES];
    }
    
    //Invitation
    {
        if (self.contactType == DetailInfoContactTypeInvitation)
        {
            if (self.contact && ((Invitation*)self.contact).status == InvitationStatusAccepted)
                [self deleteInvitation:(Invitation*)self.contact shouldDeleteContactAlso:NO];
        }
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.refreshOperationsQueue cancelAllOperations];
    [self.refreshOperationsQueue waitUntilAllOperationsAreFinished];
    self.refreshOperationsQueue = nil;
    
    [self.searchOperationsQueue cancelAllOperations];
    [self.searchOperationsQueue waitUntilAllOperationsAreFinished];
    self.searchOperationsQueue = nil;
    
    if (self.gestureRecognizerKeyboard) {
        if ([self.view gestureRecognizers] > 0) {
            [self.view removeGestureRecognizer:self.gestureRecognizerKeyboard];
        }
        self.gestureRecognizerKeyboard = nil;
    }

    [self removeObservers];

    self.favoritesContactGroup              = nil;
    [self.providerInformationKeyValuePairs removeAllObjects];
    self.providerInformationKeyValuePairs   = nil;
    self.moreInformationKeyValuePairs       = nil;
    self.conversations                      = nil;
    self.actions                            = nil;
    self.groupUsers                         = nil;
    self.searchGroupUsers                   = nil;
    self.content                            = nil;
    self.roles                              = nil;
    self.startRoles                         = nil;
    self.startGroupUsers                    = nil;
    self.inviteController                   = nil;
    self.imageCaptureController             = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
     [self performSelector:@selector(showProgressHUD) withObject:nil afterDelay:kValueDelayForProgressHUDShowing];

    dispatch_async_background(^{
        [self.refreshOperationsQueue cancelAllOperations];
        [self.refreshOperationsQueue waitUntilAllOperationsAreFinished];
        [self.searchOperationsQueue cancelAllOperations];
        [self.searchOperationsQueue waitUntilAllOperationsAreFinished];


        DDLogSupport(@"Conversation Refresh Called from didReceiveMemoryWarning");
        __weak __block typeof(self) welf = self;
        [self.refreshOperationsQueue addOperationWithBlock:^{
            [welf prepareInformation];
        }];
    });
}

- (void) updateInformation {
    if (!self.isContactPickerPushed)
    {
        DDLogSupport(@"Refresh Called from viewWillAppear during initialization");
        __weak __block typeof(self) wellf = self;
        [self.refreshOperationsQueue addOperationWithBlock:^{
            [wellf prepareInformation];
        }];
    }
    else
    {
        self.isContactPickerPushed = NO;
    }
    
    if (self.contactType == DetailInfoContactTypeConversation || self.contactType == DetailInfoContactTypeCareChannel)
    {
        [self addKeyboardNotifications];
        self.indexPathForActiveCell = [NSIndexPath indexPathForRow:0 inSection:0];
    }
}
#pragma mark - Setters -

- (void)setContact:(id)contact {
    _contact = contact;
    [self checkContactType:contact];
}

#pragma mark - Getters -

- (CallAlertService *)getCallAlertService {
    
    if (!self.callAlertService) {
        self.callAlertService = [[CallAlertService alloc] initWithPresenterViewController:self.navigationController];
    }
    
    return self.callAlertService;
}

- (DetailInfoContactType)contactType {
    return _contactType;
}

#pragma mark - KVO -

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    
    if (([keyPath isEqualToString:@"groupUsers"] ||
         [keyPath isEqualToString:@"description"] ||
         [keyPath isEqualToString:@"subject"])
                            &&
        (self.contactType == DetailInfoContactTypeConversation ||
         self.contactType == DetailInfoContactTypeCareChannel))
    {
        
        NSString *startRolesDescription = self.startRoles.description;
        NSString *currentRolesDescription = self.roles.description;
        BOOL isEqualDescription = [startRolesDescription isEqualToString:currentRolesDescription];
        BOOL isEqualParticipants = self.startGroupUsers && [self.groupUsers isEqualToArray:self.startGroupUsers];
        BOOL isEqualSubject = [self.subject isEqualToString:((Conversation *)self.contact).subject];
        
        if ((self.roles && isEqualParticipants && isEqualDescription) || (!self.roles && isEqualParticipants && isEqualSubject)) {
            [self showDoneButton:NO];
        } else {
            [self showDoneButton:YES];
        }
    }
}

- (void)showDoneButton:(BOOL)show {
    if (self.doneButton.hidden == show) {
        self.doneButton.hidden = !show;
        self.titleViewNavigationBar.hidden = show;
    }
}

- (void)removeObservers {
    
    @try {
        [self removeObserver:self forKeyPath:@"groupUsers"];
    }
    @catch (NSException *exception) {}
    
    @try {
        [self.roles removeObserver:self forKeyPath:@"description"];
    }
    @catch (NSException *exception) {}
    
    @try {
        [self.subjectTextField removeObserver:self forKeyPath:@"subject"];
    }
    @catch (NSException *exception) {}
}

- (void)addObserver:(id)observer forKeyPath:(NSString *)keyPath {
    [self addObserver:observer forKeyPath:keyPath options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:nil];
}

- (void)addObserver:(id)observer toRolesForKeyPath:(NSString *)keyPath {
    [self.roles addObserver:observer forKeyPath:keyPath options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:nil];
}

// This methods need for KVO of groupUsers and searchGroupUsers array
//http://stackoverflow.com/questions/302365/observing-an-nsmutablearray-for-insertion-removal

#pragma mark *Group Users*

- (void) addObjectToGroupUsersArray:(NSObject *) newObject {
    [self insertObject:newObject inGroupUsersAtIndex:[self countOfGroupUsers]];
}

- (void)insertObject:(NSObject *)object inGroupUsersAtIndex:(NSUInteger)index {
    [self.groupUsers insertObject:object atIndex:index];
    
    [self.groupUsers sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"lastName" ascending:YES],
                                            [NSSortDescriptor sortDescriptorWithKey:@"firstName" ascending:YES]]];
    
    return;
}

- (void)insertGroupUsers:(NSArray *)array atIndexes:(NSIndexSet *)indexes {
    [self.groupUsers insertObjects:array atIndexes:indexes];
    return;
}

- (void)removeObjectFromGroupUsersArray:(NSObject *)object {
    if ([self.groupUsers containsObject:object]) {
        NSInteger index = [self.groupUsers indexOfObject:object];
        [self removeObjectFromGroupUsersAtIndex:index];
    }
}

- (void)removeObjectFromGroupUsersAtIndex:(NSUInteger)index {
    [self.groupUsers removeObjectAtIndex:index];
}

- (void)removeAllObjectsFromGroupUsersArray {
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self.groupUsers count])];
    [self removeGroupUsersAtIndexes:indexSet];
}

- (void)removeGroupUsersAtIndexes:(NSIndexSet *)indexes {
    [self.groupUsers removeObjectsAtIndexes:indexes];
}


- (void)replaceObjectInGroupUsersAtIndex:(NSUInteger)index withObject:(NSObject *)object {
    [self.groupUsers replaceObjectAtIndex:index withObject:object];
}

- (void)replaceGroupUsersAtIndexes:(NSIndexSet *)indexes withGroupUsers:(NSArray *)array {
    [self.groupUsers replaceObjectsAtIndexes:indexes withObjects:array];
}

- (NSUInteger)countOfGroupUsers {
    return [self.groupUsers count];
}

- (NSEnumerator *)enumeratorOfGroupUsers {
    return [self.groupUsers objectEnumerator];
}

#pragma mark **

#pragma mark *Search Group Users*

- (void) addObjectToSearchGroupUsersArray:(NSObject *) newObject {
    [self insertObject:newObject inSearchGroupUsersAtIndex:[self countOfSearchGroupUsers]];
}

- (void)insertObject:(NSObject *)object inSearchGroupUsersAtIndex:(NSUInteger)index {
    [self.searchGroupUsers insertObject:object atIndex:index];
    [self.searchGroupUsers sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"lastName" ascending:YES],
                                                  [NSSortDescriptor sortDescriptorWithKey:@"firstName" ascending:YES]]];
    return;
}

- (void)insertSearchGroupUsers:(NSArray *)array atIndexes:(NSIndexSet *)indexes {
    [self.searchGroupUsers insertObjects:array atIndexes:indexes];
    return;
}

- (void)removeObjectFromSearchGroupUsersArray:(NSObject *)object {
    if ([self.searchGroupUsers containsObject:object]) {
        NSInteger index = [self.searchGroupUsers indexOfObject:object];
        [self removeObjectFromGroupUsersAtIndex:index];
    }
}

- (void)removeObjectFromSearchGroupUsersAtIndex:(NSUInteger)index {
    [self.searchGroupUsers removeObjectAtIndex:index];
}

- (void)removeAllObjectsFromSearchGroupUsersArray {
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self.groupUsers count])];
    [self removeGroupUsersAtIndexes:indexSet];
}

- (void)removeSearchGroupUsersAtIndexes:(NSIndexSet *)indexes {
    [self.searchGroupUsers removeObjectsAtIndexes:indexes];
}


- (void)replaceObjectInSearchGroupUsersAtIndex:(NSUInteger)index withObject:(NSObject *)object {
    [self.searchGroupUsers replaceObjectAtIndex:index withObject:object];
}

- (void)replaceSearchGroupUsersAtIndexes:(NSIndexSet *)indexes withSearchGroupUsers:(NSArray *)array {
    [self.searchGroupUsers replaceObjectsAtIndexes:indexes withObjects:array];
}


- (NSUInteger)countOfSearchGroupUsers {
    return [self.searchGroupUsers count];
}

- (NSEnumerator *)enumeratorOfSearchGroupUsers {
    return [self.searchGroupUsers objectEnumerator];
}

#pragma mark - Private -

- (BOOL)isSelfUserRecipientShowAlert
{
    BOOL isRecipient = NO;
    
    if ([((Conversation *)self.contact).recipients isMultiparty]) {
        isRecipient = [((Conversation *)self.contact).recipients containsRecipient:[UserSessionService currentUserSession].user];
    } else {
        isRecipient = YES;
    }
    
    if (!isRecipient) {
        
        __block __weak typeof(self) welf = self;
        dispatch_async_main(^{
            NSString *message = nil;
            NSString *subject = ((Conversation *)self.contact).subject;
            if (subject == nil || [subject length] == 0) {
    
                message = QliqLocalizedString(@"10491-TextYouDeletedFromConversation");
            } else {
                message = QliqFormatLocalizedString1(@"1049-TextYouDeletedFromConversation{ConversationName}", subject);
            }
            
            [AlertController showAlertWithTitle:nil
                                        message:message
                                    buttonTitle:nil
                              cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                     completion:^(NSUInteger buttonIndex) {
                                         if (buttonIndex ==0) {
                                             [welf onBack:nil];
                                         }
                                     }];
        });
    }
    return isRecipient;
}

- (void)checkContactType:(id)contact {
    
    if ([self.contact isKindOfClass:[QliqUser class]])
    {
        self.contactType = DetailInfoContactTypeQliqUser;
    }
    else if ([self.contact isKindOfClass:[Contact class]])
    {
        self.contactType = DetailInfoContactTypeContact;
    }
    else if ([self.contact isKindOfClass:[QliqGroup class]])
    {
        self.contactType = DetailInfoContactTypeQliqGroup;
    }
    //PersoanlGroup
    else if ([self.contact isKindOfClass:[ContactList class]])
    {
        self.contactType = DetailInfoContactTypePersonalGroup;
    }
    else if ([self.contact isKindOfClass:[Invitation class]])
    {
        self.contactType = DetailInfoContactTypeInvitation;
    }
    else if ([self.contact isKindOfClass:[Conversation class]] )
    {
        if ([(Conversation *)self.contact isCareChannel])
        {
            self.contactType = DetailInfoContactTypeCareChannel;
        }
        else
        {
            self.contactType = DetailInfoContactTypeConversation;
        }
    }
    else if ([self.contact isKindOfClass:[FhirPatient class]])
    {
        self.contactType = DetailInfoContactTypeFhirPatient;
    }
    else if ([self.contact isKindOfClass:[OnCallMemberNotes class]])
    {
        self.contactType = DetailInfoContactTypeOnCallMemberNotes;
    }
    else if([self.contact isKindOfClass:[NSArray class]])
    {
        self.contactType = DetailInfoContactTypeOnCallDayNotes;
    }
}

- (void)eraseSelectedConversation {
    if (self.selectedConversation) {
        self.selectedConversation = nil;
        [self.tableView reloadData];
    }
}

- (void)cannotStartConversationType:(NSString *)conversationType {
    
    [AlertController showAlertWithTitle:QliqLocalizedString(@"1072-TextWarning")
                                message:QliqFormatLocalizedString1(@"2431-CannotStart{conversationType}conversation", conversationType)
                            buttonTitle:nil
                      cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel")
                             completion:nil];
}

#pragma mark * NavigationBar

- (void)prepareNavigationBar
{
    if (self.contactType == DetailInfoContactTypeQliqGroup) {
        QliqGroup *group = self.contact;
        //Set Title
        self.titleViewNavigationBar.text = self.isSearching ? group.name : QliqLocalizedString(@"2151-TitleGroupInfo");
    }
    else if (self.contactType == DetailInfoContactTypePersonalGroup)
    {
        ContactList *group = self.contact;
        //Set Title
        self.titleViewNavigationBar.text = self.isSearching ? group.name : QliqLocalizedString(@"2151-TitleGroupInfo");
    }
    else if (self.contactType == DetailInfoContactTypeFhirPatient)
    {
        self.titleViewNavigationBar.text = QliqLocalizedString(@"3005-TitlePatientInfo");
    }
    else if (self.contactType == DetailInfoContactTypeConversation || self.contactType == DetailInfoContactTypeCareChannel){
        
        self.doneButton.layer.cornerRadius = 3.f;
        [self.doneButton setTitle:QliqLocalizedString(@"2375-TitleUpdate") forState:UIControlStateNormal];
        [self.doneButton setTitle:QliqLocalizedString(@"2375-TitleUpdate") forState:UIControlStateHighlighted];
        
        if ([(Conversation *)self.contact isCareChannel]) {
            self.titleViewNavigationBar.text = QliqLocalizedString(@"2348-TitleCareChannelInfo");
        } else {
            self.titleViewNavigationBar.text = QliqLocalizedString(@"2186-TitleEditParticipants");
            
        }
    }
}

#pragma mark * ContactHeaderView

- (void)showMainHeaderView:(BOOL)show withAnimation:(BOOL)animated
{
    float constant = show ? kHeaderViewHeight : 0.f;
    
    if (constant != self.contactHeaderViewHeightConstraint.constant)
    {
        VoidBlock updateConstraints = ^{
            self.contactHeaderViewHeightConstraint.constant = constant;
            [self changeFrameHeaderView];
            [self.view layoutIfNeeded];
        };
        
        if (animated)
        {
            [UIView animateWithDuration:0.3 delay:0.0 options:nil animations:^{
                updateConstraints();
                
            } completion:nil];
        }
        else
        {
            updateConstraints();
        }
    }
}

#pragma mark * HeaderView

- (BOOL)headerViewIsShow
{
    BOOL isShow = NO;
    
    if (self.headerView.frame.size.height > 0)
        isShow = YES;
    
    return isShow;
}

- (void)setTableViewContentOffsetY:(CGFloat)offset withAnimation:(BOOL)animated
{
    VoidBlock updateConstraints = ^{
        self.tableView.contentOffset = CGPointMake(self.tableView.contentOffset.x, offset);
        [self.view layoutIfNeeded];
    };
    if (animated)
    {
        [UIView animateWithDuration:0.3 delay:0.0 options:nil animations:^{
            updateConstraints();
        } completion:nil];
    }
    else
    {
        updateConstraints();
    }
}

- (void)showSearchBar:(BOOL)show withAnimation:(BOOL)animated
{
    float constant = show ? 44.f : 0.f;
    
    if (constant != self.searchBarHeightConstraint.constant)
    {
         VoidBlock updateConstraints = ^{
            self.searchBarHeightConstraint.constant = constant;
            [self changeFrameHeaderView];
            [self.view layoutIfNeeded];
        };
        if (animated)
        {
            [UIView animateWithDuration:0.3 delay:0.0 options:nil animations:^{
                updateConstraints();
                
            } completion:nil];
        }
        else
        {
            updateConstraints();
        }
    }
}

- (void)changeFrameHeaderView
{
    CGRect frame = self.headerView.frame;
    frame.size.height = self.searchBarHeightConstraint.constant;
    self.headerView.frame = frame;
    [self.tableView setTableHeaderView:self.headerView];
}

- (void)setupSubjectHeaderView {
    
    self.chooseParticipants.text = QliqLocalizedString(@"2195-TitleChooseParticipants");
    self.subjectTitle.text = [NSString stringWithFormat:@"%@ :", QliqLocalizedString(@"2032-TitleSubject")];
    self.subjectTextField.text = self.subject;
    self.subjectTextField.delegate = self;
    
    self.subjectTextFieldView.layer.borderWidth = 1.f;
    self.subjectTextFieldView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    self.subjectTextFieldView.layer.cornerRadius = 10.f;
    
    self.subjectHeaderViewHeightConstraint.constant = kValueSubjectHeaderViewHeightConstraint;
    self.contactHeaderViewHeightConstraint.constant = kValueSubjectHeaderViewHeightConstraint;
    
    //    [self.view layoutIfNeeded];
    
    self.contactHeaderView.hidden = YES;
    self.subjectHeaderView.hidden = NO;
}

- (void)rotated:(NSNotification*)notification {
    
    __weak __block typeof(self) weakSelf = self;
    dispatch_async_main(^{
        if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)) {
            
            weakSelf.avatarLeadingConstraint.constant = kAvatarLeadingConstraintLandscape;
            weakSelf.addToFavoriteTrailingConstraint.constant = kAddToFavoriteTrailingConstraintLandscape;
            weakSelf.arrowTrailingConstraint.constant = kArrowViewTrailingCostraintLandscape;
        }  else {
            weakSelf.avatarLeadingConstraint.constant = kAvatarLeadingConstraintProtrait;
            weakSelf.addToFavoriteTrailingConstraint.constant = kAddToFavoriteTrailingConstraintPortrait;
            weakSelf.arrowTrailingConstraint.constant = kArrowViewTrailingCostraintPortrait;
        }
    });
}

#pragma mark - Notifications -

- (void)addNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleApplicationDidBecomeActiveNotification:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    // Register for group change notifications here
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(prepareInformation)
                                                 name:UserConfigDidRefreshedNotification
                                               object:nil];
    
    // Register for conversation change notifications here
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReadMessages:)
                                                 name:ConversationDidReadMessagesNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveMessage:)
                                                 name:DBHelperConversationDidAddMessage
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didDeleteMessagesInConversation:)
                                                 name:QliqConnectDidDeleteMessagesInConversationNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleRecipientsChangedNotification:)
                                                 name:RecipientsChangedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshController)
                                                 name:kConversationsListDidPressActionButtonNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onPresenceChangeNotification:)
                                                 name:@"PresenceChangeStatusNotification"
                                               object:nil];
}

- (void)addKeyboardNotifications {
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeShown:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasHide:)
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];
}

- (void)removeKeyboardNotifications {
    
    [self onDismisKeyboard:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
    
}

- (void)keyboardWillBeShown:(NSNotification *)notification {
    
    self.gestureRecognizerKeyboard.numberOfTapsRequired = 1;
    
    UIViewAnimationCurve curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
    UIViewAnimationOptions options = (curve << 16) | UIViewAnimationOptionBeginFromCurrentState;
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    CGSize keyboardSize = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    
    [UIView animateWithDuration:duration delay:0.0 options:options animations:^{
        
        CGFloat offset = keyboardSize.height;
        
        if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation))
            offset = keyboardSize.height;
        
        if (self.contactType == DetailInfoContactTypeConversation || self.contactType == DetailInfoContactTypeCareChannel){
            self.tableViewBottomConstraint.constant = offset;
            if ([(Conversation *)self.contact isCareChannel]) {
                
                self.contactHeaderView.hidden = YES;
                self.subjectHeaderViewHeightConstraint.constant = 0.f;
                self.contactHeaderViewHeightConstraint.constant = 0.f;
            }
            [self.view layoutIfNeeded];
        }
        
    } completion:nil];
    
}

- (void)keyboardWasShown:(NSNotification *)notification {
    [self.view addGestureRecognizer:self.gestureRecognizerKeyboard];
    [self scrollToActiveCell];
}

- (void)keyboardWillBeHidden:(NSNotification *)notification {
    
    [self.view removeGestureRecognizer:self.gestureRecognizerKeyboard];
    
    UIViewAnimationCurve curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
    UIViewAnimationOptions options = (curve << 16) | UIViewAnimationOptionBeginFromCurrentState;
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:duration delay:0.0 options:options  animations:^{
        
        if (self.contactType == DetailInfoContactTypeConversation || self.contactType == DetailInfoContactTypeCareChannel){
            self.tableViewBottomConstraint.constant = 0.f;
            if ([(Conversation *)self.contact isCareChannel]) {
                self.contactHeaderView.hidden = NO;
                self.contactHeaderViewHeightConstraint.constant = kValueContactHeaderViewHeightConstraint;
                self.subjectHeaderViewHeightConstraint.constant = kValueContactHeaderViewHeightConstraint;
            }
            [self.view layoutIfNeeded];
        }
    } completion:nil];
}

- (void)keyboardWasHide:(NSNotification *)notification {
    [self scrollToActiveCell];
}

- (void)onDismisKeyboard:(UITapGestureRecognizer *)tap {
    [self.view endEditing:YES];
}

- (void)onPresenceChangeNotification:(NSNotification *)notification
{
    @synchronized(self) {
        
        if ([notification.userInfo[@"isForMyself"] boolValue] == NO || self.contactType == DetailInfoContactTypeConversation || self.contactType == DetailInfoContactTypeCareChannel) {
            
            __block __weak typeof(self) weakSelf = self;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                __strong typeof(self) strongSelf = weakSelf;
                
                NSString *qliqId = notification.userInfo[@"qliqId"];
                
                if (strongSelf.contactType == DetailInfoContactTypeQliqUser) {
                    QliqUser *user = strongSelf.contact;
                    if ([user.qliqId isEqualToString:qliqId]) {
                        user.presenceStatus = [notification.userInfo[@"presenceStatus"] integerValue];
                    }
                    
                    performBlockInMainThread(^{
                        [strongSelf.contactHeaderView fillWithContact:strongSelf.contact];
                    });
                }
                else if (strongSelf.contactType == DetailInfoContactTypeQliqUser ||
                         strongSelf.contactType == DetailInfoContactTypePersonalGroup ||
                         strongSelf.contactType == DetailInfoContactTypeConversation ||
                         strongSelf.contactType == DetailInfoContactTypeCareChannel)
                {
                    
                    for (NSUInteger index = 0; index < strongSelf.groupUsers.count; index++)
                    {
                        if (strongSelf.groupUsers.count == 0) {
                            break;
                        }
                        
                        Contact *contact = [strongSelf.groupUsers objectAtIndex:index];
                        
                        if ([contact.qliqId isEqualToString:qliqId]) {
                            
                            id item = [[QliqAvatar sharedInstance] contactIsQliqUser:contact];
                            
                            if ([item isKindOfClass:[QliqUser class]]) {
                                QliqUser *user = item;
                                user.presenceStatus = [notification.userInfo[@"presenceStatus"] integerValue];
                                
                                [strongSelf.groupUsers replaceObjectAtIndex:index withObject:user];
                                
                                break;
                            }
                        }
                    }
                    
                    if (strongSelf.isSearching) {
                        for (NSUInteger index = 0; index < strongSelf.searchGroupUsers.count; index++)
                        {
                            if (strongSelf.searchGroupUsers.count == 0) {
                                break;
                            }
                            
                            Contact *contact = [strongSelf.searchGroupUsers objectAtIndex:index];
                            
                            if ([contact.qliqId isEqualToString:qliqId]) {
                                
                                id item = [[QliqAvatar sharedInstance] contactIsQliqUser:contact];
                                
                                if ([item isKindOfClass:[QliqUser class]]) {
                                    QliqUser *user = item;
                                    user.presenceStatus = [notification.userInfo[@"presenceStatus"] integerValue];
                                    
                                    [strongSelf.searchGroupUsers replaceObjectAtIndex:index withObject:user];
                                    
                                    break;
                                }
                            }
                        }
                    }
                    
                    dispatch_async_main(^{
                        [strongSelf refreshViewAsync:YES loadFromDb:NO];
                        //                        [strongSelf.tableView reloadData];
                    });
                }
            });
        }
    }
}

- (void)refreshController
{
    __block __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [weakSelf refreshView:YES loadFromDb:YES];
    });
}


- (void)handleApplicationDidBecomeActiveNotification:(NSNotification *)notification
{
    [self refreshViewAsync:YES loadFromDb:NO];
}

- (void)didReadMessages:(NSNotification *)notification {
    DDLogSupport(@"didReadMessages notification, dispatching refresh");

    __block __weak typeof(self) weakSelf = self;
    [self.refreshOperationsQueue addOperationWithBlock:^{
         [weakSelf updateConversationsArrayWithConversation:[[notification userInfo] objectForKey:@"Conversation"]];
    }];
}

- (void)didReceiveMessage:(NSNotification *)notification {
    DDLogSupport(@"didReceiveMessage notification, dispatching refresh");
    
    __block __weak typeof(self) weakSelf = self;
    [self.refreshOperationsQueue addOperationWithBlock:^{
        [weakSelf updateConversationsArrayWithConversation:[[notification userInfo] objectForKey:@"Conversation"]];
    }];
}

- (void)didDeleteMessagesInConversation:(NSNotification *)notification {
    DDLogSupport(@"didDeleteMessages notification, dispatching refresh");
    
    __block __weak typeof(self) weakSelf = self;
    [self.refreshOperationsQueue addOperationWithBlock:^{
        [weakSelf updateConversationsArrayWithConversation:[[notification userInfo] objectForKey:@"Conversation"]];
    }];
}

- (void)handleRecipientsChangedNotification:(NSNotification *)notification {
    DDLogSupport(@"Conversation Refresh Called from handleRecipientsChangedNotification");
    
    if (self.contactType == DetailInfoContactTypeConversation || self.contactType == DetailInfoContactTypeCareChannel) {
        Conversation *updatedConversation = notification.object;
        CareChannel *currentConversation = (CareChannel *)self.contact;
        if (currentConversation.conversationId == updatedConversation.conversationId) {
            currentConversation.recipients = updatedConversation.recipients;
            
            __weak __block typeof(self) welf = self;
            [self.refreshOperationsQueue addOperationWithBlock:^{
                [welf isSelfUserRecipientShowAlert];
                [welf prepareInformation];
            }];
        }
    }
    else
    {
        __block __weak typeof(self) weakSelf = self;
        [self.refreshOperationsQueue addOperationWithBlock:^{
            [weakSelf updateConversationsArrayWithConversation:[[notification userInfo] objectForKey:@"Conversation"]];
        }];
    }
}

#pragma mark - IBActions -

- (IBAction)onBack:(id)sender
{
    DDLogSupport(@"Back from DetailContactInfo");
    if (self.navigationController.presentingViewController && [[self.navigationController viewControllers].firstObject isEqual:self]) {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (IBAction)onSave:(id)sender {
}

- (void)onAddButton {
    self.isContactPickerPushed = YES;
    
    SelectContactsViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([SelectContactsViewController class])];
    controller.firstFilterCharacter = @"";
    controller.delegate = self;
    controller.typeController = (self.contact && self.contactType == DetailInfoContactTypeCareChannel) ? STForCareChannelEditPaticipants : STForConversationEditParticipants;
    controller.participants = [self.groupUsers mutableCopy];
    
    [self.navigationController pushViewController:controller animated:YES];
}

- (IBAction)onDoneButton:(id)sender {
    
    if (self.groupUsers.count > 0) {
        
        if (self.contactType == DetailInfoContactTypeConversation || self.contactType == DetailInfoContactTypeCareChannel) {
            
            if ([(Conversation *)self.contact isCareChannel]) {
                
                if ([self.delegate respondsToSelector:@selector(editDoneFromCareChannelInfo:withRoles:withCompletion:)]) {
                    __weak typeof(self) weakSelf = self;
                    [self.delegate editDoneFromCareChannelInfo:self.groupUsers withRoles:self.roles withCompletion:^{
                        [weakSelf onBack:nil];
                    }];
                }
                
            } else {
                
                if (self.isCurrentUserInParticipants && !self.isGroupConversation)
                    [self addObjectToGroupUsersArray:[UserSessionService currentUserSession].user];
                
                if ([self.delegate respondsToSelector:@selector(editDoneFromConversationInfo:withSubject:withCompletion:)]) {
                    __weak typeof(self) weakSelf = self;
                    [self.delegate editDoneFromConversationInfo:self.groupUsers withSubject:self.subject withCompletion:^{
                        [weakSelf onBack:nil];
                    }];
                }
            }
        }
    } else {
        
        [AlertController showAlertWithTitle:QliqLocalizedString(@"1078-TextYouNeedToSpecifyAtLeastOneParticipant")
                                    message:nil
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                 completion:nil];
    }
}

#pragma mark - Conversation -

- (NSArray *)loadConversations
{
    if (self.contact && self.contactType == DetailInfoContactTypeFhirPatient) {
        DDLogSupport(@"Start Load Care Channels");
        
        @synchronized(self) {
            FhirPatient *patient = (FhirPatient *)self.contact;
            self.conversations = [[ConversationDBService sharedService] getCareChannelsForPatient:patient.uuid];
            return [self.conversations sortedArrayUsingSelector:@selector(lastMsgTimestampAsc:)];        }
        
    } else if(self.contact && self.contactType == DetailInfoContactTypeCareChannel) {
        return nil;
    } else {
        
        @synchronized(self) {
            
            DDLogSupport(@"Load Conversations");
            
            id item = self.contact;
            
            NSString *qliqId = @"";
            if ([item isKindOfClass:[Contact class]] || [item isKindOfClass:[QliqUser class]])
                qliqId = ((Contact*)item).qliqId;
            
            else if ([item isKindOfClass:[QliqGroup class]])
                qliqId = ((QliqGroup*)item).qliqId;
            
            else if ([item isKindOfClass:[ContactList class]]) {
                qliqId = ((ContactList*)item).qliqId;
            }
            
            self.conversations = [[ConversationDBService sharedService] getConversationsWithQliqId:qliqId];
            
            return [self.conversations sortedArrayUsingSelector:@selector(lastMsgTimestampAsc:)];
        }
    }
}

- (void)refreshViewAsync:(BOOL)force loadFromDb:(BOOL)load {
    DDLogSupport(@"Dispatching async serial queue force = %d", force);
    
    NSAssert(NULL != self.refreshOperationsQueue, @"refreshQueue MUST be initialized before this method get called");
    
    __block __weak typeof(self) weakSelf = self;
    [self.refreshOperationsQueue addOperationWithBlock:^{
        [weakSelf refreshView:force loadFromDb:load];
    }];
}

- (void)refreshView:(BOOL)force loadFromDb:(BOOL)load
{
    static BOOL performingNow = NO;
    if ([AppDelegate applicationState] == UIApplicationStateBackground)
    {
        // We should try to refresh in the BG also. Because if the App is launched, it takes a while
        // for the app to become active.
        DDLogSupport(@"Refresh called in the BG.");
    }
    @synchronized(self)
    {
        if (!performingNow || force)
        {
            performingNow = YES;
            NSArray * conversations;
            if (load)
            {
                DDLogSupport(@"Loading all conversaions from DB");
                conversations = [self loadConversations];
            }
            
            __block __weak typeof(self) weakSelf = self;
            performBlockInMainThread(^{
                DDLogSupport(@"Reloading table data");
                if (load)
                    weakSelf.conversations = conversations;
                
                [weakSelf.tableView reloadData];
                performingNow = NO;
            });
        }
        else
        {
            DDLogSupport(@"Already performing reload conversations");
        }
    }
}

#pragma mark - Invitation

- (void)deleteInvitation:(Invitation *)invitation shouldDeleteContactAlso:(BOOL)deleteContact
{
    if (deleteContact)
    {
        QliqUser *user = [[QliqUserDBService sharedService] getUserForContact:invitation.contact];
        if (user)
            [[QliqUserDBService sharedService] setUserDeleted:user];
    }
    
    [[InvitationService sharedService] deleteInvitation:invitation];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:InvitationServiceInvitationsChangedNotification object:nil userInfo:nil];
}

#pragma mark - Managing Conversation Array

- (void)sortConversations
{
    self.conversations = [self.conversations sortedArrayUsingSelector:@selector(lastMsgTimestampAsc:)];
}

- (void)addConversation:(Conversation *)conversation
{
    self.conversations = [self.conversations arrayByAddingObject:conversation];
    [self sortConversations];
}

- (NSIndexPath *)updateConversationArrayWithConversation:(Conversation *)_conversation
{
    NSArray *_array = self.conversations;
    
    NSIndexPath * indexPath = nil;
    for (Conversation *oldConv in _array)
    {
        if (oldConv.conversationId == _conversation.conversationId)
        {
            indexPath = [NSIndexPath indexPathForRow:[_array indexOfObject:oldConv] inSection:0];
            
            if (_conversation.lastMsg)
            {
                oldConv.lastMsg     = _conversation.lastMsg;
                oldConv.lastUpdated = _conversation.lastUpdated;
                oldConv.isRead      = _conversation.isRead;
            }
            else
            {
                // This conv was deleted
                NSMutableArray *newArray = [[NSMutableArray alloc] initWithCapacity:[_array count] -  1];
                [newArray addObjectsFromArray:_array];
                [newArray removeObject:oldConv];
                
                self.conversations = newArray;
            }
            break;
        }
    }
    return indexPath;
}

- (void)updateConversationsArrayWithConversation:(Conversation *)_conversation
{
    if (!_conversation)
    {
        DDLogError(@"UpdateConversationsArrayWithConversation called with nil conversation arg");
        return;
    }
    
    DDLogSupport(@"Conversation Refresh Called from updateConversationsArrayWithConversation");
    
    if (_conversation.lastMsg == nil)
    {
        ChatMessage *lastMessage = [[ChatMessageService sharedService] getLatestMessageInConversation:_conversation.conversationId];
        _conversation.lastMsg = lastMessage.text;
        _conversation.lastUpdated = lastMessage.createdAt;
    }
    
    NSIndexPath * allIndexPath = [self updateConversationArrayWithConversation:_conversation];
    
    if (allIndexPath == nil)
        [self addConversation:_conversation];
    
    [self sortConversations];
    [self refreshView:YES loadFromDb:YES];
}

#pragma mark - Utilities/Helpers -

- (NSString *)formatSocialSecurityNumber:(NSString *)ssn {
    
    NSString *formattedSSN = @"";
    NSInteger rangeLenDif = 0;
    NSInteger rangeLen = 0;
    NSInteger unHiddenDigitsCount = 0;
    NSCharacterSet *numericSet = [NSCharacterSet decimalDigitCharacterSet];
    NSError *error = nil;
    
    for (NSInteger i = ssn.length - 1; i >= 0; i--) {
        
        unichar c = [ssn characterAtIndex:i];
        
        if (![numericSet characterIsMember:c]) {
            rangeLenDif++;
        } else {
            unHiddenDigitsCount++;
            rangeLenDif++;
        }
        
        if (unHiddenDigitsCount == 4) {
            break;
        }
    }
    
    rangeLen = ssn.length - rangeLenDif;
    if (rangeLen > 0 && ssn.length > 4) {
        
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[^-,^(,^)]"
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:&error];
        
        formattedSSN = [regex stringByReplacingMatchesInString:ssn
                                                       options:0
                                                         range:NSMakeRange(0, rangeLen)
                                                  withTemplate:@"X"];
    } else {
        formattedSSN = ssn;
    }
    
    return formattedSSN;
}

- (void)removeInformation
{
    @synchronized(self) {
        [self.providerInformationKeyValuePairs removeAllObjects];
        [self.moreInformationKeyValuePairs removeAllObjects];
        [self.memberNotesKeyValuePairs removeAllObjects];
        [self.actions removeAllObjects];
        [self.content removeAllObjects];
        [self.groupUsers removeAllObjects];
        [self.startGroupUsers removeAllObjects];
        [self.roles removeAllObjects];
        self.startRoles = nil;
    }
}

- (void)inviteContact:(Contact*)contact
{
    __weak typeof(self) weakSelf = self;
    [self.inviteController inviteContact:contact isAddressBookContact:YES completionBlock:^(Invitation *invitation, NSError *error) {
        
        dispatch_async_main(^{
            if (nil == error) {
                [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"1905-TextInvited", nil)];
            }
            else {
                [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"1906-TextInvitationFailed", nil)];
            }
            [self.view endEditing:YES];
        });
        
        __block __weak typeof(weakSelf) stongSelf = weakSelf;
        double delayInSeconds = 1.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            
            [SVProgressHUD dismiss];
            
            if (nil == error) {
                [stongSelf.navigationController popViewControllerAnimated:YES];
            }
        });
    }];
}

- (void)startConversationWithItem:(id)item
{
    if ([item isKindOfClass:[QliqUser class]]) {
        [[[Presence alloc] init] setShouldAsk:YES];
        
        __block __weak typeof(self) weakSelf = self;
        [Presence askForwardingIfNeededForRecipient:(QliqUser *)item  completeBlock:^(id<Recipient> selectedRecipient) {
            
            if ([selectedRecipient isRecipientEnabled]) {
                
                [weakSelf startConversationWithParticipants:[NSMutableArray arrayWithObject:selectedRecipient] isBroadcastConvesation:NO];
            } else {
                
                [AlertController showAlertWithTitle:nil
                                            message:QliqLocalizedString(@"1037-TextContactNotactivatedQliqAccount")
                                        buttonTitle:QliqLocalizedString(@"10-ButtonSend")
                                  cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel")
                                         completion:^(NSUInteger buttonIndex) {
                                             if (buttonIndex==0) {
                                                 [weakSelf startConversationWithParticipants:[NSMutableArray arrayWithObject:selectedRecipient] isBroadcastConvesation:NO];
                                             }
                                         }];
            }
            [weakSelf refreshView:YES loadFromDb:YES];
        }];
    }
}

- (void)makeCall:(NSString *)phoneNumber
{
    NSString *phoneUrl = [NSString stringWithFormat:@"tel://%@", phoneNumber];
    phoneUrl = [phoneUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:phoneUrl];
    [[UIApplication sharedApplication] openURL:url];
}

- (void)voipCall {
    
    [[[QliqSip instance] voiceCallsController] callUser:self.contact];
}

- (void)refreshView
{
    [self.tableView reloadData];
    if (self.contactType == DetailInfoContactTypeContact || self.contactType == DetailInfoContactTypeQliqUser) {
        [self.contactHeaderView setContactIsFavorite:[self.favoritesContactGroup containsContact:self.contact]];
    }

    // As it is leaking about 7 bytes per call.
//    [self.view layoutIfNeeded];
}

- (void)addToListButtonPressed
{
    AddToListViewController *addToListVC = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([AddToListViewController class])];
    addToListVC.contactId = ((Contact*)self.contact).contactId;
    [self.navigationController pushViewController:addToListVC animated:YES];
}

- (void)startConversationWithParticipants:(NSMutableArray*)participants isBroadcastConvesation:(BOOL)isBroadcast
{
    ConversationViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([ConversationViewController class])];
    controller.isNewConversation    = YES;
    controller.isBroadcastConversation = isBroadcast;
    
    if (participants)
    {
        Recipients *recipients = [[Recipients alloc] init];
        [recipients addRecipientsFromArray:participants];
        
        controller.recipients = recipients;
    }
    
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)startConversationWithRecipients:(Recipients *)recipients isBroadcastConvesation:(BOOL)isBroadcast
{
    ConversationViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([ConversationViewController class])];
    controller.isNewConversation = YES;
    controller.isBroadcastConversation = isBroadcast;
    controller.recipients = recipients;
    [controller setNeedAskBroadcast:NO];
    
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)showProgressHUD {
    [SVProgressHUD show];
}

- (void)scrollToActiveCell {
    
    if (self.groupUsers.count > 0) {
        NSIndexPath *indPTH = self.indexPathForActiveCell;
        [self.tableView scrollToRowAtIndexPath:indPTH
                              atScrollPosition:UITableViewScrollPositionTop
                                      animated:YES];
    }
}

#pragma mark * Prepare Information
- (void)prepareInformation
{
    [self removeObservers];
    [self removeInformation];
    
    if (self.contactType != DetailInfoContactTypeOnCallMemberNotes && self.contactType != DetailInfoContactTypeConversation && self.contactType != DetailInfoContactTypeCareChannel)
    {
        [self refreshView:YES loadFromDb:YES];
    }
    
    __weak __block typeof(self) welf = self;
    //Set Header
    if (self.contactType != DetailInfoContactTypeConversation) {
        performBlockInMainThread(^{
            [welf.contactHeaderView fillWithContact:self.contact];
            welf.contactHeaderView.hidden = NO;
        });
    }
    
    DetailInfoContactType type = self.contactType;
    
    switch (type) {
        case DetailInfoContactTypeQliqUser:
        {
            QliqUser *user = self.contact;
            [self prepareInformationForQliqUser:user];
            break;
        }
        case DetailInfoContactTypeContact:
        {
            Contact *user = self.contact;
            [self prepareInformationForContact:user];
            break;
        }
        case DetailInfoContactTypeQliqGroup:
        {
            QliqGroup *group = self.contact;
            [self prepareInformationForQliqGroup:group];
            break;
        }
        case DetailInfoContactTypePersonalGroup:
        {
            ContactList *list = self.contact;
            [self prepareInformationForPersonalGroup:list];
            break;
        }
        case DetailInfoContactTypeInvitation:
        {
            Invitation *invitation = self.contact;
            [self prepareInformationForInvitation:invitation];
            break;
        }
        case DetailInfoContactTypeConversation:
        {
            
            dispatch_sync_main(^{
                //Gesture
                self.gestureRecognizerKeyboard = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onDismisKeyboard:)];
            });
            [self prepareInformationForConversation];
            break;
        }
        case DetailInfoContactTypeCareChannel:
        {
            dispatch_sync_main(^{
                //Gesture
                 self.gestureRecognizerKeyboard = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onDismisKeyboard:)];
            });
            [self prepareInformationForCC];
            break;
        }
        case DetailInfoContactTypeFhirPatient:
        {
            FhirPatient *patient = self.contact;
            [self prepareInformationForFhirPatient:patient];
            break;
        }
        case DetailInfoContactTypeOnCallMemberNotes:
        {
            self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
            OnCallMemberNotes *memberNotes = (OnCallMemberNotes *)self.contact;
            [self prepareInformationForOnCallMemberNotes:memberNotes];
            break;
        }
        case DetailInfoContactTypeOnCallDayNotes:
        {
            self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
            [self prepareInformationForOnCallDayNotes:self.contact];
            break;
        }
        default:
            break;
    }
    
     performBlockInMainThreadSync(^{
        //Refresh Data
        {
            [self refreshView];
        }
        
        if ([SVProgressHUD isVisible])
        {
            [SVProgressHUD dismiss];
        }
        else
        {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showProgressHUD) object:nil];
        }
    });
}

- (void)prepareInformationForQliqUser:(QliqUser *)user {
//    user = [[QliqUserDBService sharedService] getUserWithId:user.qliqId];
    
    //Set Title
    dispatch_async_main(^{
        self.titleViewNavigationBar.text = QliqLocalizedString(@"2152-TitleContactInfo");
    });
    
    //Add Provider
    {
        if (user.mobile.length)
            [self.providerInformationKeyValuePairs  addObject:@[kKeyMobile, user.mobile]];
        
        if (user.phone.length)
            [self.providerInformationKeyValuePairs  addObject:@[kKeyPhone, user.phone]];
        
        if (user.qliqId.length)
            [self.providerInformationKeyValuePairs  addObject:@[kKeyQliqId, user.qliqId]];
    }
    
    //Acctions
    {
        [self.actions  addObject:@[kKeyStartConversation, @""]];
    }
    
    //Add More Information
    {
        if (user.profession.length)
            [self.moreInformationKeyValuePairs      addObject:@[kKeyTitle, user.profession]];
        
        if (user.specialty.length) {
            if ([user.specialty containsString:@"-"]) {
                [self.moreInformationKeyValuePairs      addObject:@[kKeyOnCallShedule, user.specialty]];
            }
            [self.moreInformationKeyValuePairs      addObject:@[kKeySpeciality, user.specialty]];
        }
        
        [self.moreInformationKeyValuePairs          addObject:@[kKeyTitleOrgGroups, (user.groupName ? user.groupName : @"")]];
        [self.moreInformationKeyValuePairs          addObject:@[kKeyPersonalGroup, (user.listName ? user.listName : @"")]];
    }
}

- (void)prepareInformationForContact:(Contact *)user {
    user = [[ContactDBService sharedService] getContactById:user.qliqId];
    //Set Title
    dispatch_async_main(^{
        self.titleViewNavigationBar.text = QliqLocalizedString(@"2152-TitleContactInfo");
    });
    //Add Provider
    {
        if (user.mobile.length)
            [self.providerInformationKeyValuePairs  addObject:@[kKeyMobile, user.mobile]];
        
        if (user.phone.length)
            [self.providerInformationKeyValuePairs  addObject:@[kKeyPhone, user.phone]];
        
        if (user.qliqId.length)
            [self.providerInformationKeyValuePairs  addObject:@[kKeyQliqId, user.qliqId]];
    }
    //Actions
    {
        [self.actions  addObject:@[kKeyInviteToQliq, @""]];
    }
}
- (void)prepareInformationForQliqGroup:(QliqGroup *)group {
    group = [[QliqGroupDBService sharedService] getGroupWithId:group.qliqId];
    
    //Set Title
    dispatch_async_main(^{
        self.titleViewNavigationBar.text = self.isSearching ? group.name : QliqLocalizedString(@"2151-TitleGroupInfo");
    });
    
    //Actions
    {
        if (group.canBroadcast)
            [self.actions  addObject:@[kKeyStartBroadcastConversation, @""]];
        if (group.canMessage && ![[QliqGroupDBService sharedService] isPagerUsersContainsInGroup:group])
            [self.actions  addObject:@[kKeyStartGroupConversation, @""]];
    }
    
    //Contacts
    {
        self.groupUsers = [[group getOnlyContacts] mutableCopy];
        self.groupUsers = [[self.groupUsers sortedArrayUsingDescriptors:
                            @[[NSSortDescriptor sortDescriptorWithKey:@"lastName" ascending:YES],
                              [NSSortDescriptor sortDescriptorWithKey:@"firstName" ascending:YES]]] mutableCopy];
    }
}

- (void)prepareInformationForPersonalGroup:(ContactList *)list {
    //Set Title
    dispatch_async_main(^{
        self.titleViewNavigationBar.text = self.isSearching ? list.name : QliqLocalizedString(@"2151-TitleGroupInfo");
    });
    
    //Contacts
    {
        self.groupUsers = [[list getOnlyContacts] mutableCopy];
        self.groupUsers = [[self.groupUsers sortedArrayUsingDescriptors:
                            @[[NSSortDescriptor sortDescriptorWithKey:@"lastName" ascending:YES],
                              [NSSortDescriptor sortDescriptorWithKey:@"firstName" ascending:YES]]] mutableCopy];
    }
    
    //Actions
    {
        if (self.groupUsers.count > 0) {
            [self.actions  addObject:@[kKeyStartBroadcastConversation, @""]];
            [self.actions  addObject:@[kKeyStartGroupConversation, @""]];
        }
    }
    
}

- (void)prepareInformationForInvitation:(Invitation *)invitation {
    
    id contact = invitation.contact;
    
    if (invitation.contact.contactType == ContactTypeQliqUser)
    {
        QliqUser * user = [[QliqUserDBService sharedService] getUserForContact:invitation.contact];
        if (user)
            contact = user;
    }
    
    //Set Title
    {
        NSString *typeInvitation = invitation.operation == InvitationOperationSent ? QliqLocalizedString(@"2172-TitleSentInvitation") : QliqLocalizedString(@"2173-TitleReceivedInvitation");
        
        dispatch_async_main(^{
            self.titleViewNavigationBar.text = typeInvitation;
        });
    }
    
    //Add Provider
    {
        if ( ((QliqUser*)contact).mobile.length)
            [self.providerInformationKeyValuePairs  addObject:@[kKeyMobile, ((QliqUser*)contact).mobile]];
        
        if (((QliqUser*)contact).phone.length)
            [self.providerInformationKeyValuePairs  addObject:@[kKeyPhone, ((QliqUser*)contact).phone]];
        
        if (((QliqUser*)contact).qliqId.length)
            [self.providerInformationKeyValuePairs  addObject:@[kKeyQliqId, ((QliqUser*)contact).qliqId]];
    }
    
    //Actions
    {
        switch (invitation.status)
        {
            case InvitationStatusAccepted: break;
            case InvitationStatusDeclined: [self.actions  addObject:@[kKeyDelete, @""]]; break;
            default: {
                
                if (invitation.operation == InvitationOperationSent)
                {
                    [self.actions  addObject:@[kKeyRemind, @""]];
                    [self.actions  addObject:@[kKeyCancel, @""]];
                }
                else if (invitation.operation == InvitationOperationReceived)
                {
                    [self.actions  addObject:@[kKeyAccept, @""]];
                    [self.actions  addObject:@[kKeyDecline, @""]];
                }
                
                break;
            }
        }
    }
}

- (void)prepareInformationForFhirPatient:(FhirPatient *)patient {
    
    //Set Title
    dispatch_async_main(^{
        self.titleViewNavigationBar.text = QliqLocalizedString(@"3005-TitlePatientInfo");
    });
    //Add Provider
    {
        if (patient.dateOfBirth.length)
            [self.providerInformationKeyValuePairs  addObject:@[kKeyDateOfBirdth, patient.dateOfBirth]];
        
        if (patient.deceased)
            [self.providerInformationKeyValuePairs  addObject:@[kKeyDeceased, @""]];
        
        if (patient.dateOfDeath.length)
            [self.providerInformationKeyValuePairs  addObject:@[kKeyDateOfDeath, patient.dateOfDeath]];
        
        if (patient.race.length)
            [self.providerInformationKeyValuePairs  addObject:@[kKeyRace, patient.race]];
        
        if (patient.insurance.length)
            [self.providerInformationKeyValuePairs  addObject:@[kKeyInsuarance, patient.insurance]];
        
        if (patient.masterPatientindex.length)
            [self.providerInformationKeyValuePairs  addObject:@[kKeyMasterPatientIndex, patient.masterPatientindex]];
        
        if (patient.medicalRecordNumber.length)
            [self.providerInformationKeyValuePairs  addObject:@[kKeyMedicalRecordNumber, patient.medicalRecordNumber]];
        
        if (patient.patientAccountNumber.length)
            [self.providerInformationKeyValuePairs  addObject:@[kKeyPatientAccountNumber, patient.patientAccountNumber]];
        
        if (patient.socialSecurityNumber.length)
            [self.providerInformationKeyValuePairs  addObject:@[kKeySocialSecurityNumber, [self formatSocialSecurityNumber:patient.socialSecurityNumber]]];
        
        if (patient.driversLicenseNumber.length)
            [self.providerInformationKeyValuePairs  addObject:@[kKeyDriversLicenceNumber, patient.driversLicenseNumber]];
        
        if (patient.uuid.length)
            [self.providerInformationKeyValuePairs  addObject:@[kKeyFhirId, patient.uuid]];
        
        if (patient.phoneHome.length)
            [self.providerInformationKeyValuePairs  addObject:@[kKeyPhoneHome, patient.phoneHome]];
        
        if (patient.phoneWork.length)
            [self.providerInformationKeyValuePairs  addObject:@[kKeyPhoneWork, patient.phoneWork]];
        
        if (patient.email.length)
            [self.providerInformationKeyValuePairs  addObject:@[kKeyEmail, patient.email]];
        
        if (patient.address.length)
            [self.providerInformationKeyValuePairs  addObject:@[kKeyAddress, patient.address]];
        
        if (patient.nationality.length)
            [self.providerInformationKeyValuePairs  addObject:@[kKeyNationality, patient.nationality]];
        
        if (patient.language.length)
            [self.providerInformationKeyValuePairs  addObject:@[kKeyLanguage, patient.language]];
        
        if (patient.maritalStatus.length)
            [self.providerInformationKeyValuePairs  addObject:@[kKeyMaritalStatus, patient.maritalStatus]];
    }
    
    //Acctions
    {
        [self.actions  addObject:@[kKeyStartCareChannel, @""]];
    }
}

- (void)prepareInformationForConversation {
    Conversation *conversation = (Conversation *)self.contact;
    
    self.subject = conversation.subject;
    self.isGroupConversation = conversation.recipients.isGroup;
    
    //Set Title
    __weak __block typeof(self) welf = self;
    dispatch_async_main(^{
        welf.titleViewNavigationBar.text = QliqLocalizedString(@"2186-TitleEditParticipants");
        
        [welf setupSubjectHeaderView];
        [welf showDoneButton:NO];
    });
    
    //Contacts
    {
        
        self.startGroupUsers = [[[conversation.recipients allRecipients] sortedArrayUsingDescriptors:
                                 @[[NSSortDescriptor sortDescriptorWithKey:@"lastName" ascending:YES],
                                   [NSSortDescriptor sortDescriptorWithKey:@"firstName" ascending:YES]]] mutableCopy];
        
        {
            QliqUser *currentUser = [UserSessionService currentUserSession].user;
            
            NSInteger index = NSNotFound;
            index = [self.startGroupUsers indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj isKindOfClass:[QliqUser class]]) {
                    QliqUser *participant = (QliqUser*)obj;
                    return [participant.qliqId isEqualToString:currentUser.qliqId];
                }
                return NO;
            }];
            
            if (index != NSNotFound && index < self.startGroupUsers.count) {
                self.isCurrentUserInParticipants = YES;
                [self.startGroupUsers removeObjectAtIndex:index];
            }
        }
        
        self.groupUsers = [self.startGroupUsers mutableCopy];
        
        [self addObserver:self forKeyPath:@"groupUsers"];
    }

    [self addObserver:self forKeyPath:@"subject" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:nil];
}



- (void)prepareInformationForCC {
    FhirEncounter *encounter = ((Conversation *)self.contact).encounter;
    self.roles = [NSMutableDictionary dictionary];
    CareChannel *conversation = (CareChannel *)self.contact;
    
    //Set Title
    __weak __block typeof(self) welf = self;
    dispatch_async_main(^{
        welf.titleViewNavigationBar.text = QliqLocalizedString(@"Care Channel Info");
        [welf showDoneButton:NO];
        welf.contactHeaderView.hidden = NO;
    });
    
    //Add Provider
    {
        [self.providerInformationKeyValuePairs  addObject:@[kKeyAdmitDate, encounter.periodStart]];
        
    }
    //Add More Information
    {
        if (encounter.location) {
            
            //Room/Bed
            {
                if (encounter.location.room.length != 0 && encounter.location.bed.length != 0) {
                    [self.moreInformationKeyValuePairs  addObject:@[[NSString stringWithFormat:@"%@/%@", kKeyLocationRoom, kKeyLocationBed],
                                                                    [NSString stringWithFormat:@"%@/%@", encounter.location.room, encounter.location.bed]]];
                    
                } else if (encounter.location.room.length != 0) {
                    [self.moreInformationKeyValuePairs  addObject:@[kKeyLocationRoom, encounter.location.room]];
                } else if (encounter.location.bed.length != 0) {
                    [self.moreInformationKeyValuePairs  addObject:@[kKeyLocationBed, encounter.location.bed]];
                }
            }
            //Building/Floor
            {
                if (encounter.location.building.length != 0 && encounter.location.floor.length != 0) {
                    [self.moreInformationKeyValuePairs  addObject:@[[NSString stringWithFormat:@"%@/%@", kKeyLocationBuilding, kKeyLocationFloor],
                                                                    [NSString stringWithFormat:@"%@/%@", encounter.location.building, encounter.location.floor]]];
                    
                } else if (encounter.location.building.length != 0) {
                    [self.moreInformationKeyValuePairs  addObject:@[kKeyLocationBuilding, encounter.location.building]];
                } else if (encounter.location.floor.length != 0) {
                    [self.moreInformationKeyValuePairs  addObject:@[kKeyLocationFloor, encounter.location.floor]];
                }
            }
            
            //Facility
            if (encounter.location.facility.length != 0) {
                [self.moreInformationKeyValuePairs  addObject:@[kKeyLocationFacility, encounter.location.facility]];
            }
        }
    }
    
    //Contacts
    {
        self.startGroupUsers = [[[conversation.recipients allRecipients] sortedArrayUsingDescriptors:
                                 @[[NSSortDescriptor sortDescriptorWithKey:@"lastName" ascending:YES],
                                   [NSSortDescriptor sortDescriptorWithKey:@"firstName" ascending:YES]]] mutableCopy];
        
        self.groupUsers = [self.startGroupUsers mutableCopy];
        
        [self addObserver:self forKeyPath:@"groupUsers"];
    }
    
    //Roles
    {
        Multiparty *mp = [MultipartyDao selectOneWithQliqId:((Conversation *)self.contact).recipients.qliqId];
        if (mp) {
            for (QliqUser * user in self.groupUsers) {
                @autoreleasepool {
                    if (user) {
                        NSString *role = [mp roleForQliqId:user.qliqId];
                        if (role) {
                            [self.roles setObject:role forKey:user.qliqId];
                        }
                    }
                }
                
            }
        }
        
        if (self.roles.count > 0) {
            self.startRoles = [self.roles copy];
            [self addObserver:self toRolesForKeyPath:@"description"];
        }
    }
}

- (void)prepareInformationForOnCallMemberNotes:(OnCallMemberNotes *)memberNotes {
    __weak __block typeof(self) welf = self;
    //Set Title
    dispatch_async_main(^{
        welf.titleViewNavigationBar.text = QliqLocalizedString(@"2354-TitleNotes");
    });
    
    //Add Notes
    for (OnCallNote *note in memberNotes.notes) {
        [self.memberNotesKeyValuePairs addObject:@[note.author, note.text]];
    }
}

- (void)prepareInformationForOnCallDayNotes:(NSArray *)memberNotes {
    __weak __block typeof(self) welf = self;
    //Set Title
    dispatch_async_main(^{
        welf.contactHeaderViewHeightConstraint.constant = 0;
        welf.subjectHeaderViewHeightConstraint.constant = 0;
        [welf.view layoutSubviews];
        welf.contactHeaderView.hidden = YES;
        welf.titleViewNavigationBar.text = QliqLocalizedString(@"2380-TitleDayNotes");
    });
    
    //Add Notes
    for (NSString *note in memberNotes) {
        [self.memberNotesKeyValuePairs addObject:@[[NSString stringWithFormat:@"%lu",(unsigned long)[memberNotes indexOfObject:note]], note]];
    }
}


#pragma mark - Actions -

- (void)onEditContactsForPersonalGroup
{
    SelectContactsViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([SelectContactsViewController class])];
    
    controller.typeController = STForPersonalGroup;
    controller.list = self.contact;
    
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)didSelectInviteToQliq
{
    if (self.contactType == DetailInfoContactTypeContact) {
        [self inviteContact:self.contact];
    }
}

- (void)didSelectStartConversation
{
    if (self.contactType == DetailInfoContactTypeInvitation || self.contactType == DetailInfoContactTypeQliqUser) {
        [self startConversationWithItem:self.contactType == DetailInfoContactTypeInvitation ? ((Invitation*)self.contact).contact : self.contact];
    }
}

//TODO: Need to implement starting new Care Channel
- (void)didSelectStartCareChannel
{
    DDLogSupport(@"Start Care Channel");
}

- (void)didSelectStartGroupConversation {
    //Qliq Group
    if (self.contactType == DetailInfoContactTypeQliqGroup)
    {
        QliqGroup *group = self.contact;
        
        if ([group isKindOfClass:[QliqGroup class]] && [group respondsToSelector:@selector(qliqId)])
        {
            NSArray *groupRecipients = [[QliqGroupDBService sharedService] getUsersOfGroup:group];
            if (groupRecipients.count != 0) {
                Recipients *recipients = [[Recipients alloc] init];
                [recipients addRecipient:group];
                
                [self startConversationWithRecipients:recipients isBroadcastConvesation:NO];
            }
            else {
                 [self cannotStartConversationType:@"Group"];
            }
        }
    }
    //Personal Group
    else if (self.contactType == DetailInfoContactTypePersonalGroup) {
    
        if (self.groupUsers.count != 0) {
            ContactList *list = self.contact;
            
            NSMutableArray *users = [NSMutableArray new];
            
            for (id user in self.groupUsers) {
                [users addObject:[[QliqAvatar sharedInstance] contactIsQliqUser:user]];
            }
            
            Recipients *recipients = [[Recipients alloc] init];
            recipients.name = list.name;
            recipients.isPersonalGroup = YES;
            [recipients addRecipientsFromArray:users];
            
            [self startConversationWithRecipients:recipients isBroadcastConvesation:NO];
        }
        else {
             [self cannotStartConversationType:@"Group"];
        }
    }
}

- (void)didSelectStartBroadcastConversation {
    //Qliq Group
    if (self.contactType == DetailInfoContactTypeQliqGroup)
    {
        QliqGroup *group = self.contact;
        
        if ([group isKindOfClass:[QliqGroup class]] && [group respondsToSelector:@selector(qliqId)])
        {
            NSArray *groupRecipients = [[QliqGroupDBService sharedService] getUsersOfGroup:group];
            if (groupRecipients.count != 0) {
                Recipients *recipients = [[Recipients alloc] init];
                [recipients addRecipient:group];
                [self startConversationWithRecipients:recipients isBroadcastConvesation:YES];
            }
            else {
                [self cannotStartConversationType:@"Broadcast"];
            }
        }
    }
    //Personal Group
    else if (self.contactType == DetailInfoContactTypePersonalGroup) {
        
        if (self.groupUsers.count != 0) {
            
            ContactList *list = self.contact;
            
            NSMutableArray *users = [NSMutableArray new];
            
            for (id user in self.groupUsers) {
                [users addObject:[[QliqAvatar sharedInstance] contactIsQliqUser:user]];
            }
            
            Recipients *recipients = [[Recipients alloc] init];
            recipients.name = list.name;
            recipients.isPersonalGroup = YES;
            [recipients addRecipientsFromArray:users];
            
            [self startConversationWithRecipients:recipients isBroadcastConvesation:NO];
        }
        else {
            [self cannotStartConversationType:@"Broadcast"];
        }
        
    }
}

- (void)didSelectEdit
{
    if (self.contactType == DetailInfoContactTypePersonalGroup) {
        SelectContactsViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([SelectContactsViewController class])];
        
        NSString *listName = ((ContactList*)self.contact).name;
        ContactList *list = nil;
        for (ContactList *item in [[QliqListService sharedService] getLists])
        {
            if ([item.name isEqualToString:listName]) {
                list = item;
                break;
            }
        }
        controller.typeController   = STForPersonalGroup;
        controller.list             = list;
        
        [self.navigationController pushViewController:controller animated:YES];
    }
}

- (void)didSelectDelete
{
    if (self.contactType == DetailInfoContactTypeInvitation) {
        [self deleteInvitation:(Invitation *)self.contact shouldDeleteContactAlso:YES];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)didSelectRemind
{
    if (self.contactType == DetailInfoContactTypeInvitation) {
        
        [[InviteController inviteControllerFromViewController:self] remindInvitation:(Invitation*)self.contact withCompletitionBlock:^(InviteControllerState state, NSError *error) {
            
            if (state == InviteControllerStateSuccess) {
            }
        }];
    }
}

- (void)didSelectCancel
{
    if (self.contactType == DetailInfoContactTypeInvitation) {
        __block __weak typeof(self) weakSelf = self;
        [[InviteController inviteControllerFromViewController:self] cancelInvitation:(Invitation*)self.contact withCompletitionBlock:^(InviteControllerState state, NSError *error) {
            
            if (state == InviteControllerStateSuccess)
                [weakSelf.navigationController popViewControllerAnimated:YES];
        }];
    }
}

- (void)didSelectAccept
{
    if (self.contactType == DetailInfoContactTypeInvitation) {
        
        [SVProgressHUD showProgress:-1 status:NSLocalizedString(@"1115-TextProcessing", nil)];
        
        __block __weak typeof(self) weakSelf = self;
        [[InviteController inviteControllerFromViewController:self] acceptInvitation:(Invitation*)self.contact withCompletitionBlock:^(InviteControllerState state, NSError *error) {
            
            [SVProgressHUD dismiss];
            
            if (state == InviteControllerStateSuccess) {
                
                [weakSelf deleteInvitation:(Invitation*)weakSelf.contact shouldDeleteContactAlso:NO];
                
                double delayInSeconds = .25;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                    
                    [weakSelf.navigationController popViewControllerAnimated:YES];
                });
            } else {
                
                if ([error.userInfo[@"error_code"] integerValue] == InvitationIsNotInPendingState)
                {
                    [weakSelf deleteInvitation:(Invitation *)weakSelf.contact shouldDeleteContactAlso:NO];
                    
                    double delayInSeconds = .25;
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                        [weakSelf.navigationController popViewControllerAnimated:YES];
                    });
                } else {
                    
                    [AlertController showAlertWithTitle:QliqLocalizedString(@"1075-TextUnableAcceptInvitation")
                                                message:QliqLocalizedString(@"1076-TextTryLater")
                                            buttonTitle:nil
                                      cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                             completion:^(NSUInteger buttonIndex) {
                                                 if (buttonIndex==1) {
                                                     double delayInSeconds = .25;
                                                     dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                                                     dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                                                         
                                                         [weakSelf.navigationController popViewControllerAnimated:YES];
                                                     });
                                                 }
                                             }];
                }
            }
        }];
    }
}

- (void)didSelectDecline
{
    if (self.contactType == DetailInfoContactTypeInvitation) {
        
        [SVProgressHUD showProgress:-1 status:NSLocalizedString(@"1115-TextProcessing", nil)];
        
        __block __weak typeof(self) weakSelf = self;
        [[InviteController inviteControllerFromViewController:self] declineInvitation:(Invitation*)self.contact withCompletitionBlock:^(InviteControllerState state, NSError *error) {
            
            [SVProgressHUD dismiss];
            
            if (state == InviteControllerStateSuccess)
            {
                [weakSelf deleteInvitation:(Invitation*)weakSelf.contact shouldDeleteContactAlso:YES];
                
                double delayInSeconds = .25;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                    
                    [weakSelf.navigationController popViewControllerAnimated:YES];
                });
            }
            else
            {
                if ([error.userInfo[@"error_code"] integerValue] == InvitationIsNotInPendingState) {
                    
                    [weakSelf deleteInvitation:(Invitation*)weakSelf.contact shouldDeleteContactAlso:NO];
                    
                    double delayInSeconds = .25;
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                        
                        [weakSelf.navigationController popViewControllerAnimated:YES];
                    });
                } else {
                    
                    [AlertController showAlertWithTitle:QliqLocalizedString(@"1077-TextUnableDeclineInvitation")
                                                message:QliqLocalizedString(@"1076-TextTryLater")
                                            buttonTitle:nil
                                      cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK") completion:^(NSUInteger buttonIndex) {
                                          
                                          if (buttonIndex==1) {
                                              double delayInSeconds = .25;
                                              dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                                              dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                                                  
                                                  [weakSelf.navigationController popViewControllerAnimated:YES];
                                              });
                                          }
                                      }];
                }
            }
        }];
    }
}

#pragma mark - Delegates -

#pragma mark * RecentCellDelegate

- (void)cellLeftSwipe:(Conversation *)conversation {
    self.selectedConversation = conversation;
    [self.tableView reloadData];
}

- (void)cellRightSwipe {
    [self eraseSelectedConversation];
}

- (void)pressCallButton:(Conversation *)conversation {
    DDLogSupport(@"Conversation Refresh Called from Call User");
    
    [self eraseSelectedConversation];
}

- (void)pressFlagButton:(Conversation *)conversation {
    DDLogSupport(@"Flag button pressed!");
    
    [self eraseSelectedConversation];
}

- (void)pressSaveButton:(Conversation *)conversation {
    DDLogSupport(@"Conversation Refresh Called from archiveConversations");
    
    [self eraseSelectedConversation];
    
    ConversationsListViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([ConversationsListViewController class])];
    controller.conversations = self.conversations;
    controller.selectedConversations = [NSMutableSet setWithObject:conversation];
    controller.currentConversationsAction = ConversationsActionArchive;
    
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)pressDeleteButton:(Conversation *)conversation {
    DDLogSupport(@"Conversation Refresh Called from deleteConversations");
    
    [self eraseSelectedConversation];
    
    ConversationsListViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([ConversationsListViewController class])];
    controller.conversations = self.conversations;
    controller.selectedConversations = [NSMutableSet setWithObject:conversation];
    controller.currentConversationsAction = ConversationsActionDelete;
    
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark * UITableViewDataSource\UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger count = 0;
    
    [self showMainHeaderView:!self.isSearching withAnimation:YES];
    [self prepareNavigationBar];
    
    [self.content removeAllObjects];
    
    if (self.providerInformationKeyValuePairs.count > 0 && !self.isSearching)
        [self.content addObject:@(ContentTypeProvider)];
    
    if (self.moreInformationKeyValuePairs.count > 0 && !self.isSearching)
        [self.content addObject:@(ContentTypeMore)];
    
    if (self.actions.count > 0 && !self.isSearching)
        [self.content addObject:@(ContentTypeAction)];
    
    if (self.conversations.count > 0 && !self.isSearching)
        [self.content addObject:@(ContentTypeRecent)];
    
    if (self.groupUsers.count > 0)
        [self.content addObject:@(ContentTypeGroupUsers)];
    else if (self.contactType == DetailInfoContactTypePersonalGroup || self.contactType == DetailInfoContactTypeConversation || self.contactType == DetailInfoContactTypeCareChannel)
        [self.content addObject:@(ContentTypeGroupUsers)];
    
    if (self.memberNotesKeyValuePairs.count > 0) {
        [self.content addObject:@(ContentTypeOnCallNotes)];
    }
    
    count = self.content.count;
    
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    if (self.content.count > 0) {
        NSInteger contentType = [[self.content objectAtIndex:section] integerValue];
        
        switch (contentType)
        {
            case ContentTypeProvider:   count = self.providerInformationKeyValuePairs.count;    break;
            case ContentTypeMore:       count = self.moreInformationKeyValuePairs.count;        break;
            case ContentTypeAction:     count = self.actions.count;                             break;
            case ContentTypeGroupUsers: {
                
                if (self.isSearching) {
                    count = self.searchGroupUsers.count;
                }
                else {
                    count = self.groupUsers.count;
                }
                
                if (self.contactType == DetailInfoContactTypePersonalGroup && self.groupUsers.count == 0)
                {
                    count = 1;
                }
                
                break;
            }
            case ContentTypeRecent:     count = self.conversations.count;                       break;
            case ContentTypeOnCallNotes:count = self.memberNotesKeyValuePairs.count;           break;
            default: break;
        }
    }
    return count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = kValueHeightRowDefault;
    if (self.content.count > 0) {
        NSInteger contentType = [[self.content objectAtIndex:indexPath.section] integerValue];
        
        switch (contentType)
        {
            case ContentTypeProvider:
            case ContentTypeMore:
            {
                if (self.contactType == DetailInfoContactTypeCareChannel) {
                    height = kValueHeightRowDefaultInline;
                } else {
                    height = kValueHeightRowDefault;
                }
                break;
            }
            case ContentTypeAction:     height = kValueHeightRowAction;     break;
            case ContentTypeGroupUsers: height = kValueHeightRowContact;    break;
            case ContentTypeRecent:     height = kValueHeightRowRecent;     break;
            case ContentTypeOnCallNotes:
            {
                {
                    NSArray *keyValue = self.memberNotesKeyValuePairs[indexPath.row];
                    height = [DetailNotesTableViewCell getHeightForNotesCellWithContent:keyValue];
                }
                break;
            }
            default: break;
        }
    }
    
    return height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat height = 0;//kValueHeightForHeaderInSectionDefault;
    if (self.content.count > 0) {
        NSInteger contentType = [[self.content objectAtIndex:section] integerValue];
        
        switch (contentType)
        {
            case ContentTypeMore:
            case ContentTypeProvider:
            {
                if (self.contactType == DetailInfoContactTypeCareChannel || self.contactType == DetailInfoContactTypeFhirPatient) {
                    height = kValueHeightForHeaderInSectionDefault; break;
                }
                break;
            }
            case ContentTypeGroupUsers:
            case ContentTypeRecent:
            case ContentTypeOnCallNotes:
            {
                height = self.contactType != DetailInfoContactTypeOnCallDayNotes ? kValueHeightForHeaderInSectionDefault : 0;
                break;
            }
                
            default: break;
        }
    }
    return height;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    
    UIView *headerView = [[UIView alloc] init];
    if (self.content.count > 0) {
        NSString *titleHeader = @"";
        NSInteger contentType = [[self.content objectAtIndex:section] integerValue];
        
        switch (contentType)
        {
            case ContentTypeProvider:
            {
                if(self.contactType == DetailInfoContactTypeCareChannel) {
                    titleHeader = kContentCareChannelVisitInfo;
                } else if(self.contactType == DetailInfoContactTypeFhirPatient) {
                    titleHeader = QliqLocalizedString(@"3005-TitlePatientInfo");
                } else {
                    titleHeader = kContentProviderInformation;
                }
                break;
            }
            case ContentTypeMore:
            {
                if(self.contactType == DetailInfoContactTypeCareChannel) {
                    titleHeader = kContentLocation;
                } else {
                    titleHeader = kContentMoreInformation;
                }
                break;
            }
            case ContentTypeRecent:
            {
                if(self.contactType == DetailInfoContactTypeFhirPatient) {
                    titleHeader = kContentRecentCareChannels;
                } else {
                    titleHeader = kContentRecentConversation;
                }
                break;
            }
            case ContentTypeGroupUsers:
            {
                if(self.contactType == DetailInfoContactTypeCareChannel) {
                    titleHeader = kContentCareTeam;
                } else {
                    titleHeader = kContentContact;
                }
                break;
            }
            case ContentTypeOnCallNotes:
                titleHeader = kContentOnCallNotes;
                break;
            default: break;
        }
 
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 0, 300, kValueHeightForHeaderInSectionDefault)];
        headerLabel.backgroundColor = [UIColor clearColor];
        headerLabel.font            = [UIFont systemFontOfSize:14.f];
        headerLabel.textColor       = RGBa(3, 120, 173, 1);
        headerLabel.text            = titleHeader;
        if (headerLabel.text)
            headerView.backgroundColor = RGBa(235, 235, 235, 0.7f);
        [headerLabel sizeToFit];
        headerLabel.frame = CGRectMake(8, 0, headerLabel.frame.size.width, kValueHeightForHeaderInSectionDefault);
        [headerView addSubview:headerLabel];
        
        if (self.contactType == DetailInfoContactTypePersonalGroup && contentType == ContentTypeGroupUsers && self.groupUsers.count > 0) {
            UIButton *button = [[UIButton alloc] init];
            button.frame = CGRectMake(CGRectGetMaxX(headerLabel.frame), 0, 40.f, kValueHeightForHeaderInSectionDefault);
            button.backgroundColor = [UIColor clearColor];
            [button setTitle:@"+" forState:UIControlStateNormal];
            [button setTitleColor:RGBa(3, 120, 173, 1) forState:UIControlStateNormal];
            [button addTarget:self action:@selector(onEditContactsForPersonalGroup) forControlEvents:UIControlEventTouchUpInside];
            [headerView addSubview:button];
        }
        else if ((self.contactType == DetailInfoContactTypeConversation || self.contactType == DetailInfoContactTypeCareChannel) && contentType == ContentTypeGroupUsers)
        {
            UIButton *button = [[UIButton alloc] init];
            
            CGRect rect = CGRectMake(0.f, 0.f, 0.f, 0.f);
            CGRect bounds = [UIScreen mainScreen].bounds;
            
            if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                rect = CGRectMake(0, 0, MAX(bounds.size.height, bounds.size.width), MIN(bounds.size.height, bounds.size.width));
            } else if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
                rect = CGRectMake(0, 0, MIN(bounds.size.height, bounds.size.width), MAX(bounds.size.height, bounds.size.width));
            }
            
            button.frame = CGRectMake(rect.size.width - 50.f, 2.5f, 40.f, kValueHeightForHeaderInSectionDefault - 5.0f);
            button.backgroundColor = [UIColor clearColor];
            [button.titleLabel setFont:[UIFont systemFontOfSize:14.f]];
            [button setTitle:QliqLocalizedString(@"2365-TitleAdd") forState:UIControlStateNormal];
            // As it is leaking about 4 bytes per call.
//            [button setTitle:QliqLocalizedString(@"2365-TitleAdd") forState:UIControlStateHighlighted];
            [button setTitleColor:kColorDarkBlue forState:UIControlStateNormal];
            [button setTitleColor:kColorLightBlue forState:UIControlStateHighlighted];
            button.layer.borderWidth = 1.f;
            button.layer.borderColor = [kColorDarkBlue CGColor];
            button.layer.cornerRadius = 5.f;
            [button addTarget:self action:@selector(onAddButton) forControlEvents:UIControlEventTouchUpInside];
            [headerView addSubview:button];
        }
    }
    return headerView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.content.count > 0) {
        NSInteger contentType = [[self.content objectAtIndex:indexPath.section] integerValue];
        
        switch (contentType)
        {
            default:
            case ContentTypeProvider:
            case ContentTypeMore: {
                
                static NSString *reuseIdMore = @"NEW_DETAIL_CONTACT_INFO_CELL";
                DetailContactInfoCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdMore];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.delegate = self;
                cell.phoneButton.hidden = YES;
                cell.chatButton.hidden = YES;
                
                if (!self.isConstraintsForChatButtonChecked) {
                    
                    self.constantForChatButtonWidthConstraint = cell.chatButonWidthConstraint.constant;
                    self.constantForChatButtonLeadingConstraint = cell.chatButtonLeadingConstraint.constant;
                    
                    self.isConstraintsForChatButtonChecked = YES;
                }
                
                NSArray *keyValue = contentType == ContentTypeProvider ? self.providerInformationKeyValuePairs[indexPath.row] : self.moreInformationKeyValuePairs[indexPath.row];
                
                if (self.contactType == DetailInfoContactTypeCareChannel) {
                    cell.inlineTitle.text = keyValue[0];
                    cell.inlineTitle.hidden = NO;
                    cell.inlineInfo.text = keyValue[1];
                    cell.inlineInfo.hidden = NO;
                } else {
                    cell.title.text         = keyValue[0];
                    cell.title.hidden = NO;
                    cell.information.text   = keyValue[1];
                    cell.information.hidden = NO;
                }
                
                if ([cell.title.text isEqualToString:kKeyMobile] || [cell.title.text isEqualToString:kKeyPhone] )
                {
                    cell.phoneButton.hidden = NO;
                    
                    if (self.contactType != DetailInfoContactTypeContact) {
                        
                        cell.chatButton.hidden = NO;
                        
                        cell.chatButtonLeadingConstraint.constant = self.constantForChatButtonLeadingConstraint;
                        cell.chatButonWidthConstraint.constant = self.constantForChatButtonWidthConstraint;
                        
                    } else {
                        
                        cell.chatButonWidthConstraint.constant = 0;
                        cell.chatButtonLeadingConstraint.constant = 0;
                    }
                }
                else if ([cell.title.text isEqualToString:kKeyQliqId])
                {
                    QliqUser *user = self.contactType == DetailInfoContactTypeInvitation ? ((Invitation*)self.contact).contact : self.contact;
                    
                    if (!user.mobile.length && !user.phone.length)
                        cell.chatButton.hidden = NO;
                }
                
                if ([cell.title.text isEqualToString:kKeyPersonalGroup])
                {
                    cell.information.textColor  = [keyValue[1] isEqualToString:@""] ? [UIColor lightGrayColor] : [UIColor darkGrayColor];
                    cell.information.text       = [keyValue[1] isEqualToString:@""] ? QliqLocalizedString(@"2177-TitleAddPersonalGroup") : keyValue[1];
                }
                return cell;
                break;
            }
                
            case ContentTypeAction: {
                
                static NSString *reuseIdAction = @"ACTION_CELL";
                DetailContactInfoCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdAction];
                
                NSArray *keyValue = self.actions[indexPath.row];
                cell.title.text = keyValue[0];
                cell.title.hidden = NO;
                return cell;
                break;
            }
                
            case ContentTypeGroupUsers: {
                
                if (self.contactType == DetailInfoContactTypePersonalGroup && self.groupUsers.count == 0)
                {
                    static NSString *reuseIdPlus = @"PLUS_CELL_ID";
                    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdPlus];
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    return cell;
                }
                else
                {
                    static NSString *cellIdentifier = @"ContactTableViewCellReuseId";
                    
                    ContactTableCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
                    
                    if(!cell) {
                        UINib *nib = [UINib nibWithNibName:NSStringFromClass([ContactTableCell class]) bundle:nil];
                        
                        [tableView registerNib:nib forCellReuseIdentifier:cellIdentifier];
                        
                        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
                    }
                    
                    id contact = nil;
                    
                    if (self.isSearching) {
                        contact = [self.searchGroupUsers objectAtIndex:indexPath.row];
                    }
                    else {
                        contact = [self.groupUsers objectAtIndex:indexPath.row];
                    }
                    
                    contact = [[QliqAvatar sharedInstance] contactIsQliqUser:contact];
                    
                    cell.delegate = self;
                    [cell setCell:contact];
                    
                    if (self.contactType == DetailInfoContactTypeConversation || self.contactType == DetailInfoContactTypeCareChannel) {
                        [cell setRightArrowHidden:NO];
                        if (([self countOfGroupUsers] > 1 && !self.isSearching) || ([self countOfSearchGroupUsers] > 1 && self.isSearching)) {
                            [cell setRemoveButtonHidden:NO];
                        }
                    }
                    
                    return cell;
                }
                break;
            }
            case ContentTypeRecent: {
                
                static NSString *cellIdentifier = @"RecentTableViewCell_ID";
                
                RecentTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
                
                if(!cell) {
                    
                    UINib *nib = [UINib nibWithNibName:@"RecentTableViewCell" bundle:nil];
                    
                    [tableView registerNib:nib forCellReuseIdentifier:cellIdentifier];
                    
                    cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
                }
                
                cell.delegate = self;
                Conversation *conversation = nil;
                @synchronized(self) {
                    if (self.conversations.count > indexPath.row) {
                        conversation = self.conversations[indexPath.row];
                    }
                }
                
                if (conversation) {
                    [cell configureCellWithConversation:conversation withSelectedCell:self.selectedConversation];
                }
                return cell;
                
                break;
            }
            case ContentTypeOnCallNotes:
            {
                static NSString *reuseIdMore = @"ON_CALL_NOTES_CELL_REUSE_IDENTIFIER";
                DetailNotesTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdMore];
                NSArray *keyValue = self.memberNotesKeyValuePairs[indexPath.row];
                [cell configureNotesCell:cell forRowAtIndexPath:indexPath withContent:keyValue];
                return cell;
                break;
            }
        }
    }
    return [[UITableViewCell alloc] init];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger contentType = [[self.content objectAtIndex:indexPath.section] integerValue];
    
    switch (contentType)
    {
        case ContentTypeProvider: {
            /*
             NSArray *keyValue = self.providerInformationKeyValuePairs[indexPath.row];
             NSString *title = keyValue[0];
             NSString *value = keyValue[1];
             
             if ([title isEqualToString:@"Mobile"] || [title isEqualToString:@"Phone"] )
             {
             if ([value length] > 0)
             [self makeCall:value];
             }
             else if ([title isEqualToString:@"qliq ID"])
             {}
             */
            break;
        }
        case ContentTypeMore: {
            
            NSArray *keyValue = self.moreInformationKeyValuePairs[indexPath.row];
            NSString *title = keyValue[0];
            
            if ([title isEqualToString:kKeyPersonalGroup])
                [self addToListButtonPressed];
            break;
        }
        case ContentTypeAction: {
            
            NSArray *keyValue = self.actions[indexPath.row];
            NSString *title = keyValue[0];
            
            if ([title isEqualToString:kKeyInviteToQliq]) {
                [self didSelectInviteToQliq];
            }
            else if ([title isEqualToString:kKeyStartConversation]) {
                [self didSelectStartConversation];
            }
            else if ([title isEqualToString:kKeyStartCareChannel]) {
                [self didSelectStartCareChannel];
            }
            else if ([title isEqualToString:kKeyStartBroadcastConversation]) {
                [self didSelectStartBroadcastConversation];
            }
            else if ([title isEqualToString:kKeyStartGroupConversation]) {
                [self didSelectStartGroupConversation];
            }
            else if ([title isEqualToString:kKeyEdit]) {
                [self didSelectEdit];
            }
            else if ([title isEqualToString:kKeyDelete]) {
                [self didSelectDelete];
            }
            else if ([title isEqualToString:kKeyRemind]) {
                [self didSelectRemind];
            }
            else if ([title isEqualToString:kKeyCancel]) {
                [self didSelectCancel];
            }
            else if ([title isEqualToString:kKeyAccept]) {
                [self didSelectAccept];
            }
            else if ([title isEqualToString:kKeyDecline]) {
                [self didSelectDecline];
            }
            break;
        }
        case ContentTypeGroupUsers: {
            
            if (self.contactType == DetailInfoContactTypePersonalGroup && self.groupUsers.count == 0) {
                [self onEditContactsForPersonalGroup];
            }
            else {
                self.isContactPickerPushed = YES;
                
                id contact = nil;
                
                if (self.isSearching) {
                    contact = [self.searchGroupUsers objectAtIndex:indexPath.row];
                }
                else {
                    contact = [self.groupUsers objectAtIndex:indexPath.row];
                }
                
                contact = [[QliqAvatar sharedInstance] contactIsQliqUser:contact];
                
                if ([contact isKindOfClass:[QliqUser class]] && [((QliqUser *)contact).qliqId isEqualToString:[UserSessionService currentUserSession].user.qliqId]) {
                    
                    ProfileViewController *controller = [kSettingsStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([ProfileViewController class])];
                    [self.navigationController pushViewController:controller animated:YES];
                    
                } else {
                    
                    DetailContactInfoViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([DetailContactInfoViewController class])];
                    controller.contact = contact;
                    [self.navigationController pushViewController:controller animated:YES];
                }
            }
            break;
        }
        case ContentTypeRecent: {
            
            ConversationViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([ConversationViewController class])];
            controller.conversation = self.conversations[indexPath.row];
            controller.isCareChannelMode = self.contactType == DetailInfoContactTypeFhirPatient;
            [self.navigationController pushViewController:controller animated:YES];
            break;
        }
        default:
            break;
    }
    
    [self.tableView reloadData];
    [self.view endEditing:YES];
}

#pragma mark * UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.contentOffset.y <= -40)
    {
        if (!scrollView.isDecelerating && (self.contactType == DetailInfoContactTypePersonalGroup || self.contactType == DetailInfoContactTypeQliqGroup) && self.groupUsers.count > 0)
            [self showSearchBar:YES withAnimation:YES];
    }
    else if (scrollView.contentOffset.y > self.headerView.frame.size.height)
    {
        if (0 != self.searchBarHeightConstraint.constant && !self.isBlockScrollViewDelegate)
        {
            [self setTableViewContentOffsetY:self.tableView.contentOffset.y - 44.f withAnimation:NO];
            [self showSearchBar:NO withAnimation:NO];
        }
    }
    
    if (scrollView.contentOffset.y <= 0)
        self.isBlockScrollViewDelegate = NO;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if ([self headerViewIsShow])
    {
        if (scrollView.contentOffset.y >= 20 && scrollView.contentOffset.y < self.headerView.frame.size.height)
        {
            [self showSearchBar:NO withAnimation:YES];
            
            [self setTableViewContentOffsetY:self.headerView.frame.size.height withAnimation:YES];
        }
        else if (scrollView.contentOffset.y > 0 && scrollView.contentOffset.y < 20)
        {
            [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
        }
    }
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    [self eraseSelectedConversation];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self eraseSelectedConversation];
    
    if ([self.searchBar isFirstResponder]) {
        [self.searchBar resignFirstResponder];
    }
}

#pragma mark * ContactHeaderViewDelegate

- (void)favoritesButtonPressed
{
    
    __weak __block typeof(self) welf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        //Set Favorite
        {
            if ([welf.favoritesContactGroup containsContact:welf.contact])
                [welf.favoritesContactGroup removeContact:welf.contact];
            else
                [welf.favoritesContactGroup addContact:welf.contact];
        }
        
        //Set Favorite UI
        {
            dispatch_async_main(^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kUpdateContactsListNotificationName object:nil];
                [welf.contactHeaderView setContactIsFavorite:[welf.favoritesContactGroup containsContact:welf.contact]];
            });
        }
    });
}

- (void)changeAvatar
{
    if (self.contactType == DetailInfoContactTypeQliqUser)
    {
        if ([((QliqUser*)self.contact).qliqId isEqualToString:[Helper getMyQliqId]])
        {
            if ([self.contactHeaderView getAvatar])
            {
                UIActionSheet_Blocks *actionSheet = [[UIActionSheet_Blocks alloc] initWithTitle:NSLocalizedString(@"1116-TextChangeAvatar", nil)
                                                                              cancelButtonTitle:NSLocalizedString(@"4-ButtonCancel", nil)
                                                                         destructiveButtonTitle:NSLocalizedString(kRemoveAvatarTitle, nil)
                                                                              otherButtonTitles:NSLocalizedString(kCreateAvatarTitle, nil), nil];
                
                __block __weak typeof(self) weakSelf = self;
                [actionSheet showInView:self.view block:^(UIActionSheetAction action, NSUInteger buttonIndex) {
                    
                    if (action == UIActionSheetActionDidDissmiss)
                    {
                        if (buttonIndex != actionSheet.cancelButtonIndex)
                        {
                            NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
                            
                            if ([kCreateAvatarTitle isEqualToString:title])
                            {
                                [weakSelf.imageCaptureController captureImage];
                            }
                            else if ([kRemoveAvatarTitle isEqualToString:title])
                            {
                                AvatarUploadService *setAvatarService = [[AvatarUploadService alloc] initWithAvatar:nil forUser:(QliqUser *)weakSelf.contact];
                                [setAvatarService callServiceWithCompletition:^(CompletitionStatus status, id result, NSError *error) {
                                    
                                    [weakSelf.contactHeaderView fillWithContact:weakSelf.contact];
                                }];
                            }
                        }
                    }
                }];
            }
            else
            {
                [self.imageCaptureController captureImage];
            }
        }
    }
}

- (void)headerWasTapped {
    
    if (self.contactType == DetailInfoContactTypeCareChannel) {
        if (((Conversation *)self.contact).encounter.patient) {
            
            self.isContactPickerPushed = YES;
            
            DetailContactInfoViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([DetailContactInfoViewController class])];
            controller.contact = ((Conversation *)self.contact).encounter.patient;
            controller.backButtonTitleString = QliqLocalizedString(@"2348-TitleCareChannelInfo");
            
            [self.navigationController pushViewController:controller animated:YES];
        } else {
            
            DDLogSupport(@"\n\n\nonPatientInfo: Patient is nil\n\n\n");
            
        }
        
    }
}

#pragma mark * ImageCaptureControllerDelegate

- (void)presentImageCaptureController:(UIViewController *)controller {
    [self.navigationController presentViewController:controller animated:YES completion:nil];
}

- (void)imageCaptured:(UIImage *)image withController:(UIViewController *)contorller {
    __block __weak typeof(self) weakSelf = self;
    
    [self dismissViewControllerAnimated:YES completion:nil];
    AvatarUploadService *setAvatarService = [[AvatarUploadService alloc] initWithAvatar:image forUser:(QliqUser *)self.contact];
    [setAvatarService callServiceWithCompletition:^(CompletitionStatus status, id result, NSError *error) {
        
        [weakSelf.contactHeaderView fillWithContact:self.contact];
    }];
}

- (void)imageCaptureControllerCanceled:(UIViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark * ContactsCellDelegate

- (void)changeParticipant:(id)participant withRole:(NSString *)role fromCell:(ContactTableCell *)cell {
    if (participant) {
        if ([self.groupUsers containsObject:participant]) {
            if (role && ![role isEqualToString:[self.roles valueForKey:((QliqUser *)participant).qliqId]]) {
                [self.roles willChangeValueForKey:@"description"];
                [self.roles setObject:role forKey:((QliqUser *)participant).qliqId];
                [self.roles didChangeValueForKey:@"description"];
            }
        }
    }
}

- (NSString *)getRoleForCareChannelWithUser:(QliqUser *)participant {
    NSString *role = @"";
    
    if ([self.roles valueForKey:participant.qliqId]) {
        role = [self.roles valueForKey:participant.qliqId];
    }
    
    return role;
}

- (BOOL)isCareChannel {
    return self.contactType == DetailInfoContactTypeCareChannel;
}

- (void)removeContactButtonPressed:(id)contact {
    
    if (self.isSearching) {
        [self removeObjectFromSearchGroupUsersArray:contact];
    }
    [self removeObjectFromGroupUsersArray:contact];
    
    [self.tableView reloadData];
    
}

- (void)indexOfActiveCell:(ContactTableCell *)cell {
    
    NSIndexPath *indxPh = [self.tableView indexPathForCell:cell];
    if (indxPh)
        self.indexPathForActiveCell = indxPh;
    else
        self.indexPathForActiveCell = [NSIndexPath indexPathForRow:0 inSection:0];
}

#pragma mark * DetailContactInfoDelegate

- (void)onPhoneButton:(NSString *)calleePhoneNumber
{
    CallAlertService *callAlertService = [self getCallAlertService];
    [callAlertService phoneNumberWasSelectedForAction:calleePhoneNumber];
}

- (void)onMessageButton
{
    [self startConversationWithItem:self.contactType == DetailInfoContactTypeInvitation ? ((Invitation*)self.contact).contact : self.contact];
}

#pragma mark * UISearchBarDelegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self doSearchWithText:searchText];
}

- (void)doSearchWithText:(NSString*)searchText
{
    [self.searchOperationsQueue cancelAllOperations];
    
    NSArray *tempSearchArray = [self.groupUsers copy];
    
    [self.searchGroupUsers removeAllObjects];
    
    SearchOperation *searchContactsOperation = [[SearchOperation alloc] initWithArray:tempSearchArray andSearchString:searchText withPrioritizedAlphabetically:NO];
    searchContactsOperation.delegate = self;
    searchContactsOperation.batchSize = 0;
    
    self.isSearching = searchContactsOperation.isPredicateCorrect;
    
    if (!self.isSearching) {
        [self.tableView reloadData];
    }
    
    if (searchContactsOperation.isPredicateCorrect)
        [self.searchOperationsQueue addOperation:searchContactsOperation];
}

#pragma mark * SearchOperationDelegate

- (void)searchOperation:(SearchOperation *)operation didFoundResults:(NSArray *)array
{
    [self receivedResultFromSearch:array];
}

- (void)receivedResultFromSearch:(NSArray *)results
{
    __block __weak typeof(self) weakSelf = self;
    dispatch_async_main(^{
        
        @synchronized(self) {
            [weakSelf.searchGroupUsers removeAllObjects];
            [weakSelf.searchGroupUsers addObjectsFromArray:results];
        }
        
        [weakSelf.tableView reloadData];
    });
}

#pragma mark * Edit Care Team Delegate

-(void)editDoneWithCareTeam:(NSMutableArray *)careTeam withRoles:(NSDictionary *)participantsRoles {
    if (self.delegate && [self.delegate respondsToSelector:@selector(editDoneFromCareChannelInfo:withRoles:withCompletion:)]) {
        __weak typeof(self) weakSelf = self;
        [self.delegate editDoneFromCareChannelInfo:careTeam withRoles:participantsRoles withCompletion:^{
            [weakSelf onBack:nil];
        }];
    }
}

#pragma mark * SelectContactsViewControllerDelegate

- (void)didSelectRecipient:(id)contact {
    
    [self updateRecipients:@[contact]];
}

- (void)didSelectedParticipants:(NSMutableArray *)participants {
    
    [self updateRecipients:participants];
}

- (void)updateRecipients:(NSArray *)newRecipeints {
    
    for (id contact in newRecipeints) {
        
        BOOL isGroup = [contact isKindOfClass:[QliqGroup class]];
        
        if (isGroup) {
            
            if (self.isSearching) {
                [self removeAllObjectsFromSearchGroupUsersArray];
                [self addObjectToSearchGroupUsersArray:contact];
            }
            
            [self removeAllObjectsFromGroupUsersArray];
            [self addObjectToGroupUsersArray:contact];
            
            self.isGroupConversation = isGroup;
            
            [self.tableView reloadData];
            self.indexPathForActiveCell = [NSIndexPath indexPathForRow:0 inSection:0];
            
        } else if (!isGroup) {
            
            if ([self.groupUsers.firstObject isKindOfClass:[QliqGroup class]]) {
                
                if (self.isSearching) {
                    [self removeAllObjectsFromSearchGroupUsersArray];
                    [self addObjectToSearchGroupUsersArray:contact];
                }
                
                [self removeAllObjectsFromGroupUsersArray];
                [self addObjectToGroupUsersArray:contact];
                
                self.isGroupConversation = isGroup;
            } else {
                if (self.isSearching) {
                    if (![self.searchGroupUsers containsObject:contact]) {
                        [self addObjectToSearchGroupUsersArray:contact];
                    }
                }
                
                if (![self.groupUsers containsObject:contact]) {
                    [self addObjectToGroupUsersArray:contact];
                }
            }
            
            [self.tableView reloadData];
            self.indexPathForActiveCell = [NSIndexPath indexPathForRow:0 inSection:0];
        }
    }
}

#pragma mark * UITextField Delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *subject = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    self.subject = subject;
    
    return YES;
}

@end
