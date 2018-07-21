//
//  SearchPatientsTableViewCell.m
//  qliq
//
//  Created by Valerii Lider on 01/03/2017.
//
//

#import "SearchPatientsTableViewCell.h"

#define kGrayColor RGBa(95, 95, 95, 1)
#define kValueDefaultDistance 50.0f

typedef NS_ENUM(NSInteger, SearchTextFieldType ) {
    SearchTextFieldTypeLastName = 0,
    SearchTextFieldTypeFirstName,
    SearchTextFieldTypeDateOfBirth,
    SearchTextFieldTypeMRN,
    SearchTextFieldTypeCount
};

@interface SearchPatientsTableViewCell () <UITextFieldDelegate>

@property (nonatomic, strong) UIDatePicker *datePicker;
@property (nonatomic, strong) UIToolbar *datePickerToolbar;

//Constraints
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *searchButtonWidthConstraint;

@end

@implementation SearchPatientsTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.imageView.backgroundColor = [UIColor whiteColor];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.selectedBackgroundView = [[UIView alloc] init];
    self.selectedBackgroundView.backgroundColor = [UIColor clearColor];

    self.lastNameTextField.text = nil;
    self.lastNameTextField.delegate = self;
    self.lastNameTextField.tag = SearchTextFieldTypeLastName;
    self.lastNameTextField.textColor = kGrayColor;
    
    self.firstNameTextField.text = nil;
    self.firstNameTextField.delegate = self;
    self.firstNameTextField.tag = SearchTextFieldTypeFirstName;
    self.firstNameTextField.textColor = kGrayColor;
    
    self.dateOfBirthTextField.text = nil;
    self.dateOfBirthTextField.delegate = self;
    self.dateOfBirthTextField.tag = SearchTextFieldTypeDateOfBirth;
    self.dateOfBirthTextField.textColor = kGrayColor;
    
    self.mrnTextField.text = nil;
    self.mrnTextField.delegate = self;
    self.mrnTextField.tag = SearchTextFieldTypeMRN;
    self.mrnTextField.textColor = kGrayColor;
    
    self.searchButton.layer.cornerRadius = 10.f;
    self.searchButton.clipsToBounds = YES;

    [self createDatePicker];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangeOrientationNotification:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
    [self didChangeOrientationNotification:nil];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - Private -

- (BOOL)isFillSearchTextFieldWithTag:(NSInteger)tag {
    
    BOOL isFillField = NO;
    
    SearchTextFieldType type = tag;
    
    switch (type) {
        case SearchTextFieldTypeLastName: {
            
            if (!(self.lastNameTextField.text == nil) && ![self.lastNameTextField.text isEqualToString:@""]) {
                isFillField = YES;
            }
            break;
        }
        case SearchTextFieldTypeFirstName: {
            
            if (![self.firstNameTextField.text isEqualToString:@""]  && !(self.firstNameTextField.text == nil)) {
                isFillField = YES;
            }
            break;
        }
        case SearchTextFieldTypeDateOfBirth: {
            
            if ( ![self.dateOfBirthTextField.text isEqualToString:@""] && !(self.dateOfBirthTextField.text == nil)) {
                isFillField = YES;
            }
            break;
        }
        case SearchTextFieldTypeMRN: {
            
            if (![self.mrnTextField.text isEqualToString:@""] && !(self.mrnTextField.text == nil)) {
                isFillField = YES;
            }
            break;
        }
        default:
            break;
    }
    
    return isFillField;
}

- (void)didChangeOrientationNotification:(NSNotification *)notification {
    
    self.searchButtonWidthConstraint.constant = [UIScreen mainScreen].bounds.size.width - 2 * kValueDefaultDistance;
}

- (void)createDatePicker {
    
    if (self.datePicker != nil)
        return;
    
    self.datePicker = [[UIDatePicker alloc] init];

    self.datePicker.datePickerMode = UIDatePickerModeDate;
    self.datePicker.backgroundColor = [UIColor whiteColor];
    [self.datePicker setDate:[NSDate date]];

    [self.datePicker addTarget:self action:@selector(addedDate:) forControlEvents:UIControlEventValueChanged];
    self.datePicker.tag = self.dateOfBirthTextField.tag;
    self.dateOfBirthTextField.inputView = self.datePicker;
    
    UIColor *textColor = RGBa(3, 120, 173, 1);
    
    if (self.datePickerToolbar == nil) {
        self.datePickerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 0, 30.f)];
        UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
        UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(closeDatePicker:)];
        done.tintColor = textColor;
        
        self.datePickerToolbar.items = @[flexibleItem, done];
    }
    
    self.dateOfBirthTextField.inputAccessoryView = self.datePickerToolbar;
}

- (void)closeDatePicker:(id)sender {
    
    NSDateFormatter *dateFormater = [[NSDateFormatter alloc] init];
    [dateFormater setDateFormat:@"MM/dd/yyyy"];
    
    NSString *stringFormater =[dateFormater stringFromDate:self.datePicker.date];
    
    self.dateOfBirthTextField.text = stringFormater;
    
    [self.datePickerToolbar removeFromSuperview];
    [self.datePicker removeFromSuperview];
    [self.dateOfBirthTextField resignFirstResponder];
}

- (void)addedDate:(id)sender {
    
}

#pragma mark - Delegate Methods -
#pragma mark * TextField Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    
    textField.text = nil;
}


@end
