//
//  ContactTableCell.m
//  qliq
//
//  Created by Valery Lider on 9/23/14.
//
//



/**
 Services
 */
#import "ContactAvatarService.h"
#import "QliqGroupDBService.h"
#import "QliqListService.h"

#import "QliqGroup.h"
#import "OnCallGroup.h"
#import "ContactList.h"
#import "StatusView.h"

#import "MLPAutoCompleteTextField.h"
#import "RoleTextFieldDataSourceObject.h"

#import "ContactTableCell.h"

#define kValueWidthOptionButton 58.f;

#define kActiveColor RGBa(0, 120, 174, 1)
#define kInactiveColor [[UIColor alloc] initWithWhite:0.5 alpha:1.0]

NSString * const ContactTableCellId = @"ContactTableViewCellReuseId";

typedef NS_ENUM(NSInteger, OptionsButton) {
    OptionsButtonMessage,
    OptionsButtonPhone,
    OptionsButtonFavorite,
    OptionsButtonDelete,
    OptionsButtonCount
};

@interface ContactTableCell() <UITextFieldDelegate, MLPAutoCompleteTextFieldDataSource, MLPAutoCompleteTextFieldDelegate>

/**
 IBOutlet
 */
//AvatarView
@property (weak, nonatomic) IBOutlet UIView *avatarView;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet StatusView *statusView;

//ContactInfoView
@property (weak, nonatomic) IBOutlet UILabel *nameContact;
@property (weak, nonatomic) IBOutlet UILabel *statusContact;
@property (weak, nonatomic) IBOutlet UILabel *presenceStatusLabel;


@property (weak, nonatomic) IBOutlet MLPAutoCompleteTextField *roleTextField;
@property (strong, nonatomic) RoleTextFieldDataSourceObject *roleDataSource;

//OptionsView
@property (weak, nonatomic) IBOutlet UIButton *optionMessage;
@property (weak, nonatomic) IBOutlet UIButton *optionPhone;
@property (weak, nonatomic) IBOutlet UIButton *optionFavorite;
@property (weak, nonatomic) IBOutlet UIButton *optionDelete;

//ButtonView
@property (weak, nonatomic) IBOutlet UIView *buttonView;
@property (weak, nonatomic) IBOutlet UIButton *rightButton;

@property (weak, nonatomic) IBOutlet UIButton *removeContact;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *presenceTrallingEqualToStatusTrallingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *removeContactButtonWidthConstraint;

/* Constraint */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *widthOptionsViewConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *widthMessageOptionButtonConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *widthPhoneOptionButtonConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *widthFavoriteOptionButtonConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *widthDeleteOptionButtonConstraint;

//ContactInfo
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textLabelYCenterConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *nameLabelBotConstraint;

/** Data */
@property (nonatomic, strong) id item;

@end

@implementation ContactTableCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
    }
    return self;
}

- (void)awakeFromNib {
    
    [super awakeFromNib];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;

    [self configureBackroundColor:[UIColor whiteColor]];
    
    self.rightButton.layer.masksToBounds = YES;
    self.rightButton.clipsToBounds = YES;
    self.rightButton.layer.cornerRadius = 10.f;
    self.rightButton.layer.borderWidth = 1.f;
    self.rightButton.layer.borderColor = [kColorDarkBlue CGColor];
    
    self.removeContact.layer.masksToBounds = YES;
    self.removeContact.clipsToBounds = YES;
    self.removeContact.layer.cornerRadius = 5.f;
    self.removeContact.layer.borderWidth = 1.f;
    self.removeContact.layer.borderColor = [kColorDarkBlue CGColor];

    
    [self prepareForReuse];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    
    self.item = nil;
    
    self.avatarImageView.image = nil;

    self.statusView.hidden = YES;
    
    self.nameContact.text = @"";
    
    
    self.statusContact.text = @"";
    
    self.roleTextField.hidden = YES;
    self.roleTextField.text = @"";

    self.presenceStatusLabel.text = @"";
    
    //ButtonView
    self.buttonView.hidden = YES;
    
    
    [self.rightButton setTitle:@"" forState:UIControlStateNormal];
    
    self.widthMessageOptionButtonConstraint.constant = 0.f;
    self.widthPhoneOptionButtonConstraint.constant = 0.f;
    self.widthFavoriteOptionButtonConstraint.constant = 0.f;
    self.widthDeleteOptionButtonConstraint.constant = 0.f;
}

