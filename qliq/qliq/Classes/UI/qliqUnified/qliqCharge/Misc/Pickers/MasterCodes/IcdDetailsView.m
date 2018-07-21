// Created by Developer Toy
//IcdDetails.m
#import "IcdDetailsView.h"
#import "Patient_old.h"
#import "LightGreyGradientView.h"
#import "LightGreyGlassGradientView.h"
#import "StretchableButton.h"
#import "DarkGreyGlassGradientView.h"
#import "Cpt.h"
#import "Icd.h"
#import "RoundViewController.h"

#import <QuartzCore/QuartzCore.h>

@interface IcdDetailsView () <PatientHeaderViewDelegate>

- (void)presentAlertWithMessage:(NSString *)msg;
- (void)presentAliasField:(id)sender;
- (void)updateTitleLabel;
- (void)updateAliasButton;

@end

@implementation IcdDetailsView
@synthesize superbillId;
@synthesize showModifier;
@synthesize obj, censusObj;
/*
@synthesize obj,physicianNpi,superbillId;
@synthesize patient, dateOfService, showModifier;
*/

#pragma mark -
#pragma mark View lifecycle

- (void)loadView {
    [super loadView];
	//Patient *patientObj = [[Patient getPatientToDisplay:self.censusObj.patientId] objectAtIndex:0];
	
    PatientHeaderView *patientView = [self patientHeader:self.censusObj dateOfService:self.censusObj.dateOfService delegate:self];
   	[patientView setState:UIControlStateDisabled];
	[self.view addSubview:patientView];

    DarkGreyGlassGradientView *headerBgView = [[DarkGreyGlassGradientView alloc] initWithFrame:CGRectMake(0.0, 46, self.view.bounds.size.width, 42)];
    [self.view addSubview:headerBgView];
    [headerBgView release];
    LightGreyGradientView *bgView = [[LightGreyGradientView alloc] initWithFrame:CGRectMake(0.0, 88, self.view.bounds.size.width, 283)];
    bgView.layer.cornerRadius = 0;
    [self.view addSubview:bgView];
    [bgView release];
    titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 46, self.view.bounds.size.width - 20, 42)];
    titleLabel.textColor = [UIColor colorWithWhite:1.0 alpha:1.0f];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:14.0f];
    titleLabel.numberOfLines = 1;
    [self.view addSubview:titleLabel];
    
	UIView *buttonsView = [[UIView alloc] initWithFrame:CGRectMake(0, 371, 320, 45)];
	LightGreyGlassGradientView *buttonBgView = [[LightGreyGlassGradientView alloc] initWithFrame:buttonsView.bounds];
	[buttonsView addSubview:buttonBgView];
	[buttonBgView release];

	NSString *codeVal = nil;
	
	if(!showModifier){
		txtPft=[[UITextField alloc] initWithFrame:CGRectMake(50,51,260,30)];
		txtPft.delegate=self;
		
		// We are storing the PFT with quotes in the database (DBPersist.m)
		// In PFT edit mode, we need to remove the quotes
		
		NSMutableString *pft = [[NSMutableString alloc] initWithString:@""];
		NSString *shortDesc = nil;
		if ([obj isKindOfClass:[Icd class]]) {
			shortDesc = [Icd getShortDescription:(Icd *)obj];
			codeVal = ((Icd *)obj).code;
		}
		else {
			shortDesc = [Cpt getShortDescription:(Cpt *)obj];
			codeVal = ((Cpt *)obj).code;
			
		}
		[pft appendString:shortDesc];
		
		if([pft length]>0)
			[pft replaceOccurrencesOfString:@"\"" withString:@"" options:NSCaseInsensitiveSearch range:(NSRange){0,[pft length]}];
		
		txtPft.text = pft;
		[pft release];
		txtPft.placeholder=@"Alias";
		txtPft.font = [UIFont systemFontOfSize:14.0f];
		//    txtPft.adjustsFontSizeToFitWidth=YES;
		txtPft.clearsOnBeginEditing=NO;
		txtPft.autocapitalizationType=1;
		txtPft.contentVerticalAlignment=UIControlContentVerticalAlignmentCenter;
		txtPft.borderStyle = UITextBorderStyleRoundedRect;
		txtPft.hidden = YES;
		txtPft.clearButtonMode = UITextFieldViewModeWhileEditing;
		txtPft.tag = 23;
        txtPft.returnKeyType = UIReturnKeyDone;
		[self.view addSubview:txtPft];
		
		UITextView *descriptionView = [[UITextView alloc] initWithFrame:CGRectMake(0, 98, self.view.bounds.size.width, 263)];
		descriptionView.editable = NO;
		descriptionView.text = ((Icd *)obj).longDescription;
		descriptionView.font = [UIFont systemFontOfSize:14.0f];
		descriptionView.textColor = [UIColor colorWithWhite:0.3 alpha:1.0f];
		descriptionView.backgroundColor = [UIColor clearColor];
		[self.view addSubview:descriptionView];
		[descriptionView release];
		
		_favButton = [StretchableButton buttonWithType:UIButtonTypeCustom];
		_favButton.btnType = StretchableButton25;
		_favButton.tag = 21;
		_favButton.frame = CGRectMake(10, 1, 160, 42);
		_favButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.f];
		
		if ([self.obj isFavoriteFor:self.censusObj.physicianNpi:self.superbillId]) {
			[_favButton addTarget:self action:@selector(clickbtnDeleteFromFav:) forControlEvents:UIControlEventTouchUpInside];
			[_favButton setTitle:@"Remove From Favorites" forState:UIControlStateNormal];
		}
		else {
			[_favButton addTarget:self action:@selector(clickbtnAddToFav:) forControlEvents:UIControlEventTouchUpInside];
			[_favButton setTitle:@"Add To Favorites" forState:UIControlStateNormal];
		}
		
		[buttonsView addSubview:_favButton];
		
		_aliasButton = [StretchableButton buttonWithType:UIButtonTypeCustom];
		_aliasButton.btnType = StretchableButton25;
		_aliasButton.tag = 22;
		_aliasButton.frame = CGRectMake(190, 1, 120, 42);
		_aliasButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.f];

        [self updateAliasButton];
		
        [_aliasButton addTarget:self action:@selector(presentAliasField:) forControlEvents:UIControlEventTouchUpInside];
		[buttonsView addSubview:_aliasButton];
		
		[self.view addSubview:buttonsView];
		
		[self updateTitleLabel];
		
		if ([obj isKindOfClass:[Icd class]]) {
			self.navigationItem.rightBarButtonItem = [self rightItemWithTitle:NSLocalizedString(@"ICD Description", @"ICD Description") 
																  buttonImage:nil buttonAction:nil];
		}
		else {
			self.navigationItem.rightBarButtonItem = [self rightItemWithTitle:NSLocalizedString(@"CPT Description", @"CPT Description") 
																  buttonImage:nil buttonAction:nil];
		}
	}else{
		//titleLabel.text = ((SuperbillCptModifier *)obj).modifier;
		titleLabel.text = @"";
		
		UITextView *descriptionView = [[UITextView alloc] initWithFrame:CGRectMake(0, 98, self.view.bounds.size.width, 263)];
		descriptionView.editable = NO;
		//descriptionView.text = ((SuperbillCptModifier *) obj).modifierDescription;
		descriptionView.text =@"";
		descriptionView.font = [UIFont systemFontOfSize:14.0f];
		descriptionView.textColor = [UIColor colorWithWhite:0.3 alpha:1.0f];
		descriptionView.backgroundColor = [UIColor clearColor];
		[self.view addSubview:descriptionView];
		[descriptionView release];
		
		self.navigationItem.rightBarButtonItem = [self rightItemWithTitle:NSLocalizedString(@"Modifier Description", @"Modifier Description") 
															  buttonImage:nil buttonAction:nil];
	}
	if([codeVal isEqualToString:NSLocalizedString(@"NOVISIT",@"NOVISIT")]){
		_aliasButton.enabled=NO;
		_favButton.enabled=NO;
	}
	[buttonsView release];
}

