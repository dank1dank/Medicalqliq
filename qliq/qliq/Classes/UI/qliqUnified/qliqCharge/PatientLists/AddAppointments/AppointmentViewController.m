// Created by Developer Toy
//AddApptView.m
#import "AppointmentViewController.h"
#import "FacilityListView.h"
#import "ArchivedPatientListView.h"
#import "ReferralListView.h"
#import "Appointment.h"
#import "StretchableButton.h"
#import "Physician.h"

@interface AppointmentViewController (Private)

- (void)updatePatientLabel;


@end

@implementation AppointmentViewController

@synthesize appointment = _appointment;
@synthesize currentViewMode = _currentViewMode;
@synthesize physician = _physician;
#pragma mark -
#pragma mark Private

- (void)updatePatientLabel {
    UILabel *label = nil;
    switch (self.currentViewMode) {
        case QliqModelViewModeAdd:
            label = _addPatientLabel;
            break;
        case QliqModelViewModeEdit:
            label = _patientLabel;
            break;
        case QliqModelViewModeView:
            label = _viewPatientLabel;
            break;
		default:
			break;
    }
	if (self.appointment.patientName == nil) {
        label.textColor = [UIColor colorWithWhite:0.5098 alpha:1.0f];
        label.text = NSLocalizedString(@"Tap to select", @"Tap to select");
	}
	else {
		label.textColor = [UIColor blackColor];
		label.text = self.appointment.patientName;
	}
}

- (void)updateLocationLabel {
    UILabel *label = nil;
    switch (self.currentViewMode) {
        case QliqModelViewModeAdd:
            label = _addLocationLabel;
            break;
        case QliqModelViewModeEdit:
            label = _locationLabel;
            break;
        case QliqModelViewModeView:
            label = _viewLocationLabel;
            break;
		default:
			break;
    }
	if (self.appointment.facilityName == nil) {
        label.textColor = [UIColor colorWithWhite:0.5098 alpha:1.0f];
        label.text = NSLocalizedString(@"Tap to select", @"Tap to select");
	}
	else {
		label.textColor = [UIColor blackColor];
		label.text = self.appointment.facilityName;
	}
}

- (void)updateReferringLabel {
    UILabel *label = nil;
    switch (self.currentViewMode) {
        case QliqModelViewModeAdd:
            label = _addProviderLabel;
            break;
        case QliqModelViewModeEdit:
            label = _providerLabel;
            break;
        case QliqModelViewModeView:
            label = _viewProviderLabel;
            break;
		default:
			break;
    }
	if (self.appointment.referringPhysicianName == nil) {
        label.textColor = [UIColor colorWithWhite:0.5098 alpha:1.0f];
        label.text = NSLocalizedString(@"Tap to select", @"Tap to select");
	}
	else {
		label.textColor = [UIColor blackColor];
		label.text = self.appointment.referringPhysicianName;
	}
}

- (void)updateStartDateLabel {
    UILabel *label = nil;
    switch (self.currentViewMode) {
        case QliqModelViewModeAdd:
            label = _addStartTimeLabel;
            break;
        case QliqModelViewModeEdit:
            label = _startTimeLabel;
            break;
        case QliqModelViewModeView:
            label = _viewStartTimeLabel;
            break;
		default:
			break;
    }
	//RA: changed to ==
	if (self.appointment.apptDate == 0 && self.appointment.apptStart == 0) {
        label.textColor = [UIColor colorWithWhite:0.5098 alpha:1.0f];
        label.text = NSLocalizedString(@"Tap to select", @"Tap to select");
	}
	else {
		label.textColor = [UIColor blackColor];
        NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
        [formatter setDateStyle:NSDateFormatterMediumStyle];
        [formatter setTimeStyle:NSDateFormatterMediumStyle];
		label.text = [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:self.appointment.apptDate]];
	}
}

- (void)updateDurationLabel:(NSString *)txt {
    UILabel *label = nil;
    switch (self.currentViewMode) {
        case QliqModelViewModeAdd:
            label = _addDurationLabel;
            break;
        case QliqModelViewModeEdit:
            label = _durationLabel;
            break;
        case QliqModelViewModeView:
            label = _viewDurationLabel;
            break;
		default:
			break;
    }
	
    label.textColor = [UIColor blackColor];
    label.text = txt;
}