#pragma mark - Setters

#pragma mark - Public

- (void)setCell:(id)item
{
    self.item = item;
    
    [self configureOptionsView:item];
    
    RecipientType type = [[QliqAvatar sharedInstance]returnRecipientType:item];
    switch (type) {
        case RecipientTypeOnCallGroup:
        case RecipientTypeQliqGroup:
        case RecipientTypePersonalGroup: {
            
            QliqGroup *group = item;
           
            self.nameContact.text = [self getGroupName:[group name]];
            
            if (type == RecipientTypeQliqGroup) {
                self.statusContact.text = QliqLocalizedString(@"2123-TitleOrganizationGroup");
                self.nameContact.textColor =  kActiveColor;
                
                if (group.openMembership) {
                    self.buttonView.hidden = NO;
                    
                    NSString *titleButton = @"";
                    if (group.belongs) {
                        titleButton = QliqLocalizedString(@"48-ButtonLeave");
                    }
                    else {
                        titleButton = QliqLocalizedString(@"47-ButtonJoin");
                    }
                    
                    [self.rightButton setTitle:titleButton forState:UIControlStateNormal];
                }
            }
            else if (type == RecipientTypeOnCallGroup) {
                self.nameContact.textColor = [UIColor darkGrayColor];
            }
            break;
        }
        case RecipientTypeQliqUser:
       case RecipientTypeContact: {
           
           NSString *roleOfSomeUser = @"";
            Contact *contact = item;
            
            self.nameContact.text = [contact nameDescription];
            
            if ([contact isKindOfClass:[QliqUser class]])
            {
                QliqUser *user = item;
                
                if ([user.qliqId isEqualToString:[UserSessionService currentUserSession].user.qliqId]) {
                    user = [UserSessionService currentUserSession].user;
                    user.presenceStatus = [QliqUser presenceStatusFromString:[UserSessionService currentUserSession].userSettings.presenceSettings.currentPresenceType];
                    user.presenceMessage = [[QliqAvatar sharedInstance] getSelfPresenceMessage];
                }
                if (self.delegate && [self.delegate respondsToSelector:@selector(isCareChannel)]) {
                    
                    if ([self.delegate isCareChannel]) {
                        if (self.delegate && [self.delegate respondsToSelector:@selector(getRoleForCareChannelWithUser:)]) {
                            roleOfSomeUser = [self.delegate getRoleForCareChannelWithUser:user];
                            [self setupAutoCompleteTextField:roleOfSomeUser];
                        }
                    }
                }
                
                self.statusContact.text = roleOfSomeUser.length > 0 ? roleOfSomeUser : user.profession;
                
                self.statusView.hidden = NO;
                self.statusView.statusColorView.backgroundColor = [[QliqAvatar sharedInstance] colorForPresenceStatus:user.presenceStatus];
                
                self.nameContact.textColor = [user isActive] ? kActiveColor : kInactiveColor;
                self.presenceStatusLabel.textColor = [[QliqAvatar sharedInstance] colorShadowForPresenceStatus:user.presenceStatus];;
                self.presenceStatusLabel.text = [[QliqAvatar sharedInstance] getPrecenseStatusMessage:user];
            }
            else {
                self.statusContact.text = contact.groupName;
            }
            
            break;
        }
        default: {
            
            self.nameContact.text = [item recipientTitle];
            self.nameContact.textColor = kInactiveColor;
            
            break;
        }
    }
    [self configureContactInfoConstraints];
    
    //Set Avatar
    self.avatarImageView.image = [[ QliqAvatar sharedInstance] getAvatarForItem:item withTitle:nil];
}

- (void)setupAutoCompleteTextField:(NSString *)roleString; {
    
    self.roleTextField.hidden = NO;
    self.statusContact.hidden = YES;
    
    self.roleDataSource = [RoleTextFieldDataSourceObject shared];
    
    [self.roleTextField setBorderStyle:UITextBorderStyleRoundedRect];
    [self.roleTextField setAutoCompleteDataSource:self];
    [self.roleTextField setAutoCompleteTableAppearsAsKeyboardAccessory:YES];
    [self.roleTextField setAutoCompleteTableBackgroundColor:RGBa(235, 235, 235, 0.7f)];
    [self.roleTextField setClearButtonMode:UITextFieldViewModeWhileEditing];
    
    [self.roleTextField setShowAutoCompleteTableWhenEditingBegins:YES];
    [self.roleTextField setShouldResignFirstResponderFromKeyboardAfterSelectionOfAutoCompleteRows:NO];
    
    self.roleTextField.placeholder = QliqLocalizedString(@"2364-TitleRole");
    self.roleTextField.delegate = self;
    self.roleTextField.autoCompleteDelegate = self;
    
    if (roleString.length > 0) {
       self.roleTextField.text = roleString;
    }
}

