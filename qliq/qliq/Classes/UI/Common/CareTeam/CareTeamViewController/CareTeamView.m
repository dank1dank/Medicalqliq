//
//  CareTeamView.m
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/17/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import "CareTeamView.h"
#define HEADER_HEIGHT 60.0
#define TAB_VIEW_HEIGHT 55.0

@interface CareTeamView()
-(void) tapEvent:(UITapGestureRecognizer*)sender;
@end

@implementation CareTeamView
@synthesize tabView = tabView_;
@synthesize infoTable = infoTable_;
@synthesize delegate = delegate_;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code
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
        
        tabView_ = [[NurseTabView alloc] initWithSelectedItem:1];
        [self addSubview:tabView_];
        
        infoTable_ = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        infoTable_.showsHorizontalScrollIndicator = NO;
        infoTable_.showsVerticalScrollIndicator = NO;
        infoTable_.backgroundColor = [UIColor colorWithWhite:0.2039f alpha:1.0f];
        infoTable_.separatorColor = [UIColor colorWithWhite:0.2039f alpha:1.0f];
        [self addSubview:infoTable_];
        
        disclosureIndicator = [[UIImageView alloc] init];
        disclosureIndicator.image = [UIImage imageNamed:@"header_disclosure_indicator.png"];
        [self addSubview:disclosureIndicator];
        
        tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapEvent:)];
        tapRecognizer.delegate = self;
        [self addGestureRecognizer:tapRecognizer];
    }
    return self;
}

-(void) dealloc
{
    [disclosureIndicator release];
    [tapRecognizer release];
    [infoTable_ release];
    [tabView_ release];
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
    
    disclosureIndicator.frame = CGRectMake(headerView.frame.origin.x + headerView.frame.size.width - 10.0 - 6.0,
                                           (headerView.frame.origin.y + headerView.frame.size.height / 2.0) - (5.0),
                                           6.0,
                                           10.0);
    
    tabView_.frame = CGRectMake(0.0,
                                self.frame.size.height - TAB_VIEW_HEIGHT,
                                self.frame.size.width,
                                TAB_VIEW_HEIGHT);
    
    infoTable_.frame = CGRectMake(0.0,
                                  HEADER_HEIGHT,
                                  self.frame.size.width,
                                  self.frame.size.height - HEADER_HEIGHT - TAB_VIEW_HEIGHT);
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

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


#pragma mark -
#pragma mark UIGestureRecognizerDelegate

-(BOOL) gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint touch = [gestureRecognizer locationInView: self];
    if( CGRectContainsPoint(headerView.frame, touch) )
    {
        return YES;
    }
    return NO;
}

#pragma mark -
#pragma mark Private

-(void) tapEvent:(UITapGestureRecognizer *)sender
{
    [self.delegate headerSelected];
}

@end