- (void)updateReminderLabel:(NSString *)txt {
    UILabel *label = nil;
    switch (self.currentViewMode) {
        case QliqModelViewModeAdd:
            label = _addReminderLabel;
            break;
        case QliqModelViewModeEdit:
            label = _reminderLabel;
            break;
        case QliqModelViewModeView:
            label = _viewReminderLabel;
            break;
		default:
			break;
    }
    
    label.textColor = [UIColor blackColor];
    label.text = txt;
}


#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];
	self.view.backgroundColor = [UIColor colorWithWhite:0.2196 alpha:1.0f];
    
    self.chatButton.btnType = StretchableButton25;
    _editButton.btnType = StretchableButton25;
    _finishButton.btnType = StretchableButton25;
    
    _blankView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.bounds.size.width, self.view.bounds.size.height - 86)];
    _blankView.backgroundColor = [UIColor colorWithWhite:0.2196 alpha:1.0f];
    [self.view addSubview:_blankView];
    _startDatePicker = [[UIDatePicker alloc] init];
    _startDatePicker.datePickerMode = UIDatePickerModeDateAndTime;
    CGRect frame = _startDatePicker.frame;
    frame.origin.y = 44;
    _startDatePicker.frame = frame;
    
    UIToolbar *pickerToolbar = [[UIToolbar alloc] init];
    [pickerToolbar sizeToFit];
    pickerToolbar.barStyle = UIBarStyleBlackTranslucent;
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *doneButton =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(startDateDoneClicked:)];
    NSArray *array = [NSArray arrayWithObjects:flexibleSpace, doneButton, nil];
    [flexibleSpace release];
    [doneButton release];
    [pickerToolbar setItems:array];

    UIView *pickerWrapper = [[UIView alloc] initWithFrame:CGRectMake(0.0, 460, 320, 244)];
    [pickerWrapper addSubview:pickerToolbar];
    [pickerWrapper addSubview:_startDatePicker];
    
    [self.view addSubview:pickerWrapper];
    [pickerToolbar release];
    [pickerWrapper release];
    _appointment = [[Appointment alloc] initWithPrimaryKey:0];
    self.appointment.physicianNpi = self.physician.physicianNpi;
    _duration = 0;
    if (_currentViewMode == QliqModelViewModeUnknown) {
        // MZ: this call triggers custom setter
        self.currentViewMode = QliqModelViewModeAdd;
    }
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updatePatientLabel];
    [self updateLocationLabel];
    [self updateReferringLabel];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
    
    [self.view bringSubviewToFront:_startDatePicker.superview];
    
	/*
    if ([self.navigationController.viewControllers count] <= 2) {
        [self saveAppointment:nil];
    }*/
}

- (void)viewDidUnload {
	[_appointment release];
	_appointment = nil;
    [_durationPickedImage release];
    _durationPickedImage = nil;
    [_durationSelectorView release];
    _durationSelectorView = nil;
    [_reminderPickedImage release];
    _reminderPickedImage = nil;
    [_reminderSelectorView release];
    _reminderSelectorView = nil;
    [_addReminderLabel release];
    _addReminderLabel = nil;
    [_addProviderLabel release];
    _addProviderLabel = nil;
    [_addDurationLabel release];
    _addDurationLabel = nil;
    [_addStartTimeLabel release];
    _addStartTimeLabel = nil;
    [_addReasonField release];
    _addReasonField = nil;
    [_addLocationLabel release];
    _addLocationLabel = nil;
    [_addPatientLabel release];
    _addPatientLabel = nil;
    [_addView release];
    _addView = nil;
    [_viewReminderLabel release];
    _viewReminderLabel = nil;
    [_viewProviderLabel release];
    _viewProviderLabel = nil;
    [_viewDurationLabel release];
    _viewDurationLabel = nil;
    [_viewStartTimeLabel release];
    _viewStartTimeLabel = nil;
    [_viewReasonLabel release];
    _viewReasonLabel = nil;
    [_viewLocationLabel release];
    _viewLocationLabel = nil;
    [_viewPatientLabel release];
    _viewPatientLabel = nil;
    [_viewView release];
    _viewView = nil;
    [_reminderLabel release];
    _reminderLabel = nil;
    [_providerLabel release];
    _providerLabel = nil;
    [_durationLabel release];
    _durationLabel = nil;
    [_startTimeLabel release];
    _startTimeLabel = nil;
    [_reasonField release];
    _reasonField = nil;
    [_locationLabel release];
    _locationLabel = nil;
    [_patientLabel release];
    _patientLabel = nil;
    [_finishButton release];
    _finishButton = nil;
    [_editButton release];
    _editButton = nil;
    [self.chatButton release];
    self.chatButton = nil;
    [_blankView release];
    _blankView = nil;
    [_buttonView release];
    _buttonView = nil;
    [_editView release];
    _editView = nil;
}

