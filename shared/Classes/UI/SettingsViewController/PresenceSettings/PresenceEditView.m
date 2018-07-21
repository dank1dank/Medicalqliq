//
//  PresenceEditView.m
//  qliq
//
//  Created by Aleksey Garbarev on 16.11.12.
//
//

#import "PresenceEditView.h"

#import "UserSessionService.h"
//#import "SettingsTableViewCell.h"
#import "SettingsItem.h"

#import "SelectContactsViewController.h"
#import "SearchRecipientsController.h"
//#import "ContactsListViewController.h"
#import "QliqMembersContactGroup.h"

#define kTableViewOriginOffsetY -10
#define kQliqPlusImage  [UIImage imageNamed:@"Qliq_Plus_Button_Blue.png"]
#define kQliqMinusImage [UIImage imageNamed:@"Qliq_Minus_Button_Blue.png"]

@interface PresenceEditView() <QliqTextfieldDelegate, SearchRecipientsViewControllerDelegate/*, ContactsListViewControllerDelegate*/>

@property (nonatomic, strong) UITableView *searchResultsTable;
@property (nonatomic, strong) QliqLabel *topLabel;
@property (nonatomic, strong) QliqLabel *recepientLabel;
@property (nonatomic, strong) QliqTextfield *messageTextField;
@property (nonatomic, strong) UIButton *recepientButton;

@property (nonatomic, strong) SearchRecipientsController *searchRecipientsConroller;
@property (nonatomic, strong) Presence *currentPresence;

@property (nonatomic, assign) BOOL isEditing;

@end

@implementation PresenceEditView

@synthesize delegate, navigationController;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initializationWithType:@"away"];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame andPresenceType:(NSString *)type
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initializationWithType:[self messageStringFromType:type]];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    return [self initWithFrame:frame andPresenceType:@"away"];
}

- (void)initializationWithType:(NSString *)message
{
    /* Search prefill initialization */
    self.searchRecipientsConroller = [[SearchRecipientsController alloc] init];
    self.searchRecipientsConroller.delegate = self;
    [self.searchRecipientsConroller reloadContacts];
    
    /* Message label and textfield initialization */
    self.topLabel = [[QliqLabel alloc] initWithFrame:CGRectMake(10, -20, self.bounds.size.width, 18)];
    self.topLabel.text = [NSString stringWithFormat:@"Add your %@ presence message",message];
    self.topLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    self.messageTextField = [[QliqTextfield alloc] initWithFrame:CGRectMake(10, 30, self.bounds.size.width - 20, 40)];
    self.messageTextField.delegate = self;
    self.messageTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.messageTextField.clipsToBounds = NO;
    self.messageTextField.textAlignment = NSTextAlignmentLeft;
    self.messageTextField.placeholder = @"Enter your message";
    self.messageTextField.tag = 100;
    [self.messageTextField setFontSize:14];
    
    [self.messageTextField addSubview:self.topLabel];
    
    /* Recepient label, textfield initialization */
    self.recepientLabel = [[QliqLabel alloc] initWithFrame:CGRectMake(10, -20, self.bounds.size.width, 18)];
    self.recepientLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.recepientLabel.text = [NSString stringWithFormat:@"Forward %@ messages to",message];
    
    self.forwardingUserTextField = [[QliqTextfield alloc] initWithFrame:CGRectMake(10, 100, self.messageTextField.bounds.size.width, 40)];
    self.forwardingUserTextField.delegate =  (id<QliqTextfieldDelegate>)self.searchRecipientsConroller;
    self.forwardingUserTextField.tag = 101;
    self.forwardingUserTextField.clipsToBounds = NO;
    self.forwardingUserTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.forwardingUserTextField.textAlignment = NSTextAlignmentLeft;
    self.forwardingUserTextField.clearButtonMode = UITextFieldViewModeNever;
    self.forwardingUserTextField.placeholder = @"Enter recepient";
    [self.forwardingUserTextField setFontSize:14];
    
    [self.forwardingUserTextField addSubview:self.recepientLabel];
    
    self.recepientButton = [[UIButton alloc] init];
    self.recepientButton.frame = CGRectMake(0, 0, 40, 40);
    [self.recepientButton addTarget:self action:@selector(recepientButtonPressed) forControlEvents:UIControlEventTouchUpInside];
   
    self.forwardingUserTextField.rightView = self.recepientButton;
    self.forwardingUserTextField.rightViewMode = UITextFieldViewModeAlways;
    
    self.forwardingUserTextField.layer.shadowOffset = CGSizeMake(0, 2);
    self.forwardingUserTextField.layer.shadowColor = [[UIColor clearColor] CGColor];
    self.forwardingUserTextField.layer.shadowOpacity = 0.5;
    self.forwardingUserTextField.layer.shadowPath = [[UIBezierPath bezierPathWithRoundedRect:self.forwardingUserTextField.bounds cornerRadius:10]CGPath];
    
    /* SearchResultTableView initialization */
    self.searchResultsTable = [[UITableView alloc] initWithFrame:CGRectMake(self.forwardingUserTextField.frame.origin.x, CGRectGetMaxY(self.forwardingUserTextField.frame), self.forwardingUserTextField.frame.size.width,160)] ;
    self.searchResultsTable.autoresizingMask = /*UIViewAutoresizingFlexibleHeight |*/ UIViewAutoresizingFlexibleWidth;
    self.searchResultsTable.hidden = YES;
    self.searchResultsTable.separatorColor = [UIColor clearColor];
    self.searchResultsTable.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.searchResultsTable.rowHeight = 44;
    self.searchResultsTable.tag = 1;
    self.searchResultsTable.backgroundColor = [UIColor whiteColor];
    self.searchResultsTable.contentInset = UIEdgeInsetsMake(10, 0, 0, 0);
    self.searchResultsTable.scrollIndicatorInsets = self.searchResultsTable.contentInset;
    
    [self addSubview:self.messageTextField];
    [self addSubview:self.searchResultsTable];
    [self addSubview:self.forwardingUserTextField];
    
    [self configureRecipientButton];
}

