//
//  ContactsActionSheet.m
//  qliq
//
//  Created by Valerii Lider on 8/17/15.
//
//

#import "ContactsActionSheet.h"
#import "Contact.h"
#import "ContactPhoneCell.h"

#import <AddressBook/AddressBook.h>
#import <Contacts/Contacts.h>

#define heightForNonSelectedRow 53
#define heightForSelectedRow 90
#define actionSheetViewTag 666
#define kValueMaxTableViewHeightForLandscape 160
#define kValueMaxTableViewHeightForPortrait 360

@interface ContactsActionSheet () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSMutableArray *contacts;

@property (nonatomic, strong) UIControl *control;

@property (nonatomic, strong) NSMutableArray *phoneNumbers;
@property (nonatomic, assign) NSString *selectedPhone;
@property (nonatomic, assign) NSInteger selectedPhoneIndex;
@property (nonatomic, strong) NSLayoutConstraint *bottom;
@property (nonatomic, strong) NSLayoutConstraint *top;
@property (nonatomic, strong) NSLayoutConstraint *left;
@property (nonatomic, strong) NSLayoutConstraint *right;
@property (nonatomic, strong) UIView *parentView;

@property (nonatomic, strong) UIButton *cancelButton;
@end

@implementation ContactsActionSheet

- (void)dealloc
{
    self.parentView = nil;
    
    self.top = nil;
    self.left = nil;
    self.right = nil;
    self.bottom = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithContacts:(NSMutableArray *)contacts {
    
    self = [super init];
    if (self) {
        self.contacts = contacts;
        self.phoneNumbers = [NSMutableArray array];
        self.selectedPhoneIndex = NSNotFound;
        self.view.tag = actionSheetViewTag;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.view.layer.cornerRadius = 5;
    self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.25];
    self.view.opaque = NO;
    [self setupTable];
    
    [self checkContactsForMatching];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangeOrientationNotification:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];

}

- (void)didChangeOrientationNotification:(NSNotification *)notification {
  
    if (self.parentView) {
        if (self.top && self.left && self.right && self.bottom) {
            [self.parentView removeConstraints:@[self.top,
                                                 self.left,
                                                 self.right,
                                                 self.bottom]];
        }
        
        
        self.top = [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.parentView attribute:NSLayoutAttributeTop multiplier:1.0f constant:0.0f];
        self.left = [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.parentView attribute:NSLayoutAttributeLeading multiplier:1.0f constant:0.0f];
        self.right = [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.parentView attribute:NSLayoutAttributeTrailing multiplier:1.0f constant:0.0f];
        self.bottom = [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.parentView attribute:NSLayoutAttributeBottom multiplier:1.0f constant:0.0f];
        
        [self.parentView addConstraints:@[self.top,
                                          self.left,
                                          self.right,
                                          self.bottom]];

        [self.parentView updateConstraints];
        
        
        CGFloat height = 0.f;
        
        if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
            height = self.tableView.contentSize.height > kValueMaxTableViewHeightForPortrait ? kValueMaxTableViewHeightForPortrait : self.tableView.contentSize.height;
            if (height < kValueMaxTableViewHeightForPortrait)
                self.tableView.scrollEnabled = NO;
        } else {
            height = self.tableView.contentSize.height > kValueMaxTableViewHeightForLandscape ? kValueMaxTableViewHeightForLandscape : self.tableView.contentSize.height;
            if (height < kValueMaxTableViewHeightForLandscape)
                self.tableView.scrollEnabled = NO;
        }
        
        for (NSLayoutConstraint *item in self.tableView.constraints) {
            if (item.firstAttribute == NSLayoutAttributeHeight) {
                item.constant = height;
                break;
            }
        }
        [self.parentView updateConstraints];
        
        __weak __block typeof(self) weakSelf = self;
        
        [UIView animateKeyframesWithDuration:0.9 delay:0.0 options:UIViewKeyframeAnimationOptionAllowUserInteraction | UIViewKeyframeAnimationOptionLayoutSubviews | UIViewKeyframeAnimationOptionCalculationModeCubic animations:^{
            weakSelf.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.35f];
            
            [UIView addKeyframeWithRelativeStartTime:0.25 relativeDuration:0.25 animations:^{
                [UIView animateWithDuration:0.5 delay:0.15 usingSpringWithDamping:1.0 initialSpringVelocity:1.0 options:0 animations:^{
                    
                    for (NSLayoutConstraint *item in weakSelf.view.constraints) {
                        if (item.firstAttribute == NSLayoutAttributeBottom && item.firstItem == weakSelf.cancelButton) {
                            item.constant = -8;
                            break;
                        }
                    }
                    
                    [weakSelf.view layoutIfNeeded];
                } completion:^(BOOL finished) {
                }];
                
            }];
        } completion:^(BOOL finished) {
            [weakSelf setupControlView];
        }];
    } else {
        [self dismissView];
    }
}

