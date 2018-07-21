//
//  ProfileViewController.m
//  qliq
//
//  Created by Valeriy Lider on 17.11.14.
//
//

#import "ProfileViewController.h"
#import "ProfileTableViewCell.h"
#import "MainSettingsHeaderView.h"
#import "ImageCaptureController.h"

#import "AvatarUploadService.h"
#import "QliqUserDBService.h"
#import "UpdateProfileService.h"

#import "AlertController.h"
#import "SettingsItem.h"

#define kValueCellHeightDefault 44.f

typedef NS_ENUM(NSInteger, ProfileField) {
    ProfileFieldFirstName = 0,
    ProfileFieldLastName,
    ProfileFieldTitle,
    ProfileFieldOrganization,
    ProfileFieldCity,
    ProfileFieldState,
    ProfileFieldZip,
    ProfileFieldMobile
};

@interface ProfileViewController ()
<
UITableViewDataSource,
UITableViewDelegate,
UIPickerViewDataSource,
UIPickerViewDelegate,
UITextFieldDelegate,
MainSettingsHeaderViewDelegate,
ImageCaptureControllerDelegate
>

/**
 IBOutlet
 */
@property (weak, nonatomic) IBOutlet UILabel *navigationLeftTitleLabel;

@property (weak, nonatomic) IBOutlet UIButton *navigationRightButton;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet MainSettingsHeaderView *contactHeaderView;

//Constraints
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomTableViewConstraint;

/**
 UI
 */
@property (strong, nonatomic) ImageCaptureController *imageCaptureController;

@property (nonatomic, strong) UIPickerView *titlePicker;
@property (nonatomic, strong) UIToolbar *accessoryToolbar;
@property (nonatomic, strong) UIBarButtonItem *typeManuallyButton;
@property (nonatomic, strong) UIBarButtonItem *chooseFromListButton;
@property (nonatomic, strong) UIBarButtonItem *flexibleSpace;
@property (nonatomic, strong) UIBarButtonItem *doneButton;

/**
 Data
 */

@property (nonatomic, assign) BOOL stateFieldSelected;
@property (nonatomic, assign) BOOL shouldShowKeyboardForTitle;
@property (nonatomic, assign) BOOL isAvatarUpdated;

@property (nonatomic, assign) ProfileField selectedTextField;

@property (nonatomic, strong) NSArray *titles;
@property (nonatomic, strong) NSArray *states;

@property (nonatomic, strong) NSString *firstNameText;
@property (nonatomic, strong) NSString *lastNameText;
@property (nonatomic, strong) NSString *titleText;
@property (nonatomic, strong) NSString *cityText;
@property (nonatomic, strong) NSString *stateText;
@property (nonatomic, strong) NSString *organizationText;
@property (nonatomic, strong) NSString *zipText;
@property (nonatomic, strong) NSString *mobileText;

@end

@implementation ProfileViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //NavigationBar
    self.navigationLeftTitleLabel.text = QliqLocalizedString(@"103-ButtonProfile");
    
    [self.navigationRightButton setTitle:QliqLocalizedString(@"44-ButtonSave") forState:UIControlStateNormal];
    
    self.isAvatarUpdated = YES;
    
    QliqUser *currentUser = [UserSessionService currentUserSession].user;

    //Set Data
    {
        self.firstNameText      = currentUser.firstName     ? currentUser.firstName     : @"";
        self.lastNameText       = currentUser.lastName      ? currentUser.lastName      : @"";
        self.titleText          = currentUser.profession    ? currentUser.profession    : @"";
        self.cityText           = currentUser.city          ? currentUser.city          : @"";
        self.stateText          = currentUser.state         ? currentUser.state         : @"";
        self.organizationText   = currentUser.organization  ? currentUser.organization  : @"";
        self.zipText            = currentUser.zip           ? currentUser.zip           : @"";
        self.mobileText         = currentUser.mobile        ? currentUser.mobile        : @"";
        
        self.titles             = [self getTitles];
        self.states             = [self getStates];
    }
    
    //ImageCAptureController
    {
        self.imageCaptureController = [[ImageCaptureController alloc] init];
        self.imageCaptureController.delegate = self;
    }
    
    //HeaderView
    {
        [self.contactHeaderView fillWithContact:currentUser];
        self.contactHeaderView.delegate = self;
    }
    
    //AccessoryToolbar
    {
        UIColor *textColor = RGBa(3, 120, 173, 1);
        
        self.typeManuallyButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"36-ButtonTypeManually", nil)
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(onTypeManuallyButton:)];
        self.typeManuallyButton.tintColor = textColor;
        
        self.chooseFromListButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"37-ButtonSelectFromList", nil)
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(onSelectFromListButton:)];
        self.chooseFromListButton.tintColor = textColor;
        
        self.flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];
        
        self.doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"38-ButtonDone", nil)
                                                           style:UIBarButtonItemStyleDone
                                                          target:self
                                                          action:@selector(onAccessoryDoneButton:)];
        self.doneButton.tintColor = textColor;
        
        self.accessoryToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.f, 0.f, self.view.frame.size.width, 30.f)];
