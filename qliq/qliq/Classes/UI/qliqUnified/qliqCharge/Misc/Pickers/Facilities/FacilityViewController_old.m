// Created by Developer Toy
//AddFacilityView.m
#import "FacilityViewController_old.h"
#import "StretchableButton.h"
#import "LightGreyGlassGradientView.h"
#import "Facility_old.h"
#import "CustomPlaceholderTextField.h"
#import "RoundViewController.h"
#import "StatesPickerViewController.h"
#import "FacilityTypeViewController.h"

@implementation FacilityViewController_old

@synthesize facility = _facility;
@synthesize currentViewMode = _currentViewMode;
@synthesize selectedStateCode = _selectedStateCode;
@synthesize selectedStateName = _selectedStateName;
@synthesize selectedSuperbillName = _selectedSuperbillName;
@synthesize selectedFacilityType = _selectedFacilityType;


- (void)viewDidLoad {
    [super viewDidLoad];
	self.view.backgroundColor = [UIColor colorWithWhite:0.2196 alpha:1.0f];
    _blankView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.bounds.size.width, self.view.bounds.size.height - 86)];
    _blankView.backgroundColor = [UIColor colorWithWhite:0.2196 alpha:1.0f];
    [self.view addSubview:_blankView];
    if (_currentViewMode == QliqModelViewModeUnknown) {
        self.currentViewMode = QliqModelViewModeAdd;
    }
}
- (void)viewWillAppear:(BOOL)animated {
    if (self.selectedStateCode != nil) {
        [self updateStateLabel];
        [self updateFacilityTypeLabel];
        [self updateSuperbillLabel];
    }
}

-(IBAction)clickRightButton:(id)sender{
	NSArray *controllers =self.navigationController.viewControllers;
	int level=[controllers count]-2;
	if (level>=0) {
		UIViewController *last=(UIViewController *)[controllers objectAtIndex:level];
		[last.navigationController popViewControllerAnimated:YES];
	}
}

-(IBAction)clickState:(id)sender{
	StatesPickerViewController* tempController = [[StatesPickerViewController alloc] init];
    tempController.previousControllerTitle = NSLocalizedString(@"Facility", @"Facility");
    tempController.delegate = self;
    
	[self.navigationController pushViewController: tempController animated: YES];
	[tempController autorelease];
}
/*
- (void)clickSuperbill:(id)sender
{
    SuperbillPickerViewController* tempController = [[SuperbillPickerViewController alloc] init];
    tempController.previousControllerTitle = NSLocalizedString(@"Superbill", @"Superbill");
    tempController.delegate = self;
    
	[self.navigationController pushViewController: tempController animated: YES];
	[tempController autorelease];    
}
*/

- (void)clickFacilityType:(id)sender
{
    FacilityTypeViewController* tempController = [[FacilityTypeViewController alloc] init];
    tempController.previousControllerTitle = NSLocalizedString(@"Facility type", @"Facility type");
    tempController.delegate = self;
    
	[self.navigationController pushViewController: tempController animated: YES];
	[tempController autorelease];    
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
	if([self saveFacilityData]){
		NSArray *controllers =self.navigationController.viewControllers;
		int level=[controllers count]-3;
		if (level>=0) {
			RoundViewController *last=(RoundViewController *)[controllers objectAtIndex:3];
			last.selectedFacilityId = self.facility.facilityNpi;
			last.selectedFacilityName = self.facility.name;
			[self.navigationController popToViewController:last animated:YES];
		}
	}
}


- (void) pickerWithSearchViewControllerdidPickItem: (id) anItem
                                       forItemName: (NSString*) anItemName
{
    if ([anItemName isEqualToString: @"stateName"])
    {
        self.selectedStateName = (NSString*)anItem;
    }
    else if ([anItemName isEqualToString: @"stateCode"])
    {
        self.selectedStateCode = (NSString*)anItem;
    }
    else if ([anItemName isEqualToString: @"superbillName"])
    {
        self.selectedSuperbillName = (NSString*)anItem;
    }
    else if ([anItemName isEqualToString: @"facilityType"])
    {
        self.selectedFacilityType = (NSString*)anItem;
    }
}


- (BOOL)saveFacilityData {
	//Done button to validate the form
    //and save
	BOOL retval = YES;
	if([self populateFacilityData]){
		if(self.facility.facilityNpi==0){
			//add new facility
			NSInteger newFacilityId = [Facility_old addFacility:self.facility];
			if(newFacilityId <=0)
				retval=NO;
			else 
				self.facility.facilityNpi = newFacilityId;
		}
	}else {
		retval=NO;
	}
	return retval;
}

