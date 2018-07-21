//
//  AddCptView.h
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/21/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "StretchableButton.h"
#import "PatientHeaderView.h"
#import "LightGreyGlassGradientView.h"

@protocol AddCptViewDelagate <NSObject>

-(void) showDetails;
-(void) selectButtonPressed;
-(void) doneButtonPressed;
-(void) cancelButtonPressed;

@end

@interface AddCptView : UIView <UIGestureRecognizerDelegate>
{
    PatientHeaderView *header_;
    
    UIPickerView *cptPickerView;
    UIImageView *cptPickerViewFrame;
    
    UIImageView *pickerSelectorImage;
    UIImageView *details_bg;
    UILabel *detailsLabel_;
    UIImageView* detailsAccessoryView;
    UIImageView* pickerOverlayView;
	
    LightGreyGlassGradientView *buttonsView;
    StretchableButton *_selectButton;
    StretchableButton *_doneButton;
    StretchableButton *_cancelButton;
    
    UITableView *cptTable_;
    
    UITapGestureRecognizer *tapRecognizer;
    
    id<AddCptViewDelagate> delegate_;
}

@property (nonatomic, readonly) UIPickerView *pickerView;
@property (nonatomic, readonly) UITableView *tableView;
@property (nonatomic, retain) PatientHeaderView *header;
@property (nonatomic, readonly) UILabel *detailsLabel;

@property (nonatomic, assign) id<AddCptViewDelagate> delegate;

-(void)setSelectButtonEnabled:(BOOL) enabled;
-(void)setDoneButtonEnabed:(BOOL) enabled;

@end
