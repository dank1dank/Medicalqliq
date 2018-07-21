//
//  SettingsPresenceViewController.m
//  qliq
//
//  Created by Valeriy Lider on 18.12.14.
//
//

#import "SettingsPresenceViewController.h"
#import "SettingsPresenceTableViewCell.h"
#import "PresenceEditView.h"
#import "QliqConnectModule.h"
#import "SetPresenceStatusService.h"
#import "NotificationUtils.h"
#import "QliqGroupDBService.h"
#import "QliqJsonSchemaHeader.h"
#import "UpdateGroupMembershipService.h"
#import "SelectContactsViewController.h"

#define kCellHeightWithPresenceEditView 200.f
#define kCellHeightWithPresenseEditViewForwarding 262.f

#define kRescheduleChimeNotifications @"RescheduleChimeNotifications"

#define kCheckedImage    [UIImage imageNamed:@"ConversationChecked"]
#define kUncheckedImage  [UIImage imageNamed:@"ConversationUnChecked"]
typedef enum : NSInteger {
    CellTypeOnline,
    CellTypeDND,
    CellTypeAway
    //    CellTypeButtons
}
PresenceCellType;

static BOOL s_needToWaitNotify = NO;

@interface SettingsPresenceViewController ()
<
UITableViewDataSource,
UITableViewDelegate,
SettingsPresenceCellDelegate,
PresenceEditViewDelegate,
SelectContactsViewControllerDelegate
>

@property (weak, nonatomic) IBOutlet UILabel *navigationLeftTitleLabel;


@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *verticalSpaceTableView;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;

@property (nonatomic, strong) NSString * currentPresenceType;
@property (nonatomic, strong) PresenceSettings *presenceSettings;
@property (nonatomic, strong) PresenceEditView *presenceEditView;

@property (nonatomic, strong) NSMutableArray *content;
@property (nonatomic, assign) CGFloat heghtCellWithPresenceEditView;

@end

@implementation SettingsPresenceViewController

- (void)configureDefaultText {
    self.navigationLeftTitleLabel.text = QliqLocalizedString(@"2025-TitlePresence");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureDefaultText];
    
    [self updateContent];
    
    self.heghtCellWithPresenceEditView = kCellHeightWithPresenceEditView;
    
    //Presence
    {
        /**
         Get Current currentUserSession (Online, Away or Do Not Distrub
         */
        self.presenceSettings = [UserSessionService currentUserSession].userSettings.presenceSettings;
        
        
        self.currentPresenceType = self.presenceSettings.currentPresenceType;
    }
    
    //TableView
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    //Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(presenceChangedNotification:)
                                                 name:PresenceChangeStatusNotification object:nil];
    
    [self addKeyboardNotifications];
    
    self.saveButton.layer.cornerRadius = 3;
    self.saveButton.layer.masksToBounds = YES;
    [self.saveButton setTitle:QliqLocalizedString(@"44-ButtonSave") forState:UIControlStateNormal];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    self.heghtCellWithPresenceEditView = kCellHeightWithPresenceEditView;
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    self.navigationLeftTitleLabel = nil;
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.tableView = nil;
    self.verticalSpaceTableView = nil;
    self.saveButton = nil;
    self.currentPresenceType = nil;
    self.presenceSettings = nil;
    self.presenceEditView = nil;
    self.content = nil;
    
    [self removeKeyboardNotifications];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Notifications

- (void)presenceChangedNotification:(NSNotification *)notification
{
    if ([notification.userInfo[@"isForMyself"] boolValue] == YES)
    {
        DDLogSupport(@"Get Current User Session State");
        self.presenceSettings = [UserSessionService currentUserSession].userSettings.presenceSettings;
        self.currentPresenceType = self.presenceSettings.currentPresenceType;
        
        __weak __block typeof(self) weakSelf = self;
        dispatch_async_main(^{
            [weakSelf.tableView reloadData];
        });
    }
}

- (void)addKeyboardNotifications
{
    DDLogSupport(@"Adding Keyboard Notifications");
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWasShown:)
                                                     name:UIKeyboardDidShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillBeHidden:)
                                                     name:UIKeyboardWillHideNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillBeShown:)
                                                     name:UIKeyboardWillShowNotification object:nil];
    }
}

- (void)removeKeyboardNotifications
{
    DDLogSupport(@"Removing Keyboard Notifications");
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    }
}