- (void)dealloc {
    
    [self.recepientButton removeFromSuperview];
    self.recepientButton = nil;
    self.topLabel = nil;
    self.recepientLabel = nil;
    self.messageTextField = nil;
    self.searchRecipientsConroller = nil;
    self.currentPresence = nil;
}

#pragma mark - Public

- (void)setPresence:(Presence *)presence {
    DDLogSupport(@"set presence with name: %@", [self.currentPresence.forwardingUser recipientTitle]);
    
    self.currentPresence = presence;
    
    self.messageTextField.text = self.currentPresence.message;
    self.forwardingUserTextField.text = [self.currentPresence.forwardingUser recipientTitle];
    
//    [self configureRecepientButton];
}

- (void)setType:(NSString*)type
{
    NSString * message = [self messageStringFromType:type];
    self.topLabel.text = [NSString stringWithFormat:@"Add your %@ presence message",message];
    self.recepientLabel.text = [NSString stringWithFormat:@"Forward %@ messages to",message];
}


#pragma mark - Private

- (NSString *)messageStringFromType:(NSString *)type {
    NSString *string = @"";
    
    if ([type isEqualToString:PresenceTypeAway]) {
        string = @"away";
    }
    else if ([type isEqualToString:PresenceTypeDoNotDisturb]) {
        string = @"do not disturb";
    }
    else if ([type isEqualToString:PresenceTypeOnline]) {
        string = @"online";
    }
    
    return string;
}

- (BOOL)resignFirstResponder {    
    [self.messageTextField resignFirstResponder];
    [self.forwardingUserTextField resignFirstResponder];
    
    return [super resignFirstResponder];
}

- (void)didBeginEdit
{
    if (!self.isEditing) {
        self.isEditing = YES;
        if ([self.delegate respondsToSelector:@selector(presenceEditViewDidBeginEdit:)]) {
            [self.delegate presenceEditViewDidBeginEdit:self];
        }
    }
}

- (void)didEndEdit
{
    if (self.isEditing) {
        self.isEditing = NO;
        if ([self.delegate respondsToSelector:@selector(presenceEditViewDidEndEdit:)]) {
            [self.delegate presenceEditViewDidEndEdit:self];
        }
    }

}

- (void)recepientButtonPressed {
    
    if (!self.currentPresence.forwardingUser) {
        
        [self.delegate addRecipientWithView:self];
        
    } else {
        
        [self setEptyRecipient];
        
    }
}

- (void)configureRecipientButton {
    
    if (self.currentPresence.forwardingUser) {
        
        //Add initialization 'UIImage' to define. As it is leaking about 16 bytes per call.
        /*
         UIImage *qliqMinusImage = [UIImage imageNamed:@"Qliq_Minus_Button_Blue.png"];
         [self.recepientButton setImage:qliqMinusImage forState:UIControlStateNormal];
         qliqMinusImage = nil;
         */
        [self.recepientButton setImage:kQliqMinusImage forState:UIControlStateNormal];
        
    } else {
        /*
         UIImage *qliqPlusImage = [UIImage imageNamed:@"Qliq_Plus_Button_Blue.png"];
         [self.recepientButton setImage:qliqPlusImage forState:UIControlStateNormal];
         qliqPlusImage = nil;
         */
        [self.recepientButton setImage:kQliqPlusImage forState:UIControlStateNormal];
        
    }
}

#pragma mark - Actions 


//- (void) didPressedDoneButton:(QliqButton *) button{
//
//
//    [self didEndEdit];
//
//    if ([self.delegate respondsToSelector:@selector(presenceEditView:didPressedDoneButton:)])
//        [self.delegate presenceEditView:self didPressedDoneButton:button];
//
//}

