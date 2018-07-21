// Created by Developer Toy
//IcdDetails.h

#import <UIKit/UIKit.h>
#import "QliqBaseViewController.h"
#import "Census_old.h"

@class Icd;
@class Patient_old;
@class StretchableButton;

@interface IcdDetailsView : QliqBaseViewController <UITextFieldDelegate>
{
	id obj;
	UITextField *txtPft;
    double physicianNpi;
	NSInteger superbillId;
    
    StretchableButton *_favButton;
    StretchableButton *_aliasButton;
    UILabel *titleLabel;
	BOOL showModifier;
	
}
@property (nonatomic, retain) id obj;
@property (nonatomic, readwrite) NSInteger superbillId;
@property (nonatomic, retain) Census_old *censusObj;
@property (nonatomic, readwrite) BOOL showModifier;


@end