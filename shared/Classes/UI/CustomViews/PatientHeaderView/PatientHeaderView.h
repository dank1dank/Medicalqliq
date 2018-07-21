//
//  PatientHeaderView.h
//  CCiPhoneApp
//
//  Created by Marcin Zbijowski on 03/05/2011.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Census_old;
@class Patient_old;


@protocol PatientHeaderViewDelegate

@required
- (void)patientViewClicked:(Patient_old *)patientObj;

@optional
- (void)patientDateClicked:(Patient_old *)patientObj;

@end

@interface PatientHeaderView : UIView
{
    UIView *bgView;
    UIImageView *accessoryView;
    UITapGestureRecognizer *tapRecognizer;
    UIButton *_dateActionButton;
    UIButton *_actionButton;
    UIImageView *_arrowView;
    Patient_old *patientObj;
}

@property (nonatomic, retain) UILabel *dateLabel;
@property (nonatomic, retain) UILabel *textLabel;
@property (nonatomic, retain) UILabel *textLabel2;
@property (nonatomic, retain) Census_old *censusObj;
//@property (nonatomic, retain) Patient *patient;
@property (nonatomic, retain) id<PatientHeaderViewDelegate> delegate;

- (id)initWithFrame:(CGRect)frame state:(UIControlState)state;
- (void)setState:(UIControlState)state;

@end