- (BOOL) populateFacilityData {
	BOOL validData=YES;
	//set the form field values to census object
	NSString *facilityName=nil;//tag:11
	NSString *address1=nil; //tag:12
	NSString *address2=nil; //tag:13
	NSString *city=nil; //tag:15
	
	UITextField	*facilityNameField = (UITextField *)[self.view viewWithTag:11];
	facilityName = facilityNameField.text;
	
	UITextField	*addr1Field = (UITextField *)[self.view viewWithTag:12];
	address1 = addr1Field.text;
	
	UITextField	*addr2Field = (UITextField *)[self.view viewWithTag:13];
	address2 = addr2Field.text;
	
	UITextField	*cityField = (UITextField *)[self.view viewWithTag:15];
	city = cityField.text;
	if(facilityName==nil || [facilityName length] ==0){
		[self showAlertWithTitle:NSLocalizedString(@"Facility name is empty", @"Facility name is empty") 
						 message:NSLocalizedString(@"Please enter the facility name before saving", @"Please enter the facility name before saving")];
		validData=NO;
	}else {
		//check its in the right format
		self.facility.name=facilityName;
		self.facility.address=address1;
		self.facility.city=city;
		self.facility.state=[self selectedStateCode];
		self.facility.facilityTypeId = [FacilityType getFacilityTypePk:self.selectedFacilityType];
	}
	return validData;	
}


//---when the user taps on the return key on the keyboard---
-(BOOL) textFieldShouldReturn:(UITextField *) textFieldView {
    [textFieldView resignFirstResponder];
    return NO;
}


- (void)setCurrentViewMode:(QliqModelViewMode)mode {
    //if (mode != _currentViewMode) {
	_currentViewMode = mode;
	switch (self.currentViewMode) {
		case QliqModelViewModeAdd:
		{
			self.navigationItem.rightBarButtonItem = [self rightItemWithTitle:NSLocalizedString(@"Facility", @"Facility") 
																  buttonImage:nil
																 buttonAction:nil];
			
			if (_buttonView == nil) {
				_buttonView = [[UIView alloc] initWithFrame:CGRectMake(0, 374, 320, 42)];
				LightGreyGlassGradientView *bgView = [[LightGreyGlassGradientView alloc] initWithFrame:_buttonView.bounds];
				[_buttonView addSubview:bgView];
				[bgView release];
				
				_editButton = [StretchableButton buttonWithType:UIButtonTypeCustom];
				_editButton.btnType = StretchableButton25;
				_editButton.tag = 35;
				_editButton.frame = CGRectMake(175, 0, 65, 42);
				[_editButton setTitle:NSLocalizedString(@"Cancel", @"Cancel") forState:UIControlStateNormal];
				_editButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.f];
				[_editButton addTarget:self action:@selector(clickCancel:) forControlEvents:UIControlEventTouchUpInside];
				[_buttonView addSubview:_editButton];
				
				_finishButton = [StretchableButton buttonWithType:UIButtonTypeCustom];
				_finishButton.btnType = StretchableButton25;
				_finishButton.tag = 36;
				_finishButton.frame = CGRectMake(245, 0, 65, 42);
				[_finishButton setTitle:NSLocalizedString(@"Done", @"Done") forState:UIControlStateNormal];
				_finishButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.f];
				[_finishButton addTarget:self action:@selector(clickDone:) forControlEvents:UIControlEventTouchUpInside];
				[_buttonView addSubview:_finishButton];
				
			}
			if (_buttonView.superview != self.view) {
				[self.view addSubview:_buttonView];
			}
		}
			break;
	}
	
	UIView *viewForMode = [self viewForMode:self.currentViewMode];
	if (viewForMode.superview != self.view) {
		[self.view addSubview:viewForMode];
	}
	
	[self.view bringSubviewToFront:_blankView];
	[self.view bringSubviewToFront:viewForMode];
	// }
}

- (void)viewDidUnload {
}

- (void)dealloc {
	[_facility release];
	[super dealloc];
}



#pragma mark -
#pragma mark Private