- (void)configureBackroundColor:(UIColor *)color {
    self.backgroundColor = color;
    self.contentView.backgroundColor = color;
    self.avatarView.backgroundColor = color;
    self.buttonView.backgroundColor = color;
}

- (void)setRightArrowHidden:(BOOL)hidden {
    self.rightArrow.hidden = hidden;
    self.buttonView.hidden = !hidden;
}

- (void)setRemoveButtonHidden:(BOOL)hidden {
    self.removeContact.hidden = hidden;
    self.presenceTrallingEqualToStatusTrallingConstraint.constant = - self.removeContactButtonWidthConstraint.constant;
    [self layoutIfNeeded];
}

#pragma mark - Private -

- (void)setActiveCellIndex {
    if (self.delegate && [self.delegate respondsToSelector:@selector(indexOfActiveCell:)]) {
        [self.delegate indexOfActiveCell:self];
    }
}

- (void)showButton:(OptionsButton)button {
    CGFloat width = self.widthOptionsViewConstraint.constant / OptionsButtonCount;
    
    switch (button) {
        case OptionsButtonMessage: {
            self.widthMessageOptionButtonConstraint.constant = width;
            break;
        }
        case OptionsButtonPhone: {
            self.widthPhoneOptionButtonConstraint.constant = width;
            break;
        }
        case OptionsButtonFavorite: {
            self.widthFavoriteOptionButtonConstraint.constant = width;
            break;
        }
        case OptionsButtonDelete: {
            self.widthDeleteOptionButtonConstraint.constant = width;
            break;
        }
        default:
            break;
    }
}

- (BOOL)itemIsGroup
{
    BOOL isGroup = NO;
    
    if ([self.item isKindOfClass:[QliqGroup class]] || [self.item isKindOfClass:[ContactList class]])
        isGroup = YES;
    
    return isGroup;
}

- (void)configureOptionsView:(id)item {
    RecipientType type = [[QliqAvatar sharedInstance]returnRecipientType:item];
    switch (type) {
        case RecipientTypeOnCallGroup: {
            [self showButton:OptionsButtonMessage];
            break;
        }
        case RecipientTypeQliqGroup: {
            [self showButton:OptionsButtonMessage];
            break;
        }
        case RecipientTypePersonalGroup: {
            [self showButton:OptionsButtonDelete];
            break;
        }
        case RecipientTypeQliqUser: {
            [self showButton:OptionsButtonMessage];
            [self showButton:OptionsButtonPhone];
            [self showButton:OptionsButtonFavorite];
            [self showButton:OptionsButtonDelete];
        }
        case RecipientTypeContact: {
            [self showButton:OptionsButtonMessage];
            [self showButton:OptionsButtonPhone];
            [self showButton:OptionsButtonDelete];
            break;
        }
        default: {
            break;
        }
    }
}

- (void)configureContactInfoConstraints
{
    CGFloat centerYOffset = 0.f;
    CGFloat nameBotOffset = 0.f;
    
    CGFloat labelHeight = 20.f;
    
    if ([self.nameContact.text length] > 0 && [self.statusContact.text length] > 0 && [self.presenceStatusLabel.text length] == 0) {
        if (self.roleTextField.hidden) {
            centerYOffset = -(labelHeight/2);
        }
        
    }
    else if ([self.nameContact.text length] > 0 && [self.statusContact.text length] == 0 && [self.presenceStatusLabel.text length] == 0) {
        if (self.roleTextField.hidden) {
            centerYOffset = -labelHeight;
        }

       
    }
    else if ([self.nameContact.text length] > 0 && [self.statusContact.text length] == 0 && [self.presenceStatusLabel.text length] > 0) {
        if (self.roleTextField.hidden) {
            nameBotOffset = -labelHeight;
        }
    }
   
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.3f animations:^{
        weakSelf.nameLabelBotConstraint.constant = nameBotOffset;
        weakSelf.textLabelYCenterConstraint.constant = centerYOffset;
    }];
}

