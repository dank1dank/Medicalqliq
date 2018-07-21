// Created by Developer Toy
//AddPatientView.m
#import "RoundViewController.h"
#import "AVFoundation/AVFoundation.h"
#import "RaceListView.h"
#import "InsuranceListView.h"
#import "LightGreyGlassGradientView.h"
#import "StretchableButton.h"
#import "DarkGreyGlassGradientView.h"
#import "GreyGlassGradientView.h"
#import "LightGreyGradientView.h"
#import "CustomPlaceholderTextField.h"
#import "LightGreyGlassGradientView.h"
#import "Patient_old.h"
#import "Helper.h"
#import "Census_old.h"
#import "ConversationListViewController.h"
#import "FacilityListView.h"
#import "ReferralListView.h"
#import "ArchivedPatientListView.h"
#import "GTMRegex.h"
#import "NSDate+Helper.h"
#import "Facility_old.h"
#import "Outbound.h"
#import "Log.h"

@interface RoundViewController()
- (void)showAlertWithTitle:(NSString *)aTitle message:(NSString *)aMessage;
@end

@implementation RoundViewController

@synthesize currentViewMode = _currentViewMode;
@synthesize census = _census;
@synthesize patient = _patient;
@synthesize physicianPref = _physicianPref;
@synthesize selectedEthnicity = _selectedEthnicity;
@synthesize selectedFacilityName = _selectedFacilityName;
@synthesize selectedFacilityId = _selectedFacilityId;
@synthesize selectedReferringPhysicianName = _selectedReferringPhysicianName;
@synthesize selectedReferringPhysicianId = _selectedReferringPhysicianId;
@synthesize selectedDos = _selectedDos;

- (void)loadView {
    [super loadView];
	
}
- (void)setLastUsedFacility {
	if(self.physicianPref.lastUsedFacilityId>0){
		Facility_old *facilityObj = [[Facility_old getFacility:self.physicianPref.lastUsedFacilityId] retain];
		_census.facilityNpi = self.physicianPref.lastUsedFacilityId;
		self.selectedFacilityId = self.physicianPref.lastUsedFacilityId;
		self.selectedFacilityName = facilityObj.name;
		[facilityObj release];
	}
}


- (void)viewDidLoad {
    [super viewDidLoad];
	self.view.backgroundColor = [UIColor colorWithWhite:0.2196 alpha:1.0f];
    _blankView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.bounds.size.width, self.view.bounds.size.height - 86)];
    _blankView.backgroundColor = [UIColor colorWithWhite:0.2196 alpha:1.0f];
    [self.view addSubview:_blankView];
    if (_currentViewMode == QliqModelViewModeUnknown) {
        // MZ: this call triggers custom setter
        self.currentViewMode = QliqModelViewModeAdd;
    }
	
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setNavigationBarBackgroundImage];
	if(_currentViewMode != QliqModelViewModeView){
		if(_census.admitDate >0){
			[self updateAdmitDateLabel];
		}
		if (self.selectedEthnicity != nil) {
			[self updateEthnicityLabel];
		}
		if (self.selectedFacilityName != nil) {
			[self updateFacilityLabel];
		}
		if (self.selectedReferringPhysicianName != nil) {
			[self updateReferringPhysicinLabel];
		}
	}
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
	//    NSLog(@"%@", self.view);
	//    NSLog(@"%@", self.view.subviews);
}


-(IBAction)btnDoneAddPatient:(id)sender{
	NSArray *controllers =self.navigationController.viewControllers;
	int level=[controllers count]-2;
	if (level>=0) {
		UIViewController *last=(UIViewController *)[controllers objectAtIndex:level];
		[last.navigationController popViewControllerAnimated:YES];
	}
}
/*
 - (void)textFieldDidBeginEditing:(UITextField *)textFieldView{
 currentTextField = textFieldView;
 NSLog(@"textFieldDidBeginEditing currentTextField tag : %d",currentTextField.tag);
 switch (currentTextField.tag) {
 case 51:
 case 52:
 //currentTextField = nil;
 [textFieldView resignFirstResponder];
 
 pickerViewPopup = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
 
 pickerView = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 44, 0, 0)];
 pickerView.datePickerMode = UIDatePickerModeDate;
 pickerView.hidden = NO;
 pickerView.date = [NSDate date];
 
 pickerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
 pickerToolbar.barStyle = UIBarStyleBlackOpaque;
 [pickerToolbar sizeToFit];
 
 NSMutableArray *barItems = [[NSMutableArray alloc] init];
 
 UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
 [barItems addObject:flexSpace];
 
 UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed:)];
 [barItems addObject:doneBtn];
 
 UIBarButtonItem *cancelBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed:)];
 [barItems addObject:cancelBtn];
 
 [pickerToolbar setItems:barItems animated:YES];
 
 [pickerViewPopup addSubview:pickerToolbar];
 [pickerViewPopup addSubview:pickerView];
 [pickerViewPopup showInView:self.navigationController.view];
 [pickerViewPopup setBounds:CGRectMake(0,0,320, 464)];
 break;
 default:
 break;
 }	
 
 }
 -(void)doneButtonPressed:(id)sender{
 //Do something here here with the value selected using [pickerView date] to get that value
 NSDate *selectedDate = [pickerView date];
 NSString *strDate = [NSDate stringFromDate:selectedDate withFormat:@"MM/dd/yyyy"];
 NSLog(@"currentTextField tag : %d",currentTextField.tag);
 currentTextField.text = strDate;
 [pickerViewPopup dismissWithClickedButtonIndex:1 animated:YES];
 currentTextField = nil;
 }
 
 -(void)cancelButtonPressed:(id)sender{
 [pickerViewPopup dismissWithClickedButtonIndex:1 animated:YES];
 currentTextField = nil;
 }
 */
//---when a TextField view begins editing---
-(void) textFieldDidBeginEditing:(UITextField *)textFieldView {
	currentTextField = textFieldView;
}

//---when the user taps on the return key on the keyboard---
-(BOOL) textFieldShouldReturn:(UITextField *) textFieldView {
	
    UIView* nextView = nil;
    
    if (responderChainOnReturn)
    {
        NSUInteger currentIndex = [responderChainOnReturn indexOfObject: [NSNumber numberWithInt: textFieldView.tag]];
        if (currentIndex != NSNotFound && currentIndex + 1 < [responderChainOnReturn count])
        {
            NSNumber* nextIndex = [responderChainOnReturn objectAtIndex: currentIndex + 1];
            nextView = [self.view viewWithTag: [nextIndex intValue]];
        }
    }
    
    if (nextView)
    {
        [nextView becomeFirstResponder];
    }
    else
    {
        [textFieldView resignFirstResponder];
    }
    return NO;
}

//---when a TextField view is done editing---
-(void) textFieldDidEndEditing:(UITextField *) textFieldView {
    currentTextField = nil;
}

-(IBAction)clickSelectRace:(id)sender{
	RaceListView *tempController=[[RaceListView alloc] init];
    tempController.previousControllerTitle = NSLocalizedString(@"Add Rounds", @"Add Rounds");
	[self.navigationController pushViewController:tempController animated:YES];
	[tempController autorelease];
}
-(IBAction)clickSelectInsurance:(id)sender{
	InsuranceListView *tempController=[[InsuranceListView alloc] init];
	[self.navigationController pushViewController:tempController animated:YES];
	[tempController autorelease];
}

- (void)clickSelectPatient:(id)sender {
    ArchivedPatientListView *tempController = [[ArchivedPatientListView alloc] init];
    tempController.previousControllerTitle = NSLocalizedString(@"Add Rounds", @"Add Rounds");
    [self.navigationController pushViewController:tempController animated:YES];
    [tempController release];
}

- (void)clickSelectFacility:(id)sender {
    FacilityListView *tempController = [[FacilityListView alloc] init];
    tempController.previousControllerTitle = NSLocalizedString(@"Add Rounds", @"Add Rounds");
    [self.navigationController pushViewController:tempController animated:YES];
    [tempController release];
}

- (void)clickSelectReferal:(id)sender {
    ReferralListView *tempController = [[ReferralListView alloc] init];
    tempController.previousControllerTitle = NSLocalizedString(@"Add Rounds", @"Add Rounds");
    [self.navigationController pushViewController:tempController animated:YES];
    [tempController release];
}

- (void)clickCancel:(id)sender {
	//Cancel go back
	NSArray *controllers =self.navigationController.viewControllers;
	int level=[controllers count]-2;
	if (level>=0) {
		UIViewController *last=(UIViewController *)[controllers objectAtIndex:level];
		[last.navigationController popViewControllerAnimated:YES];
	}	
}

