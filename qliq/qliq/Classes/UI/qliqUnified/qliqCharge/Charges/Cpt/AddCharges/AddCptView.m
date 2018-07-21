//
//  AddCptView.m
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/21/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import "AddCptView.h"
#import "Outbound.h"

#define HEADER_HEIGHT 46.0
#define PICKER_HEIGHT 215.0
#define DETAILS_HEIGHT 35.0
#define BUTTONS_VIEW_HEIGHT 42.0

@interface AddCptView()

-(void) tapEvent:(UITapGestureRecognizer*)sender;
-(void) selectButtonPressed;
-(void) doneButtonPressed;
-(void) cancelButtonPressed;

@end

@implementation AddCptView
@synthesize pickerView = cptPickerView;
@synthesize header = _header;
@synthesize tableView = cptTable_;
@synthesize detailsLabel = detailsLabel_;
@synthesize delegate = delegate_;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code
        
        self.backgroundColor = [UIColor colorWithWhite:0.8667 alpha:1.0f];
        
        cptPickerView=[[UIPickerView alloc] initWithFrame:CGRectMake(0.0, 0.0, 0.0, PICKER_HEIGHT)];
        cptPickerView.showsSelectionIndicator=NO;
        cptPickerView.tag=10;
        cptPickerView.backgroundColor=[UIColor whiteColor];
        cptPickerView.showsSelectionIndicator = NO;
        [self addSubview:cptPickerView];
        [cptPickerView release];
        
        cptPickerViewFrame = [[UIImageView alloc] init];
        cptPickerViewFrame.image = [UIImage imageNamed:@"cpt_picker_frame.png"];
        [self addSubview:cptPickerViewFrame];

        pickerSelectorImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"picker-selector-horizontal"]];
        [self addSubview:pickerSelectorImage];
        
        details_bg = [[UIImageView alloc] init];
        details_bg.image = [UIImage imageNamed:@"bg-cpt-grey"];
        [self addSubview:details_bg];
        
        detailsAccessoryView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell-chevron.png"]] autorelease];
        [self addSubview:detailsAccessoryView];
        
        
        detailsLabel_ = [[UILabel alloc] init];
        detailsLabel_.textColor = [UIColor colorWithWhite:0.3019 alpha:1.0f];
        detailsLabel_.backgroundColor = [UIColor clearColor];
        detailsLabel_.font  = [UIFont boldSystemFontOfSize:13.0f];
        //detailsLabel_.text = @"Quick message";
        [self addSubview:detailsLabel_];
        
        buttonsView = [[LightGreyGlassGradientView alloc] init];
        [self addSubview:buttonsView];
        
        _selectButton = [StretchableButton buttonWithType:UIButtonTypeCustom];
        _selectButton.btnType = StretchableButton25;
        _selectButton.tag = 22;
        [_selectButton setTitle:NSLocalizedString(@"Select", @"Select") forState:UIControlStateNormal];
        _selectButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.f];
        [_selectButton addTarget:self action:@selector(selectButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [_selectButton addTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
        _selectButton.enabled = NO;
        [self addSubview:_selectButton];
        
        _doneButton = [StretchableButton buttonWithType:UIButtonTypeCustom];
        _doneButton.btnType = StretchableButton25;
        _doneButton.tag = 22;
        [_doneButton setTitle:NSLocalizedString(@"Done", @"Done") forState:UIControlStateNormal];
        _doneButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.f];
        _doneButton.enabled = NO;
        [_doneButton addTarget:self action:@selector(doneButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_doneButton];
        
        _cancelButton = [StretchableButton buttonWithType:UIButtonTypeCustom];
        _cancelButton.btnType = StretchableButton25;
        _cancelButton.tag = 22;
                [_cancelButton setTitle:NSLocalizedString(@"Cancel", @"Cancel") forState:UIControlStateNormal];
        _cancelButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.f];
        [_cancelButton addTarget:self action:@selector(cancelButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_cancelButton];
        
        cptTable_ = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        cptTable_.backgroundColor = [UIColor colorWithWhite:0.8667 alpha:1.0f];
        cptTable_.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        cptTable_.separatorColor = [UIColor colorWithWhite:0.349 alpha:1.0f];
        cptTable_.rowHeight = 35.0;
        [self addSubview:cptTable_];
        
        
        tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapEvent:)];
        tapRecognizer.delegate = self;
        [self addGestureRecognizer:tapRecognizer];
    }
    return self;
}


