//
//  QliqButton.m
//  qliqConnect
//
//  Created by Aleksey Garbarev on 01/10/12.
//  Copyright (c) 2012 Al Digit. All rights reserved.
//

#import "QliqButton.h"


@interface QliqButton ()

@property (nonatomic) QliqButtonStyle style;

@end

@implementation QliqButton

@synthesize style;
@synthesize context;

@synthesize titleOffset, imageOffset;

- (BOOL) isOldStyle{
    return style == QliqButtonStyleNavigationBackOld;
}

// Main initialization
- (id) initWithFrame:(CGRect) frame style:(QliqButtonStyle) _style{
    self = [super initWithFrame:frame];
    if (self){
        self.style = _style;
        
        CGFloat fontSize = 12;
        
        switch (self.style){

            case QliqButtonStyleNavigationBackOld:{
                UIImage *backgroundImage = [[UIImage imageNamed:@"qliqButtonNavigationBackOld"] stretchableImageWithLeftCapWidth:13.0f topCapHeight:0.0f];
                [self setBackgroundImage:backgroundImage forState:UIControlStateNormal];
                self.titleOffset = CGSizeMake(3, 0);
                break;
            }
            case QliqButtonStyleBlue:{
                UIImage * backgroundImage = [[UIImage imageNamed:@"buttonBackground"] stretchableImageWithLeftCapWidth:6 topCapHeight:6];
                UIImage * backgroundImageDisabled = [[UIImage imageNamed:@"buttonGrayBackground"] stretchableImageWithLeftCapWidth:6 topCapHeight:6];
                [self setBackgroundImage:backgroundImage forState:UIControlStateNormal];
                [self setBackgroundImage:backgroundImageDisabled forState:UIControlStateDisabled];
                break;
            }
            case QliqButtonStyleRoundedBlue:{
                UIImage * defaultBackgroundImage  = [[UIImage imageNamed:@"qliqButton"] stretchableImageWithLeftCapWidth:10 topCapHeight:10];
                UIImage * selectedBackgroundImage = [[UIImage imageNamed:@"qliqButtonSelected"] stretchableImageWithLeftCapWidth:10 topCapHeight:10];
                [self setBackgroundImage:defaultBackgroundImage forState:UIControlStateNormal];
                [self setBackgroundImage:selectedBackgroundImage forState:UIControlStateSelected];
                break;
            }
            case QliqButtonStyleNavigationBack:{
                UIImage *backgroundImage = [[UIImage imageNamed:@"qliqButtonNavigationBack"] stretchableImageWithLeftCapWidth:15.0f topCapHeight:0.0f];
                [self setBackgroundImage:backgroundImage forState:UIControlStateNormal];
                self.titleOffset = CGSizeMake(3, 0);
                break;
            }
            case QliqButtonStyleTabBarItem:{
                UIImage * acitveBackground = [UIImage imageNamed:@"tabBarButtonBackground_active"];
                UIImage * inacitveBackground = [UIImage imageNamed:@"tabBarButtonBackground"];
                [self setBackgroundImage:inacitveBackground forState:UIControlStateNormal];
                [self setBackgroundImage:acitveBackground forState:UIControlStateHighlighted];
                [self setBackgroundImage:acitveBackground forState:UIControlStateDisabled];
                [self setBackgroundImage:acitveBackground forState:UIControlStateSelected];
                fontSize = 9;
                break;
            }
            default:
                break;
        }
        self.titleLabel.font = [UIFont boldSystemFontOfSize:fontSize];
        
        /*disable shadows for old style*/
        if (![self isOldStyle]){
            self.titleLabel.shadowColor = [UIColor blackColor];
            self.titleLabel.shadowOffset = CGSizeMake(1, 1);
        }
        

    }
    return self;
}

- (id) initWithStyle:(QliqButtonStyle) _style{
    return [self initWithFrame:CGRectZero style:_style];
}

- (id) initWithFrame:(CGRect)frame{
    return [self initWithFrame:frame style:QliqButtonStyleBlue];
}


- (void) setFontSize:(CGFloat) fontSize{
    [self.titleLabel setFont:[self.titleLabel.font fontWithSize:fontSize]];
}


- (CGSize)sizeThatFits:(CGSize)size
{
    CGSize sizeOriginal = [[self titleForState:UIControlStateNormal] sizeWithAttributes:@{NSFontAttributeName : self.titleLabel.font}];
    CGSize textSize = CGSizeMake(ceilf(sizeOriginal.width), ceilf(sizeOriginal.height));
    
    return CGSizeMake(textSize.width + 24, 30);
}

- (void)layoutSubviews{
    
    /* 
        the solution below has grabbed from http://stackoverflow.com/questions/2451223/uibutton-how-to-center-an-image-and-a-text-using-imageedgeinsets-and-titleedgei
    */
    
    // get the size of the elements here for readability
    CGSize imageSize = self.imageView.frame.size;
    
    // lower the text and push it left to center it
    self.titleEdgeInsets = UIEdgeInsetsMake(self.titleOffset.height,
                                            self.titleOffset.width - imageSize.width,
                                            - (imageSize.height + imageOffset.height + self.titleOffset.height),
                                            0);
    
    // the text width might have changed (in case it was shortened before due to
    // lack of space and isn't anymore now), so we get the frame size again
    CGSize titleSize = self.titleLabel.text.length > 0 ? self.titleLabel.frame.size : CGSizeZero;
    
    // raise the image and push it right to center it
    self.imageEdgeInsets = UIEdgeInsetsMake(self.imageOffset.height - (titleSize.height + self.titleOffset.height),
                                            self.imageOffset.width,
                                            - self.imageOffset.height,
                                            - (titleSize.width + titleOffset.width + self.imageOffset.width));
    
    [super layoutSubviews];
}


@end
