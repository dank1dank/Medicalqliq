//
//  QliqChargeTabView.m
//  qliq
//
//  Created by Paul Bar on 3/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqChargeTabView.h"
#import "SliderView.h"
#import "ImageSliderItem.h"

#define BUTTON_WIDTH 67.0

@interface QliqChargeTabView()

-(void) chatButtonPressed;
-(void) pagesButtonPressed;

@end

@implementation QliqChargeTabView
@synthesize delegate;
@synthesize selectedButtonIndex;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code
        sliderView = [[SliderView alloc] init];
        sliderView.delegate = self;
        [self addSubview:sliderView];
        
        ImageSliderItem *imageSliderItem_1 = [[ImageSliderItem alloc] init];

        imageSliderItem_1.image = [UIImage imageNamed:@"Taskbar-Toggle-Patients-Passive.png"];
        imageSliderItem_1.selectedImage = [UIImage imageNamed:@"Taskbar-Patients-NO-BG-Button.png"];
        
        ImageSliderItem *imageSliderItem_2 = [[ImageSliderItem alloc] init];
        imageSliderItem_2.image = [UIImage imageNamed:@"Taskbar-Toggle-Facilities-Passive.png"];
        imageSliderItem_2.selectedImage = [UIImage imageNamed:@"Taskbar-Facilities-NO-BG-Button.png"];
        
        ImageSliderItem *imageSliderItem_3 = [[ImageSliderItem alloc] init];
        imageSliderItem_3.image = [UIImage imageNamed:@"Taskbar-Toggle-Provider-Passive.png"];
        imageSliderItem_3.selectedImage = [UIImage imageNamed:@"Taskbar-Provider-NO-BG-Button.png"];
        
        NSArray *items = [NSArray arrayWithObjects:imageSliderItem_1,imageSliderItem_2, imageSliderItem_3, nil];
        [sliderView setItems:items];
        [imageSliderItem_1 release];
        [imageSliderItem_2 release];
        [imageSliderItem_3 release];
        
        pagesButton = [[UIButton alloc] init];
        [pagesButton setImage:[UIImage imageNamed:@"Alert-Button.png"] forState:UIControlStateNormal];
        [pagesButton setImage:[UIImage imageNamed:@"Alert-Button-OnTap.png"] forState:UIControlStateHighlighted];
        [pagesButton addTarget:self action:@selector(pagesButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:pagesButton];
        
        chatButton = [[UIButton alloc] init];
        [chatButton setImage:[UIImage imageNamed:@"Chat-Button.png"] forState:UIControlStateNormal];
        [chatButton setImage:[UIImage imageNamed:@"Chat-Button-OnTap.png"] forState:UIControlStateHighlighted];
        [chatButton addTarget:self action:@selector(chatButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:chatButton];
        
        
        self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Taskbar-BG.png"]];
    }
    return self;
}

-(void) dealloc
{
    [chatButton release];
    [pagesButton release];
    [sliderView release];
    [super dealloc];
}


-(void) layoutSubviews
{
    [super layoutSubviews];
    CGFloat xLeftOffset = 0.0;
    chatButton.frame = CGRectMake(self.frame.size.width - BUTTON_WIDTH,
                                  0.0, 
                                  BUTTON_WIDTH,
                                  self.frame.size.height);
    
    xLeftOffset += chatButton.frame.size.width;
    
    pagesButton.frame = CGRectMake(self.frame.size.width - xLeftOffset - BUTTON_WIDTH,
                                   0.0,
                                   BUTTON_WIDTH,
                                   self.frame.size.height);
    
    xLeftOffset += pagesButton.frame.size.width;
    
    sliderView.frame = CGRectMake(5.0,
                                  5.0,
                                  self.frame.size.width - xLeftOffset - 10.0,
                                  self.frame.size.height - 10.0);
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
#pragma mark Private

-(void) chatButtonPressed
{
    [self.delegate qliqTabView:self didSelectItemAtIndex:4];
}

-(void) pagesButtonPressed
{
    
}

#pragma mark -
#pragma mark SliderViewDelegate

-(void) sliderView:(SliderView *)sliderView didSelectItemAtIndex:(NSInteger)index
{
    [self.delegate qliqTabView:self didSelectItemAtIndex:index];
}

@end