#pragma mark - Keyboard

- (void)keyboardWasShown:(NSNotification*)aNotification
{
    //    NSDictionary *info = [aNotification userInfo];
    //    CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
}

- (void)keyboardWillBeShown:(NSNotification *)notification
{
    UIViewAnimationCurve curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
    UIViewAnimationOptions options = (curve << 16) | UIViewAnimationOptionBeginFromCurrentState;
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    CGSize keyboardSize = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    
    [UIView animateWithDuration:duration delay:0.0 options:options animations:^{
        self.verticalSpaceTableView.constant = keyboardSize.height;        
        [self.view layoutIfNeeded];
        [self setRowSettings];
    } completion:nil];
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIViewAnimationCurve curve = [aNotification.userInfo[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
    UIViewAnimationOptions options = (curve << 16) | UIViewAnimationOptionBeginFromCurrentState;
    NSTimeInterval duration = [aNotification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:duration delay:0.0 options:options animations:^{
        
        self.verticalSpaceTableView.constant = 0.f;
        [self.tableView reloadData];
        [self.view layoutIfNeeded];
        
    } completion:nil];
}

#pragma mark - Private methods

- (void)updateContent
{
    if (!self.content)
        self.content = [NSMutableArray new];
    
    [self.content removeAllObjects];
    
    [self.content addObject:@(CellTypeOnline)];
    [self.content addObject:@(CellTypeDND)];
    [self.content addObject:@(CellTypeAway)];
    //    [self.content addObject:@(CellTypeButtons)];
}

/**
 Get Index in Table View With Current Showing PresenceEditView
 */

- (NSInteger)getIndexForScroll:(BOOL)forScrool
{
    NSInteger count = 0;
    
    if (forScrool)
        count = 0;
    else
        count = 100;
    
    for ( int i = 0; i < self.content.count; i++)
    {
        PresenceCellType type = [[self.content objectAtIndex:i] integerValue];
        
        
        switch (type)
        {
            case CellTypeAway: {
                
                if ([self.currentPresenceType isEqualToString:PresenceTypeAway])
                    
                    return i;
                break;
            }
            default:
                break;
        }
    }
    return count;
}

- (void)setRowSettings
{
    NSInteger count = [self getIndexForScroll:YES];
    
    if (count > 2) {
        count = 2;
    }
    
    SettingsPresenceTableViewCell *cell = (SettingsPresenceTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:count inSection:0]];
    
    if ([cell.presenceEditView.forwardingUserTextField isFirstResponder])
        self.heghtCellWithPresenceEditView = kCellHeightWithPresenseEditViewForwarding;
    
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:count inSection:0]
                          atScrollPosition:UITableViewScrollPositionBottom animated:NO];
}

#pragma mark - Inner Logic

- (void)saveSettingsWithCurrentPresenceType:(NSString *)currentPresenceTypeString firstTime:(BOOL)firstTime withBlock:(VoidBlock)block
{
    
    DDLogSupport(@"Try to update presence status");
    
    
        PresenceSettings *presenceSettings = [UserSessionService currentUserSession].userSettings.presenceSettings;
        Presence *currentPresence = [presenceSettings presenceForType:currentPresenceTypeString];
        SetPresenceStatusService *presenceService = [[SetPresenceStatusService alloc] initWithPresence:currentPresence ofType:currentPresenceTypeString];
    
        __weak __block typeof(self) welf = self;
        [presenceService callServiceWithCompletition:^(CompletitionStatus status, id result, NSError *error)
         {
             if (status == CompletitionStatusSuccess)
             {
                 presenceSettings.currentPresenceType = currentPresenceTypeString;
                 Presence * presenceInSettings = [presenceSettings presenceForType:currentPresenceTypeString];
                 presenceInSettings.message = currentPresence.message;
                 presenceInSettings.forwardingUser = currentPresence.forwardingUser;
            
                 [[UserSessionService currentUserSession].userSettings write];
                 
                 [NSNotificationCenter postNotificationToMainThread:kRescheduleChimeNotifications];
                 
                 DDLogSupport(@"Presence set to %@", presenceSettings.currentPresenceType);
                 [self saveAlertShow];
                 
                 s_needToWaitNotify = NO;
             }
             else if (status == CompletitionStatusError)
             {
                 s_needToWaitNotify = YES;
                 
                 if (firstTime && error)
                 {
                     performBlockInMainThreadSync(^{
                         [welf errorAlertShow:error];
                     });
                 }
                 
                 DDLogError(@"Error during setting presence: %@",[error localizedDescription]);
                 [NSNotificationCenter  notifyOnceForNotification:kReachabilityChangedNotification usingBlock:^(NSNotification *note) {
                     DDLogSupport(@"Notified about reachability change. Trying to update Presence status");
                     if (![presenceSettings.currentPresenceType isEqualToString:currentPresenceTypeString] && s_needToWaitNotify)
                     {
                         [welf saveSettingsWithCurrentPresenceType:currentPresenceTypeString firstTime:NO withBlock:^{
                             if (block) {
                                 block();
                             }
                         }];
                     }
                     else
                     {
                         DDLogSupport(@"Presence status is already updated");
                     }
                 }];
             }

             performBlockInMainThreadSync(^{
                 if ([SVProgressHUD isVisible]) {
                     [SVProgressHUD dismiss];
                 }
             });
             
             if (block)
                 block();
         }];
}

