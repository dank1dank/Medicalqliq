//
//  AppointmentTableViewCell.m
//  CCiPhoneApp
//
//  Created by Ravi Ada on 6/6/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import "AppointmentTableViewCell.h"


#define LEFT_X_POS_1    10
#define LEFT_X_POS_2    50


@implementation AppointmentTableViewCell

@synthesize lblRoom;
@synthesize lblPatientName;
@synthesize lblPatientAgeGenderRace;
@synthesize lblDate;
@synthesize lblFacilityType;
@synthesize statusImage;
@synthesize lblReason;
@synthesize showStatusImage = _showStatusImage;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundView = [[[UIView alloc] init] autorelease];
        self.backgroundView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg-cell"]];
        self.contentView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg-cell"]];
        
        lblFacilityType=[[UILabel alloc] initWithFrame:CGRectMake(260,6,50,20)];
        //lblRoom.text=@"Text";
        lblFacilityType.font=[UIFont systemFontOfSize:13];
        lblFacilityType.textColor = [UIColor colorWithRed:0.4275 green:0.4314 blue:0.4431 alpha:1.0f];
        lblFacilityType.adjustsFontSizeToFitWidth=YES;
        lblFacilityType.numberOfLines=0;
        lblFacilityType.tag=1;
        lblFacilityType.backgroundColor=[UIColor clearColor];
        lblFacilityType.textAlignment = UITextAlignmentRight;
        [self.contentView addSubview:lblFacilityType];
        
        lblPatientName=[[UILabel alloc] initWithFrame:CGRectMake(LEFT_X_POS_1,0,175,30)];
        //lblPatientName.text=@"Text";
        lblPatientName.font=[UIFont boldSystemFontOfSize:18];
        lblPatientName.textColor = [UIColor colorWithRed:0.0039f green:0.2549f blue:0.4353 alpha:1.0f];
        lblPatientName.adjustsFontSizeToFitWidth=YES;
        lblPatientName.numberOfLines=0;
        lblPatientName.tag=2;
        lblPatientName.backgroundColor=[UIColor clearColor];
        [self.contentView addSubview:lblPatientName];
        
        lblPatientAgeGenderRace=[[UILabel alloc] initWithFrame:CGRectMake(LEFT_X_POS_1,26,75,20)];
        //lblPatientName.text=@"Text";
        lblPatientAgeGenderRace.font=[UIFont boldSystemFontOfSize:13];
        lblPatientAgeGenderRace.textColor = [UIColor colorWithRed:0.4275 green:0.4314 blue:0.4431 alpha:1.0f];
        lblPatientAgeGenderRace.adjustsFontSizeToFitWidth=YES;
        lblPatientAgeGenderRace.numberOfLines=0;
        lblPatientAgeGenderRace.tag=3;
        lblPatientAgeGenderRace.backgroundColor=[UIColor clearColor];
        [self.contentView addSubview:lblPatientAgeGenderRace];

        lblReason=[[UILabel alloc] initWithFrame:CGRectMake(LEFT_X_POS_2,26,175,20)];
        lblReason.font=[UIFont boldSystemFontOfSize:13];
        lblReason.textColor = [UIColor colorWithRed:0.4275 green:0.4314 blue:0.4431 alpha:1.0f];
        lblReason.adjustsFontSizeToFitWidth=YES;
        lblReason.numberOfLines=0;
        lblReason.tag=3;
        lblReason.backgroundColor=[UIColor clearColor];
        [self.contentView addSubview:lblReason];
        
		
        lblDate=[[UILabel alloc] initWithFrame:CGRectMake(10,0,50,40)];
        //lblPatientName.text=@"Text";
        lblDate.font=[UIFont systemFontOfSize:13];
        lblDate.textColor = [UIColor colorWithRed:0.8235 green:0.3294 blue:0.1686 alpha:1.0f];
        lblDate.adjustsFontSizeToFitWidth=YES;
        lblDate.numberOfLines=2;
        lblDate.tag=6;
        lblDate.backgroundColor=[UIColor clearColor];
        [self.contentView addSubview:lblDate];
        
        
        lblRoom=[[UILabel alloc] initWithFrame:CGRectMake(285,26,25,20)];
        //lblPhysicianName.text=@"Text";
        lblRoom.font=[UIFont systemFontOfSize:13];
        lblRoom.textColor = [UIColor colorWithRed:0.4275 green:0.4314 blue:0.4431 alpha:1.0f];
        lblRoom.adjustsFontSizeToFitWidth=YES;
        lblRoom.numberOfLines=0;
        lblRoom.tag=4;
        lblRoom.backgroundColor=[UIColor clearColor];
        lblRoom.textAlignment = UITextAlignmentRight;
        
        [self.contentView addSubview:lblRoom];
        
        statusImage = [[UIImageView alloc] initWithFrame:CGRectMake(10, 6, 17, 17)];
        statusImage.tag = 7;
        [self.contentView addSubview:statusImage];
        _showStatusImage = NO;
		[self setShowStatusImage:NO];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
	
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.editingAccessoryView != nil) {
        NSLog(@"editing %@", self.editingAccessoryView);
    }
}

- (void)dealloc
{
    [lblRoom release];
    [lblPatientName release];
    [lblPatientAgeGenderRace release];
    [lblDate release];
    [lblFacilityType release];
    [statusImage release];
    [super dealloc];
}

- (void)setShowStatusImage:(BOOL)showStatusImage {
    CGFloat xPos = LEFT_X_POS_2;
    statusImage.hidden = YES;
    CGRect frame = self.lblPatientName.frame;
    frame.origin.x = xPos;
    self.lblPatientName.frame = frame;
    
    frame = lblPatientAgeGenderRace.frame;
    frame.origin.x = xPos;
    self.lblPatientAgeGenderRace.frame = frame;

    frame = lblReason.frame;
    frame.origin.x = xPos+50;
    self.lblReason.frame = frame;
	
}

@end