- (UIView *)viewForMode:(QliqModelViewMode)viewMode {
    switch (viewMode) {
        case QliqModelViewModeAdd:
        case QliqModelViewModeEdit:
        {
            if (_editView == nil) {
                _editView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height  - 42 - 44)];
                UIView *darkBgView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.bounds.size.width, 25.0)];
                darkBgView.backgroundColor = [UIColor colorWithWhite:0.2196 alpha:1.0f];
                [_editView addSubview:darkBgView];
                [darkBgView release];
                
                UILabel *demographicsLabel = [[UILabel alloc] initWithFrame:CGRectMake(10., 0, self.view.bounds.size.width - 20, 25)];
                demographicsLabel.font = [UIFont boldSystemFontOfSize:11.0f];
                demographicsLabel.textColor = [UIColor whiteColor];
                demographicsLabel.backgroundColor = [UIColor clearColor];
                demographicsLabel.text = NSLocalizedString(@"Facility Main Contact", @"Facility Main Contact");
                [_editView addSubview:demographicsLabel];
                [demographicsLabel release];
                
                [_editView addSubview:[self greyGlassViewInFrame:CGRectMake(0.0f, 25, 74, 35) withLabel:NSLocalizedString(@"Name", @"Name")]];
                [_editView addSubview:[self greyGlassViewInFrame:CGRectMake(0.0f, 60, 74, 35) withLabel:NSLocalizedString(@"Address 1", @"Address 1")]];
                [_editView addSubview:[self greyGlassViewInFrame:CGRectMake(0.0f, 95, 74, 35) withLabel:NSLocalizedString(@"Address 2", @"Address 2")]];
                [_editView addSubview:[self greyGlassViewInFrame:CGRectMake(0.0f, 130, 74, 35) withLabel:NSLocalizedString(@"City", @"City")]];
                [_editView addSubview:[self greyGlassViewInFrame:CGRectMake(0.0f, 165, 74, 35) withLabel:NSLocalizedString(@"State", @"State")]];
                [_editView addSubview:[self greyGlassViewInFrame:CGRectMake(0.0f, 200, 74, 35) withLabel:NSLocalizedString(@"Type", @"Type")]];
                //[_editView addSubview:[self greyGlassViewInFrame:CGRectMake(0.0f, 235, 74, 35) withLabel:NSLocalizedString(@"Superbill", @"Superbill")]];
				//                [_editView addSubview:[self greyGlassViewInFrame:CGRectMake(0.0f, 200, 74, 35) withLabel:NSLocalizedString(@"Ethnicity", @"Ethnicity")]];
                
                CustomPlaceholderTextField *nameField = [self textFieldInFrame:CGRectMake(5, 2, 236, 31) withText:nil placeholder:NSLocalizedString(@"Tap to add", @"Tap to add")];
                nameField.tag = 11;
                
                CustomPlaceholderTextField *address1Field = [self textFieldInFrame:CGRectMake(5, 2, 236, 31) withText:nil placeholder:NSLocalizedString(@"Tap to add", @"Tap to add")];
                address1Field.tag = 12;
                
                CustomPlaceholderTextField *address2Field = [self textFieldInFrame:CGRectMake(5, 2, 236, 31) withText:nil placeholder:NSLocalizedString(@"Tap to add", @"Tap to add")];
                address2Field.tag = 13;
                
                CustomPlaceholderTextField *cityField = [self textFieldInFrame:CGRectMake(5, 2, 236, 31) withText:nil placeholder:NSLocalizedString(@"Tap to add", @"Tap to add")];
                cityField.tag = 15;
                
                if (_facility != nil) {
                    // TODO set fields values
                }
                
                UIView *stateView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0, 241, 35)];
                UILabel *stateLabel = [[UILabel alloc] initWithFrame:CGRectMake(8.0f, 0, 226, 35)];
                stateLabel.font = [UIFont boldSystemFontOfSize:13];
                stateLabel.textColor = [UIColor colorWithWhite:0.5098 alpha:1.0f];
                stateLabel.backgroundColor = [UIColor clearColor];
                stateLabel.text = NSLocalizedString(@"Tap to select", @"Tap to select");
                stateLabel.tag = 16;
                [stateView addSubview:stateLabel];
                [stateLabel release];
                UIImage *chevronImage = [UIImage imageNamed:@"cell-chevron"];
                UIImageView *chevronImageView = [[UIImageView alloc] initWithImage:chevronImage];
                CGRect frame = chevronImageView.frame;
                frame.origin.y = (int)((stateView.frame.size.height - chevronImage.size.height) / 2);
                frame.origin.x = stateView.bounds.size.width - chevronImage.size.width - 5;
                chevronImageView.frame = frame;
                [stateView addSubview:chevronImageView];
                [chevronImageView release];
                UIButton *stateButton = [UIButton buttonWithType:UIButtonTypeCustom];
                stateButton.frame = stateView.bounds;
                [stateButton addTarget:self action:@selector(clickState:) forControlEvents:UIControlEventTouchUpInside];
                [stateView addSubview:stateButton];
				[self updateStateLabel];

                UIView *typeView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0, 241, 35)];
                UILabel *typeLabel = [[UILabel alloc] initWithFrame:CGRectMake(8.0f, 0, 226, 35)];
                typeLabel.font = [UIFont boldSystemFontOfSize:13];
                typeLabel.textColor = [UIColor colorWithWhite:0.5098 alpha:1.0f];
                typeLabel.backgroundColor = [UIColor clearColor];
                typeLabel.text = NSLocalizedString(@"Tap to select", @"Tap to select");
                typeLabel.tag = 17;
                [typeView addSubview:typeLabel];
                [typeLabel release];
