// Created by Developer Toy
//AddPatientView.h

#import <UIKit/UIKit.h>
#import "QliqBaseViewController.h"
#import "Physician.h"

@class StretchableButton;
@class Census_old;

@interface RoundViewController : QliqBaseViewController <UITextFieldDelegate, UIActionSheetDelegate>
{

    StretchableButton *_notesButton;
    StretchableButton *_editButton;
    StretchableButton *_finishButton;
    StretchableButton *_dischargeButton;
	

    QliqModelViewMode _currentViewMode;

    UIView *_viewView; // view to view a patient
    UIScrollView *_editView;
    UIScrollView *_addView;
    
    UIView *_buttonView;
    UIView *_blankView;
	
	//RA:
	UITextField *currentTextField;

    UILabel *demoInfoAgeLabel;
    UILabel *demoInfoSexLabel;
    UILabel *demoInfoEthnicitySexLabel;
    UILabel *demoInfoEthnicityLabel;
    
    UILabel *facilityInfoNameLabel;
	UILabel *facilityInfoMrnLabel;
    UILabel *facilityInfoRoomLabel;
    
    UILabel *visitInfoAdmissionLabel;
	UILabel *visitInfoDischargeLabel;
    UILabel *visitInfoReferringLabel;
    
    NSArray* responderChainOnReturn;
	UIActionSheet *pickerViewPopup;
	UIDatePicker *pickerView;
	UIToolbar *pickerToolbar;
	Census_old	*_census;
	NSTimeInterval _selectedDos;
}
@property (nonatomic, assign) QliqModelViewMode currentViewMode;
@property (nonatomic, retain) NSString *selectedEthnicity;
@property (nonatomic, retain) NSString *selectedFacilityName;
@property (nonatomic, assign) NSInteger selectedFacilityId;
@property (nonatomic, retain) NSString *selectedReferringPhysicianName;
@property (nonatomic, assign) NSInteger selectedReferringPhysicianId;
@property (nonatomic, retain) Census_old *census;
@property (nonatomic, retain) Patient_old *patient;
@property (nonatomic, retain) PhysicianPref *physicianPref;
@property (nonatomic, readwrite) NSTimeInterval selectedDos;

@end