#pragma mark - public


- (void)presentInView:(UIView *)parentView animated:(BOOL)animated withErrorHandler:(ContactActionSheetErrorBlock)handler {
    
    if (self.phoneNumbers.count == 0) {
        return handler(NO, nil);
    }
    
    for (UIView *subView in parentView.subviews) {
        if (subView.tag == actionSheetViewTag) {
            [subView removeFromSuperview];
        }
    }
    
    self.parentView = parentView;
    self.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    [parentView addSubview:self.view];
    self.top = [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.parentView attribute:NSLayoutAttributeTop multiplier:1.0f constant:0.0f];
    self.left = [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.parentView attribute:NSLayoutAttributeLeading multiplier:1.0f constant:0.0f];
    self.right = [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.parentView attribute:NSLayoutAttributeTrailing multiplier:1.0f constant:0.0f];
    self.bottom = [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.parentView attribute:NSLayoutAttributeBottom multiplier:1.0f constant:0.0f];
    
    [self.parentView addConstraints:@[self.top,
                                      self.left,
                                      self.right,
                                      self.bottom]];
    
    [parentView updateConstraints];
    
    self.view.backgroundColor = [UIColor clearColor];
    
    CGFloat height = 0.f;
    
    if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
        height = self.tableView.contentSize.height > kValueMaxTableViewHeightForPortrait ? kValueMaxTableViewHeightForPortrait : self.tableView.contentSize.height + 15;
        if (height < kValueMaxTableViewHeightForPortrait)
            self.tableView.scrollEnabled = NO;
    } else {
    height = self.tableView.contentSize.height > kValueMaxTableViewHeightForLandscape ? kValueMaxTableViewHeightForLandscape : self.tableView.contentSize.height;
        if (height < kValueMaxTableViewHeightForLandscape)
            self.tableView.scrollEnabled = NO;
    }
    
    for (NSLayoutConstraint *item in self.tableView.constraints) {
        if (item.firstAttribute == NSLayoutAttributeHeight) {
            item.constant = height;
            break;
        }
    }
    [parentView updateConstraints];
    
    __weak __block typeof(self) weakSelf = self;
    
    [UIView animateKeyframesWithDuration:0.9 delay:0.0 options:UIViewKeyframeAnimationOptionAllowUserInteraction | UIViewKeyframeAnimationOptionLayoutSubviews | UIViewKeyframeAnimationOptionCalculationModeCubic animations:^{
        weakSelf.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.35f];
        
        [UIView addKeyframeWithRelativeStartTime:0.25 relativeDuration:0.25 animations:^{
            [UIView animateWithDuration:0.5 delay:0.15 usingSpringWithDamping:1.0 initialSpringVelocity:1.0 options:0 animations:^{
                
                for (NSLayoutConstraint *item in weakSelf.view.constraints) {
                    if (item.firstAttribute == NSLayoutAttributeBottom && item.firstItem == weakSelf.cancelButton) {
                        item.constant = -8;
                        break;
                    }
                }
                
                [weakSelf.view layoutIfNeeded];
            } completion:^(BOOL finished) {
            }];
            
        }];
    } completion:^(BOOL finished) {
        [weakSelf setupControlView];
        handler(YES, nil);
    }];
}

