//
//  CustomBackButtonView.m
//  qliq
//
//  Created by Paul Bar on 2/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CustomBackButtonView.h"

#import "PresenceSettings.h"
#import "UserSessionService.h"

#define LABEL_OFFSET_LEFT 12.0
#define LABEL_OFFSET_RIGHT 10.0
#define NETWORK_INDICATOR_WIDTH 25.0

#define kButtonContentPadding 24

@interface CustomBackButtonView()

@property (nonatomic, strong) QliqButton * button;
@property (nonatomic, strong) UIImageView * networkIndicator;
@property (nonatomic, strong) NSString * presenceType;
@property (nonatomic, strong) UIView * presenceView;

@end

@implementation CustomBackButtonView{
//    UIView * presenceView;
}

@synthesize button, networkIndicator;
@synthesize networkIndicatorState = indicatorState;

//@synthesize presenceType;

- (id)initWithFrame:(CGRect)frame{
    
    self = [super initWithFrame:frame];
    if (self){
        // Initialization code
        CGRect buttonFrame = self.bounds;
        buttonFrame.origin.y = 5;
        buttonFrame.size.height = 30;
        buttonFrame.size.width -= NETWORK_INDICATOR_WIDTH;
        self.button = [[QliqButton alloc] initWithFrame:buttonFrame style:QliqButtonStyleNavigationBack];
        [self addSubview:button];
        
        networkIndicator = [[UIImageView alloc] initWithFrame:CGRectMake(self.bounds.size.width-NETWORK_INDICATOR_WIDTH, 0, NETWORK_INDICATOR_WIDTH, self.bounds.size.height)];
        networkIndicator.contentMode = UIViewContentModeCenter;
//        networkIndicator.image = [UIImage imageNamed:@"offline_user_icon.png"];
        // Disabled
        networkIndicator.hidden = YES;
        [self addSubview:networkIndicator];
        
        self.presenceView = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(buttonFrame)+5, (self.bounds.size.height - 10)/2, 10, 10)];
        self.presenceView.hidden = YES;
        self.presenceView.layer.cornerRadius = 5.0f;
        [self addSubview:self.presenceView];
        
        self.networkIndicatorState = NetworkIndicatorStateNone;
    }
    return self;
}

- (UIColor *) colorForPresenceType:(NSString *) type {
    
    if ([type isEqualToString: PresenceTypeAway]){
        return [UIColor colorWithRed:245.0f/255.0f green:128.0f/255.0f blue:37.0f/255.0f alpha:1.0f];
    }else if ([type isEqualToString:PresenceTypeDoNotDisturb]){
        return [UIColor colorWithRed:247.0f/255.0f green:0 blue:0 alpha:1.0f];
    }else if ([type isEqualToString:PresenceTypeOnline]){
        return [UIColor colorWithRed:29.0f/255.0f green:204.0f/255.0f blue:0 alpha:1.0f];
    }
    
    return [UIColor colorWithRed:171.0f/255.0f green:171.0f/255.0f blue:171.0f/255.0f alpha:1.0f];
    
}

- (void) updatePresence
{
    networkIndicator.hidden = YES;
    
    self.presenceType = [UserSessionService currentUserSession].userSettings.presenceSettings.currentPresenceType;
    self.presenceView.hidden = self.presenceType.length == 0;
    self.presenceView.backgroundColor = [self colorForPresenceType:self.presenceType];
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    /* Layout back button */
    CGRect buttonFrame = self.button.frame;
    buttonFrame.origin.x = 0;
    buttonFrame.origin.y = (self.bounds.size.height - buttonFrame.size.height) / 2.0f;
    if ([self.button imageForState:UIControlStateNormal]){
        buttonFrame.size.width = [self.button imageForState:UIControlStateNormal].size.width;
        CGFloat freeSpace = self.bounds.size.width - buttonFrame.size.width - self.presenceView.frame.size.width - networkIndicator.frame.size.width ;
        if (freeSpace > 8) {
            buttonFrame.origin.x = 8;
        }
    }else{
        
        CGSize size = [[self.button titleForState:UIControlStateNormal] sizeWithAttributes:@{NSFontAttributeName : self.button.titleLabel.font}];
        CGSize labelSize = CGSizeMake(ceilf(size.width), ceilf(size.height));
        buttonFrame.size.width = labelSize.width + kButtonContentPadding;
    }
    self.button.frame = CGRectIntegral(buttonFrame);
    
    /* Layout presence */
    CGRect presenceFrame = self.presenceView.frame;
    presenceFrame.origin.x = CGRectGetMaxX(buttonFrame) + 5;
    presenceFrame.origin.y = (self.bounds.size.height - presenceFrame.size.height) / 2.0f;
    self.presenceView.frame = CGRectIntegral(presenceFrame);
    
    /* Layout network indicator */
    CGRect indicatorFrame = networkIndicator.frame;
    indicatorFrame.origin.x = self.presenceView.hidden ? CGRectGetMaxX(buttonFrame) + 5 : CGRectGetMaxX(presenceFrame);
    indicatorFrame.origin.y = (self.bounds.size.height - indicatorFrame.size.height) / 2.0f;
    networkIndicator.frame = CGRectIntegral(indicatorFrame);

    
}


- (void) setTitle:(NSString *) title{
    [self.button setImage:nil forState:UIControlStateNormal];
    [self.button setTitle:title forState:UIControlStateNormal];
}

- (void) setImage:(UIImage *) image{
    [self.button setTitle:nil forState:UIControlStateNormal];
    [self.button setBackgroundImage:nil forState:UIControlStateNormal];
    [self.button setImage:image forState:UIControlStateNormal];
}

- (void) addTarget:(id)target withAction:(SEL) action{
    [self.button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
}

- (CGFloat) getWidth{

    if (networkIndicator.image){
        return CGRectGetMaxX(networkIndicator.frame);
    }else{
        return CGRectGetMaxX(self.button.frame);
    }
    
}

- (void) setNetworkIndicatorState:(NetworkIndicatorState) networkIndicatorState{
    
    indicatorState = networkIndicatorState;
    [self performSelector:@selector(updatePresence) withObject:nil afterDelay:5.0];
}

@end
