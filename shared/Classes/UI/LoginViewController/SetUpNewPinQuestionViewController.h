//
//  SetUpNewPinQuestionViewController.h
//  qliq
//
//  Created by Paul Bar on 2/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqBaseViewController.h"
#import "SetUpNewPinQuestionView.h"

@protocol SetUpNewPinQuestionViewControllerDelegate <NSObject>

-(void) setUpNewPin;
-(void) skipPinSetUp;
-(BOOL) shouldEnforcePin;

@end

@interface SetUpNewPinQuestionViewController : QliqBaseViewController<SetUpNewPinQuestionViewDelegate>
{
    SetUpNewPinQuestionView *newPinView;
}

@property (nonatomic, assign) id<SetUpNewPinQuestionViewControllerDelegate> delegate;

@end
