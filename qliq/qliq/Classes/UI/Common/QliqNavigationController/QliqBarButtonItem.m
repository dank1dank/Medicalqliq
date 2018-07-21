//
//  QliqBarButtonItem.m
//  qliq
//
//  Created by Aleksey Garbarev on 22.06.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqBarButtonItem.h"
//#import "MKNumberBadgeView.h"

@interface QliqBarButtonItem()

@property (nonatomic, strong) QliqButton * button;

@end

@implementation QliqBarButtonItem{
    void(^action)(QliqBarButtonItem *);
//    MKNumberBadgeView * badgeView;
}
@synthesize targetIdentifier;
@synthesize button;

- (void) buttonPressed{
    
    if (action){
        action(self);
    }
    
}

- (void) setSelected:(BOOL)selected{
    ((UIButton*)self.customView).selected = selected;
}
- (BOOL)selected{
    return ((UIButton*)self.customView).selected;
}
- (void) setEnabled:(BOOL)enabled{
    ((UIButton*)self.customView).enabled = enabled;
}
- (BOOL)enabled{
    return ((UIButton*)self.customView).enabled;
}

/*
- (void)setBadgeValue:(NSUInteger)badgeValue{
    badgeView.value = badgeValue;
}

- (NSUInteger)badgeValue{
    return badgeView.value;
}
 */


- (id) initWithButtonImage:(UIImage *) image targetIdentifier:(NSString *) _targetIdentifier actionBlock:(void(^)(QliqBarButtonItem *))block{
        
    self = [self initWithFrame:CGRectMake(0, 0, 62, kBarButtonHeight) buttonStyle:QliqButtonStyleTabBarItem actionBlock:block];
    
    if (self){
        self.targetIdentifier = _targetIdentifier;
        
        [self.button setAdjustsImageWhenDisabled:NO];
        [self.button setImage:image forState:UIControlStateNormal];
        self.button.imageOffset = CGSizeMake(0, fabs(kBarButtonHeight - image.size.height)/(int)2);
    }
    
    return self;
}

- (id) initWithButtonImage:(UIImage *) image  actionBlock:(void(^)(QliqBarButtonItem *))block{
    
    return [self initWithButtonImage:image targetIdentifier:nil actionBlock:block];
}

//- (void)setWidth:(CGFloat)width{
//    CGRect frame = self.customView.frame;
//    frame.size.width = width;
//    self.customView.frame = frame;
//    [super setWidth:width];
//}

- (id) initWithTitle:(NSString *)title actionBlock:(void(^)(QliqBarButtonItem * item))block{
    
	self = [self initWithFrame:CGRectMake(0, 0, 62, kBarButtonHeight*0.7) buttonStyle:QliqButtonStyleBlue actionBlock:block];
    if (self){
        [self.button setTitle:title forState:UIControlStateNormal];
        self.button.titleLabel.font = [UIFont fontWithName:@"HelveticaNeueLTStd-Bd" size:16];
        self.button.contentEdgeInsets = UIEdgeInsetsMake(9, 0, 0, 0);
        [self.button setAdjustsImageWhenDisabled:NO];
    }
    return self;
}

- (id) initWithFrame:(CGRect) frame buttonStyle:(QliqButtonStyle) style actionBlock:(void(^)(QliqBarButtonItem * item))block{
    self = [super init];
    if (self) {
        self.button = [[QliqButton alloc] initWithFrame:frame style:style];
        [self.button addTarget:self action:@selector(buttonPressed) forControlEvents:UIControlEventTouchUpInside];
        action = block;
        
        /*
        badgeView = [[MKNumberBadgeView alloc] initWithFrame:CGRectMake(35, -2, 25, 25)];
        badgeView.hideWhenZero = YES;
        badgeView.value = 0;
        badgeView.font = [UIFont boldSystemFontOfSize:11];
        badgeView.pad = 0;
        badgeView.strokeWidth = 1.0f;
        badgeView.shadow = YES;
        [self.button addSubview:badgeView];
        */
         
        self.customView = self.button;
    }
    return self;
    
}


@end
