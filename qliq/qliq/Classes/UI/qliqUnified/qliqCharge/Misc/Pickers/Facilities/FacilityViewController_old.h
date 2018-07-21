// Created by Developer Toy
//AddFacilityView.h

#import <UIKit/UIKit.h>
#import "QliqBaseViewController.h"

@class StretchableButton;
@class Facility_old;

@interface FacilityViewController_old : QliqBaseViewController
{

    StretchableButton *_notesButton;
    StretchableButton *_editButton;
    StretchableButton *_finishButton;
    
    QliqModelViewMode _currentViewMode;
    
    UIView *_viewView; // view to view a patient
    // MZ: this one is used for edit and add
    // MZ: difference is in edit mode fields are filled with data already
    UIView *_editView;
    
    UIView *_buttonView;
    UIView *_blankView;

}

@property (nonatomic, assign) QliqModelViewMode currentViewMode;
@property (nonatomic, retain) NSString *selectedStateName;
@property (nonatomic, retain) NSString *selectedStateCode;

@property (nonatomic, retain) NSString *selectedSuperbillName;
@property (nonatomic, retain) NSString *selectedFacilityType;

//@property (nonatomic, assign) NSInteger selectedFacilityId;
@property (nonatomic, retain) Facility_old *facility;

@end