- (void)setupControlView {
    
    CGRect frame = self.view.bounds;
    frame.size.height -= self.tableView.frame.size.height + self.cancelButton.bounds.size.height + 16;
    
    if (!self.control) {
        
        self.control = [[UIControl alloc] initWithFrame:frame];
        [self.control addTarget:self action:@selector(onTap) forControlEvents:UIControlEventTouchDown];
        [self.view addSubview:self.control];
        
    } else {
        self.control.frame = frame;
    }
}

#pragma mark - UIGestureRecognizer

- (void)onTap {
    
    [UIView animateKeyframesWithDuration:0.9 delay:0.0 options:UIViewKeyframeAnimationOptionAllowUserInteraction | UIViewKeyframeAnimationOptionLayoutSubviews | UIViewKeyframeAnimationOptionCalculationModeCubic animations:^{
        self.view.backgroundColor = [UIColor clearColor];
        
        [UIView addKeyframeWithRelativeStartTime:0.25 relativeDuration:0.25 animations:^{
            [UIView animateWithDuration:0.5 delay:0.15 usingSpringWithDamping:1.0 initialSpringVelocity:1.0 options:0 animations:^{
                
                for (NSLayoutConstraint *constraint in self.view.constraints) {
                    if (constraint.firstItem == self.cancelButton && constraint.firstAttribute == NSLayoutAttributeBottom) {
                        constraint.constant = [UIScreen mainScreen].bounds.size.height + self.tableView.height + 16;
                        break;
                    }
                }
                
                [self.view layoutIfNeeded];
            } completion:^(BOOL finished) {
                
            }];
            
        }];
    } completion:^(BOOL finished) {
        [self dismissView];
    }];
}
- (void)dismissView {
    [self.view removeFromSuperview];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ContactsActionSheetDismissed" object:self];
}

- (void)onQliqAssistedCall:(UIButton *)button {
    NSString *phone = self.selectedPhone;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(actionSheet:onQliqAssistedCallTo:)]) {
        [self.delegate actionSheet:self onQliqAssistedCallTo:phone];
    }
    
    [self onTap];
}

- (void)onDirectCall:(UIButton *)button {
    NSString *phone = self.selectedPhone;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(actionSheet:onDirectCallTo:)]) {
        [self.delegate actionSheet:self onDirectCallTo:phone];
    }
    
    [self onTap];
}

