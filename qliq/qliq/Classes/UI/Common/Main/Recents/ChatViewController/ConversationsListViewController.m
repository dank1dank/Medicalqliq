//
//  ConversationsListViewController.m
//  qliq
//
//  Created by Valerii Lider on 10/08/15.
//
//

#import "ConversationsListViewController.h"
#import "ConversationsListTableViewCell.h"

#import "ConversationDBService.h"
#import "Conversation.h"

@interface ConversationsListViewController () <UITabBarDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet UIButton *selectAllButton;
@property (weak, nonatomic) IBOutlet UIButton *actionButton;

@end

@implementation ConversationsListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (!self.selectedConversations) {
        self.selectedConversations = [NSMutableSet new];
    }
    
    [self.selectAllButton setTitle:QliqLocalizedString(@"51-ButtonSelectAll") forState:UIControlStateNormal];
    self.currentConversationsAction = self.currentConversationsAction;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO];
    [self.navigationController.navigationBar setTranslucent:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.navigationController setNavigationBarHidden:YES];
    [self.view endEditing:YES];
    self.view.window.backgroundColor = [UIColor whiteColor];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private -

- (void)setCurrentConversationsAction:(ConversationsAction)currentConversationsAction {
    
    switch (currentConversationsAction) {
        case ConversationsActionDelete: {
            [self.actionButton setTitle:QliqLocalizedString(@"1046-TextDelete") forState:UIControlStateNormal];
            self.titleLabel.text = QliqLocalizedString(@"2183-TitleDeleteConversations");
            break;
        }
        case ConversationsActionArchive: {
            [self.actionButton setTitle:QliqLocalizedString(@"2015-TitleArchive") forState:UIControlStateNormal];
            self.titleLabel.text = QliqLocalizedString(@"2184-TitleArchiveConversations");
            break;
        }
        case ConversationsActionRestore: {
            [self.actionButton setTitle:QliqLocalizedString(@"53-ButtonRestore") forState:UIControlStateNormal];
            self.titleLabel.text = QliqLocalizedString(@"2185-TitleRestoreConversations");
            break;
        }
        default:
            break;
    }
    
    _currentConversationsAction = currentConversationsAction;
}

- (void)configureSelectAllButtonTitle
{
    __block BOOL isSelectAll = YES;
    if (self.selectedConversations.count == self.conversations.count)
    {
        isSelectAll = NO;
        NSSet *selectedMessagesSet = self.selectedConversations;
        [self.conversations enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (![selectedMessagesSet containsObject:obj])
            {
                isSelectAll = YES;
                *stop = YES;
            }
        }];
    }
    
    if (isSelectAll)
    {
        [self.selectAllButton setTitle:QliqLocalizedString(@"51-ButtonSelectAll") forState:UIControlStateNormal];
    }
    else
    {
        [self.selectAllButton setTitle:QliqLocalizedString(@"52-ButtonDeselectAll") forState:UIControlStateNormal];
    }
}


#pragma mark - Actions -

#pragma mark * IBAction

- (IBAction)onBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onSelectAllButton:(id)sender {
    
    if (self.conversations.count == self.selectedConversations.count) {
        [self.selectedConversations removeAllObjects];
        [self.selectAllButton setTitle:QliqLocalizedString(@"51-ButtonSelectAll") forState:UIControlStateNormal];
    }
    else {
        [self.selectedConversations addObjectsFromArray:self.conversations];
        [self.selectAllButton setTitle:QliqLocalizedString(@"52-ButtonDeselectAll") forState:UIControlStateNormal];
    }
    
    [self.tableView reloadData];
}

- (IBAction)onActionButton:(id)sender {
    ConversationsAction currentConversationsAction = self.currentConversationsAction;
    
    BOOL canAction = NO;
    
    switch (currentConversationsAction)
    {
        case ConversationsActionDelete: {
            
            __block __weak typeof(self) weakSelf = self;
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:QliqLocalizedString(@"1046-TextDelete")
                                                                           message:QliqLocalizedString(@"1048-TextAskDeleteConversations")
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *noAction = [UIAlertAction actionWithTitle:QliqLocalizedString(@"2-ButtonNO")
                                                               style:UIAlertActionStyleDefault
                                                             handler:nil];
            
            UIAlertAction *yesAction = [UIAlertAction actionWithTitle:QliqLocalizedString(@"3-ButtonYES")
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * _Nonnull action) {
                                                                  DDLogSupport(@"Deleting selected conversations: %lu", (unsigned long)self.selectedConversations.count);
                                                                  [[ConversationDBService sharedService] deleteConversations:[self.selectedConversations allObjects]];
                                                                  
                                                                  //Need to send Notification with deleted conversations and update conversations array in Recents Menu
                                                                  NSDictionary *info = @{@"DeletedConversations": [self.selectedConversations allObjects]};
                                                                  [[NSNotificationCenter defaultCenter] postNotificationName:kConversationsListDidPressDeleteButtonNotification object:nil userInfo:info];
                                                                  
                                                                  //                    [[NSNotificationCenter defaultCenter] postNotificationName:kConversationsListDidPressActionButtonNotification object:nil];
                                                                  [weakSelf.navigationController popViewControllerAnimated:YES];
                                                              }];
            
            [alert addAction:noAction];
            [alert addAction:yesAction];
            [self presentViewController:alert animated:YES completion:nil];
            
//                    [[NSNotificationCenter defaultCenter] postNotificationName:kConversationsListDidPressActionButtonNotification object:nil];

            break;
        }
        case ConversationsActionArchive: {
            DDLogSupport(@"Archive selected conversations: %lu", (unsigned long)self.selectedConversations.count);
            [[ConversationDBService sharedService] archiveConversations:[self.selectedConversations  allObjects]];
            
            canAction = YES;
            break;
        }
        case ConversationsActionRestore: {
            DDLogSupport(@"Restore selected conversations: %lu", (unsigned long)self.selectedConversations.count);
            [[ConversationDBService sharedService] restoreConversations:[self.selectedConversations  allObjects]];
            
            canAction = YES;
            break;
        }
        default:
            break;
    }
    
    if (canAction) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kConversationsListDidPressActionButtonNotification object:nil];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - Delegates -

#pragma mark * UITableViewDelegate/DataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    
    count = self.conversations.count;
    
    return count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = kDefaultConversationsListTableViewCellHeight;
    return height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *reuseIdentifire = kConversationsListTableViewCellReuseId;
    ConversationsListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifire];

    Conversation *conversation = self.conversations[indexPath.row];
    BOOL cellIsChecked = [self.selectedConversations containsObject:conversation];
    
    [cell configureCellWithConversation:conversation cellIsChecked:cellIsChecked];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    Conversation *conversation = self.conversations[indexPath.row];
    
    if ([self.selectedConversations containsObject:conversation]) {
        [self.selectedConversations removeObject:conversation];
    }
    else {
        [self.selectedConversations addObject:conversation];
    }
    [self configureSelectAllButtonTitle];
    
    [tableView reloadData];
}

@end
