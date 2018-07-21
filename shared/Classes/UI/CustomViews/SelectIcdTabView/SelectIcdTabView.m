//
//  SelectIcdTabView.m
//  CCiPhoneApp
//
//  Created by Marcin Zbijowski on 03/05/2011.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import "SelectIcdTabView.h"
#import "Helper.h"

@interface SelectIcdTabView (Private)

- (UILabel *)bottomLabelWithText:(NSString*)lblText frame:(CGRect)frame;
- (UIButton *)buttonWithNormalImage:(UIImage *)normalImg highlightImage:(UIImage *)highlightImg frame:(CGRect)frame;
- (void)addSeparatorAtX:(CGFloat)posX;

@end

@implementation SelectIcdTabView

@synthesize favoritesButton = _favoritesButton;
@synthesize crosswalkButton = _crosswalkButton;
@synthesize allButton = _allButton;

@synthesize favoritesLabel = _favoritesLabel;
@synthesize crosswalkLabel = _crosswalkLabel;
@synthesize allLabel = _allLabel;

- (id)initWithFrame:(CGRect)frame withCrosswalk:(BOOL)yesNo
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg-toolbar"]];
        if (yesNo) {
            [self addSeparatorAtX:106];
            [self addSeparatorAtX:213];

            _favoritesLabel = [self bottomLabelWithText:NSLocalizedString(@"Favorites", @"Favorites") frame:CGRectMake(0, 35, 107, 15)];
            _crosswalkLabel = [self bottomLabelWithText:NSLocalizedString(@"Cross Walk", @"Cross Walk") frame:CGRectMake(107, 35, 107, 15)];
            _allLabel = [self bottomLabelWithText:NSLocalizedString(@"All", @"All") frame:CGRectMake(214, 35, 107, 15)];
            
            _favoritesLabel.textColor = [UIColor colorWithWhite:0.0f alpha:1.0f];
            _crosswalkLabel.textColor = [UIColor colorWithWhite:0.0f alpha:1.0f];
            _allLabel.textColor = [UIColor colorWithWhite:0.0f alpha:1.0f];
            
            _favoritesButton = [self buttonWithNormalImage:[UIImage imageNamed:@"btn-favs-off"] highlightImage:[UIImage imageNamed:@"btn-favs-on"] frame:CGRectMake(0.0, 0.0, 107, 35)];
            _crosswalkButton = [self buttonWithNormalImage:[UIImage imageNamed:@"btn-crosswalk-off"] highlightImage:[UIImage imageNamed:@"btn-crosswalk-on"] frame:CGRectMake(107.0, 0.0, 107, 35)];
            _allButton = [self buttonWithNormalImage:[UIImage imageNamed:@"btn-all-off"] highlightImage:[UIImage imageNamed:@"btn-all-on"] frame:CGRectMake(214, 0.0, 107, 35)];
            
            [self addSubview:_favoritesLabel];
            [self addSubview:_crosswalkLabel];
            [self addSubview:_allLabel];
            [self addSubview:_favoritesButton];
            [self addSubview:_crosswalkButton];
            [self addSubview:_allButton];

        }
        else {
            [self addSeparatorAtX:160];
    //        [self addSeparatorAtX:213];
            _favoritesLabel = [self bottomLabelWithText:NSLocalizedString(@"Favorites", @"Favorites") frame:CGRectMake(0, 35, 160, 15)];
    //        _crosswalkLabel = [self bottomLabelWithText:NSLocalizedString(@"Cross Walk", @"Cross Walk") frame:CGRectMake(107, 35, 107, 15)];
            _allLabel = [self bottomLabelWithText:NSLocalizedString(@"All", @"All") frame:CGRectMake(160, 35, 160, 15)];
            
            _favoritesLabel.textColor = [UIColor colorWithWhite:0.0f alpha:1.0f];
    //        _crosswalkLabel.textColor = [UIColor colorWithWhite:0.0f alpha:1.0f];
            _allLabel.textColor = [UIColor colorWithWhite:0.0f alpha:1.0f];
            
            _favoritesButton = [self buttonWithNormalImage:[UIImage imageNamed:@"btn-favs-off"] highlightImage:[UIImage imageNamed:@"btn-favs-on"] frame:CGRectMake(0.0, 0.0, 160, 35)];
    //        _crosswalkButton = [self buttonWithNormalImage:[UIImage imageNamed:@"btn-crosswalk-off"] highlightImage:[UIImage imageNamed:@"btn-crosswalk-on"] frame:CGRectMake(107.0, 0.0, 107, 35)];
            _allButton = [self buttonWithNormalImage:[UIImage imageNamed:@"btn-all-off"] highlightImage:[UIImage imageNamed:@"btn-all-on"] frame:CGRectMake(160, 0.0, 160, 35)];

            [self addSubview:_favoritesLabel];
    //        [self addSubview:_crosswalkLabel];
            [self addSubview:_allLabel];
            [self addSubview:_favoritesButton];
    //        [self addSubview:_crosswalkButton];
            [self addSubview:_allButton];
        }
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

- (void)dealloc
{
    [_favoritesButton release];
    [_crosswalkButton release];
    [_allButton release];
    [_favoritesLabel release];
    [_crosswalkLabel release];
    [_allLabel release];
    [super dealloc];
}

#pragma mark -
#pragma mark Private

- (UILabel *)bottomLabelWithText:(NSString*)lblText frame:(CGRect)frame {
    UILabel *lbl = [[[UILabel alloc] initWithFrame:frame] autorelease];
    lbl.textColor = [UIColor whiteColor];
    lbl.font = [UIFont boldSystemFontOfSize:11.0f];
    lbl.textAlignment = UITextAlignmentCenter;
    lbl.backgroundColor = [UIColor clearColor];
    lbl.text = lblText;
    return lbl;
}

- (UIButton *)buttonWithNormalImage:(UIImage *)normalImg highlightImage:(UIImage *)highlightImg frame:(CGRect)frame {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setImage:normalImg forState:UIControlStateNormal];
    [btn setImage:highlightImg forState:UIControlStateSelected];
    btn.frame = frame;
    return btn;
}

- (void)addSeparatorAtX:(CGFloat)posX {
    UIImageView *separator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tab-separator"]];
    CGRect frame = separator.frame;
    frame.origin.x = posX;
    separator.frame = frame;
    [self addSubview:separator];
    [separator release];
}

@end