#pragma mark - UITableViewDataSorce/UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == self.selectedPhoneIndex) {
        
        return heightForSelectedRow;
    }
    return heightForNonSelectedRow;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [self.phoneNumbers count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    ContactPhoneCell *cell = nil;
    NSString *fName = self.phoneNumbers[indexPath.row][@"firstName"];
    NSString *lName = self.phoneNumbers[indexPath.row][@"lastName"];
    NSString *name = @"";
    if (fName && lName)
        name = [fName stringByAppendingFormat:@" %@", lName];
    else if (fName)
        name = fName;
    else if (lName)
        name = lName;
    
    static NSString *reuseIdentifire = @"ContactPhoneCell";
    ContactPhoneCell *customCell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifire];
    customCell.titleLabel.text = name;
    customCell.subTitleLabel.text = self.phoneNumbers[indexPath.row][@"phone"];
    customCell.typeLabel.text = self.phoneNumbers[indexPath.row][@"label"];
    customCell.phoneButton.hidden = NO;
    
    [customCell.anonymousCallButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    [customCell.anonymousCallButton addTarget:self action:@selector(onQliqAssistedCall:) forControlEvents:UIControlEventTouchUpInside];
    customCell.anonymousCallButton.tag = indexPath.row;
    
    [customCell.withCalledIDButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    [customCell.withCalledIDButton addTarget:self action:@selector(onDirectCall:) forControlEvents:UIControlEventTouchUpInside];
    customCell.withCalledIDButton.tag = indexPath.row;
    
    cell = customCell;
    cell.clipsToBounds = YES;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    self.tableView.scrollEnabled = YES;
    
    NSInteger prev = self.selectedPhoneIndex;
    self.selectedPhone = self.phoneNumbers[indexPath.row][@"phone"];
    
    if (prev != NSNotFound){
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:prev inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        
    } else {
        
        BOOL upTable = NO;
        CGFloat tableViewHeightDifference =  heightForSelectedRow - heightForNonSelectedRow;
        CGFloat tableViewHeight = self.tableView.frame.size.height + tableViewHeightDifference;

        if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
            tableViewHeight = tableViewHeight > kValueMaxTableViewHeightForPortrait ? kValueMaxTableViewHeightForPortrait : tableViewHeight;
            if (tableViewHeight < kValueMaxTableViewHeightForPortrait) {
                self.tableView.scrollEnabled = NO;
                upTable = YES;
            }
        } else {
            tableViewHeight = tableViewHeight > kValueMaxTableViewHeightForLandscape ? kValueMaxTableViewHeightForLandscape : tableViewHeight;
            if (tableViewHeight < kValueMaxTableViewHeightForLandscape) {
                self.tableView.scrollEnabled = NO;
                upTable = YES;
            }
        }
        
                      
        [UIView animateWithDuration:0.3 delay:0.0 options:nil animations:^{
            
            self.tableView.frame = CGRectMake(tableView.frame.origin.x,
                                              tableView.frame.origin.y - (upTable ? tableViewHeightDifference : 0.0),
                                              tableView.frame.size.width, tableViewHeight);
            [self setupControlView];
            [self.tableView updateConstraints];
            [self.view layoutSubviews];
        } completion:nil];
    }
    
    self.selectedPhoneIndex = indexPath.row;
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - private

- (void)setupTable {
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button setBackgroundImage:[UIImage imageNamed:@"AlertButton"] forState:UIControlStateNormal];
    button.frame = CGRectMake(8, [UIScreen mainScreen].bounds.size.height + 200 + 16, [UIScreen mainScreen].bounds.size.width - 16, 30);
    [button addTarget:self action:@selector(onTap) forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"Cancel" forState:UIControlStateNormal];
    [self.view addSubview:button];
    
    self.cancelButton = button;
    
    NSLayoutConstraint *leadig = [NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeading multiplier:1.0f constant:8.0f];
    NSLayoutConstraint *trailing = [NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTrailing multiplier:1.0f constant:-8.0f];
    NSLayoutConstraint *bottom = [NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0f constant:-200.0f - 8];
    NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:30.0f];
    [self.view addConstraints:@[leadig, bottom, trailing]];
    [button addConstraint:height];
    
    CGRect frame = self.view.bounds;
    frame.size.height = 200;
    frame.origin.x = 8;
    frame.size.width -= 16;
    frame.origin.y = [UIScreen mainScreen].bounds.size.height + 8;
    self.tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
    self.tableView.tableFooterView = [UIView new];
    self.tableView.separatorInset = UIEdgeInsetsZero;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.layer.cornerRadius = 5;
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    UINib *nib = [UINib nibWithNibName:@"ContactPhoneCell" bundle:[NSBundle mainBundle]];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"ContactPhoneCell"];
    [self.view addSubview:self.tableView];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"CancelTableViewCell"];
    
    //    NSLayoutConstraint *top = [NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0f constant:[UIScreen mainScreen].bounds.size.height];
    NSLayoutConstraint *leading = [NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeading multiplier:1.0f constant:8.f];
    trailing = [NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTrailing multiplier:1.0f constant:-8.f];
    height = [NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:200.0f];
    bottom = [NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:button attribute:NSLayoutAttributeTop multiplier:1.0f constant:-8.f];
    [self.view addConstraints:@[/*top, */leading, trailing, bottom]];
    [self.tableView addConstraint:height];
    
    [self.view updateConstraintsIfNeeded];
}