#pragma mark - IBActions

- (IBAction)onBack:(id)sender
{
    if ([self.navigationController.topViewController isKindOfClass:[SettingsPresenceViewController class]]) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}


- (IBAction)onSave:(id)sender {
    
    /**
     Save settings and call service only when something changed
     */
    DDLogSupport(@"onSave");
    
    __weak __block typeof(self) welf = self;
    [self saveSettingsWithCurrentPresenceType:self.currentPresenceType
                                                              firstTime:YES
                                                              withBlock:^{
                                                                  welf.currentPresenceType = welf.presenceSettings.currentPresenceType;
                                                                  performBlockInMainThread(^{
                                                                      [welf.tableView reloadData];
                                                                  });
                                                              }];
    performBlockInMainThreadSync(^{
        [SVProgressHUD showWithStatus:QliqLocalizedString(@"2385-TitleUpdatingOfPresenceStatus")
                             maskType:SVProgressHUDMaskTypeClear
                   dismissButtonTitle:QliqLocalizedString(@"4-ButtonCancel")];
        
    });
}

- (void)saveAlertShow {
    
    NSString *statusPresence = @"";
    
    if([[UserSessionService currentUserSession].userSettings.presenceSettings.currentPresenceType isEqualToString:PresenceTypeOnline]) {
        
        statusPresence = QliqLocalizedString(@"2050-TitleOnline#presenceType");
    }
    else if([[UserSessionService currentUserSession].userSettings.presenceSettings.currentPresenceType isEqualToString:PresenceTypeDoNotDisturb]) {
        
        statusPresence = QliqLocalizedString(@"2051-TitleDnD#presenceType");
    }
    else if ([[UserSessionService currentUserSession].userSettings.presenceSettings.currentPresenceType isEqualToString:PresenceTypeAway]){
        
        statusPresence = QliqLocalizedString(@"2052-TitleAway#presenceType");
    }
    
    NSString * alertMessage = QliqFormatLocalizedString1(@"1219-TextYourPresenceIsNow{PresenceCurrentType}", statusPresence);

    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:nil message:alertMessage preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"1-ButtonOk", nil) style:UIAlertActionStyleCancel handler:nil];
    [alertView addAction:ok];
    [self presentViewController:alertView animated:YES completion:nil];
}

- (void)errorAlertShow:(NSError *)error {
    
    NSString *alertTitle = QliqLocalizedString(@"2384-TitlePresenceStatusUpdateFailed");
    
    NSString * alertMessage = QliqFormatLocalizedString1(@"2383-Reason:{reason}", [error localizedDescription]);

    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:alertTitle message:alertMessage preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"1-ButtonOk", nil) style:UIAlertActionStyleCancel handler:nil];
    [alertView addAction:ok];
    [self presentViewController:alertView animated:YES completion:nil];
}


#pragma mark - Delegates

#pragma mark - UITableViewDataSource\Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger count = 1;
    return count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = 44.f;
    NSInteger index = [self getIndexForScroll:NO];
    
    if (indexPath.row == index)
        height = self.heghtCellWithPresenceEditView;
    
    if (indexPath.row == index && indexPath.row == 1)
        height = 130.f;
    
    return height;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    
    if (self.content.count > 0)
        count = self.content.count;
    
    return count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SettingsPresenceTableViewCell *cell = nil;
    