//- (void) didPressedCancelButton:(QliqButton *) button{
//
//    [self didEndEdit];
//
//    if ([self.delegate respondsToSelector:@selector(presenceEditView:didPressedCancelButton:)])
//        [self.delegate presenceEditView:self didPressedCancelButton:button];
//}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    [self.messageTextField endEditing:NO];
    self.messageTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    return textField.tag != 101;
}

- (void)textFieldDidBeginEditing:(QliqTextfield *)textField {
    if (textField.tag == 101) {
        [self didBeginEdit];
    }
}

- (void)textFieldDidEndEditing:(QliqTextfield *)textField {
    
    if (self.messageTextField.text != nil || [self.messageTextField.text isEqualToString:@""]) {
        [self.messageTextField endEditing:NO];
        self.messageTextField.clearButtonMode = UITextFieldViewModeUnlessEditing;
    }
    
    //Save message
    self.currentPresence.message = self.messageTextField.text;
    [[UserSessionService currentUserSession].userSettings write];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    self.currentPresence.message = [textField.text stringByReplacingCharactersInRange:range withString:string];
    return YES;
}

//- (void)textFieldDidDeleteBackward:(QliqTextfield *)textField {
//    
//    
//    
//}
//
//- (void)textFieldDidDeleteBackwardOnEmpty:(QliqTextfield *)textField
//{
//    self.currentPresence.forwardingUser = nil;
//    
//    [[UserSessionService currentUserSession].userSettings write];
//}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    if (textField.tag == 101) {
        [self didEndEdit];
    }
    return YES;
}

#pragma mark - ContactlistViewControllerDelegate
/*
- (void)contactsList:(ContactsListViewController *)contactList didSelectRecipient:(id)user {
    [self selectedRecipient:user];
    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)contactsList:(ContactsListViewController *)contactList shouldShowDetailsFor:(Contact *)contact {
    return NO;
}
*/
#pragma mark - SearchRecipientsViewControllerDelegat

- (void)setSearchingEnabled:(BOOL)isSearching {

    if (isSearching) {
        [self didBeginEdit];
    }
    else {
        [self didEndEdit];
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        
        self.messageTextField.alpha = isSearching ? 0.0f : 1.0f;
        
        [self.forwardingUserTextField setFrameOriginY:isSearching? 30.0f : 100.0f];
        [self.searchResultsTable setFrameOriginY:CGRectGetMaxY(self.forwardingUserTextField.frame) + kTableViewOriginOffsetY];
        
        self.searchResultsTable.alpha = isSearching ? 1.0f : 0.0f;

    }];
}

- (void)searchResultsUpdatedForRecipientSearchController:(SearchRecipientsController*)controller numberOfResults:(NSInteger)numOfResults {
    
    self.searchResultsTable.hidden = (numOfResults == 0);
    self.forwardingUserTextField.layer.shadowColor = self.searchResultsTable.hidden ? [[UIColor clearColor] CGColor] : [[UIColor blackColor] CGColor];
    [self.searchResultsTable reloadData];
    
    [self.searchResultsTable flashScrollIndicators];
}

- (void)searchRecipientsViewControllerWillStartSearching:(SearchRecipientsController*)controller {

    [self setSearchingEnabled:YES];
    
    self.searchResultsTable.dataSource = controller;
    self.searchResultsTable.delegate = controller;
    
    [self setNeedsLayout];
}

- (BOOL)searchRecipientsViewControllerShouldEndSearching:(SearchRecipientsController*)controller
{
   [self setSearchingEnabled:NO];
    
    return YES;
}

- (void)selectedRecipient:(QliqUser *)contact
{
    self.searchResultsTable.hidden = YES;
    self.forwardingUserTextField.layer.shadowColor = self.searchResultsTable.hidden ? [[UIColor clearColor] CGColor] : [[UIColor blackColor] CGColor];
    
    self.forwardingUserTextField.text = [contact nameDescription];
    
    [self setSearchingEnabled:NO];
    
    self.currentPresence.forwardingUser = contact;
    
    [self.forwardingUserTextField resignFirstResponder];
    
    [[UserSessionService currentUserSession].userSettings write];
    
    
    [self configureRecipientButton];
}

- (void)setEptyRecipient
{
    self.searchResultsTable.hidden = YES;
    self.forwardingUserTextField.layer.shadowColor = self.searchResultsTable.hidden ? [[UIColor clearColor] CGColor] : [[UIColor blackColor] CGColor];
    
    self.forwardingUserTextField.text = @"";
    
    self.currentPresence.forwardingUser = nil;
    
    [[UserSessionService currentUserSession].userSettings write];
    
    [self configureRecipientButton];
}

@end
    