- (void)checkContactsForMatching {
    
    __weak __block typeof(self) welf = self;
    __block BOOL needWait = YES;
    
    dispatch_group_t access = dispatch_group_create();
    
    if (is_ios_greater_or_equal_9() && [CNContactStore class])
    {
        CNEntityType entityType = CNEntityTypeContacts;
        __block CNContactStore * contactStore = [[CNContactStore alloc] init];

        if([CNContactStore authorizationStatusForEntityType:entityType] == CNAuthorizationStatusNotDetermined)
        {
            dispatch_group_enter(access);
            [contactStore requestAccessForEntityType:entityType completionHandler:^(BOOL granted, NSError * _Nullable error)
             {
                 if(granted) {
                     [welf getMatchedContactsWithCNContactsStore:contactStore];
                 } else {
                     DDLogSupport(@"CNContactStore requestAccessForEntityType: Not Granted");
                     if (error) {
                         DDLogError(@"%@", [error localizedDescription]);
                     }
                 }
                  dispatch_group_leave(access);
             }];
        } else if( [CNContactStore authorizationStatusForEntityType:entityType] == CNAuthorizationStatusAuthorized) {
             needWait = NO;
            [self getMatchedContactsWithCNContactsStore:contactStore];
        } else {
            needWait = NO;
            if ([CNContactStore authorizationStatusForEntityType:entityType] == CNAuthorizationStatusDenied)
                DDLogSupport(@"CNContactStore authorizationStatusForEntityType: CNEntityTypeContacts - CNAuthorizationStatusDenied");
            else if ([CNContactStore authorizationStatusForEntityType:entityType] == CNAuthorizationStatusRestricted)
                DDLogSupport(@"CNContactStore authorizationStatusForEntityType: CNEntityTypeContacts - CNAuthorizationStatusRestricted");
            
            [self getPhonesWithoutDeviceContacts];
        }
    } else {
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        if (addressBook)
        {
            if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined)
            {
                dispatch_group_enter(access);
                ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error)
                {
                    if (granted)
                    {
                        [welf getMatchedContactsWithABAddressBook:addressBook];
                        if (addressBook)
                            CFRelease(addressBook);
                    } else {
                        DDLogSupport(@"CNContactStore requestAccessForEntityType: Not Granted");
                        if (error) {
                            NSError *nsError = CFBridgingRelease(error);
                            DDLogError(@"%@", [nsError localizedDescription]);
                        }
                    }
                    dispatch_group_leave(access);
                });
            } else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
                needWait = NO;
                [self getMatchedContactsWithABAddressBook:addressBook];
                if (addressBook)
                    CFRelease(addressBook);
            } else {
                needWait = NO;
                if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied)
                    DDLogSupport(@"ABAddressBookGetAuthorizationStatus - kABAuthorizationStatusDenied");
                else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusRestricted)
                    DDLogSupport(@"ABAddressBookGetAuthorizationStatus - kABAuthorizationStatusRestricted");
                
                [self getMatchedContactsWithABAddressBook:nil];
            }
        }
        else
        {
            needWait = NO;
            DDLogSupport(@"ABAddressBookRef = nil");
            
            [self getMatchedContactsWithABAddressBook:nil];
        }
    }
    
    if (needWait) {
        dispatch_group_wait(access, DISPATCH_TIME_FOREVER);
    }
}


- (void)getPhonesWithoutDeviceContacts {
    for (Contact * qliqContact in self.contacts)
    {
        [self mergePhones:nil forContact:qliqContact];
    }
}

- (void)getMatchedContactsWithCNContactsStore:(CNContactStore *)contactStore
{
        NSError * contactError = nil;
        [contactStore containersMatchingPredicate:[CNContainer predicateForContainersWithIdentifiers:@[contactStore.defaultContainerIdentifier]] error:&contactError];
        if (contactError) {
            DDLogError(@"%@", [contactError localizedDescription]);
            
            [self getPhonesWithoutDeviceContacts];
        } else {
            NSArray *keysToFetch = @[CNContactGivenNameKey,
                                     CNContactFamilyNameKey,
                                     CNContactPhoneNumbersKey];
            
            CNContactFetchRequest *fetchRequest = [[CNContactFetchRequest alloc] initWithKeysToFetch:keysToFetch];
            
            for (Contact * qliqContact in self.contacts) {
                
                NSArray *phones = [self getPhonesWithFirstName:qliqContact.firstName
                                                      lastName:qliqContact.lastName
                                              fromContactStore:contactStore
                                              withFetchRequest:fetchRequest];
                
                [self mergePhones:phones forContact:qliqContact];
            }
        }
}

