//
//  PinViewController.h
//  qliq
//
//  Created by Valerii Lider on 5/27/14.
//
//

#import <UIKit/UIKit.h>

typedef enum {
    ActionTipePinSet = 0,
    ActionTipePinConfirm,
    ActionTipePinEnter
}ActionTipePin;

@interface LoginWithPinViewController : UIViewController

@property (assign, nonatomic) BOOL setupPinFromSettings;

@property (assign, nonatomic) ActionTipePin action;

@end
