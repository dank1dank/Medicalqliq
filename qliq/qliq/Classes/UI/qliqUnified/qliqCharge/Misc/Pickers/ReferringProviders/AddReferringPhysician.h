// Created by Developer Toy
//AddFacilityView.h

#import <UIKit/UIKit.h>
#import "QliqBaseViewController.h"

@class StretchableButton;
@class ReferringPhysician;

@interface AddReferringPhysician: QliqBaseViewController
{

    StretchableButton *_notesButton;
    StretchableButton *_editButton;
    StretchableButton *_finishButton;
    
    QliqModelViewMode _currentViewMode;
    
    UIView *_viewView; // view to view a patient
    UIView *_editView;
    
    UIView *_buttonView;
    UIView *_blankView;

}
@property (nonatomic, assign) QliqModelViewMode currentViewMode;
@property (nonatomic, retain) ReferringPhysician *referringPhysician;

@end