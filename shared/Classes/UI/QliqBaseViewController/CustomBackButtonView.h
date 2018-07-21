//
//  CustomBackButtonView.h
//  qliq
//
//  Created by Paul Bar on 2/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum{
    NetworkIndicatorStateNone = 0,
    NetworkIndicatorStateUserOffline = 1
} NetworkIndicatorState;

@interface CustomBackButtonView : UIView

- (CGFloat) getWidth;

@property (nonatomic) NetworkIndicatorState networkIndicatorState;



- (void) setTitle:(NSString *) title;
- (void) setImage:(UIImage *) image;

- (void) addTarget:(id)target withAction:(SEL) action;


- (void) updatePresence;
@end
