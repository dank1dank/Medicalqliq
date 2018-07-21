//
//  CreateListViewController.h
//  qliq
//
//  Created by Vita on 7/19/12.
//  Copyright (c) 2012 Al Digit. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QliqBaseViewController.h"

@interface CreateListViewController : UIViewController

- (instancetype)initForAddingContacts;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITextField *textView;

@property (assign, nonatomic) BOOL isPersonalGroup;
@property (nonatomic, assign) BOOL shouldShowContactsToAdd;

@end