- (void)clickDone:(id)sender {
	UIView* nextView =nil;
	for(int i=0;i<[responderChainOnReturn count];i++){
		NSNumber* nextIndex = [responderChainOnReturn objectAtIndex: i];
		nextView = [self.view viewWithTag: [nextIndex intValue]];
		if ([nextView isKindOfClass:[UITextField class]])
			[nextView resignFirstResponder];
	}
	if([self savePatientRoundsData]){
		self.physicianPref.lastUsedFacilityId = _census.facilityNpi;
		[PhysicianPref updatePhysicianPrefs:self.physicianPref];
		if(self.currentViewMode == QliqModelViewModeEdit){
			_editButton.enabled = YES;
			_notesButton.enabled = YES;
			_dischargeButton.enabled = YES;
			self.chatButton.enabled=YES;
			self.currentViewMode = QliqModelViewModeView;
			[self updateViewFields];
		}else{
			NSArray *controllers =self.navigationController.viewControllers;
			int level=[controllers count]-3;
			if (level>=0) {
				[self.navigationController popToViewController:[[self.navigationController viewControllers] objectAtIndex:2] animated:YES];
			}
		}
	}
}

- (BOOL)savePatientRoundsData {
	//Done button to validate the form
    //and save
	BOOL retval = YES;
	//populate all fields, save patient, then save census
	if([self populateRoundsData])
	{
		if(self.currentViewMode==QliqModelViewModeEdit || self.currentViewMode==QliqModelViewModeAdd){
			//save patient
			if(_census.patientId==0){
				//add new patient
				NSInteger newPatientId = [Patient_old addPatient:self.patient];
				_census.patientId=newPatientId;
				self.patient.patientId=newPatientId;
			}else {
				//update the patient
				[Patient_old updatePatient:self.patient];
			}
		}
		//save census
		if(_census.censusId==0){
            // [DBPersist addPatientToCensus] will create a new metadata and set
            // current user as author.
			NSInteger newRoundsRecId = [Census_old addPatientToCensus:_census];
			NSLog(@"newRoundsRecId: %d",newRoundsRecId);
		}else {
			[Census_old updateCensus:_census];
            //[_census setMetadataAuthor:[Metadata defaultAuthor]];
            [_census setRevisionDirty:YES];
		}
	}else {
		retval=NO;
	}
    if(self.currentViewMode != QliqModelViewModeEdit){
		if (retval) {
			[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:SAVED_ROUND_NOTIFICATION object:_census]];
		}
	}
	return retval;
}

- (BOOL) populateRoundsData {
	BOOL validData=YES;
	//demographics info
	NSString *firstName=nil; //tag : 41
	NSString *middleName=nil; //tag : 42
	NSString *lastName=nil;  //tag: 40
	NSString *gender=nil;//male tag:43 female tag:44
	NSString *strDob=nil;//tag:45
	NSString *race=nil;
	//facility info
	double facilityNpi;
	NSString *mrn;//tag 48
	NSString *room;//tag 49
	//visit info
	NSString *strAdmitDate=nil;//tag 51
	NSString *strDischargeDate=nil;//tag 52
	//NSInteger referralId;
	
	
	if(self.currentViewMode == QliqModelViewModeAdd || self.currentViewMode == QliqModelViewModeEdit){
		
		UITextField	*lastNameField = (UITextField *)[self.view viewWithTag:40];
		UITextField	*firstNameField = (UITextField *)[self.view viewWithTag:41];
		UITextField	*middleNameField = (UITextField *)[self.view viewWithTag:42];
		UITextField	*dobField = (UITextField *)[self.view viewWithTag:45];
		UIButton *btnMale = (UIButton *)[self.view viewWithTag:43];
		UIButton *btnFemale = (UIButton *)[self.view viewWithTag:44];
		
		
		//demographics
		firstName = firstNameField.text;
		middleName = middleNameField.text;
		lastName = lastNameField.text;
		if(btnMale.selected)
			gender=btnMale.titleLabel.text;
		else if(btnFemale.selected)	
			gender=btnFemale.titleLabel.text;
		
		
		strDob = dobField.text;
		race = self.selectedEthnicity;
		
		if((firstName==nil) || [firstName length]==0 || (lastName==nil) || [lastName length]==0){
			[self showAlertWithTitle:NSLocalizedString(@"Patient name cannot be blank", @"Patient name cannot be blank ") 
							 message:NSLocalizedString(@"Please enter the patient name <first middle last> before saving", @"Please enter the patient name <first middle last> before saving")];
			validData=NO;
		}
		if((gender==nil) || [gender length]==0){
			[self showAlertWithTitle:NSLocalizedString(@"Patient gender cannot be blank", @"Patient gender cannot be blank ") 
							 message:NSLocalizedString(@"Please select <Male> or <Female> before saving", @"Please select <Male> or <Female> before saving")];
			validData=NO;
		}
	}	
	UITextField	*mrnField = (UITextField *)[self.view viewWithTag:48];
	UITextField	*roomField = (UITextField *)[self.view viewWithTag:49];
	UITextField	*admitDateField = (UITextField *)[self.view viewWithTag:51];
	UITextField	*dischargeDateField = (UITextField *)[self.view viewWithTag:52];
	
	//facility
	facilityNpi = self.selectedFacilityId;
	mrn = mrnField.text;
	room = roomField.text;
	//visit
	strAdmitDate = admitDateField.text;
	strDischargeDate = dischargeDateField.text;
	
	NSTimeInterval admitDateInSecs;
	NSTimeInterval dischargeDateInSecs;
	if(facilityNpi<=0){
		[self showAlertWithTitle:NSLocalizedString(@"Facility Missing", @"Facility Missing ") 
						 message:NSLocalizedString(@"Choose the facility before saving", @"Choose the facility before saving")];
		validData=NO;
	}		
	if((strAdmitDate==nil) || [strAdmitDate length]==0){
		[self showAlertWithTitle:NSLocalizedString(@"Patient admit date cannot be blank", @"Patient admit date cannot be blank ") 
						 message:NSLocalizedString(@"Please enter admit date before saving", @"Please enter admit date before saving")];
		validData=NO;
	}else {
		
		/*
		 if([self validateDate:strAdmitDate]){
		 [self showAlertWithTitle:NSLocalizedString(@"Invalid Admit Date", @"Invalid Admit Date ") 
		 message:NSLocalizedString(@"Please enter the patient admit date in <mm/dd/yyyy> format before saving", @"Please enter the patient admit date in <mm/dd/yyyy> format before saving")];
		 validData=NO;
		 }else {
		 */
		admitDateInSecs = [Helper strDateToInterval:strAdmitDate :@"MM/dd/yyyy"];
		if([Census_old hasPriorChargesToAdmitDate:_census andNewAdmitDate:admitDateInSecs]){
			[self showAlertWithTitle:NSLocalizedString(@"Patient admit date is not valid", @"Patient admit date is not valid ") 
							 message:NSLocalizedString(@"Patient has charges prior to this admit date, please choose the right date", @"Patient has charges prior to this admit date, please choose the right date")];
			validData=NO;
		}
		//}
	}
	
	if((strDischargeDate!=nil) && ([strDischargeDate length]>0) && [Census_old hasLaterChargesToDischargeDate:_census andNewDischargeDate:dischargeDateInSecs]){
		[self showAlertWithTitle:NSLocalizedString(@"Patient discharge date is not valid", @"Patient discharge date is not valid ") 
						 message:NSLocalizedString(@"Patient has charges after this discharge date, please choose the right date", @"Patient has charges after this discharge date, please choose the right date")];
		validData=NO;
	}
	
	
	self.patient.firstName=firstName;
	self.patient.lastName=lastName;
	self.patient.middleName=middleName;
	self.patient.gender=gender;
	
	NSTimeInterval dobtime;
	if(strDob!=nil && [strDob length]>0){
		dobtime = [Helper strDateToInterval:strDob :@"MM/dd/yyyy"];
		self.patient.dateOfBirth = dobtime;
	}
	self.patient.race = race;
	
	_census.mrn=mrn;
	_census.room=room;
	_census.referringPhysicianNpi=self.selectedReferringPhysicianId;
	_census.referringPhysicianName=self.selectedReferringPhysicianName;
	_census.facilityNpi=self.selectedFacilityId;
	_census.facilityName=self.selectedFacilityName;
	_census.admitDate=admitDateInSecs;
	if(strDischargeDate!=nil && [strDischargeDate length]>0){
		dischargeDateInSecs = [Helper strDateToInterval:strDischargeDate :@"MM/dd/yyyy"];
		_census.dischargeDate = dischargeDateInSecs;
	}else {
		_census.dischargeDate=0;	
	}

	UIButton *btnAdmit = (UIButton *)[self.view viewWithTag:53];
	UIButton *btnConsult = (UIButton *)[self.view viewWithTag:54];
	
	NSLog(@"NonConsult :%d",NonConsult);
	NSLog(@"Consult :%d",Consult);
	NSLog(@"_census.censusType :%d",_census.censusType);
	
	if(btnAdmit.selected)
		_census.censusType=NonConsult;
	else if(btnConsult.selected)	
		_census.censusType=Consult;
	
	NSLog(@"_census.censusType :%d",_census.censusType);

	_census.active=YES;
	
	return validData;	
}


