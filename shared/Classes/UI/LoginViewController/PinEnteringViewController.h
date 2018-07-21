//
//  PinEnteringViewController.h
//  qliq
//
//  Created by Paul Bar on 2/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqBaseViewController.h"
#import "PinEnteringView.h"

@class PinEnteringViewController;

@protocol PinEnteringViewControllerDelegate <NSObject>

-(void) pinEnteringViewController:(PinEnteringViewController*)ctrl didEnterPin:(NSString*)pin;
-(void) didSetUpNewPin:(NSString*)pin;
-(void) switchToPasswordLogin;
-(void) willConfirmPin;
-(void) didFailedToConfirmPin;

@end

@interface PinEnteringViewController : QliqBaseViewController <PinEnteringViewDelegate>
{
    PinEnteringView *pinEnteringView;
}
-(void) reset:(BOOL)setupNewPin;

- (void) closeKeyboard;

@property (nonatomic, assign) id<PinEnteringViewControllerDelegate> delegate;
@property (nonatomic, assign) BOOL setupNewPin;
@property (nonatomic, assign) BOOL setupPinFromSettings;

@end
