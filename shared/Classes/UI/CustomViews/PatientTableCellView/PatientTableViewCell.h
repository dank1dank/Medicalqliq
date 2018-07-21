//
//  PatientTableViewCell.h
//  CCiPhoneApp
//
//  Created by Marcin Zbijowski on 18/05/2011.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum
{
    HandoffIndicatorNone,
    HandoffIndicatorRight,
    HandoffIndicatorLeft
} HandoffIndicatorType;

@class PatientTableViewCell;
@class Census;

@protocol PatientTableViewCellDelegate

-(BOOL) shouldShowVisitStatusButtonForCell:(PatientTableViewCell*)cell;
-(BOOL) shouldShowHandoffButtonForCell:(PatientTableViewCell*) cell;
-(NSString*) visitStatusButtonTitleForCell:(PatientTableViewCell*) cell;
-(NSString*) handoffButtonTitleForCell:(PatientTableViewCell*) cell;
-(void) visitButtonPressedOnCell:(PatientTableViewCell*) cell;
-(void) handoffButtonPressedOnCell:(PatientTableViewCell*) cell;

@end

@interface PatientTableViewCell : UITableViewCell 
{
    UISwipeGestureRecognizer *leftToRightSwipeRecognizer;
    UISwipeGestureRecognizer *rightToLeftSwipeRecognizer;
    
    UIButton *handOffButton;
    UILabel *handOffButtonTitle;
    CGFloat handOffButtonWidth;
    
    UIButton *visitStatusButton;
    UILabel *visitStatusButtonTitle;
    CGFloat visitStatusButtonWidth;
    
    BOOL handOffButtonVisible_;
    BOOL visitStatusButtonVisible_;
    id<PatientTableViewCellDelegate> delegate_;
    
    UIImageView *handoffIndicator;
    HandoffIndicatorType handoffIndicatorType_;
}

@property (nonatomic, retain) UILabel *lblFacilityAbbreviation;
@property (nonatomic, retain) UILabel *lblPatientName;
@property (nonatomic, retain) UILabel *lblRoomFacilityName;
@property (nonatomic, retain) UILabel *lblPatientAgeGenderRace;
@property (nonatomic, retain) UILabel *lblAdmitDischargeConsultIndicator;
@property (nonatomic, retain) UILabel *lblInsurance;
@property (nonatomic, retain) UILabel *lblDate;
@property (nonatomic, retain) UILabel *lblPhysicianName;
@property (nonatomic, retain) UIImageView *statusImage;

@property (nonatomic, assign) BOOL showStatusImage;

@property (nonatomic, assign) BOOL handOffButtonVisible;
@property (nonatomic, assign) BOOL visitStatusButtonVisible;

@property (nonatomic, assign) id<PatientTableViewCellDelegate> delegate;
@property (nonatomic, assign) HandoffIndicatorType handoffIndicatorType;

-(void) setHandOffButtonVisible:(BOOL)handOffButtonVisible animated:(BOOL)animated;
-(void) setVisitStatusButtonVisible:(BOOL)visitStatusButtonVisible animated:(BOOL)animated;

-(void) disable;
-(void) enable;
-(void) fillWithCensus:(Census*)census;

@end