//        self.accessoryToolbar.items = @[self.flexibleSpace, self.doneButton];
    }
        
    //TitlePicker
    {
        self.titlePicker = [[UIPickerView alloc] init];
        self.titlePicker.backgroundColor            = [UIColor clearColor];
        self.titlePicker.showsSelectionIndicator    = YES;
        self.titlePicker.delegate                   = self;
        self.titlePicker.dataSource                 = self;
        
        if ([self.titlePicker respondsToSelector:@selector(setTintAdjustmentMode:)])
        {
            [self.titlePicker setTintAdjustmentMode:UIViewTintAdjustmentModeDimmed];
            [self.titlePicker setBackgroundColor:[UIColor whiteColor]];
        }
        
        if (NSNotFound != [self.titles indexOfObjectIdenticalTo:currentUser.profession])
        {
            [self.titlePicker selectRow:[self.titles indexOfObjectIdenticalTo:currentUser.profession] + 1 inComponent:0 animated:NO];
        }
    }
    
    //Notifications
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(checkAvatar:)
                                                     name:@"UserHasChangeAvatar"
                                                   object: nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reShowUpdateActivity:)
                                                     name:SVProgressHUDDidDisappearNotification
                                                   object: nil];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO];
    
    [self addKeyboardNotificationHandling];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES];
    
    [self removeKeyboardNotificationHandling];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)dealloc
{
    self.accessoryToolbar.items = nil;
    self.accessoryToolbar = nil;
    self.navigationLeftTitleLabel = nil;
    self.navigationRightButton = nil;
    self.tableView.dataSource = nil;
    self.tableView.delegate = nil;
    self.tableView = nil;
    [self.contactHeaderView removeFromSuperview];
    self.contactHeaderView = nil;
    self.imageCaptureController = nil;
    self.titlePicker = nil;
    self.typeManuallyButton = nil;
    self.chooseFromListButton = nil;
    self.flexibleSpace = nil;
    self.doneButton = nil;
    self.selectedTextField = nil;
    self.titles = nil;
    self.states = nil;
    self.firstNameText = nil;
    self.lastNameText = nil;
    self.titleText = nil;
    self.cityText = nil;
    self.stateText = nil;
    self.organizationText = nil;
    self.zipText = nil;
    self.mobileText = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}

#pragma mark - Notifications keyboard

- (void)onKeyboardWillShowNotification:(NSNotification *)notification
{
    NSValue *value = notification.userInfo[UIKeyboardFrameEndUserInfoKey];
    CGRect keyBoardFrame = [value CGRectValue];
    
    self.bottomTableViewConstraint.constant = keyBoardFrame.size.height;
}

- (void)onKeyboardWillHideNotification:(NSNotification *)notification
{
    self.bottomTableViewConstraint.constant = 0;
}

- (void)onKeyboardDidShowNotification:(NSNotification *)notification
{
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.selectedTextField inSection:0]
                          atScrollPosition:UITableViewScrollPositionBottom animated:NO];
}

- (void)addKeyboardNotificationHandling
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onKeyboardWillShowNotification:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onKeyboardWillHideNotification:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onKeyboardDidShowNotification:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
}

- (void)removeKeyboardNotificationHandling
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
}

#pragma mark - Private Methods