- (void)dealloc {
	[_appointment release];	
    [_blankView release];
    [_editView release];
    [_buttonView release];
    [_editButton release];
    [_finishButton release];
    [_patientLabel release];
    [_locationLabel release];
    [_reasonField release];
    [_startTimeLabel release];
    [_durationLabel release];
    [_providerLabel release];
    [_reminderLabel release];
    [_viewView release];
    [_viewPatientLabel release];
    [_viewLocationLabel release];
    [_viewReasonLabel release];
    [_viewStartTimeLabel release];
    [_viewDurationLabel release];
    [_viewProviderLabel release];
    [_viewReminderLabel release];
    [_addView release];
    [_addPatientLabel release];
    [_addLocationLabel release];
    [_addReasonField release];
    [_addStartTimeLabel release];
    [_addDurationLabel release];
    [_addProviderLabel release];
    [_addReminderLabel release];
    [_reminderSelectorView release];
    [_reminderPickedImage release];
    [_durationSelectorView release];
    [_durationPickedImage release];
	[super dealloc];
}

#pragma mark -
#pragma mark UITextFieldDelegate

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField.tag == 1) {
        NSLog(@"%@", textField.text);
    }
    else if (textField.tag == 2) {
        self.appointment.reason = textField.text;
    }
    
    if (textField == (UITextField *)_addReasonField) {
        self.appointment.reason = textField.text;
    }
    
	[textField resignFirstResponder];
	return YES;
}

#pragma mark -
#pragma mark Actions

-(IBAction)btnSelectFacility:(id)sender{
	FacilityListView *tempController=[[FacilityListView alloc] init];
    tempController.previousControllerTitle = NSLocalizedString(@"Appointment", @"Appointment");
	[self.navigationController pushViewController:tempController animated:YES];
	[tempController autorelease];
}

-(IBAction)btnSelectPatient:(id)sender{
	ArchivedPatientListView *tempController=[[ArchivedPatientListView alloc] init];
    tempController.adding = @"appts";
	[self.navigationController pushViewController:tempController animated:YES];
	[tempController autorelease];
}

-(IBAction)btnSelectReferral:(id)sender{
	ReferralListView *tempController=[[ReferralListView alloc] init];
	[self.navigationController pushViewController:tempController animated:YES];
	[tempController autorelease];
}


- (IBAction)presentPatientList:(id)sender {
	ArchivedPatientListView *tempController=[[ArchivedPatientListView alloc] init];
    tempController.previousControllerTitle = NSLocalizedString(@"Appointment", @"Appointment");
    tempController.adding = @"appts";
	[self.navigationController pushViewController:tempController animated:YES];
	[tempController autorelease];
}

- (IBAction)presentLocationList:(id)sender {
	FacilityListView *tempController=[[FacilityListView alloc] init];
    tempController.previousControllerTitle = NSLocalizedString(@"Appointment", @"Appointment");
	[self.navigationController pushViewController:tempController animated:YES];
	[tempController autorelease];
}

- (IBAction)presentStartTimePicker:(id)sender {
    CGRect frame = _startDatePicker.superview.frame;
    frame.origin.y = 156;
    _startDatePicker.superview.frame = frame;
}

- (IBAction)presentDurationList:(id)sender {
    [self.view bringSubviewToFront:_blankView];
    [self.view bringSubviewToFront:_durationSelectorView];
    CGRect frame = _durationSelectorView.frame;
    frame.origin.y = 0;
    _durationSelectorView.frame = frame;

}

- (IBAction)presentProviderList:(id)sender {
    ReferralListView *tempController=[[ReferralListView alloc] init];
    tempController.previousControllerTitle = NSLocalizedString(@"Appointment", @"Appointment");
	[self.navigationController pushViewController:tempController animated:YES];
	[tempController autorelease];

}

