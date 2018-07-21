//
//  Home.h
//  CCiPhoneApp
//
//  Created by Ravi Ada on 4/12/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//


#import <UIKit/UIKit.h>

#import "QliqBaseViewController.h"
#import "HorizontalPickerView.h"

@class StretchableButton;

@class Census_old;
@class Appointment;
@class StretchableButton;
@class PatientHeaderView;

@interface CodesView_old : QliqBaseViewController <UITabBarControllerDelegate,HorizontalPickerViewDelegate>{
    HorizontalPickerView* horizontalPicker;
	NSMutableArray *pickerViewArray; 
	NSString *_selectedDos;
	NSTimeInterval dosIntervalToQuery;
	
	NSMutableArray *arrayToDisplay;
	NSMutableArray *cptInsidePickerViewArray;
	
    //UITableView *_tableView;
    StretchableButton *_notesButton;
    //StretchableButton *_editButton;
    StretchableButton *_copyButton;
    StretchableButton *_finishButton;
    NSInteger _openedSection;
    BOOL _showAllSections;
    Census_old *_censusObj;
    Appointment *apptObj;
	
	UIBarButtonItem *addChargesBtnWithSelector;
	UIBarButtonItem *addChargesBtnWithNoSelector;
	
	NSInteger encounterId;
    PatientHeaderView *_patientView;
	unsigned int days;
	NSInteger lastSelectedPickerRow;
	
}
@property (nonatomic, retain) Census_old *censusObj;
@property (nonatomic, retain) Appointment *apptObj;
@property (nonatomic, retain) UITableView *tableView;

- (void) addNewCpt:(id) sender;

@end