- (BOOL) validateDate:(NSString*) dateAsStr {
	BOOL validData=YES;
	// MZ: check if date is in correct format
	if(![dateAsStr gtm_matchesPattern:@"[0-9]+/[0-9]+/[0-9]{4}"]){
		validData=NO;
	}	
	return validData;
}

/*
 - (BOOL)savePatientRoundsData {
 //Done button to validate the form
 //and save
 BOOL retval = YES;
 if([self populatePatientData]){
 if(_census.patientId==0){
 //add new patient
 NSInteger newPatientId = [Patient addPatient:self.patient];
 _census.patientId=newPatientId;
 self.patient.patientId=newPatientId;
 }else {
 [Patient updatePatient:self.patient];
 }
 
 if([self populateRoundsData]){
 //finally save the record
 if(_census.censusId==0){
 NSInteger newRoundsRecId = [Census addPatientToCensus:_census];
 NSLog(@"newRoundsRecId: %d",newRoundsRecId);
 }else {
 [Census updateCensus:_census];	
 }
 }else {
 retval = NO;
 }
 }else {
 retval=NO;
 }
 if(self.currentViewMode != QliqModelViewModeEdit){
 if (retval) {
 [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:SAVED_ROUND_NOTIFICATION object:_census]];
 }
 }
 
 return retval;
 }
 
 - (BOOL) populatePatientData {
 BOOL validData=YES;
 //set the form field values to census object
 NSString *patientName=nil; //tag : 40
 NSString *firstName=nil; //tag : 40
 NSString *middleName=nil; //tag : 41
 NSString *lastName=nil;  //tag: 42
 NSString *dob=nil;//tag:45
 
 if(self.currentViewMode == QliqModelViewModeAdd || self.currentViewMode == QliqModelViewModeEdit){
 
 UITextField	*firstNameField = (UITextField *)[self.view viewWithTag:40];
 firstName = firstNameField.text;
 UITextField	*middleNameField = (UITextField *)[self.view viewWithTag:41];
 middleName = middleNameField.text;
 UITextField	*lastNameField = (UITextField *)[self.view viewWithTag:42];
 lastName = lastNameField.text;
 
 UITextField	*dobField = (UITextField *)[self.view viewWithTag:45];
 dob = dobField.text;
 if(dob != nil && [dob length]>0)
 self.patient.dateOfBirth = [Helper strDateToInterval:dob :@"MM/dd/yyyy"];
 else 
 self.patient.dateOfBirth=0;
 
 
 if(dob==nil || [dob length] ==0){
 self.patient.dateOfBirth=[Helper strDateToInterval:dob :@"MM/dd/yyyy"];
 [self showAlertWithTitle:NSLocalizedString(@"Date of Birth is empty", @"Date of Birth is empty") 
 message:NSLocalizedString(@"Please update the date of birth when available", @"Please update the date of birth when available")];
 }		
 }else{
 UITextField	*fullNameField = (UITextField *)[self.view viewWithTag:42];
 patientName = fullNameField.text;
 
 NSArray *chunks = [patientName componentsSeparatedByString: @" "];
 if([chunks count]==0){
 [self showAlertWithTitle:NSLocalizedString(@"Patient name cannot be blank", @"Patient name cannot be blank ") 
 message:NSLocalizedString(@"Please enter the patient name <first middle last> before saving", @"Please enter the patient name <first middle last> before saving")];
 validData=NO;
 }else {
 switch ([chunks count]) {
 case 1:
 //get only firstname
 firstName = [chunks objectAtIndex:0];
 break;
 case 2:
 {
 //get first and last names
 firstName = [chunks objectAtIndex:0];
 lastName = [chunks objectAtIndex:1];
 break;
 }	
 case 3:
 {
 //get first,middle and last names
 firstName = [chunks objectAtIndex:0];
 middleName = [chunks objectAtIndex:1];
 lastName = [chunks objectAtIndex:2];
 break;
 }	
 default:
 break;
 }
 }
 }
 if((firstName==nil) || [firstName length]==0 || (lastName==nil) || [lastName length]==0){
 [self showAlertWithTitle:NSLocalizedString(@"Patient name cannot be blank", @"Patient name cannot be blank ") 
 message:NSLocalizedString(@"Please enter the patient name <first middle last> before saving", @"Please enter the patient name <first middle last> before saving")];
 validData=NO;
 }else {
 
 
 NSString *gender=nil;//male tag:43 female tag:44
 NSString *race=nil;
 if(self.currentViewMode == QliqModelViewModeSelectedEdit){
 gender = self.patient.gender;
 race = self.patient.race;
 }else if(self.currentViewMode == QliqModelViewModeEdit){
 UITextField	*dobField = (UITextField *)[self.view viewWithTag:45];
 dob = dobField.text;
 if(dob != nil && [dob length]>0)
 self.patient.dateOfBirth = [Helper strDateToInterval:dob :@"MM/dd/yyyy"];
 
 race = self.selectedEthnicity;
 UIButton *btnMale = (UIButton *)[self.view viewWithTag:43];
 UIButton *btnFemale = (UIButton *)[self.view viewWithTag:44];
 if(btnMale.selected)
 gender=btnMale.titleLabel.text;
 else if(btnFemale.selected)	
 gender=btnFemale.titleLabel.text;
 }else {
 race = self.selectedEthnicity;
 UIButton *btnMale = (UIButton *)[self.view viewWithTag:43];
 UIButton *btnFemale = (UIButton *)[self.view viewWithTag:44];
 if(btnMale.selected)
 gender=btnMale.titleLabel.text;
 else if(btnFemale.selected)	
 gender=btnFemale.titleLabel.text;
 }
 
 self.patient.firstName=firstName;
 self.patient.lastName=lastName;
 self.patient.middleName=middleName;
 self.patient.gender=gender;
 self.patient.race = race;
 
 if(dob==nil || [dob length] ==0){
 [self showAlertWithTitle:NSLocalizedString(@"Date of Birth is empty", @"Date of Birth is empty") 
 message:NSLocalizedString(@"Please enter the patient date of birth <mm/dd/yyyy> before saving", @"Please enter the patient date of borth <mm/dd/yyyy> before saving")];
 validData=NO;
 }else {
 //check its in the right format
 if ([self validateDob:dob]) {
 self.patient.firstName=firstName;
 self.patient.lastName=lastName;
 self.patient.middleName=middleName;
 self.patient.gender=gender;
 self.patient.dateOfBirth=[Helper strDateToInterval:dob :@"MM/dd/yyyy"];
 self.patient.race = self.selectedEthnicity;
 }else {
 [self showAlertWithTitle:NSLocalizedString(@"Invalid Date", @"Invalid Date") 
 message:NSLocalizedString(@"Please enter the patient date of birth in <mm/dd/yyyy> format before saving", @"Please enter the patient date of birth in <mm/dd/yyyy> format before saving")];
 validData=NO;
 }
 }
 }
 return validData;	
 }
 - (BOOL) populateRoundsData {
 BOOL validData=YES;
 
 if(_census.patientId==0){
 [self showAlertWithTitle:NSLocalizedString(@"Invalid Patient", @"Invalid Patient") 
 message:NSLocalizedString(@"Problem with saving patient", @"Problem with saving the patient")];
 validData=NO;
 }else{
 _census.facilityNpi=self.selectedFacilityId;
 
 if(_census.facilityNpi==nil || _census.facilityNpi==0){
 [self showAlertWithTitle:NSLocalizedString(@"Facility Missing", @"Facility Missing ") 
 message:NSLocalizedString(@"Choose the facility before saving", @"Choose the facility before saving")];
 validData=NO;
 }else{
 NSString *mrn;//tag 48
 UITextField	*mrnField = (UITextField *)[self.view viewWithTag:48];
 mrn = mrnField.text;
 
 NSString *room;//tag 49
 UITextField	*roomField = (UITextField *)[self.view viewWithTag:49];
 room = roomField.text;
 
 _census.mrn=mrn;
 _census.room=room;
 _census.referringPhysicianNpi=self.selectedReferringPhysicianId;
 _census.referringPhysicianName=self.selectedReferringPhysicianName;
 _census.facilityName=self.selectedFacilityName;
 
 _census.active=YES;
 }
 }	
 return validData;
 }
 */