//                UIImage *chevronImage = [UIImage imageNamed:@"cell-chevron"];
                UIImageView *chevronImageView2 = [[UIImageView alloc] initWithImage:chevronImage];
                frame = chevronImageView2.frame;
                frame.origin.y = (int)((typeView.frame.size.height - chevronImage.size.height) / 2);
                frame.origin.x = typeView.bounds.size.width - chevronImage.size.width - 5;
                chevronImageView2.frame = frame;
                [typeView addSubview:chevronImageView2];
                [chevronImageView2 release];
                UIButton *typeButton = [UIButton buttonWithType:UIButtonTypeCustom];
                typeButton.frame = stateView.bounds;
                [typeButton addTarget:self action:@selector(clickFacilityType:) forControlEvents:UIControlEventTouchUpInside];
                [typeView addSubview:typeButton];
				[self updateFacilityTypeLabel];
                
				
                UIView *superbillView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0, 241, 35)];
                UILabel *superbillLabel = [[UILabel alloc] initWithFrame:CGRectMake(8.0f, 0, 226, 35)];
                superbillLabel.font = [UIFont boldSystemFontOfSize:13];
                superbillLabel.textColor = [UIColor colorWithWhite:0.5098 alpha:1.0f];
                superbillLabel.backgroundColor = [UIColor clearColor];
                superbillLabel.text = NSLocalizedString(@"Tap to select", @"Tap to select");
                superbillLabel.tag = 18;
                [superbillView addSubview:superbillLabel];
                [superbillLabel release];
                UIImageView *chevronImageView3 = [[UIImageView alloc] initWithImage:chevronImage];
                frame = chevronImageView3.frame;
                frame.origin.y = (int)((superbillView.frame.size.height - chevronImage.size.height) / 2);
                frame.origin.x = superbillView.bounds.size.width - chevronImage.size.width - 5;
                chevronImageView3.frame = frame;
                [superbillView addSubview:chevronImageView3];
                [chevronImageView3 release];
                UIButton *superbillButton = [UIButton buttonWithType:UIButtonTypeCustom];
                superbillButton.frame = stateView.bounds;
                [superbillButton addTarget:self action:@selector(clickSuperbill:) forControlEvents:UIControlEventTouchUpInside];
                [superbillView addSubview:superbillButton];
				[self updateSuperbillLabel];

                
                [_editView addSubview:[self greyGradientViewInFrame:CGRectMake(74, 25, 246, 35) withSubview:nameField]];
                [_editView addSubview:[self greyGradientViewInFrame:CGRectMake(74, 60, 246, 35) withSubview:address1Field]];
                [_editView addSubview:[self greyGradientViewInFrame:CGRectMake(74, 95, 246, 35) withSubview:address2Field]];
                [_editView addSubview:[self greyGradientViewInFrame:CGRectMake(74, 130, 246, 35) withSubview:cityField]];
				//                [_editView addSubview:[self greyGradientViewInFrame:CGRectMake(74, 165, 246, 35) withSubview:dobField]];
                [_editView addSubview:[self greyGradientViewInFrame:CGRectMake(74, 165, 246, 35) withSubview:stateView]];
                [_editView addSubview:[self greyGradientViewInFrame:CGRectMake(74, 200, 246, 35) withSubview:typeView]];
                //[_editView addSubview:[self greyGradientViewInFrame:CGRectMake(74, 235, 246, 35) withSubview:superbillView]];
                
                [stateView release];
                [typeView release];
				[superbillView release];
            }
            
            return _editView;
        }
            break;
	}
	return nil;
}

- (void)updateStateLabel {
    UILabel *stateLabel = (UILabel *)[self.view viewWithTag:16];
    if (self.selectedStateCode == nil) {
		stateLabel.textColor = [UIColor colorWithWhite:0.5098 alpha:1.0f];
		stateLabel.text = NSLocalizedString(@"Tap to add", @"Tap to add");
    }
    else {
        stateLabel.textColor = [UIColor blackColor];
        stateLabel.text = self.selectedStateName;
    }
}

- (void)updateFacilityTypeLabel {
    UILabel *label = (UILabel *)[self.view viewWithTag:17];
    if (self.selectedFacilityType == nil) {
		label.textColor = [UIColor colorWithWhite:0.5098 alpha:1.0f];
		label.text = NSLocalizedString(@"Tap to add", @"Tap to add");
    }
    else {
        label.textColor = [UIColor blackColor];
        label.text = self.selectedFacilityType;
    }
}

- (void)updateSuperbillLabel {
    UILabel *label = (UILabel *)[self.view viewWithTag:18];
    if (self.selectedSuperbillName == nil) {
		label.textColor = [UIColor colorWithWhite:0.5098 alpha:1.0f];
		label.text = NSLocalizedString(@"Tap to add", @"Tap to add");
    }
    else {
        label.textColor = [UIColor blackColor];
        label.text = self.selectedSuperbillName;
    }
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
