//
//  SettingsEscalatedViewController.m
//  qliq
//
//  Created by Valerii Lider on 29/06/15.
//
//

#import "SettingsEscalatedViewController.h"
#import "MainSettingsTableViewCell.h"

#import "UpdateEscalatedCallnotifyInfoService.h"
#import "QliqUserDBService.h"
#import "UserSettingsService.h"

#import "AlertController.h"

typedef enum {
    rowPhoneNumber = 0,
    rowWeekdays,
    rowWeeknights,
    rowWeekends
}TableRows;

@interface SettingsEscalatedViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UILabel *navigationLeftTitleLabel;

@property (weak, nonatomic) IBOutlet UIButton *navigationRightButton;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) UITextField *textField;

@property (nonatomic, strong) NSString *phoneNumber;
@property (nonatomic, assign) BOOL weekdays;
@property (nonatomic, assign) BOOL weeknights;
@property (nonatomic, assign) BOOL weekends;

@end

@implementation SettingsEscalatedViewController

- (void)configureDefaultText {
    self.navigationLeftTitleLabel.text = QliqLocalizedString(@"2028-TitleEscalationSettings");
    
    [self.navigationRightButton setTitle:QliqLocalizedString(@"44-ButtonSave") forState:UIControlStateNormal];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureDefaultText];
    
    UITapGestureRecognizer* tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap:)];
    [self.view addGestureRecognizer:tapGestureRecognizer];
}

