//
//  PatientTableViewCell.m
//  CCiPhoneApp
//
//  Created by Marcin Zbijowski on 18/05/2011.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import "AllChargesTableViewCell.h"

#define LEFT_X_POS_1    10
#define LEFT_X_POS_2    50
#define WIDTH_1   200
#define WIDTH_2   55



@implementation AllChargesTableViewCell

@synthesize lblCptCodes;
@synthesize lblIcdCodes;
@synthesize lblDate;
@synthesize statusImage;
@synthesize showStatusImage = _showStatusImage;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundView = [[[UIView alloc] init] autorelease];
        self.backgroundView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg-cell"]];
        self.contentView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg-cell"]];
        
        //lblPatientName=[[UILabel alloc] initWithFrame:CGRectMake(LEFT_X_POS_1,0,175,30)];
        lblCptCodes=[[UILabel alloc] initWithFrame:CGRectMake(LEFT_X_POS_1,0,225,30)];
        //lblPatientName.text=@"Text";
        lblCptCodes.font=[UIFont boldSystemFontOfSize:14];
        lblCptCodes.textColor = [UIColor colorWithRed:0.0039f green:0.2549f blue:0.4353 alpha:1.0f];
        lblCptCodes.adjustsFontSizeToFitWidth=YES;
        lblCptCodes.numberOfLines=1;
        lblCptCodes.tag=2;
        lblCptCodes.backgroundColor=[UIColor clearColor];
        [self.contentView addSubview:lblCptCodes];
        
        lblIcdCodes=[[UILabel alloc] initWithFrame:CGRectMake(LEFT_X_POS_1,26,225,30)];
        //lblPatientName.text=@"Text";
        lblIcdCodes.font=[UIFont boldSystemFontOfSize:13];
        lblIcdCodes.textColor = [UIColor colorWithRed:0.4275 green:0.4314 blue:0.4431 alpha:1.0f];
        lblIcdCodes.adjustsFontSizeToFitWidth=YES;
        lblIcdCodes.numberOfLines=1;
        lblIcdCodes.tag=3;
        lblIcdCodes.backgroundColor=[UIColor clearColor];
        [self.contentView addSubview:lblIcdCodes];
		
        lblDate=[[UILabel alloc] initWithFrame:CGRectMake(10,26,60,20)];
        //lblPatientName.text=@"Text";
        lblDate.font=[UIFont boldSystemFontOfSize:13];
        lblDate.textColor = [UIColor colorWithRed:0.73 green:0.21 blue:0.15 alpha:1.0f];
        lblDate.adjustsFontSizeToFitWidth=YES;
        lblDate.numberOfLines=0;
        lblDate.tag=6;
        lblDate.backgroundColor=[UIColor clearColor];
        [self.contentView addSubview:lblDate];
        
        
        statusImage = [[UIImageView alloc] initWithFrame:CGRectMake(10, 6, 17, 17)];
        statusImage.tag = 7;
        [self.contentView addSubview:statusImage];
        _showStatusImage = NO;
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
    [lblCptCodes release];
    [lblIcdCodes release];
    [lblDate release];
    [statusImage release];
    [super dealloc];
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

    CGRect frame = self.lblCptCodes.frame;
    frame.origin.x = xPos;
    self.lblCptCodes.frame = frame;
    
    frame = lblIcdCodes.frame;
    frame.origin.x = xPos;
	//frame.size.width = width;
    self.lblIcdCodes.frame = frame;
}

@end