//     static NSString *reuseId1 = @"PRESENCE_SETTINGS_CELL_ID";
     //    NSString *reuseId2 = @"PRESENCE_SETTINGS_BUTTONS_CELL_ID";
     cell = [tableView dequeueReusableCellWithIdentifier:@"PRESENCE_SETTINGS_CELL_ID"];
    
    NSInteger contentType = [[self.content objectAtIndex:indexPath.row] integerValue];
    
    //Add initialization 'UIImage' to define. As it is leaking about 15 bytes per call.
//    UIImage *checkedImage = [UIImage imageNamed:@"ConversationChecked"];
//    UIImage *uncheckedImage = [UIImage imageNamed:@"ConversationUnChecked"];
    
    switch (contentType)
    {
        default:
        case CellTypeOnline: {
            
            cell.titleLabel.text = QliqLocalizedString(@"2050-TitleOnline#presenceType");
            
            if ([self.currentPresenceType isEqualToString:PresenceTypeOnline]) {
                [cell.checkBoxButton setImage:kCheckedImage forState:UIControlStateNormal];
            }
            else {
                [cell.checkBoxButton setImage:kUncheckedImage forState:UIControlStateNormal];
            }
            break;
        }
        case CellTypeDND: {
            
            cell.titleLabel.text = QliqLocalizedString(@"2051-TitleDnD#presenceType");
            
            //            cell.presenceEditView.delegate  = self;
            //            cell.presenceEditView.forwardingUserTextField.hidden = YES;
            //            [cell.presenceEditView setType:PresenceTypeDoNotDisturb];
            //            [cell.presenceEditView setPresence:[self.presenceSettings presenceForType:PresenceTypeDoNotDisturb]];
            
            
            if ([self.currentPresenceType isEqualToString:PresenceTypeDoNotDisturb])
            {
                [cell.checkBoxButton setImage:kCheckedImage forState:UIControlStateNormal];
            }
            else {
                [cell.checkBoxButton setImage:kUncheckedImage forState:UIControlStateNormal];
            }
            break;
        }
        case CellTypeAway: {
            
            cell.titleLabel.text =  QliqLocalizedString(@"2052-TitleAway#presenceType");
            cell.presenceEditView.delegate  = self;
            [cell.presenceEditView setType:PresenceTypeAway];
            [cell.presenceEditView setPresence:[self.presenceSettings presenceForType:PresenceTypeAway]];
            
            if ([self.currentPresenceType isEqualToString:PresenceTypeAway])
            {
                [cell.checkBoxButton setImage:kCheckedImage forState:UIControlStateNormal];
                cell.presenceEditView.hidden = NO;
            }
            else {
                [cell.checkBoxButton setImage:kUncheckedImage forState:UIControlStateNormal];
            }
            
            break;
        }
            /*
             case CellTypeButtons: {
             
             cell = [tableView dequeueReusableCellWithIdentifier:reuseId2];
             
             [cell.leftButton setTitle:QliqLocalizedString(@"2026-TitleJoinGroup") forState:UIControlStateNormal];
             
             [cell.rightButton setTitle:QliqLocalizedString(@"2027-TitleLeaveGroup") forState:UIControlStateNormal];
             
             break;
             }
             */
    }
    
//    uncheckedImage = nil;
//    checkedImage = nil;
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [cell reloadInputViews];
    cell.delegate = self;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger contentType = [[self.content objectAtIndex:indexPath.row] integerValue];
    
    switch (contentType)
    {
        case CellTypeOnline: {
            self.currentPresenceType = PresenceTypeOnline;
            break;
        }
        case CellTypeDND: {
            
            
            self.currentPresenceType = PresenceTypeDoNotDisturb;
            break;
        }
        case CellTypeAway: {
            
            self.currentPresenceType = PresenceTypeAway;
            break;
        }
        default:
            break;
    }

    self.heghtCellWithPresenceEditView = kCellHeightWithPresenceEditView;
    [self.tableView reloadData];
}

#pragma mark - SettingsPresenceCellDelegate