#pragma mark - Get...

- (NSString *)getGroupName:(NSString *)name
{
    NSString * acronym = nil;
    NSRange dotRange = [name rangeOfString:@" • "];
    
    if (dotRange.length > 0)
    {
        NSRange acronymRange;
        acronymRange.location = 0;
        acronymRange.length = dotRange.location + dotRange.length;
        
        NSRange nameRange;
        nameRange.location = dotRange.location + dotRange.length;
        nameRange.length = [name length] - nameRange.location;
        
        acronym = [name substringWithRange:acronymRange];
        name = [name substringWithRange:nameRange];
    }
    
    NSString *finalName = @"";
    if (acronym)
        finalName = [NSString stringWithFormat:@"%@ %@", acronym, name];
    else
        finalName = name;
    
    return finalName;
}

#pragma mark - Hide options

- (void)hideOptions
{
    [UIView animateWithDuration:0.5 animations:^{
        
        self.optionsView.frame = CGRectMake(self.bounds.size.width + 20.f,
                                            self.optionsView.frame.origin.y,
                                            self.optionsView.frame.size.width,
                                            self.optionsView.frame.size.height);
        
        self.contactInfoView.frame = CGRectMake(self.avatarView.frame.size.width,
                                                self.optionsView.frame.origin.y,
                                                self.optionsView.frame.size.width,
                                                self.optionsView.frame.size.height);
    } completion:^(BOOL finished) {}];
}

#pragma mark - IBActions

- (IBAction)onRightButton:(id)sender {
    
    if ([self.item isKindOfClass:[QliqGroup class]] && self.delegate) {
        
        [self.delegate pressRightButton:(QliqGroup *)self.item];
    }
}

- (IBAction)onMessagePressed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(pressMessageButton:)])
        [self.delegate pressMessageButton:self.item];
}

- (IBAction)onPhonePressed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(pressPhoneButton:)])
        [self.delegate pressPhoneButton:self.item];
}

- (IBAction)onFavoritePressed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(pressFavoriteButton:)])
        [self.delegate pressFavoriteButton:self.item];
}

- (IBAction)onDeletePressed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(pressDeleteButton:)])
        [self.delegate pressDeleteButton:self.item];
}

- (IBAction)onRemoveContactButton:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(removeContactButtonPressed:)]) {
        [self.delegate removeContactButtonPressed:self.item];
    }
}

#pragma mark - UITextField Delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    [self setActiveCellIndex];
    
    NSString *resultString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    textField.text = [resultString capitalizedString];
   
    [[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification
                                                        object:textField];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(changeParticipant:withRole:fromCell:)]) {
        [self.delegate changeParticipant:self.item withRole:textField.text fromCell:self];
    }
    
    return NO;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {

   textField.text = @"";
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification
                                                        object:textField];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(changeParticipant:withRole:fromCell:)]) {
        [self.delegate changeParticipant:self.item withRole:textField.text fromCell:self];
    }
    
    return NO;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self setActiveCellIndex];
}

#pragma mark - MLP Delegate

- (void)autoCompleteTextField:(MLPAutoCompleteTextField *)textField
  didSelectAutoCompleteString:(NSString *)selectedString
       withAutoCompleteObject:(id<MLPAutoCompletionObject>)selectedObject
            forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    DDLogSupport(@"Autocomplete table view didSelectRow");

    
    if (self.delegate && [self.delegate respondsToSelector:@selector(changeParticipant:withRole:fromCell:)]) {
        [self.delegate changeParticipant:self.item withRole:self.roleTextField.text fromCell:self];
    }

}



-(void)autoCompleteTextField:(MLPAutoCompleteTextField *)textField possibleCompletionsForString:(NSString *)string completionHandler:(void (^)(NSArray *))handler {
    
    [self.roleDataSource autoCompleteTextField:textField possibleCompletionsForString:string completionHandler:handler];
}

- (NSArray *)autoCompleteTextField:(MLPAutoCompleteTextField *)textField possibleCompletionsForString:(NSString *)string {

    return [self.roleDataSource autoCompleteTextField:textField possibleCompletionsForString:string];
}

@end
