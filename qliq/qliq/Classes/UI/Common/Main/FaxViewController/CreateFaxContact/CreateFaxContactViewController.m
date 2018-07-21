//
//  CreateFaxContactViewController.m
//  qliq
//
//  Created by Valeriy Lider on 1/9/18.
//

#import "CreateFaxContactViewController.h"
#import "CreateFaxContactTableViewCell.h"
#import "FaxContact.h"
#import "FaxViewController.h"
#import "SelectContactsViewController.h"
#import "ModifyFaxContactsWebService.h"
#import "AlertController.h"

#define kValueCellHeightDefault 44.f

typedef NS_ENUM(NSInteger, FaxContactField) {
    FaxContactFieldFaxNumber = 0,
    FaxContactFieldFaxOrganization,
    FaxContactFieldFaxContact,
    FaxContactFieldFaxVoiceNumber,
};

@interface CreateFaxContactViewController () <
UITableViewDataSource,
UITableViewDelegate,
UITextFieldDelegate
>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, assign) FaxContactField selectedTextField;
@property (nonatomic, strong) UIToolbar *accessoryToolbar;

@property (nonatomic, strong) NSString *organizationText;
@property (nonatomic, strong) NSString *faxNumberText;
@property (nonatomic, strong) NSString *faxContactText;
@property (nonatomic, strong) NSString *phoneNumberText;

@property (nonatomic, strong) NSMutableArray *participants;

@property (nonatomic, strong) UIButton *saveContactButton;
@property (nonatomic, strong) UIBarButtonItem *doneButton;
@property (nonatomic, strong) UIBarButtonItem *flexibleSpace;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomTableViewConstraint;

@end

@implementation CreateFaxContactViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.participants = [NSMutableArray new];

    [self configureAccessoryToolbar];
    [self configureSaveButton];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated {

    self.navigationController.navigationBarHidden = NO;
    [self addKeyboardNotificationHandling];
}

- (void)viewWillDisappear:(BOOL)animated {

    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES];

    [self removeKeyboardNotificationHandling];
}

- (void)dealloc {
    
    self.accessoryToolbar.items = nil;
    self.accessoryToolbar = nil;
    self.tableView.dataSource = nil;
    self.tableView.delegate = nil;
    self.tableView = nil;
    self.flexibleSpace = nil;
    self.doneButton = nil;
    self.selectedTextField = nil;
    self.faxNumberText = nil;
    self.faxContactText = nil;
    self.phoneNumberText = nil;
    self.organizationText = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void) configureAccessoryToolbar {

    UIColor *textColor = RGBa(3, 120, 173, 1);
    self.flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];

    self.doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"38-ButtonDone", nil)
                                                       style:UIBarButtonItemStyleDone
                                                      target:self
                                                      action:@selector(onAccessoryDoneButton:)];
    self.doneButton.tintColor = textColor;

    self.accessoryToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.f, 0.f, self.view.frame.size.width, 30.f)];
}

- (void)configureSaveButton {
    
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0,0, 320, 50.f)];
    self.saveContactButton = [[UIButton alloc] init];
    self.saveContactButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.saveContactButton setTitle:@"Save Fax Contact" forState:UIControlStateNormal];
    [self.saveContactButton addTarget:self action:@selector(saveContactButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.saveContactButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    UIColor *blueColor = kQliqBlueColor;
    [self.saveContactButton setBackgroundColor:blueColor];
    self.saveContactButton.frame=CGRectMake(self.view.width/2-80, 20, 160, 30);
    [footerView addSubview:self.saveContactButton];
    self.tableView.tableFooterView = footerView;
}

#pragma mark - Notifications keyboard

- (void)onKeyboardWillShowNotification:(NSNotification *)notification {
    
    NSValue *value = notification.userInfo[UIKeyboardFrameEndUserInfoKey];
    CGRect keyBoardFrame = [value CGRectValue];
    
    __weak __block typeof(self) weakSelf = self;
    [UIView animateWithDuration:10 animations:^{
        weakSelf.bottomTableViewConstraint.constant = keyBoardFrame.size.height;
    }];
}

- (void)onKeyboardWillHideNotification:(NSNotification *)notification {
    
    __weak __block typeof(self) weakSelf = self;
    [UIView animateWithDuration:5 animations:^{
        weakSelf.bottomTableViewConstraint.constant = 0;
    }];
}

- (void)onKeyboardDidShowNotification:(NSNotification *)notification {

    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.selectedTextField inSection:0]
                          atScrollPosition:UITableViewScrollPositionBottom animated:NO];
}