- (void)setSex:(id)sender {
	UIButton *btnSender = sender;
	int tag = 43;
	if (btnSender.tag == tag) {
		tag = 44;
	}
	UIButton *btnOther = (UIButton *)[self.view viewWithTag:tag];
	btnSender.selected = YES;
	btnOther.selected = NO;
}

- (void)setCensusType:(id)sender {
	UIButton *btnSender = sender;
	int tag = 53;
	if (btnSender.tag == tag) {
		tag = 54;
	}
	UIButton *btnOther = (UIButton *)[self.view viewWithTag:tag];
	btnSender.selected = YES;
	btnOther.selected = NO;
}

- (void)updateAdmitDateLabel {
	UILabel *admitDateLabel = (UILabel *)[self.view viewWithTag:51];
	if (_census.admitDate == 0) {
		if (_patient != nil) {
			admitDateLabel.text = [Helper convertIntervalToDateString:_census.admitDate:@"MM/dd/yyyy"];
			admitDateLabel.textColor = [UIColor blackColor];
		}
		else {
			admitDateLabel.textColor = [UIColor colorWithWhite:0.5098 alpha:1.0f];
			admitDateLabel.text = NSLocalizedString(@"Tap to add", @"Tap to add");
		}
	}
	else {
		admitDateLabel.textColor = [UIColor blackColor];
		admitDateLabel.text = [Helper convertIntervalToDateString:_census.admitDate:@"MM/dd/yyyy"];
	}
}

- (void)updateEthnicityLabel {
	UILabel *ethnicityLabel = (UILabel *)[self.view viewWithTag:47];
	if (self.selectedEthnicity == nil) {
		if (_patient != nil) {
			NSLog(@"_patient.race: %@",self.patient.race);
			//ethnicityLabel.text = _census.race;
			ethnicityLabel.text = self.patient.race;
			ethnicityLabel.textColor = [UIColor blackColor];
		}
		else {
			ethnicityLabel.textColor = [UIColor colorWithWhite:0.5098 alpha:1.0f];
			ethnicityLabel.text = NSLocalizedString(@"Tap to add", @"Tap to add");
		}
	}
	else {
		ethnicityLabel.textColor = [UIColor blackColor];
		ethnicityLabel.text = self.selectedEthnicity;
	}
}

- (void)updateFacilityLabel {
	NSLog(@"self.selectedFacilityName : %@", self.selectedFacilityName);
	NSLog(@"_census.facilityName : %@", _census.facilityName);
	UILabel *facilityLabel = (UILabel *)[self.view viewWithTag:46];
	if (self.selectedFacilityName == nil) {
		if (_census != nil) {
			NSLog(@"_census.facilityName : %@", _census.facilityName);
			facilityLabel.text = _census.facilityName;
			facilityLabel.textColor = [UIColor blackColor];
			NSLog(@"_census.facilityName : %@", _census.facilityName);
		}
		else {
			facilityLabel.textColor = [UIColor colorWithWhite:0.5098 alpha:1.0f];
			facilityLabel.text = NSLocalizedString(@"Tap to add", @"Tap to add");
		}
	}
	else {
		facilityLabel.textColor = [UIColor blackColor];
		facilityLabel.text = self.selectedFacilityName;
	}
}

- (void)updateReferringPhysicinLabel {
	UILabel *referringPhysicinLabel = (UILabel *)[self.view viewWithTag:50];
	if (self.selectedReferringPhysicianName == nil) {
		if (_census != nil) {
			referringPhysicinLabel.text = _census.referringPhysicianName;
			referringPhysicinLabel.textColor = [UIColor blackColor];
		}
		else {
			referringPhysicinLabel.textColor = [UIColor colorWithWhite:0.5098 alpha:1.0f];
			referringPhysicinLabel.text = NSLocalizedString(@"Tap to add", @"Tap to add");
		}
	}
	else {
		referringPhysicinLabel.textColor = [UIColor blackColor];
		referringPhysicinLabel.text = self.selectedReferringPhysicianName;
	}
}

- (void)showChat:(id)sender
{
    [super showChat];
}

- (void) toggleEdit:(id)sender
{
	/*
	 if(_editButton.selected  && [_editButton.titleLabel.text isEqualToString:NSLocalizedString(@"Done", @"Done")]){
	 //Done pressed. save the edits.
	 if([self savePatientRoundsData]){
	 _editButton.selected = !_editButton.selected;
	 
	 _notesButton.enabled = !_editButton.selected;
	 self.chatButton.enabled = !_editButton.selected;
	 [self setFinishButtonState];
	 self.currentViewMode = _editButton.selected ? QliqModelViewModeEdit : QliqModelViewModeView;
	 
	 [self updateViewFields];
	 }
	 } else {
	 _editButton.selected = !_editButton.selected;
	 
	 _notesButton.enabled = !_editButton.selected;
	 self.chatButton.enabled = !_editButton.selected;
	 [self setFinishButtonState];
	 self.currentViewMode = _editButton.selected ? QliqModelViewModeEdit : QliqModelViewModeView;
	 }*/
	if(self.currentViewMode == QliqModelViewModeView){
		_editButton.enabled = NO;
		_notesButton.enabled = NO;
		_dischargeButton.enabled = NO;
		self.chatButton.enabled=NO;
		self.currentViewMode = QliqModelViewModeEdit;
	}
	
}

- (void) processDischarge:(id)sender
{
	NSTimeInterval dos=0;
	NSDate *today = [NSDate dateWithoutTime];
	if(_census.selectedDos == 0)
		dos = [today timeIntervalSince1970];
	else 
		dos = _census.selectedDos;
	
	if([Census_old hasLaterChargesToDischargeDate:_census andNewDischargeDate:dos]){
		[self showAlertWithTitle:NSLocalizedString(@"Patient discharge date is not valid", @"Patient discharge date is not valid ") 
						 message:NSLocalizedString(@"Patient has charges after this discharge date, please choose the right date", @"Patient has charges after this discharge date, please choose the right date")];
	}else {
		_census.dischargeDate=dos;
		if([Census_old dischargePatient:_census])
		{
			self.currentViewMode = QliqModelViewModeView;
		}
	}
}


- (void)setFinishButtonState {
	// TODO update finish button state
}

- (void)showNotesInfo:(id)sender {
	// TODO notes button clicked
}

- (void)updateAvatar:(id)sender {
	// TODO bring image selection view
}

