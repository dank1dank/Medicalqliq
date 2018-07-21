//
//  CellPhoneView.m
//  qliq
//
//  Created by Vita on 1/26/12.
//  Copyright (c) 2012 Al Digit. All rights reserved.
//

#import "CellPhoneView.h"

#define kCallStarButtonTag 111
#define kCallHashButtonTag 112
#define tagOffset 100

@implementation CellPhoneView

@synthesize delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        for (int i=1; i<10; i++)
        {
            UIButton * cellBtn = [[[UIButton alloc] initWithFrame:CGRectZero] autorelease];
            [cellBtn setBackgroundImage:[UIImage imageNamed:[NSString stringWithFormat:@"%d.png",i]] forState:UIControlStateNormal];
            [cellBtn setBackgroundImage:[UIImage imageNamed:[NSString stringWithFormat:@"%d_selected.png",i]] forState:UIControlStateSelected];
            [cellBtn addTarget:self action:@selector(onCellButton:) forControlEvents:UIControlEventTouchUpInside];
            cellBtn.tag = i+tagOffset;
            [self addSubview:cellBtn];
        
        }
        UIButton * starBtn = [[[UIButton alloc] initWithFrame:CGRectZero] autorelease];
        [starBtn setBackgroundImage:[UIImage imageNamed:@"cell_star.png"] forState:UIControlStateNormal];
        [starBtn setBackgroundImage:[UIImage imageNamed:@"cell_star_selected.png"] forState:UIControlStateSelected];
        [starBtn addTarget:self action:@selector(onStarButton:) forControlEvents:UIControlEventTouchUpInside];
        starBtn.tag = kCallStarButtonTag;
        [self addSubview:starBtn];

        UIButton * zeroBtn = [[[UIButton alloc] initWithFrame:CGRectZero] autorelease];
        [zeroBtn setBackgroundImage:[UIImage imageNamed:@"0.png"] forState:UIControlStateNormal];
        [zeroBtn setBackgroundImage:[UIImage imageNamed:@"0_selected.png"] forState:UIControlStateSelected];
        zeroBtn.tag = tagOffset;
        [zeroBtn addTarget:self action:@selector(onCellButton:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:zeroBtn];

        UIButton * hashBtn = [[[UIButton alloc] initWithFrame:CGRectZero] autorelease];
        [hashBtn setBackgroundImage:[UIImage imageNamed:@"hash.png"] forState:UIControlStateNormal];
        [hashBtn setBackgroundImage:[UIImage imageNamed:@"hash_selected.png"] forState:UIControlStateSelected];
        [hashBtn addTarget:self action:@selector(onHashButton:) forControlEvents:UIControlEventTouchUpInside];
        hashBtn.tag = kCallHashButtonTag;
        [self addSubview:hashBtn];
    }
    return self;
}

- (void)layoutSubviews 
{
    [super layoutSubviews];
    
    CGFloat buttonWidth = MIN(self.frame.size.width/3, CellButtonsWidth);
    CGFloat buttonHeigh = MIN(self.frame.size.height/4, CellButtonsHeight);
    CGRect btnFrame = CGRectMake(0.0, 0.0, buttonWidth, buttonHeigh);
    
    for (int i=1; i<10; i++)
    {
        UIButton* btn = (UIButton*)[self viewWithTag:i+tagOffset];
        btn.frame = btnFrame;
        
        if (i %3 == 0)// new line
        {
            btnFrame.origin.x = 0;
            btnFrame.origin.y += buttonHeigh; 
        }
        else
        {
            btnFrame.origin.x += buttonWidth;
        }
    }
    UIButton * starBtn = (UIButton*)[self viewWithTag:kCallStarButtonTag];
    starBtn.frame = btnFrame;
    
    btnFrame.origin.x += buttonWidth;
    
    UIButton * zeroBtn = (UIButton*)[self viewWithTag:tagOffset];
    zeroBtn.frame = btnFrame;
    
    btnFrame.origin.x += buttonWidth;
    
    UIButton * hashBtn = (UIButton*)[self viewWithTag:kCallHashButtonTag];
    hashBtn.frame = btnFrame; 
}

- (void)onCellButton:(id)sender
{
    if ([delegate respondsToSelector:@selector(cellPhoneView:tapOnCell:)])
    {
        [delegate cellPhoneView:self tapOnCell:[(UIButton*)sender tag]-tagOffset];
    }
}

- (void)onStarButton:(id)sender
{
    if ([delegate respondsToSelector:@selector(cellPhoneViewTapOnStar:)])
    {
        [delegate cellPhoneViewTapOnStar:self];
    }
}

- (void)onHashButton:(id)sender
{
    if ([delegate respondsToSelector:@selector(cellPhoneViewTapOnHash:)])
    {
        [delegate cellPhoneViewTapOnHash:self];
    }
}

@end
