//
//  ContactsViewController.h
//  qliq
//
//  Created by Valerii Lider on 7/29/14.
//
//

#import <UIKit/UIKit.h>

#import "GroupListPopover.h"

@interface ContactsViewController : UIViewController

@property (weak, nonatomic) IBOutlet GroupListPopover *groupListPopover;
@property (assign, nonatomic) BOOL isHide;

- (void)pressedGroup:(GroupList)option;

@end
