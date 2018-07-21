//
//  AddCptView.h
//  CCiPhoneApp
//
//  Created by Ravi Ada on 4/12/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "Superbill.h"
#import "CptGroup.h"
#import "AddCptView.h"
#import "QliqBaseViewController.h"

@class StretchableButton;

@interface AddCptViewController : QliqBaseViewController <UIPickerViewDelegate,UIPickerViewDataSource>
{

    AddCptView *addCptView;
    NSMutableArray *cptGroups;
    StretchableButton *_modAddButton;
    UITextView *_descTextView;
	UITapGestureRecognizer *tapGestureRecognizer;
}
@end