- (void)viewDidUnload {
}

- (void)dealloc {
    [obj release];
	[txtPft release];
	[super dealloc];
}

#pragma mark -
#pragma mark Actions

-(void) clickbtnAddToFav:(id)sender
{
    NSInteger favId = 0;
    if ([obj isKindOfClass:[Icd class]]) {
        favId = [Icd addToFavorites:((Icd *)obj).code :self.censusObj.physicianNpi];
    }
    else {
        favId = [Cpt addCptToFavorites:superbillId :((Cpt *)obj).code :self.censusObj.physicianNpi];
    }
	
    if (favId > 0) {
        UIButton *btnAddToFav = sender;
        [btnAddToFav removeTarget:self action:@selector(clickbtnAddToFav:) forControlEvents:UIControlEventTouchUpInside];
        [btnAddToFav addTarget:self  action:@selector(clickbtnDeleteFromFav:) forControlEvents:UIControlEventTouchUpInside];
        [btnAddToFav setTitle:@"Remove From Favorites" forState:UIControlStateNormal];
        [self presentAlertWithMessage:NSLocalizedString(@"Successfully added to favorites", nil)];
    }
    else {
        [self presentAlertWithMessage:NSLocalizedString(@"There was a problem adding to favorites", nil)];
    }
}

-(void) clickbtnDeleteFromFav:(id)sender
{
    BOOL success = NO;
    if ([obj isKindOfClass:[Icd class]]) {
        success = [Icd deleteFromFavorites:((Icd *)obj).code :self.censusObj.physicianNpi];
    }
    else {
        success = [Cpt deleteCptFromFavorites:superbillId :((Cpt *)obj).code :self.censusObj.physicianNpi];
    }
	
	NSLog(@"delete fav: %d", success);
    if (success) {
        UIButton *btnAddToFav = sender;
        [btnAddToFav removeTarget:self action:@selector(clickbtnDeleteFromFav:) forControlEvents:UIControlEventTouchUpInside];
        [btnAddToFav addTarget:self  action:@selector(clickbtnAddToFav:) forControlEvents:UIControlEventTouchUpInside];
        [btnAddToFav setTitle:@"Add To Favorites" forState:UIControlStateNormal];
        [self presentAlertWithMessage:NSLocalizedString(@"Successfully removed from favorites", nil)];
    }
}