- (NSArray *)getPhonesWithFirstName:(NSString *)qliqContactFirstName
                           lastName:(NSString *)qliqContactLastName
                   fromContactStore:(CNContactStore *)contactStore
                   withFetchRequest:(CNContactFetchRequest *)fetchRequest {
    
    NSMutableArray *unsorted = [NSMutableArray new];
    NSError * enumerationError = nil;
    
    if ([CNContactStore class]) {
        
        BOOL success = [contactStore enumerateContactsWithFetchRequest:fetchRequest error:&enumerationError usingBlock:^(CNContact * _Nonnull iPhoneContact, BOOL * _Nonnull stop) {
            
            if (([iPhoneContact.familyName length] && [iPhoneContact.familyName isEqualToString:qliqContactLastName] && [iPhoneContact.givenName length] && [iPhoneContact.givenName isEqualToString:qliqContactFirstName]) ||
                ([iPhoneContact.familyName length] && [iPhoneContact.familyName isEqualToString:qliqContactLastName] && [iPhoneContact.givenName length] == 0) ||
                ([iPhoneContact.givenName length] && [iPhoneContact.givenName isEqualToString:qliqContactFirstName] && [iPhoneContact.familyName length] == 0))
            {
                NSArray *phones = iPhoneContact.phoneNumbers;
                if (0 != [phones count])
                {
                    for (int i = 0; i < [phones count]; ++i) {
                        
                        NSMutableDictionary *info = [NSMutableDictionary new];
                        if ([iPhoneContact.familyName length])
                            info[@"lastName"] = iPhoneContact.familyName;
                        if ([iPhoneContact.givenName length])
                            info[@"firstName"] = iPhoneContact.givenName;
                        
                        id item = phones[i];
                        
                        if ([item isKindOfClass:[CNLabeledValue class]]) {
                            CNLabeledValue *phone = (CNLabeledValue *)item;
                            NSString *label = phone.label;
                            label = [label stringByReplacingOccurrencesOfString:@"_$!<" withString:@""];
                            label = [label stringByReplacingOccurrencesOfString:@">!$_" withString:@""];
                            info[@"label"] = label;
                            
                            if ([phone.value isKindOfClass:[CNPhoneNumber class]]) {
                                CNPhoneNumber *phoneNumber = (CNPhoneNumber *)phone.value;
                                info[@"phone"] = phoneNumber.stringValue;
                            }
                        }
                        
                        [unsorted addObject:info];
                    }
                }
                *stop = YES;
            }
        }];
        
        [self sortPhones:unsorted];
        
        if (success) {
            return [unsorted copy];
        } else if (enumerationError) {
            DDLogError(@"%@", [enumerationError localizedDescription]);
        }
    }
    
    return nil;
}

- (void)sortPhones:(NSMutableArray *)unsorted {
    if (unsorted) {
        [unsorted sortUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
            NSString *lName1 = obj1[@"lastName"];
            NSString *lName2 = obj2[@"lastName"];
            NSString *fName1 = obj1[@"firstName"];
            NSString *fName2 = obj2[@"firstName"];
            
            NSComparisonResult result = [fName1 compare:fName2];
            switch (result) {
                case NSOrderedSame:
                    result = [lName1 compare:lName2];
                    break;
                case NSOrderedAscending:
                    result = [lName2 compare:lName1];
                    break;
                case NSOrderedDescending:
                    result = [lName2 compare:lName1];
                    break;
                default:
                    break;
            }
            
            return result;
        }];
    }
}

