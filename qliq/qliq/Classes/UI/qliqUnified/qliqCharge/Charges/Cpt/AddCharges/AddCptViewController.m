//
//  AddCodesViewController.h
//  CCiPhoneApp
//
//  Created by Ravi Ada on 4/12/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//
//	1. group changes - erase selected cpt and modifiers
//  2. within the group - retain the selection when changing the cpt wheel or mod wheel
//  3. select button - enable only when there is a valid cpt selected
//  6. when a new CPT under focus within the same group, overwrite the selected CPT, keep the selected modifier(s)
//  
//  Exception: ALL CPT CODES is the group and VIEW is the code
//  1. When VIEW is in focus, show all CPT codes
//  2. If Cancel is pressed in all cpt codes view, keep the selected CPT and Modifier(s)
//  3. If Done, overwirte the selected CPT with the newly selected CPT code and keep the selected modifier(s)  

#import "AddCptViewController.h"
#import "UserHeaderView.h"
#import "LightGreyGlassGradientView.h"
#import "StretchableButton.h"
#import "ObjectSelectViewController.h"
#import "WhiteObjectDetailsTableCell.h"
#import "GreyObjectDetailsTableCell.h"

#define OR_START_ID 149
#define AN_START_ID 147
#define AN_STOP_ID 148
#define OR_STOP_ID 150


@interface AddCptViewController (Private) <PatientHeaderViewDelegate, UITableViewDelegate, UITableViewDataSource>
- (void) resetTableViewAfterSwipeDelete;
- (void) presentDetails;
- (NSString*) getTextWhenSecondWheelSelected;
- (NSString*) getTextWhenThirdWheelSelected;
- (NSString*)getTextWhenSelectBtnSelected;
- (void) updateSelectButton;
- (void) updateDoneButton;
- (BOOL) enableDoneBtn;
- (NSInteger) selectedGroup;
- (BOOL) groupIsSelected;
- (NSInteger) selectedCptCode;
- (BOOL) cptCodeIsSelected;
- (NSInteger) selectedModifier;
- (BOOL) modifierIsSelected;
- (void) scrollTableToBottom;
- (void) saveChangesAndClose;
- (void) closeWithoutSaving;
- (BOOL) allRequiredGroupsSelected;
- (NSInteger) getRowToSelectForFirstWheel;
- (NSInteger) getRowToSelectForSecondWheel;
- (NSInteger) getRowToSelectForThirdWheel;
- (NSInteger) indexOfGroupWithId:(NSInteger)groupId;
- (NSInteger) indexOfCptCodeWithId:(NSInteger)cptcodeId;
- (NSInteger) indexOfModifierWithId:(NSInteger)modifierId;
- (NSString*) validateSelectedItem; //returns nil if ok
- (int) compareCurrentTimeWithTimeOfGroup:(NSInteger)groupID;
@end

@implementation AddCptViewController

-(id) init
{
    self = [super init];
    if(self)
    {
		//initialize the instance vars
		
    }
    return self;
}

- (void)dealloc 
{
    [cptGroups release];
    [_modAddButton release];
	[super dealloc];
}

#pragma mark -
#pragma mark View lifecycle
- (void)loadView 
{
    [super loadView];
    
    self.navigationItem.rightBarButtonItem = [self rightItemWithTitle:NSLocalizedString(@"CPT Entry", @"CPT Entry") 
                                                          buttonImage:nil
                                                         buttonAction:nil];
	
    UIButton* cancelButtonView = [UIButton buttonWithType: UIButtonTypeCustom];
    UIImage* cancelButtonImage = [[UIImage imageNamed: @"bg-cancel-btn.png"] stretchableImageWithLeftCapWidth: 17 topCapHeight: 0];
    [cancelButtonView setBackgroundImage: cancelButtonImage
                                forState: UIControlStateNormal];
    [cancelButtonView setTitle: @"Cancel" forState: UIControlStateNormal];
    cancelButtonView.titleLabel.font = [UIFont boldSystemFontOfSize: 12.0f];
    cancelButtonView.frame = CGRectMake(0.0f, 0.0f, 80.0f, 42.0f);
    [cancelButtonView addTarget: self 
                         action:@selector(closeWithoutSaving) 
               forControlEvents: UIControlEventTouchUpInside];
    UIBarButtonItem* cancelBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView: cancelButtonView] autorelease];
    self.navigationItem.leftBarButtonItem = cancelBarButtonItem;
}

- (void)viewDidLoad 
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self setNavigationBarBackgroundImage];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setNavigationBarBackgroundImage];
}

- (void)viewDidUnload
{
}
#pragma mark -
#pragma mark Actions

-(void) closeWithoutSaving
{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	return 3;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    switch(component)
    {
        case 0:
        {
        }break;
        case 1:
        {
        }break;
        case 2:
        {
        }break;
        default: return 0;
    }
    return 0;
}

#pragma mark -
#pragma mark UIPickerViewDelegate

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
	return 30.0;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
	// Return width for each wheel
	switch (component) 
	{
			// GROUP
		case 0:
			return 200;
			// CPT CODE	
		case 1:
			return 60;
			// MODIFIER	
		case 2:
			return 50;
		default:
			break;
	}
	return 100.0;
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row 
		  forComponent:(NSInteger)component reusingView:(UIView *)view 
{
	
	UILabel *retval = (id)view;
	if (!retval)
    {
		retval= [[[UILabel alloc] initWithFrame:CGRectMake(5,
                                                           0,
                                                           [pickerView rowSizeForComponent:component].width, 
														   [pickerView rowSizeForComponent:component].height)] autorelease];
	}
	retval.backgroundColor = [UIColor clearColor];
    retval.textAlignment = UITextAlignmentRight;
    retval.font = [UIFont boldSystemFontOfSize:12];
    retval.textColor = [UIColor blackColor];
	NSLog(@"Component: %d Row: %d ", component, row);	
	
	switch (component)
	{
			// PAINT GROUP LABEL	
		case 0:
				retval.text = @"";
			break;
			// PAINT CPT CODE LABEL
		case 1:
 				retval.text = @"";	
 			break;
			// PAINT MODIFIER LABEL 			
		case 2:
				retval.text = @"";
			break;			
		default:
			retval.text = @"";
			break;
	}
	NSLog(@"Component: %d Row: %d Text: %@", component, row, retval.text);	
	return retval;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
	NSLog(@"Selected Component: %d Row: %d ", component, row);
	switch (component)
	{
		// GROUP SELECTION
		case 0:
        {
		}break;
			// CPT CODE SELECTION
		case 1:
        {
        }break;
			// MODIFIER SELECTION
		case 2:
        {
        }break;
		default:
			break;
	}
}

#pragma mark -
#pragma mark UITableViewDatasource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WhiteObjectDetailsTableCell *cell = nil;
	NSString *CellIdentifier = @"CPTSelection";
	cell = (WhiteObjectDetailsTableCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
    if (cell == nil)
    {
        cell = [[[WhiteObjectDetailsTableCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
	cell.textLabel.text = @"";
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
   return 1;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath 
{
    return YES;
}

-(BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
}

-(UITableViewCellEditingStyle) tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

-(NSString*) tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"Delete";
}

#pragma mark -
#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 35.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}


-(void) doneButtonPressed
{
}

-(void) cancelButtonPressed
{

}

@end