- (void)setCurrentViewMode:(QliqModelViewMode)mode {
	_currentViewMode = mode;
	switch (self.currentViewMode) {
			
		case QliqModelViewModeSelectedEdit:
		case QliqModelViewModeEdit:
		case QliqModelViewModeAdd:
		{
			UIButton* doneButtonView = [UIButton buttonWithType: UIButtonTypeCustom];
			UIImage* doneButtonImage = [[UIImage imageNamed: @"bg-cancel-btn.png"] stretchableImageWithLeftCapWidth: 17 topCapHeight: 0];
			[doneButtonView setBackgroundImage: doneButtonImage
									  forState: UIControlStateNormal];
			[doneButtonView setTitle: @"Done" forState: UIControlStateNormal];
			doneButtonView.titleLabel.font = [UIFont boldSystemFontOfSize: 12.0f];
			doneButtonView.frame = CGRectMake(0.0f, 0.0f, 80.0f, 42.0f);
			[doneButtonView addTarget: self 
							   action: @selector(clickDone:)
					 forControlEvents: UIControlEventTouchUpInside];
			UIBarButtonItem *_doneItem = [[[UIBarButtonItem alloc] initWithCustomView: doneButtonView] autorelease];
			
			self.navigationItem.rightBarButtonItem = _doneItem;
			if (_census != nil && _patient == nil) {
				if(_census.patientId >0){
					// Use setter so the Patient object is retained
					self.patient = [Patient_old getPatientToDisplay:_census.patientId];
					NSLog(@"_patient.race : %@", _patient.race);
				}
				else
					_patient = [[Patient_old alloc] initWithPrimaryKey:0];
			}			break;
		}
		case QliqModelViewModeView:
		{
			if (_census != nil && _patient == nil) {
				// Use setter so the Patient object is retained
				self.patient = [Patient_old getPatientToDisplay:_census.patientId];
				NSLog(@"_patient.race : %@", _patient.race);
			}
			self.navigationItem.rightBarButtonItem = [self rightItemWithTitle:NSLocalizedString(@"View Round", @"View Round") 
																  buttonImage:nil
																 buttonAction:nil];
			
			if (_buttonView == nil) {
				_buttonView = [[UIView alloc] initWithFrame:CGRectMake(0, 374, 320, 42)];
				LightGreyGlassGradientView *bgView = [[LightGreyGlassGradientView alloc] initWithFrame:_buttonView.bounds];
				[_buttonView addSubview:bgView];
				[bgView release];
				
				_notesButton = [StretchableButton buttonWithType:UIButtonTypeCustom];
				_notesButton.btnType = StretchableButton25;
				_notesButton.tag = 33;
				_notesButton.frame = CGRectMake(10, 0, 65, 42);
				[_notesButton setTitle:NSLocalizedString(@"Notes", @"Notes") forState:UIControlStateNormal];
				_notesButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.f];
				[_notesButton addTarget:self action:@selector(showNotesInfo:) forControlEvents:UIControlEventTouchUpInside];
				[_buttonView addSubview:_notesButton];
				
				self.chatButton = [StretchableButton buttonWithType:UIButtonTypeCustom];
				self.chatButton.btnType = StretchableButton25;
				self.chatButton.tag = 34;
				self.chatButton.frame = CGRectMake(80, 0, 65, 42);
				[self.chatButton setTitle:NSLocalizedString(@"Chat", @"Chat") forState:UIControlStateNormal];
				self.chatButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.f];
				[self.chatButton addTarget:self action:@selector(showChat:) forControlEvents:UIControlEventTouchUpInside];
				[_buttonView addSubview:self.chatButton];
				
				_editButton = [StretchableButton buttonWithType:UIButtonTypeCustom];
				_editButton.btnType = StretchableButton25;
				_editButton.tag = 35;
				_editButton.frame = CGRectMake(150, 0, 65, 42);
				[_editButton setTitle:NSLocalizedString(@"Edit", @"Edit") forState:UIControlStateNormal];
				[_editButton setTitle:NSLocalizedString(@"Done", @"Done") forState:UIControlStateSelected];
				_editButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.f];
				[_editButton addTarget:self action:@selector(toggleEdit:) forControlEvents:UIControlEventTouchUpInside];
				[_buttonView addSubview:_editButton];
				
				
				_dischargeButton = [StretchableButton buttonWithType:UIButtonTypeCustom];
				_dischargeButton.btnType = StretchableButton25;
				_dischargeButton.tag = 36;
				_dischargeButton.frame = CGRectMake(225, 0, 90, 42);
				[_dischargeButton setTitle:NSLocalizedString(@"Discharge", @"Discharge") forState:UIControlStateNormal];
				_dischargeButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.f];
				[_dischargeButton addTarget:self action:@selector(processDischarge:) forControlEvents:UIControlEventTouchUpInside];
				[_buttonView addSubview:_dischargeButton];
			}
			
			
		}
			break;
			
		case QliqModelViewModeUnknown:
		default:
			break;
	}
	
	if (_census != nil) {
		
		if (_census.facilityNpi > 0) {
			self.selectedFacilityId = _census.facilityNpi;
			self.selectedFacilityName = _census.facilityName;
		}
		if (_census.gender != nil) {
			self.selectedEthnicity = _census.gender;
		}
		if (_census.referringPhysicianNpi > 0) {
			self.selectedReferringPhysicianId = _census.referringPhysicianNpi;
			self.selectedReferringPhysicianName = _census.referringPhysicianName;
		}
	}
	
	
	//if (_buttonView.superview != self.view) {
	if(self.currentViewMode == QliqModelViewModeView){	
		[self.view addSubview:_buttonView];
		if(_census.dischargeDate>0)
			_dischargeButton.enabled=FALSE;
		else
			_dischargeButton.enabled=TRUE;
	}
	
	UIView *viewForMode = [self viewForMode:self.currentViewMode];
	if (viewForMode.superview != self.view) {
		[self.view addSubview:viewForMode];
	}
	
	if(self.currentViewMode != QliqModelViewModeView){
		if (self.selectedEthnicity != nil) {
			[self updateEthnicityLabel];
		}
		if (self.selectedFacilityName != nil) {
			[self updateFacilityLabel];
		}
		if (self.selectedReferringPhysicianName != nil) {
			[self updateReferringPhysicinLabel];
		}
	}
	
	[self.view bringSubviewToFront:_blankView];
	[self.view bringSubviewToFront:viewForMode];
	
	NSLog(@"%@", self.view);
	NSLog(@"%@", self.view.subviews);
	//}
}

- (void)viewDidUnload {
	[super viewDidUnload];
}

- (void)dealloc {
	[self.physicianPref release];
    [responderChainOnReturn	release];
	[_notesButton release];
	[self.chatButton release];
	[_editButton release];
	[_finishButton release];
	[self.selectedEthnicity release];
	[self.selectedFacilityName release];
	[self.selectedReferringPhysicianName release];
	[_census release];
	[self.patient release];
	[super dealloc];
}

#pragma mark -
#pragma mark Private

- (void)updateViewFields
{
	NSLog("self.patient.dateOfBirth %f",self.patient.dateOfBirth);
    if (self.patient != nil) {
		NSInteger myage = [Helper age:self.patient.dateOfBirth];
		NSString *dobstr = [Helper getDateFromInterval:self.patient.dateOfBirth];
		NSMutableString *strDobAge = [NSMutableString stringWithString:@""];
		if(myage >0){
			[strDobAge appendString:dobstr];
			[strDobAge appendString:@" • "];
			[strDobAge appendString:[NSString stringWithFormat:@"%d",myage]];
			demoInfoAgeLabel.text=strDobAge;
		}else{ 
			demoInfoAgeLabel.text =@"";
		}
		NSString *sex = self.patient.gender!=nil ? self.patient.gender : @"";
		NSString *ethnicity = self.patient.race!=nil ? self.patient.race : @"";
		
		NSMutableString *strEthnicitySex = [NSMutableString stringWithString:@""];
		[strEthnicitySex appendString:sex];
		if([ethnicity length]>0){
			[strEthnicitySex appendString:@" • "];
			[strEthnicitySex appendString:ethnicity];
		}
		if(self.census.censusType == NonConsult){
			[strEthnicitySex appendString:@" • "];
			[strEthnicitySex appendString:@"Admit"];
		}else{
			[strEthnicitySex appendString:@" • "];
			[strEthnicitySex appendString:@"Consult"];
		}
			
		demoInfoEthnicitySexLabel.text = strEthnicitySex;
    }
    facilityInfoNameLabel.text = _census.facilityName;
    facilityInfoMrnLabel.text = _census.mrn;
    facilityInfoRoomLabel.text = _census.room;
    
    visitInfoAdmissionLabel.text = [Helper getDateFromInterval:_census.admitDate];
    visitInfoDischargeLabel.text = [Helper getDateFromInterval:_census.dischargeDate];
    visitInfoReferringLabel.text = _census.referringPhysicianName;
}