- (void)getMatchedContactsWithABAddressBook:(ABAddressBookRef)addressBook {
    
    for (Contact *contact in self.contacts) {
        
        NSArray *phones = nil;
        
        if (addressBook) {
            NSString *fName = contact.firstName;
            NSString *lName = contact.lastName;
            
            phones = [self getPhonesWithFirstName:fName lastName:lName fromABAddressBook:addressBook];
        }
        
        [self mergePhones:phones forContact:contact];
    }
    
}

- (NSArray *)getPhonesWithFirstName:(NSString *)qliqContactFirstName
                           lastName:(NSString *)qliqContactLastName
                  fromABAddressBook:(ABAddressBookRef)addressBook {
    
    NSArray *contacts = (__bridge_transfer NSArray *)ABAddressBookCopyArrayOfAllPeople(addressBook);
    
    NSMutableArray *unsorted = [NSMutableArray new];
    
    if (contacts) {
        for (int i = 0; i < [contacts count]; ++i) {
            ABRecordRef item = (__bridge ABRecordRef)(contacts[i]);
            NSString *firstName = (__bridge_transfer NSString *)ABRecordCopyValue(item, kABPersonFirstNameProperty);
            NSString *lastName = (__bridge_transfer NSString *)ABRecordCopyValue(item, kABPersonLastNameProperty);
            
            BOOL matched = NO;
            // If first and last name matches it is a match
            // If Last name does not exist in address book then it is a match
            //
            if (([lastName length] && [lastName isEqualToString:qliqContactLastName] && [firstName length] && [firstName isEqualToString:qliqContactFirstName]) ||
                ([lastName length] && [lastName isEqualToString:qliqContactLastName] && [firstName length] == 0) ||
                ([firstName length] && [firstName isEqualToString:qliqContactFirstName] && [lastName length] == 0))
                matched = YES;
            
            if (matched) {
                
                ABMultiValueRef multiRec = ABRecordCopyValue(item, kABPersonPhoneProperty);
                
                if (multiRec) {
                    NSArray *phones = (__bridge_transfer NSArray *)ABMultiValueCopyArrayOfAllValues(multiRec);
                    if (0 == [phones count])
                        continue;
                    
                    for (int i = 0; i < [phones count]; ++i) {
                        
                        NSMutableDictionary *info = [NSMutableDictionary new];
                        if ([lastName length])
                            info[@"lastName"] = lastName;
                        if ([firstName length])
                            info[@"firstName"] = firstName;
                        
                        info[@"phone"] = phones[i];
                        
                        NSString *label = (__bridge_transfer NSString *)ABMultiValueCopyLabelAtIndex(multiRec, i);
                        label = [label stringByReplacingOccurrencesOfString:@"_$!<" withString:@""];
                        label = [label stringByReplacingOccurrencesOfString:@">!$_" withString:@""];
                        info[@"label"] = label;
                        
                        [unsorted addObject:info];
                    }
                }
                break;
            }
        }
        
        [self sortPhones:unsorted];
    }
    
    if (unsorted) {
        return [unsorted copy];
    }
    
    return nil;
}

- (void)mergePhones:(NSArray *)phones forContact:(Contact *)contact {
    
    NSMutableArray *result = [NSMutableArray new];
    
    if (0 != [contact.mobile length]) {
        
        NSMutableDictionary *item = [NSMutableDictionary new];
        if ([contact.firstName length])
            item[@"firstName"] = contact.firstName;
        if ([contact.lastName length])
            item[@"lastName"] = contact.lastName;
        item[@"phone"] = contact.mobile;
        item[@"label"] = @"Mobile";
        
        [result addObject:item];
        
    }
    
    if (0 != [contact.phone length]) {
        
        NSMutableDictionary *item = [NSMutableDictionary new];
        if ([contact.firstName length])
            item[@"firstName"] = contact.firstName;
        if ([contact.lastName length])
            item[@"lastName"] = contact.lastName;
        item[@"phone"] = contact.phone;
        item[@"label"] = @"Phone";
        
        [result addObject:item];
    }
    
    if (phones) {
        [result insertObjects:phones atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [phones count])]];
    }
    
    [self.phoneNumbers addObjectsFromArray:result];
}

@end