- (void)addKeyboardNotificationHandling {

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

- (void)removeKeyboardNotificationHandling {

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
}

- (IBAction)onBack:(id)sender {

    [self.navigationController popViewControllerAnimated:YES];
}

-(void) saveContactButton:(id)sender {
    
    if (self.faxNumberText.length != 10) {
        DDLogSupport(@"Entered is not valid fax number");
        
        [AlertController showAlertWithTitle:QliqLocalizedString(@"1023-TextError")
                                    message:QliqLocalizedString(@"3054-TextNoValidFaxNumber")
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                 completion:nil];
        
    } else if ([self.organizationText isEqualToString:@""]) {
        
        DDLogSupport(@"Empty organization name");
        
        [AlertController showAlertWithTitle:QliqLocalizedString(@"1023-TextError")
                                    message:QliqLocalizedString(@"3055-TextNoEnterOrganizationName")
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                 completion:nil];
    } else {
        
        [self.view endEditing:YES];
        FaxContact *newContact = [[FaxContact alloc] init];
        
        newContact.isCreatedByUser = YES;
        newContact.faxNumber    = self.faxNumberText;
        newContact.organization = self.organizationText;
        newContact.contactName  = self.faxContactText;
        newContact.voiceNumber  = self.phoneNumberText;
        
        DDLogSupport(@"Save fax contact:%@, from organization:%@, with fax number %@", newContact.contactName, newContact.organization, newContact.faxNumber);
        
        ModifyFaxContactOperation operation = AddModifyFaxContactOperation;
        ModifyFaxContactsWebService *modifyFaxContactsService = [[ModifyFaxContactsWebService alloc] init];
        [modifyFaxContactsService callForContact:newContact operation:operation withCompletition:^(CompletitionStatus status, id result, NSError *error) {
            if (error) {
                // Show error to user [error localizedDescription]
                DDLogSupport(@"Error:%@ description:%@", error, error.localizedDescription);
                
                [AlertController showAlertWithTitle:QliqLocalizedString(@"1023-TextError")
                                            message:error.localizedDescription
                                        buttonTitle:nil
                                  cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                         completion:nil];
            } else {
                // Contact is inserted/updated (by service code) in database at this point
                
                DDLogSupport(@"New Fax Contact: %@, successfully saved", newContact.contactName);
                
                [AlertController showAlertWithTitle:QliqLocalizedString(@"1081-TextSuccess")
                                            message:QliqLocalizedString(@"3056-TextSuccessfullySavedFaxContact")
                                        buttonTitle:nil
                                  cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                         completion:^(NSUInteger buttonIndex) {
                                             if (buttonIndex==1) {
                                                 
                                                 [self.participants removeAllObjects];
                                                 [self.participants addObject:newContact];
                                                 
                                                 [self.delegate didSelectedNewParticipant:self.participants];
                                                 
                                                 [self.navigationController popViewControllerAnimated:YES];
                                                 
                                             }
                                         }];
            }
        }];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

    return kValueCellHeightDefault;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    NSInteger count = 0;
    count = 4;
    return count;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    CreateFaxContactTableViewCell *cell = nil;

    static NSString *reuseId = @"FAX_CELL_ID";
    cell = [tableView dequeueReusableCellWithIdentifier:reuseId];
    cell.selectionStyle                                 = UITableViewCellSelectionStyleNone;
    cell.titleLabel.text                                = [self getTextTitleWithType:indexPath.row];
    cell.descriptionTextField.tag                       = indexPath.row;
    cell.descriptionTextField.delegate                  = self;
    cell.descriptionTextField.placeholder               = [self getTextDescriptionWithType:indexPath.row];
    cell.descriptionTextField.userInteractionEnabled    = NO;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    self.selectedTextField = indexPath.row;

    CreateFaxContactTableViewCell *cell = (CreateFaxContactTableViewCell *) [self.tableView cellForRowAtIndexPath:indexPath];
    cell.descriptionTextField.userInteractionEnabled    = YES;
    cell.descriptionTextField.inputAccessoryView        = self.accessoryToolbar;

    [cell.descriptionTextField becomeFirstResponder];
}

- (NSString*)getTextTitleWithType:(FaxContactField)type {

    NSString *description = @"";

    switch (type)
    {
        case FaxContactFieldFaxNumber:        description = @"Fax Number";      break;
        case FaxContactFieldFaxOrganization:  description = @"Organization";    break;
        case FaxContactFieldFaxContact:       description = @"Contact Person";  break;
        case FaxContactFieldFaxVoiceNumber:   description = @"Voice Number";    break;

        default: break;
    }

    description = QliqLocalizedString(description);

    return description;
}

- (NSString*)getTextDescriptionWithType:(FaxContactField)type {

    NSString *description = @"";

    switch (type)
    {
        case FaxContactFieldFaxNumber:        description = @"Enter Fax Number";              break;
        case FaxContactFieldFaxOrganization:  description = @"Enter Organization (Optional)"; break;
        case FaxContactFieldFaxContact:       description = @"Enter Name (Optional)";         break;
        case FaxContactFieldFaxVoiceNumber:   description = @"Enter Voice Number (Optional)"; break;
        default: break;
    }

    return description;
}

- (void)setDescription:(NSString*)text forType:(FaxContactField)type {

    switch (type)
    {
        case FaxContactFieldFaxOrganization: self.organizationText  = text; break;
        case FaxContactFieldFaxNumber:       self.faxNumberText     = text; break;
        case FaxContactFieldFaxContact:      self.faxContactText    = text; break;
        case FaxContactFieldFaxVoiceNumber:  self.phoneNumberText   = text; break;
        default: break;
    }
}

- (void)onAccessoryDoneButton:(UIBarButtonItem *)button {

    [self.view endEditing:YES];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {

    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:textField.tag inSection:0]
                          atScrollPosition:UITableViewScrollPositionBottom animated:NO];

    textField.inputView = nil;

    switch (textField.tag)
    {
        case FaxContactFieldFaxOrganization: textField.keyboardType = UIKeyboardTypeDefault;  break;
        case FaxContactFieldFaxNumber:       textField.keyboardType = UIKeyboardTypePhonePad; break;
        case FaxContactFieldFaxContact:      textField.keyboardType = UIKeyboardTypeDefault;  break;
        case FaxContactFieldFaxVoiceNumber:  textField.keyboardType = UIKeyboardTypePhonePad; break;

        default: break;
    }

    self.accessoryToolbar.items = @[self.flexibleSpace, self.doneButton];

    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {

    [self setDescription:textField.text forType:textField.tag];

    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {

    //    [self setDescription:string forType:textField.tag];
    return YES;
}

@end