- (UIView *)viewForMode:(QliqModelViewMode)viewMode {
	switch (viewMode) {
		case QliqModelViewModeView:
		{
			if (_viewView == nil) {
				_viewView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - 42 - 44)];
				LightGreyGlassGradientView *topBgView = [[LightGreyGlassGradientView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.bounds.size.width, 58)];
				[_viewView addSubview:topBgView];
				[topBgView release];
				
				UIButton *avatarButton = [UIButton buttonWithType:UIButtonTypeCustom];
				UIImage *avatarImage = [UIImage imageNamed:@"btn-add-avatar"];
				[avatarButton setImage:avatarImage forState:UIControlStateNormal];
				CGRect frame = avatarButton.frame;
				frame.size = avatarImage.size;
				frame.origin.x = 8;
				frame.origin.y = 0;
				avatarButton.frame = frame;
				avatarButton.tag = 310;
				[_viewView addSubview:avatarButton];
				
				UILabel *userLabel = [[UILabel alloc] initWithFrame:CGRectMake(avatarButton.frame.origin.x + avatarButton.frame.size.width + 16, 0, self.view.bounds.size.width - (avatarButton.frame.origin.x + avatarButton.frame.size.width + 26), 58)];
				userLabel.text = _patient.fullName;
				userLabel.textColor = [UIColor colorWithWhite:0.2196 alpha:1.0f];
				userLabel.backgroundColor = [UIColor clearColor];
				userLabel.font = [UIFont boldSystemFontOfSize:16];
				userLabel.tag = 320;
				[_viewView addSubview:userLabel];
				[userLabel release];
				
				UIScrollView *viewScrollView = [[[UIScrollView alloc] initWithFrame:CGRectMake(0, 58, self.view.bounds.size.width, 316)] autorelease];
				
				// DEMOGRAPHICS
				UIView *demographicsView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 86)];
				[demographicsView addSubview:[self darkGreyHeaderInFrame:CGRectMake(0.0, 0.0, self.view.bounds.size.width, 30.0) withText:NSLocalizedString(@"Demographics", @"Demographics")]];
				
				UILabel *demoAgeLabel = [self leftViewLabelInFrame:CGRectMake(0.0, 30.0, 100, 28) withText:NSLocalizedString(@"DOB • Age", @"DOB & Age")];
				UILabel *demoDobLabel = [self leftViewLabelInFrame:CGRectMake(0.0, 58.0, 100, 28) withText:NSLocalizedString(@"Ethnicity • Sex", @"Ethnicity & Sex")];
				
				demoInfoAgeLabel = [self rightViewLabelInFrame:CGRectMake(110.0, 30.0, 230, 28) withText:nil];
				demoInfoAgeLabel.tag = 330;
				demoInfoEthnicitySexLabel = [self rightViewLabelInFrame:CGRectMake(110.0, 58.0, 230, 28) withText:nil];
				demoInfoEthnicitySexLabel.tag = 340;
				[demographicsView addSubview:demoAgeLabel];
				[demographicsView addSubview:demoDobLabel];
				[demographicsView addSubview:demoInfoAgeLabel];
				[demographicsView addSubview:demoInfoEthnicitySexLabel];
				
				// FACILITY
				UIView *facilityView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 114)];
				[facilityView addSubview:[self darkGreyHeaderInFrame:CGRectMake(0.0, 0.0, self.view.bounds.size.width, 30.0) withText:NSLocalizedString(@"Facility Information", @"Facility Information")]];
				UILabel *facilityNameLabel = [self leftViewLabelInFrame:CGRectMake(0.0, 30.0, 100, 28) withText:NSLocalizedString(@"Facility", @"Facility")];
				UILabel *facilityMrnLabel = [self leftViewLabelInFrame:CGRectMake(0.0, 58.0, 100, 28) withText:NSLocalizedString(@"MRN", @"MRN")];
				UILabel *facilityRoomLabel = [self leftViewLabelInFrame:CGRectMake(0.0, 86.0, 100, 28) withText:NSLocalizedString(@"Room", @"Room")];
				facilityInfoNameLabel = [self rightViewLabelInFrame:CGRectMake(110.0, 30.0, 230, 28) withText:nil];
				facilityInfoNameLabel.tag = 350;
				facilityInfoMrnLabel = [self rightViewLabelInFrame:CGRectMake(110.0, 58.0, 230, 28) withText:nil];
				facilityInfoMrnLabel.tag = 360;
				facilityInfoRoomLabel = [self rightViewLabelInFrame:CGRectMake(110.0, 86.0, 230, 28) withText:nil];
				facilityInfoRoomLabel.tag = 370;
                
                [facilityView addSubview:facilityNameLabel];
				[facilityView addSubview:facilityMrnLabel];
				[facilityView addSubview:facilityRoomLabel];
				[facilityView addSubview:facilityInfoNameLabel];
				[facilityView addSubview:facilityInfoMrnLabel];
				[facilityView addSubview:facilityInfoRoomLabel];
				
				// VISIT
				UIView *visitView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 116)];
				[visitView addSubview:[self darkGreyHeaderInFrame:CGRectMake(0.0, 0.0, self.view.bounds.size.width, 30.0) withText:NSLocalizedString(@"Visit Information", @"Visit Information")]];
				UILabel *visitAdmissionLabel = [self leftViewLabelInFrame:CGRectMake(0.0, 30.0, 100, 28) withText:NSLocalizedString(@"Admission", @"Admission")];
				UILabel *visitDischargeLabel = [self leftViewLabelInFrame:CGRectMake(0.0, 58.0, 100, 28) withText:NSLocalizedString(@"Discharge", @"Discharge")];
				UILabel *visitReferringLabel = [self leftViewLabelInFrame:CGRectMake(0.0, 86.0, 100, 28) withText:NSLocalizedString(@"Referring", @"Referring")];
				visitInfoAdmissionLabel = [self rightViewLabelInFrame:CGRectMake(110.0, 30.0, 230, 28) withText:nil];
				visitInfoAdmissionLabel.tag = 380;
				visitInfoDischargeLabel = [self rightViewLabelInFrame:CGRectMake(110.0, 58.0, 230, 28) withText:nil];
				visitInfoDischargeLabel.tag = 390;
				visitInfoReferringLabel = [self rightViewLabelInFrame:CGRectMake(110.0, 86.0, 230, 28) withText:nil];
				visitInfoAdmissionLabel.tag = 400;
				[visitView addSubview:visitAdmissionLabel];
				[visitView addSubview:visitDischargeLabel];
				[visitView addSubview:visitReferringLabel];
				[visitView addSubview:visitInfoAdmissionLabel];
				[visitView addSubview:visitInfoDischargeLabel];
				[visitView addSubview:visitInfoReferringLabel];
				
				[viewScrollView addSubview:[self greyGradientViewInFrame:CGRectMake(0, 0, 320, 86) withSubview:demographicsView]];
				[viewScrollView addSubview:[self greyGradientViewInFrame:CGRectMake(0, 86, 320, 114) withSubview:facilityView]];
				[viewScrollView addSubview:[self greyGradientViewInFrame:CGRectMake(0, 200, 320, 116) withSubview:visitView]];
				[demographicsView release];
				[facilityView release];
				[visitView release];
				viewScrollView.tag = 39;
				UIView *lastView = [viewScrollView.subviews lastObject];
				viewScrollView.contentSize = CGSizeMake(viewScrollView.bounds.size.width, lastView.frame.origin.y + lastView.frame.size.height);
				[_viewView addSubview:viewScrollView];
			}
			[self updateViewFields];
			return _viewView;
		}
			
		case QliqModelViewModeSelectedEdit: 
		case QliqModelViewModeEdit: 
		case QliqModelViewModeAdd:
		{
			if (_addView == nil) {
				if(_currentViewMode == QliqModelViewModeAdd || _currentViewMode == QliqModelViewModeSelectedEdit)
					[self setLastUsedFacility];
				
				//CGFloat height = 374;
				CGFloat height = self.view.bounds.size.height - 44;
				_addView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, height)];
				
				
				UIScrollView *editScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, _addView.bounds.size.height)];
				NSLog(@"%@", editScrollView);
				editScrollView.tag=100;
				
				// DEMOGRAPHICS
				[editScrollView addSubview:[self darkGreyHeaderInFrame:CGRectMake(0.0, 0.0, self.view.bounds.size.width, 25.0) withText:NSLocalizedString(@"Demographics & Visit", @"Demographics & Visit")]];
				
				[editScrollView addSubview:[self greyGlassViewInFrame:CGRectMake(0.0f, 25, 74, 35) withLabel:NSLocalizedString(@"Last Name", @"Last Name")]];
				[editScrollView addSubview:[self greyGlassViewInFrame:CGRectMake(0.0f, 60, 74, 35) withLabel:NSLocalizedString(@"First Name", @"First Name")]];
				[editScrollView addSubview:[self greyGlassViewInFrame:CGRectMake(0.0f, 95, 74, 35) withLabel:NSLocalizedString(@"Type", @"Type")]];
				[editScrollView addSubview:[self greyGlassViewInFrame:CGRectMake(0.0f, 130, 74, 35) withLabel:NSLocalizedString(@"Sex", @"Sex")]];
				[editScrollView addSubview:[self greyGlassViewInFrame:CGRectMake(0.0f, 165, 74, 35) withLabel:NSLocalizedString(@"DOB", @"DOB")]];
				[editScrollView addSubview:[self greyGlassViewInFrame:CGRectMake(0.0f, 200, 74, 35) withLabel:NSLocalizedString(@"Admission", @"Admission")]];
				
				UIView *sexView = [[[UIView alloc] initWithFrame:CGRectMake(0.0f, 0, 241, 35)] autorelease];
				StretchableButton *maleButton = [StretchableButton buttonWithType:UIButtonTypeCustom];
				maleButton.btnType = StretchableButton25;
				[maleButton setTitle:NSLocalizedString(@"Male", @"Male") forState:UIControlStateNormal];
				CGRect frame = maleButton.frame;
				frame.size = CGSizeMake(60, 42);
				frame.origin.y = (int)((sexView.frame.size.height - frame.size.height) / 2);
				frame.origin.x = 8;
				maleButton.frame = frame;
				maleButton.tag = 43;
				//                NSLog(@"%@", _patient.gender);
				if (_patient != nil) {
					maleButton.selected = [[_patient.gender lowercaseString] isEqualToString:@"male"];
				}
				[maleButton addTarget:self action:@selector(setSex:) forControlEvents:UIControlEventTouchUpInside];
				
				StretchableButton *femaleButton = [StretchableButton buttonWithType:UIButtonTypeCustom];
				femaleButton.btnType = StretchableButton25;
				[femaleButton setTitle:NSLocalizedString(@"Female", @"Female") forState:UIControlStateNormal];
				frame = femaleButton.frame;
				frame.size = CGSizeMake(60, 42);
				frame.origin.y = maleButton.frame.origin.y;
				frame.origin.x = maleButton.frame.origin.x + maleButton.frame.size.width + 8;
				femaleButton.frame = frame;
				femaleButton.tag = 44;
				if (_patient != nil) {
					femaleButton.selected = [[_patient.gender lowercaseString] isEqualToString:@"female"];
				}
				[femaleButton addTarget:self action:@selector(setSex:) forControlEvents:UIControlEventTouchUpInside];
				[sexView addSubview:maleButton];
				[sexView addSubview:femaleButton];
				
				//censusType
				UIView *censusTypeView = [[[UIView alloc] initWithFrame:CGRectMake(0.0f, 0, 241, 35)] autorelease];
				StretchableButton *admitButton = [StretchableButton buttonWithType:UIButtonTypeCustom];
				admitButton.btnType = StretchableButton25;
				[admitButton setTitle:NSLocalizedString(@"Admit", @"Admit") forState:UIControlStateNormal];
				frame = admitButton.frame;
				frame.size = CGSizeMake(60, 42);
				frame.origin.y = (int)((censusTypeView.frame.size.height - frame.size.height) / 2);
				frame.origin.x = 8;
				admitButton.frame = frame;
				admitButton.tag = 53;
				//default setting
				[admitButton addTarget:self action:@selector(setCensusType:) forControlEvents:UIControlEventTouchUpInside];

				StretchableButton *consultButton = [StretchableButton buttonWithType:UIButtonTypeCustom];
				consultButton.btnType = StretchableButton25;
				[consultButton setTitle:NSLocalizedString(@"Consult", @"Consult") forState:UIControlStateNormal];
				frame = consultButton.frame;
				frame.size = CGSizeMake(60, 42);
				frame.origin.y = admitButton.frame.origin.y;
				frame.origin.x = admitButton.frame.origin.x + admitButton.frame.size.width + 8;
				consultButton.frame = frame;
				consultButton.tag = 54;
				switch (self.census.censusType) {
					case Consult:
						admitButton.selected=NO;
						consultButton.selected=YES;
						break;
					case NonConsult:
					default:
						admitButton.selected=YES;
						consultButton.selected = NO;
						break;
				}
				[consultButton addTarget:self action:@selector(setCensusType:) forControlEvents:UIControlEventTouchUpInside];
				[censusTypeView addSubview:admitButton];
				[censusTypeView addSubview:consultButton];
				
				CustomPlaceholderTextField *lastNameField = [self textFieldInFrame:CGRectMake(5, 2, 236, 31) 
																		  withText:nil
																	   placeholder:NSLocalizedString(@"Tap to Add", @"Tap to Add")];
				lastNameField.tag = 40;
				CustomPlaceholderTextField *firstNameField = [self textFieldInFrame:CGRectMake(5, 2, 180, 31) 
																		   withText:nil
																		placeholder:NSLocalizedString(@"Tap to Add", @"Tap to Add")];
				firstNameField.tag = 41;
				CustomPlaceholderTextField *middleNameField = [self textFieldInFrame:CGRectMake(5, 2, 56, 31) 
																			withText:nil
																		placeholder:NSLocalizedString(@"MI",@"MI")];
				middleNameField.tag = 42;
				
				if(self.patient.firstName != nil )
					firstNameField.text = [self.patient.firstName capitalizedString] ;
				if(self.patient.middleName != nil )
					middleNameField.text = [self.patient.middleName capitalizedString];
				if(self.patient.lastName != nil )
					lastNameField.text = [self.patient.lastName capitalizedString];
				
				CustomPlaceholderTextField *dobField = [self textFieldInFrame:CGRectMake(5, 2, 236, 31) 
																	 withText:nil
																  placeholder:NSLocalizedString(@"MM/DD/YYYY", @"MM/DD/YYYY")];
				dobField.tag = 45;
				if (_patient.patientId>0) {
					dobField.text = [Helper getDateFromInterval:_patient.dateOfBirth];
				}
				dobField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
				
				CustomPlaceholderTextField *admissionField = [self textFieldInFrame:CGRectMake(5, 2, 236, 31) 
																		   withText:nil
																		placeholder:NSLocalizedString(@"MM/DD/YYYY", @"MM/DD/YYYY")];
				admissionField.tag = 51;
				admissionField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
				if (_census.admitDate>0) {
					admissionField.text = [Helper getDateFromInterval:_census.admitDate];
				}
				
				[editScrollView addSubview:[self greyGradientViewInFrame:CGRectMake(74, 25, 246, 35) withSubview:lastNameField]];
				[editScrollView addSubview:[self greyGradientViewInFrame:CGRectMake(74, 60, 190, 35) withSubview:firstNameField]];
				[editScrollView addSubview:[self greyGradientViewInFrame:CGRectMake(254, 60, 66, 35) withSubview:middleNameField]];
				[editScrollView addSubview:[self greyGradientViewInFrame:CGRectMake(74, 95, 246, 35) withSubview:censusTypeView]];
				[editScrollView addSubview:[self greyGradientViewInFrame:CGRectMake(74, 130, 246, 35) withSubview:sexView]];
				[editScrollView addSubview:[self greyGradientViewInFrame:CGRectMake(74, 165, 246, 35) withSubview:dobField]];
				[editScrollView addSubview:[self greyGradientViewInFrame:CGRectMake(74, 200, 246, 35) withSubview:admissionField]];
				
				
				// OTHER INFORMATION
				[editScrollView addSubview:[self darkGreyHeaderInFrame:CGRectMake(0.0, 235, self.view.bounds.size.width, 25.0) withText:NSLocalizedString(@"Additional Information", @"Additional Information")]];
				[editScrollView addSubview:[self greyGlassViewInFrame:CGRectMake(0.0f, 260, 74, 35) withLabel:NSLocalizedString(@"Facility", @"Facility")]];
				[editScrollView addSubview:[self greyGlassViewInFrame:CGRectMake(0.0f, 295, 74, 35) withLabel:NSLocalizedString(@"Ethnicity", @"Ethnicity")]];
				[editScrollView addSubview:[self greyGlassViewInFrame:CGRectMake(0.0f, 330, 74, 35) withLabel:NSLocalizedString(@"MRN", @"MRN")]];
				[editScrollView addSubview:[self greyGlassViewInFrame:CGRectMake(0.0f, 365, 74, 35) withLabel:NSLocalizedString(@"Room", @"Room")]];
				
				UIView *ethnicityView = [[[UIView alloc] initWithFrame:CGRectMake(0.0f, 0, 241, 35)] autorelease];
				UILabel *ethnicityLabel = [[UILabel alloc] initWithFrame:CGRectMake(8.0f, 0, 226, 35)];
				ethnicityLabel.font = [UIFont boldSystemFontOfSize:13];
				ethnicityLabel.textColor = [UIColor colorWithWhite:0.5098 alpha:1.0f];
				ethnicityLabel.backgroundColor = [UIColor clearColor];
				ethnicityLabel.text = NSLocalizedString(@"Tap to select", @"Tap to select");
				ethnicityLabel.tag = 47;
				[ethnicityView addSubview:ethnicityLabel];
				[ethnicityLabel release];
				UIImage *chevronImage = [UIImage imageNamed:@"cell-chevron"];
				UIImageView *chevronImageView2 = [[UIImageView alloc] initWithImage:chevronImage];
				
				frame = chevronImageView2.frame;
				frame.origin.y = (int)((ethnicityView.frame.size.height - chevronImage.size.height) / 2);
				frame.origin.x = ethnicityView.bounds.size.width - chevronImage.size.width - 5;
				chevronImageView2.frame = frame;
				[ethnicityView addSubview:chevronImageView2];
				[chevronImageView2 release];
				UIButton *ethnicityButton = [UIButton buttonWithType:UIButtonTypeCustom];
				ethnicityButton.frame = ethnicityView.bounds;
				[ethnicityButton addTarget:self action:@selector(clickSelectRace:) forControlEvents:UIControlEventTouchUpInside];
				[ethnicityView addSubview:ethnicityButton];
				self.selectedEthnicity = self.patient.race;
				[self updateEthnicityLabel];
				
				CustomPlaceholderTextField *mrnField = [self textFieldInFrame:CGRectMake(5, 2, 236, 31) 
																	 withText:nil
																  placeholder:NSLocalizedString(@"Tap to add", @"Tap to add")];
				mrnField.tag = 48;
				CustomPlaceholderTextField *roomField = [self textFieldInFrame:CGRectMake(5, 2, 236, 31) 
																	  withText:nil
																   placeholder:NSLocalizedString(@"Tap to add", @"Tap to add")];
				roomField.tag = 49;
				
				if (_census != nil) {
					mrnField.text = _census.mrn;
					roomField.text = _census.room;
				}
				mrnField.keyboardType=UIKeyboardTypeNumbersAndPunctuation;
				roomField.keyboardType=UIKeyboardTypeNumbersAndPunctuation;
				
				UIView *facilityView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0, 241, 35)];
				UILabel *facilityLabel = [[UILabel alloc] initWithFrame:CGRectMake(8.0f, 0, 226, 35)];
				facilityLabel.font = [UIFont boldSystemFontOfSize:13];
				facilityLabel.textColor = [UIColor colorWithWhite:0.5098 alpha:1.0f];
				facilityLabel.backgroundColor = [UIColor clearColor];
				facilityLabel.text = NSLocalizedString(@"Tap to select", @"Tap to select");
				facilityLabel.tag = 46;
				[facilityView addSubview:facilityLabel];
				[facilityLabel release];
				chevronImage = [UIImage imageNamed:@"cell-chevron"];
				UIImageView *chevronImageView = [[UIImageView alloc] initWithImage:chevronImage];
				
				frame = chevronImageView.frame;
				frame.origin.y = (int)((facilityView.frame.size.height - chevronImage.size.height) / 2);
				frame.origin.x = facilityView.bounds.size.width - chevronImage.size.width - 5;
				chevronImageView.frame = frame;
				[facilityView addSubview:chevronImageView];
				[chevronImageView release];
				UIButton *facilityButton = [UIButton buttonWithType:UIButtonTypeCustom];
				facilityButton.frame = facilityView.bounds;
				[facilityButton addTarget:self action:@selector(clickSelectFacility:) forControlEvents:UIControlEventTouchUpInside];
				[facilityView addSubview:facilityButton];
				[self updateFacilityLabel];
				
				[editScrollView addSubview:[self greyGradientViewInFrame:CGRectMake(74, 260, 246, 35) withSubview:facilityView]];
				[editScrollView addSubview:[self greyGradientViewInFrame:CGRectMake(74, 295, 246, 35) withSubview:ethnicityView]];
				[editScrollView addSubview:[self greyGradientViewInFrame:CGRectMake(74, 330, 246, 35) withSubview:mrnField]];
				[editScrollView addSubview:[self greyGradientViewInFrame:CGRectMake(74, 365, 246, 35) withSubview:roomField]];
				// VISIT
				//[editScrollView addSubview:[self darkGreyHeaderInFrame:CGRectMake(0.0, 365, self.view.bounds.size.width, 25.0) withText:NSLocalizedString(@"Visit Information", @"Visit Information")]];
				[editScrollView addSubview:[self greyGlassViewInFrame:CGRectMake(0.0f, 400, 74, 35) withLabel:NSLocalizedString(@"Discharge", @"Discharge")]];
				[editScrollView addSubview:[self greyGlassViewInFrame:CGRectMake(0.0f, 435, 74, 35) withLabel:NSLocalizedString(@"Referral", @"Referral")]];
				
				UIView *referalView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0, 241, 35)];
				UILabel *referalLabel = [[UILabel alloc] initWithFrame:CGRectMake(8.0f, 0, 226, 35)];
				referalLabel.font = [UIFont boldSystemFontOfSize:13];
				referalLabel.textColor = [UIColor colorWithWhite:0.5098 alpha:1.0f];
				referalLabel.backgroundColor = [UIColor clearColor];
				referalLabel.text = NSLocalizedString(@"Tap to select", @"Tap to select");
				referalLabel.tag = 50;
				[referalView addSubview:referalLabel];
				[referalLabel release];
				UIImageView *chevronImageView3 = [[UIImageView alloc] initWithImage:chevronImage];
				
				frame = chevronImageView3.frame;
				frame.origin.y = (int)((ethnicityView.frame.size.height - chevronImage.size.height) / 2);
				frame.origin.x = ethnicityView.bounds.size.width - chevronImage.size.width - 5;
				chevronImageView3.frame = frame;
				[referalView addSubview:chevronImageView3];
				[chevronImageView3 release];
				UIButton *referalButton = [UIButton buttonWithType:UIButtonTypeCustom];
				referalButton.frame = ethnicityView.bounds;
				[referalButton addTarget:self action:@selector(clickSelectReferal:) forControlEvents:UIControlEventTouchUpInside];
				[referalView addSubview:referalButton];
				[self updateReferringPhysicinLabel];
				
				CustomPlaceholderTextField *dischargeField = [self textFieldInFrame:CGRectMake(5, 2, 236, 31) 
																		   withText:nil
																		placeholder:NSLocalizedString(@"MM/DD/YYYY", @"MM/DD/YYYY")];
				
				dischargeField.tag = 52;
				dischargeField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
				if (_census.dischargeDate>0) {
					dischargeField.text = [Helper getDateFromInterval:_census.dischargeDate];
				}
				
				
				[editScrollView addSubview:[self greyGradientViewInFrame:CGRectMake(74, 400, 246, 35) withSubview:dischargeField]];
				[editScrollView addSubview:[self greyGradientViewInFrame:CGRectMake(74, 435, 246, 35) withSubview:referalView]];
				[referalView release];
				
				
				UIView *lastView = [editScrollView.subviews lastObject];
				editScrollView.contentSize = CGSizeMake(editScrollView.bounds.size.width, lastView.frame.origin.y + lastView.frame.size.height);
				
				[_addView addSubview:editScrollView];
				[editScrollView release];
				[facilityView release];
                
                responderChainOnReturn = [[NSArray alloc] initWithObjects:
                                          [NSNumber numberWithInt: 40],
                                          [NSNumber numberWithInt: 41],
                                          [NSNumber numberWithInt: 42],
                                          [NSNumber numberWithInt: 45],
                                          [NSNumber numberWithInt: 51],
                                          [NSNumber numberWithInt: 48],
                                          [NSNumber numberWithInt: 49],nil];
				
			}
			
			return _addView;
			
		}
			break;
	}
	
	return nil;
}