- (void)hideKeyboard
{
    ProfileTableViewCell *cell = (ProfileTableViewCell *) [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.selectedTextField inSection:0]];
    if ([cell.descriptionTextField isFirstResponder])
        [cell.descriptionTextField resignFirstResponder];
}

- (void)saveAvatar:(UIImage *)image {
    DDLogSupport(@"Save Avatar");
    
    self.isAvatarUpdated = NO;
    
    dispatch_async_main(^{
        [SVProgressHUD showProgress:-1 status:NSLocalizedString(@"1915-StatusUpdating", nil) maskType:SVProgressHUDMaskTypeGradient];
    });
    
    
    AvatarUploadService *setAvatarService = [[AvatarUploadService alloc] initWithAvatar:image forUser:[UserSessionService currentUserSession].user];
    
    [setAvatarService callServiceWithCompletition:^(CompletitionStatus status, id result, NSError *error) {
        dispatch_async_main(^{
            
            if (error) {

                DDLogError(@"Localized Description: \n%@", [error localizedDescription]);

                [AlertController showAlertWithTitle:QliqLocalizedString(@"1155-TextUnableToUpdateDueToServerError")
                                            message:QliqLocalizedString(@"1076-TextTryLater")
                                        buttonTitle:nil
                                  cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                         completion:nil];
                
            } else if (status == CompletitionStatusSuccess) {
                
                self.contactHeaderView.avatarView.image = [[QliqAvatar sharedInstance] getAvatarForItem:[UserSessionService currentUserSession].user withTitle:nil];
                
                [self.view reloadInputViews];
            }
            
            self.isAvatarUpdated = YES;
            [SVProgressHUD dismiss];
        });
    }];
}

- (void)checkAvatar:(NSNotification *)notification {
    
    Contact *contact = [[notification userInfo] objectForKey:@"contact"];
    if ([[UserSessionService currentUserSession].user.qliqId isEqualToString:contact.qliqId]) {
        dispatch_async_main(^{
            self.contactHeaderView.avatarView.image = [[QliqAvatar sharedInstance] getAvatarForItem:[UserSessionService currentUserSession].user withTitle:nil];
        });
    }
}

- (void)reShowUpdateActivity:(NSNotification *)notification {
    if (!self.isAvatarUpdated) {
        dispatch_async_main(^{
            [SVProgressHUD showProgress:-1 status:NSLocalizedString(@"1915-StatusUpdating", nil) maskType:SVProgressHUDMaskTypeGradient];
        });
    }
}

- (NSString*)getTextTitleWithType:(ProfileField)type
{
    NSString *description = @"";
    
    switch (type)
    {
        case ProfileFieldFirstName:     description = @"2042-TitleFirstName#profile";       break;
        case ProfileFieldLastName:      description = @"2043-TitleLastName#profile";        break;
        case ProfileFieldTitle:         description = @"2044-TitleTitle#profile";           break;
        case ProfileFieldOrganization:  description = @"2045-TitleOrganization#profile";    break;
        case ProfileFieldCity:          description = @"2046-TitleCity#profile";            break;
        case ProfileFieldState:         description = @"2047-TitleState#profile";           break;
        case ProfileFieldZip:           description = @"2048-TitleZIP#profile";             break;
        case ProfileFieldMobile:        description = @"2049-TitleMobile#profile";          break;
        default: break;
    }
    
    description = QliqLocalizedString(description);
    
    return description;
}

- (NSString*)getTextDescriptionWithType:(ProfileField)type
{
    NSString *description = @"";
    
    switch (type)
    {
        case ProfileFieldFirstName:     description = self.firstNameText;        break;
        case ProfileFieldLastName:      description = self.lastNameText;         break;
        case ProfileFieldTitle:         description = self.titleText;            break;
        case ProfileFieldOrganization:  description = self.organizationText;     break;
        case ProfileFieldCity:          description = self.cityText;             break;
        case ProfileFieldState:         description = self.stateText;            break;
        case ProfileFieldZip:           description = self.zipText;              break;
        case ProfileFieldMobile:        description = self.mobileText;           break;
        default: break;
    }
    
    return description;
}


- (NSArray*)getTitles
{
    NSArray *array;
    
    array = @[@"Physician",
              @"Nurse",
              @"Non-Physician Practitioner",
              @"Limited License Practitioner",
              @"IT/HIM Manager",
              @"Security Officer",
              @"Compliance Manager",
              @"Administrator",
              @"Social Worker",
              @"Other"];
    
    return array;
}