-(void)clickCancelIcdDetails:(id)sender
{
	[self dismissModalViewControllerAnimated:YES];
}

-(void)clickDoneIcdDetails:(id)sender
{
	BOOL icdAdded = [Icd updatePhysicianIcdPft:((Icd *)obj).code :((Icd *)obj).physicianIcdPft];
	if(icdAdded)
		[self dismissModalViewControllerAnimated:YES];
}

- (void)updateTitleLabel {
    if (txtPft.hidden) {
        NSMutableString *desc = [NSMutableString stringWithString:@""];
        if ([obj isKindOfClass:[Icd class]]) {
			[desc appendString:((Icd *)obj).code];
			NSString *shortDesc = [Icd getShortDescription:(Icd *)obj];
			[desc appendString:@" • "];
			[desc appendString:shortDesc];
        }
        else {
			[desc appendString:((Cpt *)obj).code];
			NSString *shortDesc = [Cpt getShortDescription:(Cpt *)obj];
			[desc appendString:@" • "];
			[desc appendString:shortDesc];
        }
        titleLabel.text = desc;
        //titleLabel.text = [NSString stringWithFormat:@"%@ • %@", ((Icd *)obj).code, desc];
    }
    else {
        titleLabel.text = ((Icd *)obj).code;
    }
}