#pragma mark -
#pragma mark Keyboard notifications handling

//---when the keyboard appears---
- (void)keyboardOn:(id)sender {
	if (self.isKeyboardOn) {
		return;
	}
	
	NSNotification *notification = sender;
	
	NSDictionary* info = [notification userInfo];
	
	//---obtain the size of the keyboard---
	NSValue *aValue =
	[info objectForKey:UIKeyboardFrameEndUserInfoKey];
	CGRect keyboardRect =
	[self.view convertRect:[aValue CGRectValue] fromView:nil];
	
	NSLog(@"%f", keyboardRect.size.height);
	
	UIScrollView *scrollView = (UIScrollView *) [self.view viewWithTag:100];	 
	
	//---resize the scroll view (with keyboard)---
	CGRect viewFrame = [scrollView frame];
	viewFrame.size.height -= keyboardRect.size.height;
	//viewFrame.size.height += 44;
	
	scrollView.frame = viewFrame;
	
	//---scroll to the current text field---
	// MZ: textField is wrapped in gradient view
	CGRect textFieldRect = [currentTextField.superview frame];
	// MZ: add a little bit of space
	textFieldRect.origin.y += 5;
	[scrollView scrollRectToVisible:textFieldRect animated:YES];
	
	self.keyboardOn = YES;
}