- (IBAction)presentReminderList:(id)sender {
    [self.view bringSubviewToFront:_blankView];
    [self.view bringSubviewToFront:_reminderSelectorView];
    CGRect frame = _reminderSelectorView.frame;
    frame.origin.y = 0;
    _reminderSelectorView.frame = frame;

}

- (IBAction)selectReminder:(id)sender {
    UIButton *btn = sender;
    NSInteger minutes = btn.tag;
    _reminderPickedImage.hidden = NO;
    [btn.superview addSubview:_reminderPickedImage];
 
    CGRect frame = _reminderSelectorView.frame;
    frame.origin.y = 460;
    _reminderSelectorView.frame = frame;

    self.currentViewMode = _currentViewMode;
    self.appointment.reminder = minutes;
    
    NSString *text = [[btn.superview.subviews objectAtIndex:0] text];
    [self updateReminderLabel:text];

}

- (IBAction)selectDuration:(id)sender {
    UIButton *btn = sender;
    NSInteger minutes = btn.tag;
    _durationPickedImage.hidden = NO;
    [btn.superview addSubview:_durationPickedImage];
    
    CGRect frame = _durationSelectorView.frame;
    frame.origin.y = 460;
    _durationSelectorView.frame = frame;
    
    self.currentViewMode = _currentViewMode;
    _duration = minutes;
    if (self.appointment.apptStart > 0) {
        self.appointment.apptEnd = self.appointment.apptStart + (60 *_duration);
    }
    
    NSString *text = [[btn.superview.subviews objectAtIndex:0] text];
    [self updateDurationLabel:text];
}

- (void)reminderSliderUpdated:(id)sender {
    UISlider *slider = sender;
    self.appointment.reminder = (int)slider.value;
}

- (void)durationDoneClicked:(id)sender {
//    UITableViewCell *cell = [tblAppt cellForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
//    [cell.editingAccessoryView resignFirstResponder];
//    _duration = [[cell.editingAccessoryView text] integerValue];
//    if (self.appointment.apptStart > 0) {
//        self.appointment.apptEnd = self.appointment.apptStart + (60 *_duration);
//    }
}

- (void)btnSelectStartDate {
    CGRect frame = _startDatePicker.superview.frame;
    frame.origin.y = 156;
    _startDatePicker.superview.frame = frame;
}

- (void)startDateDoneClicked:(id)sender {
    CGRect frame = _startDatePicker.superview.frame;
    frame.origin.y = 460;
    _startDatePicker.superview.frame = frame;
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSDateComponents *apptDateComponents = [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit) fromDate:_startDatePicker.date];
//    [apptDateComponents setHour:0];
//    [apptDateComponents setMinute:0];
    [apptDateComponents setSecond:0];
    NSDateComponents *apptStartComponents = [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit) fromDate:_startDatePicker.date];
    [apptStartComponents setSecond:0];
    NSDate *apptDate = [gregorian dateFromComponents:apptDateComponents];
    NSDate *apptStart = [gregorian dateFromComponents:apptStartComponents];
    self.appointment.apptDate = [apptDate timeIntervalSince1970];
    self.appointment.apptStart = [apptStart timeIntervalSince1970];

    NSLog(@"%@ -> %f", apptDate, self.appointment.apptDate);
    NSLog(@"%@ -> %f", apptStart, self.appointment.apptStart);
    
    if (_duration > 0) {
        [apptStartComponents setYear:0];
        [apptStartComponents setMonth:0];
        [apptStartComponents setDay:0];
        [apptStartComponents setHour:0];
        [apptStartComponents setMinute:_duration];
        [apptStartComponents setSecond:0];
        NSDate *apptEnd = [gregorian dateByAddingComponents:apptStartComponents toDate:apptStart options:0];
        self.appointment.apptEnd = [apptEnd timeIntervalSince1970];
    }
    
    
    [gregorian release];
    [self updateStartDateLabel];
//    [tblAppt reloadData];
//    self.appointment.apptStart
}