- (void)presentAliasField:(id)sender {
    txtPft.hidden = !txtPft.hidden;
    if (txtPft.hidden) {
        [txtPft resignFirstResponder];
    }
    else {
        [txtPft becomeFirstResponder];
    }
}

- (void)updateAliasButton{
    if ([obj isKindOfClass:[Icd class]]) {
		NSString *masterPft = ((Icd *)obj).masterIcdPft;
		NSString *physicianPft = ((Icd *)obj).physicianIcdPft;
        if ((masterPft != nil && [masterPft length] > 0) 
			|| (physicianPft != nil && [physicianPft length] > 0))
		{
            [_aliasButton setTitle:@"Update ICD Alias" forState:UIControlStateNormal];
        }
        else {
            [_aliasButton setTitle:@"Create ICD Alias" forState:UIControlStateNormal];
        }
    }
    else {
        if ((((Cpt *)obj).physicianCptPft != nil && [((Cpt *)obj).physicianCptPft length] > 0)
			|| (((Cpt *)obj).masterCptPft != nil && [((Cpt *)obj).masterCptPft length] > 0))
		{
            [_aliasButton setTitle:@"Update CPT Alias" forState:UIControlStateNormal];
        }
        else {
            [_aliasButton setTitle:@"Create CPT Alias" forState:UIControlStateNormal];
        }
    }
}

#pragma mark -
#pragma mark UITextFieldDelegate

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    if (textField.tag == 23) {
		NSMutableString *pft = [NSMutableString stringWithString:@""];
		[pft appendString:@"\""];
		[pft appendString:textField.text];
		[pft appendString:@"\""];
		
        if ([obj isKindOfClass:[Icd class]]) {
            ((Icd *)obj).physicianIcdPft = pft;
        }
        else {
            ((Cpt *)obj).physicianCptPft = pft;
        }
    }
    [obj savePft];
    textField.hidden = YES;
    [self updateTitleLabel];
	[textField resignFirstResponder];
	return YES;
}

//---when a TextField view is done editing---
-(void) textFieldDidEndEditing:(UITextField *) textField {
    if (textField.tag == 23) {
		NSMutableString *pft = [NSMutableString stringWithString:@""];
		[pft appendString:@"\""];
		[pft appendString:textField.text];
		[pft appendString:@"\""];
        if ([obj isKindOfClass:[Icd class]]) {
            ((Icd *)obj).physicianIcdPft = pft;
        }
        else {
            ((Cpt *)obj).physicianCptPft = pft;
        }
        [obj savePft];
        [self updateTitleLabel];

    }
    
    [self updateAliasButton];
    
    textField.hidden = YES;
}




#pragma mark -
#pragma mark UIAlertViewDelegate

- (void)presentAlertWithMessage:(NSString *)msg {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Info", @"Info")
                                                    message:msg
                                                   delegate:nil 
                                          cancelButtonTitle:NSLocalizedString(@"OK", @"OK") 
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
}

#pragma mark -
#pragma mark PatientListViewDelegate

- (void)patientViewClicked:(Patient_old *)patient {
    RoundViewController *patientView = [[RoundViewController alloc] init];
    //patientView.census = [[Census getCensusObject:self.censusId] objectAtIndex:0];
	PhysicianPref *physicianPref = [PhysicianPref getPhysicianPrefs:self.censusObj.physicianNpi];
	patientView.physicianPref = physicianPref;
    patientView.census = self.censusObj;
    patientView.currentViewMode = QliqModelViewModeView;
	if ([obj isKindOfClass:[Cpt class]])
		patientView.previousControllerTitle = NSLocalizedString(@"CPT Description", @"CPT Description");
	else if ([obj isKindOfClass:[Icd class]])
		patientView.previousControllerTitle = NSLocalizedString(@"ICD Description", @"ICD Description");
    [self.navigationController pushViewController:patientView animated:YES];
    [patientView release];
}
@end