//---when the keyboard disappears---
- (void)keyboardOff:(id)sender {
	if (!self.isKeyboardOn) {
		return;
	}
	NSNotification *notification = sender;
	NSDictionary* info = [notification userInfo];
	
	//---obtain the size of the keyboard---
	NSValue* aValue =
	[info objectForKey:UIKeyboardFrameEndUserInfoKey];
	CGRect keyboardRect =
	[self.view convertRect:[aValue CGRectValue] fromView:nil];
	
	//---resize the scroll view back to the original size
	// (without keyboard)---
	UIScrollView *scrollView = (UIScrollView *) [self.view viewWithTag:100];	 
	CGRect viewFrame = [scrollView frame];
	viewFrame.size.height += keyboardRect.size.height;
	//viewFrame.size.height -= 44;
	
	scrollView.frame = viewFrame;
	
	self.keyboardOn = NO;
}

#pragma mark -
#pragma mark UIAlertView help

- (void)showAlertWithTitle:(NSString *)aTitle message:(NSString *)aMessage {
	UIAlertView *alert=[[UIAlertView alloc]initWithTitle:aTitle
												 message:aMessage 
												delegate:self 
									   cancelButtonTitle:NSLocalizedString(@"OK", @"OK")
									   otherButtonTitles:nil];
	[alert show];
	[alert release];
}
@end