- (IBAction)saveAppointment:(id)sender {
    BOOL isError = NO;
    NSMutableArray *missingFields = [NSMutableArray arrayWithCapacity:5];
    if (self.appointment.facilityNpi <= 0) {
        isError = YES;
        [missingFields addObject:NSLocalizedString(@"Facility", @"Facility")];
    }
    if (self.appointment.physicianNpi <= 0) {
        isError = YES;
        [missingFields addObject:NSLocalizedString(@"Physician", @"Physician")];
    }
    if (self.appointment.patientId <= 0) {
        isError = YES;
        [missingFields addObject:NSLocalizedString(@"Patient", @"Patient")];
    }
    if (self.appointment.apptStart <= 0) {
        isError = YES;
        [missingFields addObject:NSLocalizedString(@"Start Time", @"Start Time")];
    }
    if (self.appointment.reason == nil) {
        isError = YES;
        [missingFields addObject:NSLocalizedString(@"Reason", @"Reason")];
    }
    if (isError) {
        NSString *errorString = nil;
        if ([missingFields count] > 0) {
            errorString = [NSString stringWithFormat:@"%@\n%@", NSLocalizedString(@"There is missing field:", @"There is missing field"), [missingFields componentsJoinedByString:@", "]];
        }
        else {
            errorString = [NSString stringWithFormat:@"%@\n%@", NSLocalizedString(@"There are missing fields:", @"There are missing fields"), [missingFields componentsJoinedByString:@", "]];
        }
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error") 
                                                        message:errorString
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", @"OK") 
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
		
    }
    else {
        BOOL success = [Appointment addAppointment:self.appointment];
        NSLog(@"appt saved ? %d", success);
        [self.navigationController popViewControllerAnimated:YES];
    }

}

- (void)setCurrentViewMode:(QliqModelViewMode)mode {
    //if (mode != _currentViewMode) {
    _currentViewMode = mode;
	switch (self.currentViewMode) {
		case QliqModelViewModeAdd:
		{
			self.navigationItem.rightBarButtonItem = [self rightItemWithTitle:NSLocalizedString(@"Add Appointment", @"Add Appointment") 
																  buttonImage:nil
																 buttonAction:nil];

			
			break;
		}
		case QliqModelViewModeView:
		case QliqModelViewModeEdit:
		{
			self.navigationItem.rightBarButtonItem = [self rightItemWithTitle:NSLocalizedString(@"Appointment", @"Appointment") 
																  buttonImage:nil
																 buttonAction:nil];
			
		}
			break;
			
		case QliqModelViewModeUnknown:
		default:
			break;
	}
    
    if (_buttonView.superview != self.view) {
        [self.view addSubview:_buttonView];
    }
    
	UIView *viewForMode = [self viewForMode:self.currentViewMode];
	if (viewForMode.superview != self.view) {
		[self.view addSubview:viewForMode];
	}
    
	[self.view bringSubviewToFront:_blankView];
	[self.view bringSubviewToFront:viewForMode];
    // MZ: keep picker always on top, even if it's not visible
    [self.view bringSubviewToFront:_startDatePicker.superview];
    
    NSLog(@"%@", self.view);
    NSLog(@"%@", self.view.subviews);
    //}
}

#pragma mark -
#pragma mark Private

- (UIView *)viewForMode:(QliqModelViewMode)viewMode {
    switch (viewMode) {
        case QliqModelViewModeView:
        {
            return _viewView;
        }
			
		case QliqModelViewModeAdd:
        {
			UIView *editButton = (UIView *)[self.view viewWithTag:21];
			editButton.hidden=YES;
            return _addView;
        }
            break;
            
		case QliqModelViewModeEdit: 
        {
            return _editView;
        }
		default:
			break;
    }
    
    return nil;
}


#pragma mark -
#pragma mark Keyboard notifications handling

- (void)keyboardOn:(id)sender {
	if (self.isKeyboardOn) {
		return;
	}
    // MZ: adjust the table view when keyboard is on
//	CGRect rect = tblAppt.frame;
//	rect.size.height = 200;
//	tblAppt.frame = rect;
	
	self.keyboardOn = YES;
}

- (void)keyboardOff:(id)sender {
	if (!self.isKeyboardOn) {
		return;
	}
    // MZ: adjust the table view when keyboard is off
//	CGRect rect = tblAppt.frame;
//	rect.size.height = 300;
//	tblAppt.frame = rect;
	
	self.keyboardOn = NO;
}


@end
