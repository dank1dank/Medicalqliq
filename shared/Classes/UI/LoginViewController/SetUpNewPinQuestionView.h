//
//  SetUpNewPinQuestionView.h
//  qliq
//
//  Created by Paul Bar on 2/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class StretchableButton;
@class LightGreyGlassGradientView;

@protocol SetUpNewPinQuestionViewDelegate <NSObject>

-(void) setUpPin;
-(void) skipPinSetUp;

- (BOOL) shouldEnforcePin;

@end

@interface SetUpNewPinQuestionView : UIView
{
    UILabel *quickLoginUsingPinLabel;
    UILabel *emailConfirmLabel;
    UILabel *backToPasswordLabel;
    UILabel *addPinInSettingsLabel;
	
    LightGreyGlassGradientView *buttonsBackground;
    StretchableButton *setUpPinButton;
    StretchableButton *laterButton;

}

@property (nonatomic, assign) id<SetUpNewPinQuestionViewDelegate> delegate;

@end
