//
//  NavigationBarChattingWithView.h
//  qliqConnect
//
//  Created by Paul Bar on 12/19/11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol NavigationBarChattingWithViewDelegate <NSObject>

-(void) disclosureButtonPressed;

@end

@interface NavigationBarChattingWithView : UIView
{    
    UILabel *recipientNameLabel;
    UILabel *regardingTextLabel;
}
@property (nonatomic, assign) NSString *recipientName;
@property (nonatomic, assign) NSString *regardingText;
@property (nonatomic, assign) id<NavigationBarChattingWithViewDelegate> delegate;

-(void) setDisclosureButtonOpen:(BOOL)open animaged:(BOOL)animated;

@end
