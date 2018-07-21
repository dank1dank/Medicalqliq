//
//  RoomPlaceView.m
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/16/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import "RoomPlaceView.h"

#define VIEWS_OFFSET 10.0

@implementation RoomPlaceView
@synthesize empty = empty_;
@synthesize patient = patient_;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code
        patientNameLabel = [[UILabel alloc] init];
        patientNameLabel.backgroundColor = [UIColor clearColor];
        patientNameLabel.font = [UIFont boldSystemFontOfSize:18.0];
        patientNameLabel.textColor = [UIColor colorWithRed:0.0039f green:0.2549f blue:0.4353 alpha:1.0f];
        patientNameLabel.adjustsFontSizeToFitWidth=NO;
        [self addSubview:patientNameLabel];
        
        nurseNameLabel = [[UILabel alloc] init];
        nurseNameLabel.backgroundColor = [UIColor clearColor];
        nurseNameLabel.font = [UIFont systemFontOfSize:12.0];
        nurseNameLabel.textColor = [UIColor colorWithRed:0.4275 green:0.4314 blue:0.4431 alpha:1.0f];
        nurseNameLabel.adjustsFontSizeToFitWidth=NO;
        [self addSubview:nurseNameLabel];
        
        emptyLabel = [[UILabel alloc] init];
        emptyLabel.backgroundColor = [UIColor clearColor];
        emptyLabel.textColor = [UIColor colorWithWhite: 0.6677 alpha: 1.0];
        emptyLabel.font = [UIFont boldSystemFontOfSize:18.0];
        emptyLabel.text = @"Empty";
        emptyLabel.textAlignment = UITextAlignmentCenter;
        [self addSubview:emptyLabel];
        //nurse name [UIColor colorWithRed:0.4275 green:0.4314 blue:0.4431 alpha:1.0f];
        //empty [UIColor colorWithWhite: 0.6677 alpha: 1.0]
        //patient name [UIColor colorWithRed:0.0039f green:0.2549f blue:0.4353 alpha:1.0f]
        //lblPatientName.adjustsFontSizeToFitWidth=YES;
        //lblPatientName.font=[UIFont boldSystemFontOfSize:18];
        
        empty_ = YES;
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

-(void) dealloc
{
    [nurseNameLabel release];
    [emptyLabel release];
    [patientNameLabel release];
	[patient_ release];
    [super dealloc];
}


-(void) layoutSubviews
{
    [super layoutSubviews];
    
    if(empty_)
    {
        emptyLabel.frame = CGRectMake(0.0, 0.0, self.frame.size.width, self.frame.size.height);
        patientNameLabel.frame = CGRectZero;
        nurseNameLabel.frame = CGRectZero;
    }
    else
    {
        CGFloat minRectSize = VIEWS_OFFSET * 2.0 + 10.0;
        CGRect rectForLabels = CGRectMake(VIEWS_OFFSET,
                                          VIEWS_OFFSET,
                                          self.frame.size.width - VIEWS_OFFSET * 2.0,
                                          self.frame.size.height - VIEWS_OFFSET * 2.0);
        if(rectForLabels.size.width < minRectSize || rectForLabels.size.height < minRectSize)
        {
            patientNameLabel.frame = CGRectZero;
            nurseNameLabel.frame = CGRectZero;
        }
        else
        {
            patientNameLabel.frame = CGRectMake(rectForLabels.origin.x,
                                                rectForLabels.origin.y,
                                                rectForLabels.size.width,
                                                rectForLabels.size.height / 2.0);
            
            nurseNameLabel.frame = CGRectMake(rectForLabels.origin.x,
                                              rectForLabels.origin.y + patientNameLabel.frame.size.height + (VIEWS_OFFSET / 2.0),
                                              rectForLabels.size.width,
                                              (rectForLabels.size.height / 2.0) - (VIEWS_OFFSET / 2.0));
        }
    }
}


-(void) setPatientName:(NSString *)patientName
{
    patientNameLabel.text = patientName;
}

-(NSString*) patientName
{
    return patientNameLabel.text;
}

-(void) setNurseName:(NSString *)nurseName
{
    nurseNameLabel.text = nurseName;
}

-(NSString*) nurseName
{
    return nurseNameLabel.text;
}

@end
