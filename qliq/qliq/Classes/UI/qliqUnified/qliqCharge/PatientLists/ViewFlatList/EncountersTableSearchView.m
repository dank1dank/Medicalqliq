//
//  EncountersTableSearchView.m
//  qliq
//
//  Created by Paul Bar on 3/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EncountersTableSearchView.h"

@interface EncountersTableSearchView()
-(void) searchButtonPressed;
@end

@implementation EncountersTableSearchView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code
        searchBarBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Search-Bar.png"]];
        [self addSubview:searchBarBackground];
        
        textField = [[UITextField alloc] init];
        textField.delegate = self;
        [self addSubview:textField];
        
        searchButton = [[UIButton alloc] init];
        [searchButton setImage:[UIImage imageNamed:@"Search-Button.png"] forState:UIControlStateNormal];
        [searchButton setImage:[UIImage imageNamed:@"Search-Button-OnTap.png"] forState:UIControlStateHighlighted];
        [searchButton addTarget:self action:@selector(searchButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:searchButton];
        
    }
    return self;
}

-(void) dealloc
{
    [searchButton release];
    [textField release];
    [searchBarBackground release];
    [super dealloc];
}

-(void) layoutSubviews
{
    [super layoutSubviews];
    
    searchBarBackground.frame = CGRectMake(0.0,
                                           0.0,
                                           self.frame.size.width,
                                           self.frame.size.height);
    
    textField.frame = CGRectMake(35.0,
                                 12.0,
                                 self.frame.size.width - 35.0 - 85.0,
                                 self.frame.size.height - 12.0 - 10.0);
    
    searchButton.frame = CGRectMake(self.frame.size.width - 70.0 - 2.0,
                                    roundf(self.frame.size.height / 2.0 - 32 / 2.0),
                                    70.0,
                                    32.0);
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
#pragma mark TextFieldDelegate

-(BOOL) textFieldShouldReturn:(UITextField *)_textField
{
    [_textField resignFirstResponder];
    return YES;
}


#pragma mark -
#pragma mark Private

-(void) searchButtonPressed
{
    [textField resignFirstResponder];
}

@end