- (void)onTap:(UITapGestureRecognizer*)tapGestureRecognizer
{
    [self.textField resignFirstResponder];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO];
    
    
    //set property from the userSettings to temp varialbes
    UserSettings *userSettings = [UserSessionService currentUserSession].userSettings;
    self.phoneNumber = userSettings.escalatedCallnotifyInfo.escalationNumber;
    self.weekends   = userSettings.escalatedCallnotifyInfo.escalateWeekends;
    self.weeknights = userSettings.escalatedCallnotifyInfo.escalateWeeknights;
    self.weekdays   = userSettings.escalatedCallnotifyInfo.escalateWeekdays;
    
    if (!self.phoneNumber)
        self.phoneNumber = @"";
        
    //TableView
    {
        self.tableView.tableFooterView = [[ UIView alloc ] initWithFrame:CGRectZero];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Private -

- (void)didChangeWeekdays:(UISwitch*)_switch {
    self.weekdays =_switch.on;
}

- (void)didChangeWeeknights:(UISwitch*)_switch {
    self.weeknights =_switch.on;
}

- (void)didChangeWeekends:(UISwitch*)_switch {
    self.weekends = _switch.on;
}

#pragma mark - Actions -

- (IBAction)onBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onSave:(id)sender {
    
    [self.textField resignFirstResponder];
    self.phoneNumber = self.textField.text;
    
    UpdateEscalatedCallnotifyInfoService *updateService = [UpdateEscalatedCallnotifyInfoService sharedService];
    UserSettings *userSettings = [UserSessionService currentUserSession].userSettings;


    VoidBlock updateEscalatedCallBlock = ^{

        [SVProgressHUD showWithStatus:QliqLocalizedString(@"44-ButtonSave") maskType:SVProgressHUDMaskTypeBlack];

        [updateService updateEscalatedCallnotifyInfoEscalationNumber: self.phoneNumber
                                                    escalateWeekends: self.weekends
                                                  escalateWeeknights: self.weeknights
                                                    escalateWeekdays: self.weekdays
                                               withCompletitionBlock: ^(CompletitionStatus status, id result, NSError *error)
         {
             [SVProgressHUD dismiss];

             if (status == CompletitionStatusError) {
                 [AlertController showAlertWithTitle:nil
                                             message:error.description
                                         buttonTitle:nil
                                   cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                          completion:nil];
             } else {

                 userSettings.escalatedCallnotifyInfo.escalationNumber = self.phoneNumber;
                 userSettings.escalatedCallnotifyInfo.escalateWeekends = self.weekends;
                 userSettings.escalatedCallnotifyInfo.escalateWeeknights = self.weeknights;
                 userSettings.escalatedCallnotifyInfo.escalateWeekdays = self.weekdays;

                 UserSettingsService *userSettingsService = [[UserSettingsService alloc] init];
                 [userSettingsService saveUserSettings:userSettings forUser:[UserSessionService currentUserSession].user];

                 [AlertController showAlertWithTitle:nil
                                             message:QliqLocalizedString(@"1209-TextEscalatedCallInfoSaved")
                                         buttonTitle:nil
                                   cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                          completion:nil];
             }
         }];
    };

    if (!isValidPhone(self.phoneNumber)) {
        
        [AlertController showAlertWithTitle:nil
                                    message:QliqLocalizedString(@"1208-TextPhoneNumberNotValid")
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                 completion:^(NSUInteger buttonIndex) {
                                     updateEscalatedCallBlock();
                                 }];
    } else {
        updateEscalatedCallBlock();
    }
}


#pragma mark - Delegates -

#pragma mark * TableView Delegate/DataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 4;
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MainSettingsTableViewCell *cell = nil;
    
    static NSString *reuseId1 = @"SETTINGS_CELL_ID";
    
    switch (indexPath.row)
    {
        case rowPhoneNumber: {
            
            cell = [tableView dequeueReusableCellWithIdentifier:reuseId1];
            
            cell.nameOptionLabel.text = QliqLocalizedString(@"2069-TitlePhoneNumber");
            
            cell.arrowImageView.hidden = YES;
            cell.textField.hidden = NO;
            cell.switchOptionMode.hidden = YES;
            
            cell.textField.delegate = self;
            cell.textField.text = self.phoneNumber;
            cell.textField.keyboardType = UIKeyboardTypeNumberPad;
            self.textField = cell.textField;
            
            break;
        }
        case rowWeekdays: {
            
            cell = [tableView dequeueReusableCellWithIdentifier:reuseId1];
            
            cell.nameOptionLabel.text = QliqLocalizedString(@"2070-TitleWeekdays");
            
            cell.arrowImageView.hidden = YES;
            cell.textField.hidden = YES;
            cell.switchOptionMode.hidden = NO;
            
            cell.switchOptionMode.on = self.weekdays;
            [cell.switchOptionMode addTarget:self action:@selector(didChangeWeekdays:) forControlEvents:UIControlEventValueChanged];
            
            break;
        }
        default:
        case rowWeeknights: {
            
            cell = [tableView dequeueReusableCellWithIdentifier:reuseId1];
            
            cell.nameOptionLabel.text = QliqLocalizedString(@"2071-TitleWeeknights");
            
            cell.arrowImageView.hidden = YES;
            cell.textField.hidden = YES;
            cell.switchOptionMode.hidden = NO;
            
            cell.switchOptionMode.on = self.weeknights;
            [cell.switchOptionMode addTarget:self action:@selector(didChangeWeeknights:) forControlEvents:UIControlEventValueChanged];
            
            break;
        }
        case rowWeekends: {
            
            cell = [tableView dequeueReusableCellWithIdentifier:reuseId1];
            
            cell.nameOptionLabel.text = QliqLocalizedString(@"2072-TitleWeekends");
            
            cell.arrowImageView.hidden = YES;
            cell.textField.hidden = YES;
            cell.switchOptionMode.hidden = NO;
            
            cell.switchOptionMode.on = self.weekends;
            [cell.switchOptionMode addTarget:self action:@selector(didChangeWeekends:) forControlEvents:UIControlEventValueChanged];
            
            break;
        }
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark * UITextField Delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    [self performSelector:@selector(changePhoneNumber) withObject:nil afterDelay:0.1];
    return YES;
}

- (void)changePhoneNumber
{
    self.phoneNumber = self.textField.text;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end
