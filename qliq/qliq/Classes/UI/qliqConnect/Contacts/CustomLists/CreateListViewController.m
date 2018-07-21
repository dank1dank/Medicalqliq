//
//  CreateListViewController.m
//  qliq
//
//  Created by Vita on 7/19/12.
//  Copyright (c) 2012 Al Digit. All rights reserved.
//

#import "CreateListViewController.h"
#import "QuartzCore/QuartzCore.h"
#import "QliqListService.h"

#import "QliqContactsProvider.h"
#import "QliqModelServiceFactory.h"
#import "SelectContactsViewController.h"

#import "Recipients.h"
#import "QliqConnectModule.h"
#import "ConversationDBService.h"
#import "Conversation.h"
#import "AlertController.h"

@interface CreateListViewController ()


@property (weak, nonatomic) IBOutlet UILabel *navigationRightTitleLabel;
@property (weak, nonatomic) IBOutlet UIButton *createButton;

@end

@implementation CreateListViewController

- (instancetype)initForAddingContacts {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        
    }
    
    return self;
}

- (void)configureDefaultText {
    self.navigationRightTitleLabel.text = QliqLocalizedString(@"2179-TitleCreateNewList");
    [self.createButton setTitle:QliqLocalizedString(@"50-ButtonCreate") forState:UIControlStateNormal];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureDefaultText];
    
    self.textView.background                = QliqTextFieldBackground;
    self.textView.clearButtonMode           = UITextFieldViewModeWhileEditing;
    self.textView.font                      = [UIFont fontWithName:QliqFontNameBold size:16];
    self.textView.leftViewMode              = UITextFieldViewModeAlways;
    self.textView.contentVerticalAlignment  = UIControlContentVerticalAlignmentCenter;
    self.textView.textAlignment             = NSTextAlignmentCenter;
    self.textView.autocapitalizationType    = UITextAutocapitalizationTypeWords;
    
    if (self.isPersonalGroup) {
        self.titleLabel.text = QliqLocalizedString(@"2180-TitleCreatePersonalGroup");
        self.textView.placeholder = QliqLocalizedString(@"2181-TitleNewPersonalGroup");
    }
    else {
        self.textView.placeholder = QliqLocalizedString(@"2182-TitleNewListName");
    }
    
    [self.textView becomeFirstResponder];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES];
}

#pragma mark - IBActions

AUTOROTATE_METHOD
- (IBAction)onCreateListButton:(id)sender
{
    NSString *listName = self.textView.text;
    
    if (listName && [listName length] > 0 && [[listName stringByReplacingOccurrencesOfString:@" " withString:@""] length] > 0)
    {
        if (![[QliqListService sharedService] isListExistWithName:listName])
        {
            if ([[QliqListService sharedService] addListWithName:listName]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ContactServiceNewContactNotification" object:nil];
            };
            
            if (self.shouldShowContactsToAdd) {
                [self.navigationController popViewControllerAnimated:YES];
            } else {
                
                ContactList *list = nil;
                for (ContactList *item in [[QliqListService sharedService] getLists])
                {
                    if ([item.name isEqualToString:listName]) {
                        list = item;
                        break;
                    }
                }

                SelectContactsViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([SelectContactsViewController class])];
                controller.typeController   = STForPersonalGroup;
                controller.list             = list;
                [self.navigationController pushViewController:controller animated:YES];
            }
        } else {
            [AlertController showAlertWithTitle:QliqLocalizedString(@"1069-TextListExists")
                                        message:nil
                                    buttonTitle:nil
                              cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                     completion:nil];
        }
    } else {
        [AlertController showAlertWithTitle:QliqLocalizedString(@"1070-TextProvideListName")
                                    message:nil
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                 completion:nil];
    }
}

- (IBAction)onBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