- (NSArray*)getStates
{
    NSArray *array;
    
    array = @[@"Alabama",
              @"Alaska",
              @"Arizona",
              @"Arkansas",
              @"California",
              @"Colorado",
              @"Connecticut",
              @"Delaware",
              @"Florida",
              @"Georgia",
              @"Hawaii",
              @"Idaho",
              @"Illinois",
              @"Indiana",
              @"Iowa",
              @"Kansas",
              @"Kentucky",
              @"Louisiana",
              @"Maine",
              @"Maryland",
              @"Massachusetts",
              @"Michigan",
              @"Minnesota",
              @"Mississippi",
              @"Missouri",
              @"Montana",
              @"Nebraska",
              @"Nevada",
              @"New Hampshire",
              @"New Jersey",
              @"New Mexico",
              @"New York",
              @"North Carolina",
              @"North Dakota",
              @"Ohio",
              @"Oklahoma",
              @"Oregon",
              @"Pennsylvania",
              @"Rhode Island",
              @"South Carolina",
              @"South Dakota",
              @"Tennessee",
              @"Texas",
              @"Utah",
              @"Vermont",
              @"Virginia",
              @"Washington",
              @"West Virginia",
              @"Wisconsin",
              @"Wyoming"];
    
    return array;
}

- (void)setDescription:(NSString*)text forType:(ProfileField)type
{
    switch (type)
    {
        case ProfileFieldFirstName:     self.firstNameText      = text;   break;
        case ProfileFieldLastName:      self.lastNameText       = text;   break;
        case ProfileFieldTitle:         self.titleText          = text;   break;
        case ProfileFieldOrganization:  self.organizationText   = text;   break;
        case ProfileFieldCity:          self.cityText           = text;   break;
        case ProfileFieldState:         self.stateText          = text;   break;
        case ProfileFieldZip:           self.zipText            = text;   break;
        case ProfileFieldMobile:        self.mobileText         = text;   break;
        default: break;
    }
}

#pragma mark - Accessory Methods

- (void)onSelectFromListButton:(UIBarButtonItem *)button
{
    [self.view endEditing:YES];
    
    self.shouldShowKeyboardForTitle = NO;
    self.accessoryToolbar.items = @[self.typeManuallyButton, self.flexibleSpace, self.doneButton];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.stateFieldSelected ? ProfileFieldState : ProfileFieldTitle inSection:0];
    
    ProfileTableViewCell *cell = (ProfileTableViewCell *) [self.tableView cellForRowAtIndexPath:indexPath];
    cell.descriptionTextField.inputView = self.titlePicker;
    [cell.descriptionTextField becomeFirstResponder];
}

- (void)onTypeManuallyButton:(UIBarButtonItem *)button
{
    [self.view endEditing:YES];
    
    self.shouldShowKeyboardForTitle = YES;
    self.accessoryToolbar.items = @[self.chooseFromListButton, self.flexibleSpace, self.doneButton];

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.stateFieldSelected ? ProfileFieldState : ProfileFieldTitle inSection:0];
    
    ProfileTableViewCell *cell = (ProfileTableViewCell *) [self.tableView cellForRowAtIndexPath:indexPath];
    cell.descriptionTextField.inputView = self.titlePicker;
    cell.descriptionTextField.keyboardType = UIKeyboardTypeDefault;
    [cell.descriptionTextField becomeFirstResponder];
}

- (void)onAccessoryDoneButton:(UIBarButtonItem *)button {
    [self.view endEditing:YES];
}

#pragma mark - IBActions

