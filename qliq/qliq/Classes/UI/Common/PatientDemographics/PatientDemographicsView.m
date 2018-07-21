//
//  PatientDemographicsView.m
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/18/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import "PatientDemographicsView.h"

#define HEADER_HEIGHT 60.0

@implementation PatientDemographicsView

@synthesize infoTable = infoTable_;

-(id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
        headerView = [[UIImageView alloc] init];
        headerView.image = [UIImage imageNamed:@"careTeamView_header_background.png"];
        [self addSubview:headerView];
        
        patientPhotoView = [[UIImageView alloc] init];
        patientPhotoView.backgroundColor = [UIColor clearColor];
        patientPhotoView.image = [UIImage imageNamed:@"add_photo.png"];
        [self addSubview:patientPhotoView];
        
        patientNameLabel = [[UILabel alloc] init];
        patientNameLabel.textColor = [UIColor blackColor];
        patientNameLabel.backgroundColor = [UIColor clearColor];
        patientNameLabel.font = [UIFont boldSystemFontOfSize:18.0];
        [self addSubview:patientNameLabel];
        
        infoTable_ = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        infoTable_.showsHorizontalScrollIndicator = NO;
        infoTable_.showsVerticalScrollIndicator = NO;
        infoTable_.backgroundColor = [UIColor colorWithWhite:0.2039f alpha:1.0f];
        infoTable_.separatorColor = [UIColor colorWithWhite:0.2039f alpha:1.0f];
        [self addSubview:infoTable_];
        
    }
    return self;
}


-(void) dealloc
{
    [infoTable_ release];
    [patientNameLabel release];
    [patientPhotoView release];
    [headerView release];
    [super dealloc];
}

-(void) layoutSubviews
{
    [super layoutSubviews];
    headerView.frame = CGRectMake(0.0,
                                  0.0,
                                  self.frame.size.width, 
                                  HEADER_HEIGHT);
    
    patientPhotoView.frame = CGRectMake(20.0,
                                        5.0,
                                        50.0,
                                        headerView.frame.size.height - 5.0 * 2.0);
    
    CGFloat xOffset = patientPhotoView.frame.origin.x + patientPhotoView.frame.size.width + 10.0;
    CGFloat maxLabelWidth = self.frame.size.width - xOffset - 10.0;
    CGSize tmpSize = [patientNameLabel.text sizeWithFont:patientNameLabel.font];
    if(tmpSize.width > maxLabelWidth)
    {
        tmpSize.width = maxLabelWidth;
    }
    patientNameLabel.frame = CGRectMake(xOffset,
                                        (headerView.frame.size.height / 2.0) - (tmpSize.height / 2.0),
                                        maxLabelWidth,
                                        tmpSize.height);
    
    infoTable_.frame = CGRectMake(0.0,
                                  HEADER_HEIGHT,
                                  self.frame.size.width,
                                  self.frame.size.height - HEADER_HEIGHT);

}

#pragma mark -
#pragma mark Properties

-(void) setPatientName:(NSString *)patientName
{
    patientNameLabel.text = patientName;
}

-(NSString*) patientName
{
    return patientNameLabel.text;
}


-(void) setPatientPhoto:(UIImage *)patientPhoto
{
    if(patientPhoto == nil)
    {
        patientPhotoView.image = [UIImage imageNamed:@"add_photo.png"];
    }
    else
    {
        patientPhotoView.image = patientPhoto;
    }
}

-(UIImage*) patientPhoto
{
    return patientPhotoView.image;
}


@end
