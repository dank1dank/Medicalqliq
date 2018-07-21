//
//  PatientHeaderView.m
//  CCiPhoneApp
//
//  Created by Marcin Zbijowski on 03/05/2011.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import "PatientHeaderView.h"
#import "LightGreyGlassGradientView.h"
#import "Helper.h"

@implementation PatientHeaderView

@synthesize dateLabel = _dateLabel;
@synthesize textLabel = _textLabel;
@synthesize textLabel2 = _textLabel2;
@synthesize censusObj = _censusObj;
@synthesize delegate = _delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        bgView = [[LightGreyGlassGradientView alloc] init];
        [self addSubview:bgView];
		
        _arrowView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bg-right-arrow"]];
        //_arrowView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"btn-add-avatar"]];
        
        /*CGRect arrowFrame = _arrowView.frame;
        arrowFrame.origin = CGPointMake(10.0f, 5.0f);
        _arrowView.frame = arrowFrame;*/
        //[self addSubview:_arrowView];
        
        /*_dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(_arrowView.frame.origin.x, _arrowView.frame.origin.y, _arrowView.frame.size.width - 4, _arrowView.frame.size.height)];
        _dateLabel.numberOfLines = 2;
        _dateLabel.backgroundColor = [UIColor clearColor];
        _dateLabel.font = [UIFont boldSystemFontOfSize:10];
        _dateLabel.textColor = [UIColor colorWithWhite:0.9059 alpha:1.0];
        _dateLabel.textAlignment = UITextAlignmentCenter;*/
        //[self addSubview:_dateLabel];
        
        _textLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, frame.size.width - 50, frame.size.height/2)];
        _textLabel.backgroundColor = [UIColor clearColor];
        _textLabel.font = [UIFont boldSystemFontOfSize:14];
        _textLabel.textColor = [UIColor colorWithWhite:0.2231 alpha:1.0];
        [self addSubview:_textLabel];

        /*_textLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(10, 20, frame.size.width - 50, frame.size.height/2)];
        _textLabel2.backgroundColor = [UIColor clearColor];
        _textLabel2.font = [UIFont boldSystemFontOfSize:14];
        _textLabel2.textColor = [UIColor colorWithWhite:0.2231 alpha:1.0];
        [self addSubview:_textLabel2];*/
        
        /*UIImageView *chevronView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-chevron"]] autorelease];
        CGRect chevronFrame = chevronView.frame;
        chevronFrame.origin = CGPointMake(frame.size.width - chevronFrame.size.width - 10, (int)((frame.size.height - chevronFrame.size.height ) / 2));
        chevronView.frame = chevronFrame;*/

        /*_dateActionButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        _dateActionButton.frame = CGRectMake(0, 0, _arrowView.frame.size.width + 10, self.bounds.size.height);
        [_dateActionButton setBackgroundColor:[UIColor greenColor]];
        [_dateActionButton addTarget:self action:@selector(viewDateClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_dateActionButton];*/
        
		/*_actionButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        _actionButton.frame = CGRectMake(_dateLabel.frame.size.width + 10, 0, self.bounds.size.width - _dateLabel.frame.size.width - 10, self.bounds.size.height);
        [_actionButton addTarget:self action:@selector(viewClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_actionButton];*/
        tapRecognizer = [[UITapGestureRecognizer alloc] init];
        [tapRecognizer addTarget:self action:@selector(viewClicked:)];
        [self addGestureRecognizer:tapRecognizer];
		 
        
        accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell-chevron.png"]];
        [self addSubview:accessoryView];
        
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame state:(UIControlState)state {
    self = [self initWithFrame:frame];
    if (self != nil)
    {
        [self setState:state];
    }
    return self;
}

- (void)addTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents {
    [_actionButton addTarget:target action:action forControlEvents:controlEvents];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)dealloc
{
    [accessoryView release];
    [bgView release];
    [tapRecognizer release];
    
    [_actionButton release];
    [_dateLabel release];
    [_textLabel release];
    [_censusObj release];
	
    _delegate = nil;
    [super dealloc];
}

#pragma mark -
#pragma mark Custom setters

-(void) layoutSubviews
{
    [super layoutSubviews];
    bgView.frame = CGRectMake(0.0,
                              0.0,
                              self.frame.size.width,
                              self.frame.size.height);
    
    CGFloat rightOffset = 5.0;
    
    accessoryView.frame = CGRectMake(self.frame.size.width - rightOffset - accessoryView.image.size.width,
                                     roundf(self.frame.size.height/2.0 - accessoryView.image.size.height / 2.0),
                                     accessoryView.image.size.width,
                                     accessoryView.image.size.height);
    
    rightOffset += accessoryView.frame.size.width;
    rightOffset += 5.0;
    
    CGSize labelSize = [_textLabel.text sizeWithFont:_textLabel.font];
    
    _textLabel.frame = CGRectMake(10.0,
                                  roundf(self.frame.size.height / 2.0 - labelSize.height / 2.0),
                                  self.frame.size.width - 10.0 - rightOffset,
                                  labelSize.height);
    
}

- (void)setCensusObj:(Census_old *)censusObj
{
    [_censusObj autorelease];
    _censusObj = [censusObj retain];
	patientObj = [Patient_old getPatientToDisplay:self.censusObj.patientId];
	Facility_old *facilityObj = [Facility_old getFacility:self.censusObj.facilityNpi];
	if(patientObj){
		self.textLabel.text = [NSString stringWithFormat:@"%@ • %@", patientObj.fullName, [Helper getRaceGenderAgeStringForPatient:patientObj]];
	}else {
		self.textLabel.text=@"";
	}
	if (facilityObj!=nil) {
		self.textLabel2.text = facilityObj.name;
	}else {
		self.textLabel2.text = @"";
	}
}

- (void)viewClicked:(id)sender {
    if (_delegate != nil) {
        [_delegate patientViewClicked:patientObj];
    }
}

- (void)viewDateClicked:(id)sender {
    if (_delegate != nil && [(NSObject *)_delegate respondsToSelector:@selector(patientDateClicked:)]) {
        [_delegate patientDateClicked:patientObj];
    }
}

- (void)setState:(UIControlState)state {
    _actionButton.enabled = YES;
    _actionButton.selected = NO;
    _dateActionButton.enabled = YES;
    _dateActionButton.selected = NO;
    switch (state) {
        case UIControlStateDisabled:
        {
            _arrowView.image = [UIImage imageNamed:@"bg-right-arrow-disabled"];
            _actionButton.enabled = YES;
            _dateActionButton.enabled = NO;
        }
            break;
            
        case UIControlStateSelected:
            _arrowView.image = [UIImage imageNamed:@"bg-right-arrow-selected"];
            _actionButton.selected = YES;
            _dateActionButton.selected = YES;
            
        default:
            break;
    }
}

@end