- (IBAction)onBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onSave:(id)sender
{
    DDLogSupport(@"SaveUser");
    
    [self hideKeyboard];
    
    QliqUser *user = [UserSessionService currentUserSession].user;
    user.firstName      = self.firstNameText;
    user.lastName       = self.lastNameText;
    user.mobile         = self.mobileText;
    user.state          = self.stateText;
    user.city           = self.cityText;
    user.zip            = self.zipText;
    user.organization   = self.organizationText;
    user.profession     = self.titleText;
    
    [[QliqUserDBService sharedService] saveUser:user];
    
    [SVProgressHUD showProgress:-1 status:NSLocalizedString(@"1915-StatusUpdating", nil)];
    
    [[UpdateProfileService sharedService] sendUpdateInfoWithCompletion:^(NSError *error) {
        
        [SVProgressHUD dismiss];
        
        if (error) {
            
            [AlertController showAlertWithTitle:QliqLocalizedString(@"1155-TextUnableToUpdateDueToServerError")
                                        message:QliqLocalizedString(@"1076-TextTryLater")
                                    buttonTitle:nil
                              cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                     completion:nil];
        } else {
            [AlertController showAlertWithTitle:QliqLocalizedString(@"1156-TextProfileDetailsSuccessfullyUpdated")
                                        message:nil
                                    buttonTitle:nil
                              cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                     completion:^(NSUInteger buttonIndex) {
                                         [self.navigationController popViewControllerAnimated:YES];
                                     }];
        }
    }];
}

#pragma mark - Delegates

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kValueCellHeightDefault;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    count = 8;
    return count;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ProfileTableViewCell *cell = nil;
    
    static NSString *reuseId = @"PROFILE_CELL_ID";
    cell = [tableView dequeueReusableCellWithIdentifier:reuseId];
    cell.selectionStyle                                 = UITableViewCellSelectionStyleNone;
    cell.titleLabel.text                                = [self getTextTitleWithType:indexPath.row];
    cell.descriptionTextField.tag                       = indexPath.row;
    cell.descriptionTextField.text                      = [self getTextDescriptionWithType:indexPath.row];
    cell.descriptionTextField.userInteractionEnabled    = NO;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedTextField = indexPath.row;
    
    ProfileTableViewCell *cell = (ProfileTableViewCell *) [self.tableView cellForRowAtIndexPath:indexPath];
    cell.descriptionTextField.userInteractionEnabled    = YES;
    cell.descriptionTextField.delegate                  = self;
    cell.descriptionTextField.inputAccessoryView        = self.accessoryToolbar;
    
    switch (indexPath.row)
    {
        case ProfileFieldFirstName:     cell.descriptionTextField.keyboardType  = UIKeyboardTypeDefault;    break;
        case ProfileFieldLastName:      cell.descriptionTextField.keyboardType  = UIKeyboardTypeDefault;    break;
        case ProfileFieldTitle:         cell.descriptionTextField.inputView     = self.titlePicker;         break;
        case ProfileFieldOrganization:  cell.descriptionTextField.keyboardType  = UIKeyboardTypeDefault;    break;
        case ProfileFieldCity:          cell.descriptionTextField.keyboardType  = UIKeyboardTypeDefault;    break;
        case ProfileFieldState:         cell.descriptionTextField.inputView     = self.titlePicker;         break;
        case ProfileFieldZip:           cell.descriptionTextField.keyboardType  = UIKeyboardTypeDecimalPad; break;
        case ProfileFieldMobile:        cell.descriptionTextField.keyboardType  = UIKeyboardTypeDecimalPad; break;
        default: break;
    }
    
    [cell.descriptionTextField becomeFirstResponder];
}

#pragma mark - UIPickerViewDelegate/DataSource methods

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    NSInteger count = 0;
    
    if (self.stateFieldSelected)
        count = self.states.count;
    else
        count = self.titles.count + 1;
    
    return count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSString *string = 0;
    
    if (self.stateFieldSelected)
        string = self.states[row];
    else if (0 == row)
        string = @"Not specified";
    else
        string = self.titles[row - 1];
    
    return string;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if (self.stateFieldSelected)
    {
        ProfileTableViewCell *cell = (ProfileTableViewCell *) [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:ProfileFieldState inSection:0]];
        cell.descriptionTextField.text = self.states[row];
    }
    else
    {
        ProfileTableViewCell *cell = (ProfileTableViewCell *) [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:ProfileFieldTitle inSection:0]];
        if (0 == row)
            cell.descriptionTextField.text = @"";
        else
            cell.descriptionTextField.text = self.titles[row - 1];
    }
}

#pragma mark - ImageCaptureControllerDelegate

- (void)presentImageCaptureController:(UIViewController *)controller {
    [self.navigationController presentViewController:controller animated:YES completion:nil];
}