- (void)joinGroupWasPressed
{
    //    JoinLeaveGroupViewController *controller = [kDefaultStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([JoinLeaveGroupViewController class])];
    //    controller.delegate             = self;
    //    controller.cells                = [self cellsForJoinLeaveWithSelectedItem:[[QliqGroupDBService sharedService] getJoinGroups]];
    //    controller.multipleSelection    = YES;
    //    controller.saveButtonTitle      = @"Join";
    //
    //    [self.navigationController pushViewController:controller animated:YES];
}

- (void)leaveGroupWasPressed
{
    //    JoinLeaveGroupViewController *controller = [kDefaultStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([JoinLeaveGroupViewController class])];
    //    controller.delegate             = self;
    //    controller.cells                = [self cellsForJoinLeaveWithSelectedItem:[[QliqGroupDBService sharedService] getLeaveGroups]];
    //    controller.multipleSelection    = YES;
    //    controller.saveButtonTitle      = @"Leave";
    //
    //    [self.navigationController pushViewController:controller animated:YES];
}

- (NSMutableDictionary*)cellsForJoinLeaveWithSelectedItem:(NSArray *)itemsArray
{
    NSMutableDictionary *selectGroupCells = [[NSMutableDictionary alloc] init];
    NSMutableArray *sections = [[NSMutableArray alloc] init];
    int section_counter = 0;
    NSInteger num_sections = 1;
    
    for(int i = 0; i<num_sections; i++)
    {
        NSMutableDictionary *sectionDict = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *headerCell = [[NSMutableDictionary alloc] init];
        
        [headerCell setObject:@"Select all" forKey:@"title"];
        [sectionDict setObject:headerCell forKey:@"header"];
        
        NSMutableArray *cells = [[NSMutableArray alloc] init];
        int row_counter = 0;
        
        NSInteger num_rows = [itemsArray count];
        
        for(int j = 0; j<num_rows; j++)
        {
            QliqGroup *group = [itemsArray objectAtIndex:j];
            NSMutableDictionary *cellDict = [[NSMutableDictionary alloc] init];
            
            NSString *cellText = [NSString stringWithFormat:@"%@", group.name];
            NSString *cellDetailText = nil;
            
            if( group.parentQliqId != nil )
            {
                QliqGroup *parentGroup = [[QliqGroupDBService sharedService] getGroupWithId:group.parentQliqId];
                cellDetailText = parentGroup.name;
            }
            
            if (cellText)
                [cellDict setObject:cellText forKey:@"title"];
            
            if (cellDetailText)
                [cellDict setObject:cellDetailText forKey:@"description"];
            
            if([group.name isEqualToString:@"Oncall"])
                [cellDict setObject:[NSNumber numberWithBool:YES] forKey:@"selected"];
            else
                [cellDict setObject:[NSNumber numberWithBool:NO] forKey:@"selected"];
            
            [cellDict setObject:group forKey:@"item"];
            [cells addObject:cellDict];
            
            row_counter ++;
        }
        
        [sectionDict setObject:cells forKey:@"cells"];
        [sections addObject:sectionDict];
        
        section_counter ++;
    }
    
    [selectGroupCells setObject:sections forKey:@"sections"];
    
    return selectGroupCells;
}

#pragma mark - PresenceEditView Delegate methods

- (void)addRecipientWithView:(id)view
{
    self.presenceEditView = view;
    
    SelectContactsViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([SelectContactsViewController class])];
    controller.typeController = STForForwarding;
    controller.delegate = self;
    
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)presenceEditViewDidBeginEdit:(PresenceEditView *)editView
{
    self.heghtCellWithPresenceEditView = kCellHeightWithPresenseEditViewForwarding;
    [self.tableView reloadData];
    
    NSInteger index = [self getIndexForScroll:YES];
    SettingsPresenceTableViewCell *cell = (SettingsPresenceTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    
    [cell.presenceEditView.forwardingUserTextField becomeFirstResponder];
}

- (void)presenceEditViewDidEndEdit:(PresenceEditView *)editView
{
    [self.tableView reloadData];
}

- (void)presenceEditView:(PresenceEditView *)editView didPressedCancelButton:(QliqButton *)button{
    
}

- (void)presenceEditView:(PresenceEditView *)editView didPressedDoneButton:(QliqButton *)button{
    
}

#pragma mark - SelectContactsViewController Delegate

- (void)didSelectRecipient:(id)contact
{
    [self.presenceEditView selectedRecipient:contact];
}

@end
