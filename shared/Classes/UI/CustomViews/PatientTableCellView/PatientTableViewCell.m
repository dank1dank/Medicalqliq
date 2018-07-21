//
//  PatientTableViewCell.m
//  CCiPhoneApp
//
//  Created by Marcin Zbijowski on 18/05/2011.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import "PatientTableViewCell.h"

//census
#import "Census.h"
#import "Encounter.h"
#import "Patient.h"
#import "Facility.h"
#import "PatientVisit.h"
#import "Helper.h"
#import "QliqUser.h"
//--

#define LEFT_X_POS_1    10
#define LEFT_X_POS_2    50
#define WIDTH_1   200
#define WIDTH_2   55

#define BUTTONS_X_OFFSET 5.0
#define BUTTONS_HEIGHT 35.0
#define MINIMAL_BUTTON_WIDTH 50.0
#define BUTTON_LABEL_TEXT_OFFSET 10.0

@interface PatientTableViewCell()

-(void) leftToRightSwipeAction;
-(void) rightToLeftSwipeAction;
-(void) visitButtonPressed;
-(void) handoffButtonPressed;

@end

@implementation PatientTableViewCell

@synthesize lblFacilityAbbreviation;
@synthesize lblPatientName;
@synthesize lblRoomFacilityName;
@synthesize lblPatientAgeGenderRace;
@synthesize lblAdmitDischargeConsultIndicator;
@synthesize lblInsurance;
@synthesize lblDate;
@synthesize lblPhysicianName;
@synthesize statusImage;
@synthesize showStatusImage = _showStatusImage;
@synthesize delegate = delegate_;
@synthesize handoffIndicatorType = handoffIndicatorType_;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundView = [[[UIView alloc] init] autorelease];
        self.backgroundView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg-cell"]];
        self.contentView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg-cell"]];
        
        self.lblFacilityAbbreviation=[[UILabel alloc] initWithFrame:CGRectZero];
        self.lblFacilityAbbreviation.font=[UIFont systemFontOfSize:13];
        self.lblFacilityAbbreviation.textColor = [UIColor colorWithRed:0.4275 green:0.4314 blue:0.4431 alpha:1.0f];
        self.lblFacilityAbbreviation.adjustsFontSizeToFitWidth=YES;
        self.lblFacilityAbbreviation.numberOfLines=0;
        self.lblFacilityAbbreviation.tag=1;
        self.lblFacilityAbbreviation.backgroundColor=[UIColor clearColor];
        self.lblFacilityAbbreviation.textAlignment = UITextAlignmentRight;
        [self.contentView addSubview:self.lblFacilityAbbreviation];
        
        self.lblPatientName=[[UILabel alloc] initWithFrame:CGRectZero];
        self.lblPatientName.font=[UIFont boldSystemFontOfSize:18];
        self.lblPatientName.textColor = [UIColor colorWithRed:0.0039f green:0.2549f blue:0.4353 alpha:1.0f];
        self.lblPatientName.adjustsFontSizeToFitWidth=YES;
        self.lblPatientName.numberOfLines=0;
        self.lblPatientName.tag=2;
        self.lblPatientName.backgroundColor=[UIColor clearColor];
        [self.contentView addSubview:self.lblPatientName];
		
        self.lblRoomFacilityName =[[UILabel alloc] initWithFrame:CGRectZero];
        self.lblRoomFacilityName.font=[UIFont systemFontOfSize:13];
        self.lblRoomFacilityName.textColor = [UIColor colorWithRed:0.4275 green:0.4314 blue:0.4431 alpha:1.0f];
        self.lblRoomFacilityName.adjustsFontSizeToFitWidth=YES;
        self.lblRoomFacilityName.numberOfLines=1;
        self.lblRoomFacilityName.tag=3;
        self.lblRoomFacilityName.backgroundColor=[UIColor clearColor];
        [self.contentView addSubview:self.lblRoomFacilityName];
		
        
        self.lblPatientAgeGenderRace=[[UILabel alloc] initWithFrame:CGRectZero];
        //self.lblPatientName.text=@"Text";
        self.lblPatientAgeGenderRace.font=[UIFont boldSystemFontOfSize:13];
        self.lblPatientAgeGenderRace.textColor = [UIColor colorWithRed:0.4275 green:0.4314 blue:0.4431 alpha:1.0f];
        self.lblPatientAgeGenderRace.adjustsFontSizeToFitWidth=YES;
        self.lblPatientAgeGenderRace.numberOfLines=1;
        self.lblPatientAgeGenderRace.tag=4;
        self.lblPatientAgeGenderRace.backgroundColor=[UIColor clearColor];
        [self.contentView addSubview:self.lblPatientAgeGenderRace];
		
        self.lblAdmitDischargeConsultIndicator=[[UILabel alloc] initWithFrame:CGRectZero];
        //self.lblPatientName.text=@"Text";
        self.lblAdmitDischargeConsultIndicator.font=[UIFont boldSystemFontOfSize:13];
        self.lblAdmitDischargeConsultIndicator.textColor = [UIColor colorWithRed:0.73 green:0.21 blue:0.15 alpha:1.0f];
        self.lblAdmitDischargeConsultIndicator.adjustsFontSizeToFitWidth=YES;
        self.lblAdmitDischargeConsultIndicator.numberOfLines=1;
        self.lblAdmitDischargeConsultIndicator.tag=5;
        self.lblAdmitDischargeConsultIndicator.backgroundColor=[UIColor clearColor];
        [self.contentView addSubview:self.lblAdmitDischargeConsultIndicator];

        self.lblInsurance=[[UILabel alloc] initWithFrame:CGRectZero];
        self.lblInsurance.font=[UIFont boldSystemFontOfSize:13];
        self.lblInsurance.textColor = [UIColor colorWithRed:0.4275 green:0.4314 blue:0.4431 alpha:1.0f];
        self.lblInsurance.adjustsFontSizeToFitWidth=YES;
        self.lblInsurance.numberOfLines=1;
        self.lblInsurance.tag=6;
        self.lblInsurance.backgroundColor=[UIColor clearColor];
        [self.contentView addSubview:self.lblInsurance];
		
        self.lblDate=[[UILabel alloc] initWithFrame:CGRectZero];
        //self.lblPatientName.text=@"Text";
        self.lblDate.font=[UIFont boldSystemFontOfSize:13];
        self.lblDate.textColor = [UIColor colorWithRed:0.73 green:0.21 blue:0.15 alpha:1.0f];
        self.lblDate.adjustsFontSizeToFitWidth=YES;
        self.lblDate.numberOfLines=1;
        self.lblDate.tag=7;
        self.lblDate.backgroundColor=[UIColor clearColor];
        [self.contentView addSubview:self.lblDate];
        
        self.lblPhysicianName=[[UILabel alloc] initWithFrame:CGRectZero];
        //self.lblPhysicianName.text=@"Text";
        self.lblPhysicianName.font=[UIFont systemFontOfSize:13];
        self.lblPhysicianName.textColor = [UIColor colorWithRed:0.4275 green:0.4314 blue:0.4431 alpha:1.0f];
        self.lblPhysicianName.adjustsFontSizeToFitWidth=YES;
        self.lblPhysicianName.numberOfLines=1;
        self.lblPhysicianName.tag=8;
        self.lblPhysicianName.backgroundColor=[UIColor clearColor];
        self.lblPhysicianName.textAlignment = UITextAlignmentRight;
        [self.contentView addSubview:self.lblPhysicianName];
        
        statusImage = [[UIImageView alloc] initWithFrame:CGRectZero];
        statusImage.tag = 9;
        [self.contentView addSubview:statusImage];
        _showStatusImage = NO;
        
        leftToRightSwipeRecognizer = [[UISwipeGestureRecognizer alloc] init];
        leftToRightSwipeRecognizer.numberOfTouchesRequired = 1;
        leftToRightSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
        [leftToRightSwipeRecognizer addTarget:self action:@selector(leftToRightSwipeAction)];
        [self addGestureRecognizer:leftToRightSwipeRecognizer];
        
        rightToLeftSwipeRecognizer = [[UISwipeGestureRecognizer alloc] init];
        rightToLeftSwipeRecognizer.numberOfTouchesRequired = 1;
        rightToLeftSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
        [rightToLeftSwipeRecognizer addTarget:self action:@selector(rightToLeftSwipeAction)];
        [self addGestureRecognizer:rightToLeftSwipeRecognizer];
        
        handoffIndicator = [[UIImageView alloc] init];
        [self addSubview:handoffIndicator];
        self.handoffIndicatorType = HandoffIndicatorNone;
        
        handOffButton = [[UIButton alloc] init];
        [handOffButton setImage:[UIImage imageNamed:@"patientTableViewCellButton.png"] forState:UIControlStateNormal];
        handOffButton.titleLabel.backgroundColor = [UIColor clearColor];
        [handOffButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [handOffButton addTarget:self action:@selector(handoffButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:handOffButton];
        handOffButtonVisible_ = NO;
        handOffButtonWidth = 0.0;
        
        handOffButtonTitle = [[UILabel alloc] init];
        handOffButtonTitle.backgroundColor = [UIColor clearColor];
        handOffButtonTitle.textColor = [UIColor whiteColor];
        [self addSubview:handOffButtonTitle];
        
        visitStatusButton = [[UIButton alloc] init];
        [visitStatusButton setImage:[UIImage imageNamed:@"patientTableViewCellButton.png"] forState:UIControlStateNormal];
        visitStatusButton.titleLabel.backgroundColor = [UIColor clearColor];
        [visitStatusButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [visitStatusButton addTarget:self action:@selector(visitButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:visitStatusButton];
        visitStatusButtonVisible_ = NO;
        visitStatusButtonWidth = 0.0;
        visitStatusButtonTitle = [[UILabel alloc] init];
        visitStatusButtonTitle.textColor = [UIColor whiteColor];
        visitStatusButtonTitle.backgroundColor = [UIColor clearColor];
        [self addSubview:visitStatusButtonTitle];
        
    }
    return self;
}

- (void)dealloc
{
    [handoffIndicator release];
    [handOffButtonTitle release];
    [visitStatusButtonTitle release];
    [visitStatusButton release];
    [handOffButton release];
    [rightToLeftSwipeRecognizer release];
    [leftToRightSwipeRecognizer release];
    [self.lblFacilityAbbreviation release];
    [self.lblPatientName release];
    [self.lblPatientAgeGenderRace release];
    [self.lblDate release];
    [self.lblPhysicianName release];
	[self.lblInsurance release];
	[self.lblRoomFacilityName release];
    [statusImage release];
    [super dealloc];
}

-(void) disable
{
   	self.lblPatientName.textColor =[UIColor colorWithWhite: 0.6677 alpha: 1.0];
	self.lblPatientAgeGenderRace.textColor = [UIColor colorWithWhite: 0.6677 alpha: 1.0];
	self.lblInsurance.textColor = [UIColor colorWithWhite: 0.6677 alpha: 1.0]; 
	self.lblPhysicianName.textColor = [UIColor colorWithWhite: 0.6677 alpha: 1.0];
	self.lblFacilityAbbreviation.textColor = [UIColor colorWithWhite: 0.6677 alpha: 1.0];
	self.lblDate.textColor = [UIColor colorWithWhite: 0.6677 alpha: 1.0];
	self.lblAdmitDischargeConsultIndicator.textColor = [UIColor colorWithWhite: 0.6677 alpha: 1.0]; 
	
}

-(void) enable
{
    self.lblPatientName.textColor = [UIColor colorWithRed:0.0039f green:0.2549f blue:0.4353 alpha:1.0f];
	self.lblPatientAgeGenderRace.textColor = [UIColor colorWithRed:0.4275 green:0.4314 blue:0.4431 alpha:1.0f];
	self.lblInsurance.textColor = [UIColor colorWithRed:0.4275 green:0.4314 blue:0.4431 alpha:1.0f];
	self.lblFacilityAbbreviation.textColor = [UIColor colorWithRed:0.4275 green:0.4314 blue:0.4431 alpha:1.0f];
	self.lblAdmitDischargeConsultIndicator.textColor = [UIColor colorWithRed:0.73 green:0.21 blue:0.15 alpha:1.0f];
	self.lblDate.textColor = [UIColor colorWithRed:0.73 green:0.21 blue:0.15 alpha:1.0f];
	self.lblPhysicianName.textColor = [UIColor colorWithRed:0.4275 green:0.4314 blue:0.4431 alpha:1.0f];
	
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void)layoutSubviews 
{
    [super layoutSubviews];
    
    CGSize labelSize = CGSizeZero;
    if(!handOffButtonVisible_)
    {
        handOffButton.frame = CGRectMake(self.frame.size.width - BUTTONS_X_OFFSET,
                                         roundf((self.frame.size.height / 2.0) - (BUTTONS_HEIGHT / 2.0)),
                                         handOffButtonWidth,
                                         BUTTONS_HEIGHT);
        
        handOffButtonTitle.frame = CGRectMake(handOffButtonTitle.frame.origin.x,
                                              handOffButtonTitle.frame.origin.y,
                                              0.0,
                                              0.0);
        handOffButtonTitle.alpha = 0.0;
    }
    else
    {
        labelSize = [handOffButtonTitle.text sizeWithFont:handOffButtonTitle.font];
        handOffButton.frame = CGRectMake(self.frame.size.width - BUTTONS_X_OFFSET - handOffButtonWidth,
                                         roundf((self.frame.size.height / 2.0) - (BUTTONS_HEIGHT / 2.0)),
                                         handOffButtonWidth,
                                         BUTTONS_HEIGHT);
        
        handOffButtonTitle.frame = CGRectMake(handOffButtonTitle.frame.origin.x,
                                              handOffButtonTitle.frame.origin.y,
                                              labelSize.width,
                                              labelSize.height);
        handOffButtonTitle.center = handOffButton.center;
        
        handOffButtonTitle.alpha = 1.0;
    }
    
    labelSize = [visitStatusButtonTitle.text sizeWithFont:visitStatusButtonTitle.font];
    visitStatusButton.frame = CGRectMake(BUTTONS_X_OFFSET,
                                         roundf((self.frame.size.height / 2.0) - (BUTTONS_HEIGHT / 2.0)),
                                         visitStatusButtonWidth,
                                         BUTTONS_HEIGHT);
    visitStatusButtonTitle.frame = CGRectMake(visitStatusButtonTitle.frame.origin.x,
                                              visitStatusButtonTitle.frame.origin.y,
                                              labelSize.width,
                                              labelSize.height);
    visitStatusButtonTitle.center = visitStatusButton.center;
    
    CGFloat visitButtonViewsXOffset = 0.0;
    
    if(visitStatusButtonVisible_)
    {
        visitStatusButtonTitle.alpha = 1.0;
        visitButtonViewsXOffset = visitStatusButtonWidth + BUTTONS_X_OFFSET;
    }
    else
    {
        visitStatusButtonTitle.alpha = 0.0;
    }
    
    self.lblFacilityAbbreviation.frame = CGRectMake(self.frame.size.width - 50.0 + visitButtonViewsXOffset,
                                                    6.0,
                                                    45.0,
                                                    20.0);
    
    CGFloat xOffset = 10.0;
    
    statusImage.frame = CGRectMake(xOffset + visitButtonViewsXOffset,
                                   6.0,
                                   17.0,
                                   17.0);
    
    xOffset += statusImage.frame.size.width;
    xOffset += 10.0;
    
    self.lblPatientName.frame = CGRectMake(xOffset + visitButtonViewsXOffset,
                                      0.0,
                                      self.frame.size.width - (xOffset + visitButtonViewsXOffset + self.lblFacilityAbbreviation.frame.size.width + 5.0),
                                      30.0);

    labelSize = [self.lblRoomFacilityName.text sizeWithFont:self.lblRoomFacilityName.font];
    self.lblRoomFacilityName.frame = CGRectMake(xOffset + visitButtonViewsXOffset,
                                                self.frame.size.height - labelSize.height - 5.0,
                                                self.lblPatientName.frame.size.width,
                                                labelSize.height);
    
    CGFloat x = 5.0;
    self.lblDate.frame = CGRectMake(x + visitButtonViewsXOffset,
                               28.0,
                               35.0,
                               20.0);
    x+=self.lblDate.frame.size.width;
    
    self.lblPatientAgeGenderRace.frame = CGRectMake(x + visitButtonViewsXOffset,
                                               28.0,
                                               80,
                                               20.0);
    x+=self.lblPatientAgeGenderRace.frame.size.width;
    
    self.lblAdmitDischargeConsultIndicator.frame = CGRectMake(x + visitButtonViewsXOffset,
                                                         28.0,
                                                         80.0,
                                                         20.0);
    
    x+= self.lblAdmitDischargeConsultIndicator.frame.size.width;
    
    self.lblInsurance.frame = CGRectMake(x + visitButtonViewsXOffset,
                                                         28.0,
                                                         80.0,
                                                         20.0);
    
    x+= self.lblInsurance.frame.size.width;

    labelSize = [self.lblRoomFacilityName.text sizeWithFont:self.lblRoomFacilityName.font];

    self.lblPhysicianName.frame = CGRectMake(self.frame.size.width - 20.0 - 10.0 + visitButtonViewsXOffset,
                                        self.frame.size.height - labelSize.height - 5.0,
                                        20.0,
                                        labelSize.height);

    handoffIndicator.frame = CGRectMake(self.lblPhysicianName.frame.origin.x - 6.0 - 5.0,
                                        self.lblPhysicianName.frame.origin.y + (roundf((self.lblPhysicianName.frame.size.height - 10.0) / 2.0)),
                                        6.0,
                                        10.0);    
    
}

- (void)setShowStatusImage:(BOOL)showStatusImage {
    _showStatusImage = showStatusImage;
    CGFloat xPos = LEFT_X_POS_1;
    CGFloat width = WIDTH_1;
	
    if (_showStatusImage) {
        xPos = LEFT_X_POS_2;
		width = WIDTH_2;
        statusImage.hidden = NO;
    }
    else {
        statusImage.hidden = YES;
    }

    CGRect frame = self.lblPatientName.frame;
    frame.origin.x = xPos;
    self.lblPatientName.frame = frame;
    
    frame = self.lblPatientAgeGenderRace.frame;
    frame.origin.x = xPos;
	frame.size.width = width;
    self.lblPatientAgeGenderRace.frame = frame;
}

-(void) setHandOffButtonVisible:(BOOL)handOffButtonVisible animated:(BOOL)animated
{
    if(handOffButtonVisible_ && handOffButtonVisible)
    {
        return;
    }
    if(!handOffButtonVisible_ && !handOffButtonVisible)
    {
        return;
    }
    
    if(!handOffButtonVisible_ && handOffButtonVisible)
    {
        BOOL shouldShowButton = [self.delegate shouldShowHandoffButtonForCell:self];
        if(!shouldShowButton)
        {
            return;            
        }
    }
    
    if(animated)
    {
        [UIView beginAnimations:@"handoff button visible change" context:nil];
        [UIView setAnimationDuration:0.3];
    }
    handOffButtonVisible_ = handOffButtonVisible;
    if(handOffButtonVisible)
    {
        NSString *buttonTitle = [self.delegate handoffButtonTitleForCell:self];
        CGSize labelSize = [buttonTitle sizeWithFont:handOffButton.titleLabel.font];
        CGFloat buttonWidth = labelSize.width + (BUTTON_LABEL_TEXT_OFFSET * 2.0);
        if(buttonWidth < MINIMAL_BUTTON_WIDTH)
        {
            buttonWidth = MINIMAL_BUTTON_WIDTH;
        }
        handOffButtonWidth = buttonWidth;
        handOffButtonTitle.text = buttonTitle;
    }
    else
    {
        handOffButtonWidth = 0.0;
    }
    [self layoutSubviews];
    if(animated)
    {
        [UIView commitAnimations];
    }
}

-(void) setVisitStatusButtonVisible:(BOOL)visitStatusButtonVisible animated:(BOOL)animated
{
    if(visitStatusButtonVisible_ && visitStatusButtonVisible)
    {
        return;
    }
    if(!visitStatusButtonVisible_ && !visitStatusButtonVisible)
    {
        return;
    }
    
    if(!visitStatusButtonVisible_ && visitStatusButtonVisible)
    {
        BOOL shouldShowButton = [self.delegate shouldShowVisitStatusButtonForCell:self];
        if(!shouldShowButton)
        {
            return;
        }
    }
    
    if(animated)
    {
        [UIView beginAnimations:@"visit button visible change" context:nil];
        [UIView setAnimationDuration:0.3];
    }
    
    if(visitStatusButtonVisible)
    {
        NSString *buttonTitle = [self.delegate visitStatusButtonTitleForCell:self];
        CGSize labelSize = [buttonTitle sizeWithFont:visitStatusButton.titleLabel.font];
        CGFloat buttonWidth = labelSize.width + (BUTTON_LABEL_TEXT_OFFSET * 2.0);
        if(buttonWidth < MINIMAL_BUTTON_WIDTH)
        {
            buttonWidth = MINIMAL_BUTTON_WIDTH;
        }
        visitStatusButtonWidth = buttonWidth;
        visitStatusButtonTitle.text = buttonTitle;
    }
    else
    {
        visitStatusButtonWidth = 0.0;
    }
    visitStatusButtonVisible_ = visitStatusButtonVisible;

    [self layoutSubviews];
    [visitStatusButton bringSubviewToFront:visitStatusButton.titleLabel];
    if(animated)
    {
        [UIView commitAnimations];
    }
}


-(void) fillWithCensus:(Census *)census
{
	self.lblPatientName.text = [NSString stringWithFormat:@"%@, %@ %@",census.patient.lastName,census.patient.firstName,census.patient.middleName!=nil?census.patient.middleName:@""];
	
    NSString *thisGender = census.patient.gender==nil ? @"" : [[census.patient.gender substringToIndex:1] uppercaseString];
    NSString *thisRace = census.patient.race==nil ? @"" : [[census.patient.race substringToIndex:1] uppercaseString];
	NSInteger age = census.patient.dateOfBirth != nil ? [Helper age:[census.patient.dateOfBirth timeIntervalSince1970]]:0;
    NSString *ageRaceGenderText;
	
    if (age>0)
        ageRaceGenderText=[NSString stringWithFormat:@"%d%@%@",age,thisGender,thisRace];
    else
        ageRaceGenderText=[NSString stringWithFormat:@"%@%@",thisGender,thisRace];

	
    NSString *roomFacilityText;
    
    if([census.facility.name length] != 0  && [census.patientVisit.room length] != 0)
    {
        roomFacilityText = [NSString stringWithFormat:@"%@ • %@", ageRaceGenderText, census.facility.name];
    }
    else
    {
        if([census.facility.name length] !=0)
        {
            roomFacilityText = census.facility.name;
        }
        if([census.patientVisit.room length] != 0)
        {
            roomFacilityText = ageRaceGenderText;
        }
    }
    
    self.lblRoomFacilityName.text = roomFacilityText;
	if(census.admitUser != nil){
		//self.lblPhysicianName.text = census.admitUser.initials;
	}
}

#pragma mark -
#pragma mark Properties

-(void) setHandOffButtonVisible:(BOOL)handOffButtonVisible
{
    [self setVisitStatusButtonVisible:handOffButtonVisible animated:NO];
}

-(BOOL) handOffButtonVisible
{
    return handOffButtonVisible_;
}

-(void) setVisitStatusButtonVisible:(BOOL)visitStatusButtonVisible
{
    [self setVisitStatusButtonVisible:visitStatusButtonVisible animated:NO];
}

-(BOOL) visitStatusButtonVisible
{
    return visitStatusButtonVisible_;
}

-(void) setHandoffIndicatorType:(HandoffIndicatorType)handoffIndicatorType
{
    switch(handoffIndicatorType)
    {
        case HandoffIndicatorNone:
        {
            handoffIndicator.image = nil;
        }break;
        case HandoffIndicatorRight:
        {
            handoffIndicator.image = [UIImage imageNamed:@"handoff_indicator_right.png"];
        }break;
        case HandoffIndicatorLeft:
        {
            handoffIndicator.image = [UIImage imageNamed:@"handoff_indicator_left.png"];            
        }break;
    }
}

#pragma mark -
#pragma mark Private

-(void) leftToRightSwipeAction
{
    if(handOffButtonVisible_)
    {
        [self setHandOffButtonVisible:NO animated:YES];
    }
    else
    {
        [self setVisitStatusButtonVisible:YES animated:YES];
    }
}

-(void) rightToLeftSwipeAction
{
    if(visitStatusButtonVisible_)
    {
        [self setVisitStatusButtonVisible:NO animated:YES];
    }
    else
    {
        [self setHandOffButtonVisible:YES animated:YES];
    }
}

-(void) handoffButtonPressed
{
    [self.delegate handoffButtonPressedOnCell:self];
}

-(void) visitButtonPressed
{
    [self.delegate visitButtonPressedOnCell:self];
}

@end