- (void)imageCaptured:(UIImage *)image withController:(UIViewController *)contorller {

    [self dismissViewControllerAnimated:YES completion:^{}];

    if (image) {
        [self saveAvatar:image];
    } else {
        DDLogError(@"Nil image captured");

        [AlertController showAlertWithTitle:QliqLocalizedString(@"1023-TextError")
                                    message:QliqLocalizedString(@"2356-TextImageWasNotCaptured")
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                 completion:^(NSUInteger buttonIndex) {
                                     [SVProgressHUD dismiss];
                                 }];
    }
}

- (void)imageCaptureControllerCanceled:(UIViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UserHeaderDelegate methods

- (void)showUserProfile{}

- (void)changeAvatar
{
    DDLogSupport(@"Change Avatar");
    
    if(self.contactHeaderView.avatar)
    {
        __weak typeof(self) weakSelf = self;
        [AlertController showActionSheetAlertWithTitle:NSLocalizedString(@"1116-TextChangeAvatar", nil)
                                               message:nil
                                      withTitleButtons:@[NSLocalizedString(@"24-ButtonCreateAvatar", nil)]
                                destructiveButtonTitle:NSLocalizedString(@"23-ButtonRemoveAvatar", nil)
                                     cancelButtonTitle:NSLocalizedString(@"4-ButtonCancel", nil) inController:self
                                            completion:^(NSUInteger buttonIndex) {
                                                switch (buttonIndex)
                                                {
                                                    case 0: [weakSelf.imageCaptureController captureImage]; break;
                                                    case 1: [weakSelf saveAvatar:nil]; break;
                                                    default: break;
                                                }
                                            }];
    }
    else
    {
        [self.imageCaptureController captureImage];
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:textField.tag inSection:0]
                          atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    
    textField.inputView = nil;
    
    switch (textField.tag)
    {
        case ProfileFieldFirstName:     textField.keyboardType  = UIKeyboardTypeDefault;    break;
        case ProfileFieldLastName:      textField.keyboardType  = UIKeyboardTypeDefault;    break;
        case ProfileFieldTitle:         textField.inputView     = self.titlePicker;         break;
        case ProfileFieldOrganization:  textField.keyboardType  = UIKeyboardTypeDefault;    break;
        case ProfileFieldCity:          textField.keyboardType  = UIKeyboardTypeDefault;    break;
        case ProfileFieldState:         textField.inputView     = self.titlePicker;         break;
        case ProfileFieldZip:           textField.keyboardType  = UIKeyboardTypeDecimalPad; break;
        case ProfileFieldMobile:        textField.keyboardType  = UIKeyboardTypeDecimalPad; break;
        default: break;
    }

    
    if (textField.tag == ProfileFieldTitle)
    {
        self.stateFieldSelected = NO;
        
        if (self.shouldShowKeyboardForTitle)
        {
            self.accessoryToolbar.items = @[self.chooseFromListButton, self.flexibleSpace, self.doneButton];
            textField.inputView = nil;
        }
        else
        {
            self.accessoryToolbar.items = @[self.typeManuallyButton, self.flexibleSpace, self.doneButton];
            textField.inputView = self.titlePicker;
        }
        
        [self.titlePicker reloadAllComponents];
        
        NSUInteger index = [self.titles indexOfObject:textField.text];
        if (NSNotFound != index)
        {
            [self.titlePicker selectRow:index + 1 inComponent:0 animated:NO];
        }
    }
    else if (textField.tag == ProfileFieldState)
    {
        self.stateFieldSelected = YES;
        self.accessoryToolbar.items = @[self.flexibleSpace, self.doneButton];
        
        textField.inputView = self.titlePicker;
        [self.titlePicker reloadAllComponents];
        
        NSUInteger index = [self.states indexOfObject:textField.text];
        if (NSNotFound != index)
        {
            [self.titlePicker selectRow:index inComponent:0 animated:NO];
        }
    }
    else
    {
        self.stateFieldSelected = NO;
        self.accessoryToolbar.items = @[self.flexibleSpace, self.doneButton];
    }
    
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    [self setDescription:textField.text forType:textField.tag];
    
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
//    [self setDescription:string forType:textField.tag];
    return YES;
}


@end
