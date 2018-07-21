// Created by Developer Toy
//AddReferringPhysicianView.m
#import "AddReferringPhysician.h"
#import "StretchableButton.h"
#import "LightGreyGlassGradientView.h"
#import "ReferringPhysician.h"
#import "CustomPlaceholderTextField.h"
#import "RoundViewController.h"
#define ARC4RANDOM_MAX      0x100000000

@implementation AddReferringPhysician

@synthesize referringPhysician = _referringPhysician;
@synthesize currentViewMode = _currentViewMode;

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
}

-(IBAction)clickRightButton:(id)sender{
	NSArray *controllers =self.navigationController.viewControllers;
	int level=[controllers count]-2;
	if (level>=0) {
		UIViewController *last=(UIViewController *)[controllers objectAtIndex:level];
		[last.navigationController popViewControllerAnimated:YES];
	}
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

- (BOOL) populateReferringPhysicianData {
	BOOL validData=YES;
	//set the form field values to census object
	NSString *referringPhysicianName=nil;//tag:11
	NSString *fax=nil; //tag:12
	NSString *phone=nil; //tag:13
	NSString *mobile=nil; //tag:15
	NSString *email=nil; //tag:16
	
	UITextField	*referringPhysicianNameField = (UITextField *)[self.view viewWithTag:11];
	referringPhysicianName = referringPhysicianNameField.text;
	
	UITextField	*faxField = (UITextField *)[self.view viewWithTag:12];
	fax = faxField.text;
	
	UITextField	*phoneField = (UITextField *)[self.view viewWithTag:13];
	phone = phoneField.text;
	
	UITextField	*mobileField = (UITextField *)[self.view viewWithTag:15];
	mobile = mobileField.text;

	UITextField	*emailField = (UITextField *)[self.view viewWithTag:16];
	email = emailField.text;
	
	if(referringPhysicianName==nil || [referringPhysicianName length] ==0){
		[self showAlertWithTitle:NSLocalizedString(@"ReferringPhysician name is empty", @"ReferringPhysician name is empty") 
						 message:NSLocalizedString(@"Please enter the referringPhysician name before saving", @"Please enter the referringPhysician name before saving")];
		validData=NO;
	}else {
		//check its in the right format
		self.referringPhysician.name=referringPhysicianName;
		self.referringPhysician.fax=fax;
		self.referringPhysician.phone=phone;
		self.referringPhysician.mobile=mobile;
		self.referringPhysician.email=email;
	}
	return validData;	
}

- (BOOL)saveReferringPhysicianData {
	//Done button to validate the form
    //and save
	BOOL retval = YES;
	if([self populateReferringPhysicianData]){
		if(self.referringPhysician.referringPhysicianNpi==0){
			//add new referringPhysician
			self.referringPhysician.referringPhysicianNpi = floorf(((double)arc4random() / ARC4RANDOM_MAX) * 9000000000.0f);
			NSInteger newReferringPhysicianId = [ReferringPhysician  addReferringPhysician:self.referringPhysician];
			if(newReferringPhysicianId <=0)
				retval=NO;
			else 
				self.referringPhysician.referringPhysicianNpi = newReferringPhysicianId;
		}
	}else {
		retval=NO;
	}
	return retval;
}

- (void)clickDone:(id)sender {
	if([self saveReferringPhysicianData]){
		NSArray *controllers =self.navigationController.viewControllers;
		int level=[controllers count]-3;
		if (level>=0) {
			RoundViewController *last=(RoundViewController *)[controllers objectAtIndex:level];
			last.selectedReferringPhysicianId = self.referringPhysician.referringPhysicianNpi;
			last.selectedReferringPhysicianName = self.referringPhysician.name;
			[self.navigationController popToViewController:last animated:YES];
		}
	}
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
			self.navigationItem.rightBarButtonItem = [self rightItemWithTitle:NSLocalizedString(@"ReferringPhysician", @"ReferringPhysician") 
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
	[_referringPhysician release];
	[super dealloc];
}



#pragma mark -
#pragma mark Private

- (UIView *)viewForMode:(QliqModelViewMode)viewMode {
    switch (viewMode) {
		case QliqModelViewModeUnknown:
		case QliqModelViewModeView:
		case QliqModelViewModeSelectedEdit:	
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
                demographicsLabel.text = NSLocalizedString(@"Referring Physician Details", @"Referring Physician Details");
                [_editView addSubview:demographicsLabel];
                [demographicsLabel release];
                
                [_editView addSubview:[self greyGlassViewInFrame:CGRectMake(0.0f, 25, 74, 35) withLabel:NSLocalizedString(@"Name", @"Name")]];
                [_editView addSubview:[self greyGlassViewInFrame:CGRectMake(0.0f, 60, 74, 35) withLabel:NSLocalizedString(@"Fax", @"Fax")]];
                [_editView addSubview:[self greyGlassViewInFrame:CGRectMake(0.0f, 95, 74, 35) withLabel:NSLocalizedString(@"Phone", @"Phone")]];
                [_editView addSubview:[self greyGlassViewInFrame:CGRectMake(0.0f, 130, 74, 35) withLabel:NSLocalizedString(@"Mobile", @"Mobile")]];
                [_editView addSubview:[self greyGlassViewInFrame:CGRectMake(0.0f, 165, 74, 35) withLabel:NSLocalizedString(@"Email", @"Email")]];
                
                CustomPlaceholderTextField *nameField = [self textFieldInFrame:CGRectMake(5, 2, 236, 31) withText:nil placeholder:NSLocalizedString(@"Tap to add", @"Tap to add")];
                nameField.tag = 11;
                
                CustomPlaceholderTextField *faxField = [self textFieldInFrame:CGRectMake(5, 2, 236, 31) withText:nil placeholder:NSLocalizedString(@"Tap to add", @"Tap to add")];
                faxField.tag = 12;
                
                CustomPlaceholderTextField *phoneField = [self textFieldInFrame:CGRectMake(5, 2, 236, 31) withText:nil placeholder:NSLocalizedString(@"Tap to add", @"Tap to add")];
                phoneField.tag = 13;
                
                CustomPlaceholderTextField *mobileField = [self textFieldInFrame:CGRectMake(5, 2, 236, 31) withText:nil placeholder:NSLocalizedString(@"Tap to add", @"Tap to add")];
                mobileField.tag = 15;
                
                CustomPlaceholderTextField *emailField = [self textFieldInFrame:CGRectMake(5, 2, 236, 31) withText:nil placeholder:NSLocalizedString(@"Tap to add", @"Tap to add")];
                emailField.tag = 16;
                if (_referringPhysician != nil) {
                    // TODO set fields values
                }
                
                [_editView addSubview:[self greyGradientViewInFrame:CGRectMake(74, 25, 246, 35) withSubview:nameField]];
                [_editView addSubview:[self greyGradientViewInFrame:CGRectMake(74, 60, 246, 35) withSubview:faxField]];
                [_editView addSubview:[self greyGradientViewInFrame:CGRectMake(74, 95, 246, 35) withSubview:phoneField]];
                [_editView addSubview:[self greyGradientViewInFrame:CGRectMake(74, 130, 246, 35) withSubview:mobileField]];
                [_editView addSubview:[self greyGradientViewInFrame:CGRectMake(74, 165, 246, 35) withSubview:emailField]];
            }
            
            return _editView;
        }
            break;
	}
	return nil;
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