-(void) dealloc
{
    [cptPickerViewFrame release];
    [tapRecognizer release];
    [cptTable_ release];
    [detailsAccessoryView release];
    [pickerSelectorImage release];
    [cptPickerView release];
    [header_ release];
    [buttonsView release];
    [_selectButton release];
    [_doneButton release];
    [_cancelButton release];
    [details_bg release];
    [detailsLabel_ release];
    [super dealloc];
}

-(void) layoutSubviews
{
    [super layoutSubviews];
    
    header_.frame = CGRectMake(0.0,
                               0.0,
                               self.frame.size.width,
                               HEADER_HEIGHT);
    
    
    cptPickerView.frame= CGRectMake(0.0,
                                    header_.frame.size.height,
                                    self.frame.size.width,
                                    PICKER_HEIGHT);
    
    CGSize imageSize = pickerSelectorImage.image.size;
    if([UIDevice currentDevice].systemVersion.floatValue < 5.0)
    {
        pickerSelectorImage.frame = CGRectMake(cptPickerView.frame.origin.x,
                                           roundf(215.0 / 2.0 - imageSize.height / 2.0 + cptPickerView.frame.origin.y),
                                           cptPickerView.frame.size.width,
                                           imageSize.height);
    }
    else
    {
        pickerSelectorImage.frame = CGRectMake(cptPickerView.frame.origin.x,
                                               roundf(cptPickerView.frame.size.height / 2.0 - imageSize.height / 2.0 + cptPickerView.frame.origin.y),
                                               cptPickerView.frame.size.width,
                                               imageSize.height);
    }
	
    
    cptPickerViewFrame.frame = cptPickerView.frame;
    
    details_bg.frame = CGRectMake(0.0,
                                  cptPickerView.frame.origin.y + cptPickerView.frame.size.height,
                                  self.frame.size.width,
                                  DETAILS_HEIGHT);
    
    imageSize = detailsAccessoryView.image.size;
    
    detailsAccessoryView.frame = CGRectMake(details_bg.frame.origin.x + details_bg.frame.size.width - 10.0 - imageSize.width,
                                            roundf(details_bg.frame.size.height / 2.0 - imageSize.height / 2.0 + details_bg.frame.origin.y),
                                            imageSize.width,
                                            imageSize.height);
    
    detailsLabel_.frame = CGRectMake(10.0,
                                    details_bg.frame.origin.y,
                                    details_bg.frame.size.width - 10.0 * 3.0 - imageSize.width,
                                    details_bg.frame.size.height);
    
    buttonsView.frame = CGRectMake(0.0,
                                   details_bg.frame.origin.y + details_bg.frame.size.height,
                                   self.frame.size.width,
                                   BUTTONS_VIEW_HEIGHT);
    
    _selectButton.frame = CGRectMake(10.0,
                                     buttonsView.frame.origin.y,
                                     65.0,
                                     42.0);
    
    _doneButton.frame = CGRectMake(245.0,
                                   buttonsView.frame.origin.y,
                                   65.0,
                                   42.0);
    
    _cancelButton.frame = CGRectMake(175.0,
                                     buttonsView.frame.origin.y,
                                     65.0,
                                     42.0);
    
    cptTable_.frame = CGRectMake(0.0,
                                 buttonsView.frame.origin.y + buttonsView.frame.size.height,
                                 self.frame.size.width,
                                 self.frame.size.height - buttonsView.frame.origin.y - buttonsView.frame.size.height);

}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

-(void) setSelectButtonEnabled:(BOOL)enabled
{
    [_selectButton setEnabled:enabled];
}

-(void) setDoneButtonEnabed:(BOOL)enabled
{
    [_doneButton setEnabled:enabled];
}

#pragma mark -
#pragma mark Properties

-(PatientHeaderView*) header
{
    return header_;
}

-(void) setHeader:(PatientHeaderView *)header
{
    [header retain];
    [header_ release];
    [header_ removeFromSuperview];
    header_ = header;
    [self addSubview:header_];
}

#pragma mark -
#pragma mark UIGestureRecognizerDelegate

-(BOOL) gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint touch = [gestureRecognizer locationInView:self];
    if(CGRectContainsPoint(details_bg.frame, touch))
    {
        return YES;
    }
    return NO;
}

#pragma mark -
#pragma mark Private

-(void) tapEvent:(UITapGestureRecognizer *)sender
{
    [self.delegate showDetails];
}

-(void) selectButtonPressed
{
    [self.delegate selectButtonPressed];
}

-(void) doneButtonPressed
{
    [self.delegate doneButtonPressed];
//    [[Outbound sharedOutbound] sendCensusesToSuperNode];
}

-(void) cancelButtonPressed
{
    [self.delegate cancelButtonPressed];
}

@end
