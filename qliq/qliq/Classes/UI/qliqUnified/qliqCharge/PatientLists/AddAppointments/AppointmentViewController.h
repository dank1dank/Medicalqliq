// Created by Developer Toy
//AddApptView.h

#import <UIKit/UIKit.h>
#import "QliqBaseViewController.h"

@class Appointment;
@class StretchableButton;
@class Physician;

@interface AppointmentViewController : QliqBaseViewController<UITextFieldDelegate>
{
    UIDatePicker *_startDatePicker;
    NSInteger _duration;
	
    UIView *_blankView;
    
    IBOutlet UIView *_editView;
    IBOutlet UILabel *_patientLabel;
    IBOutlet UILabel *_locationLabel;
    IBOutlet CustomPlaceholderTextField *_reasonField;
    IBOutlet UILabel *_startTimeLabel;
    IBOutlet UILabel *_durationLabel;
    IBOutlet UILabel *_providerLabel;
    IBOutlet UILabel *_reminderLabel;
    
    IBOutlet UIView *_addView;
    IBOutlet UILabel *_addPatientLabel;
    IBOutlet UILabel *_addLocationLabel;
    IBOutlet CustomPlaceholderTextField *_addReasonField;
    IBOutlet UILabel *_addStartTimeLabel;
    IBOutlet UILabel *_addDurationLabel;
    IBOutlet UILabel *_addProviderLabel;
    IBOutlet UILabel *_addReminderLabel;

    
    IBOutlet UIView *_viewView;
    IBOutlet UILabel *_viewPatientLabel;
    IBOutlet UILabel *_viewLocationLabel;
    IBOutlet UILabel *_viewReasonLabel;
    IBOutlet UILabel *_viewStartTimeLabel;
    IBOutlet UILabel *_viewDurationLabel;
    IBOutlet UILabel *_viewProviderLabel;
    IBOutlet UILabel *_viewReminderLabel;

    IBOutlet UIView *_buttonView;
    IBOutlet StretchableButton *_editButton;
    IBOutlet StretchableButton *_finishButton;

    IBOutlet UIView *_reminderSelectorView;
    IBOutlet UIImageView *_reminderPickedImage;

    IBOutlet UIView *_durationSelectorView;
    IBOutlet UIImageView *_durationPickedImage;
    UIButton *_selectDuration;
}

@property (nonatomic, assign) QliqModelViewMode currentViewMode;
@property (nonatomic, retain) Appointment *appointment;
@property (nonatomic, retain) Physician *physician;

- (IBAction)presentPatientList:(id)sender;
- (IBAction)presentLocationList:(id)sender;
- (IBAction)presentStartTimePicker:(id)sender;
- (IBAction)presentDurationList:(id)sender;
- (IBAction)presentProviderList:(id)sender;
- (IBAction)presentReminderList:(id)sender;
- (IBAction)selectReminder:(id)sender;
- (IBAction)selectDuration:(id)sender;
- (IBAction)saveAppointment:(id)sender;

@end