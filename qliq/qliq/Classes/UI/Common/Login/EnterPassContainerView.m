//
//  EnterPassContainerView.m
//  qliq
//
//  Created by Valerii Lider on 7/23/14.
//
//

#import "EnterPassContainerView.h"
#import "QliqGroup.h"

@interface EnterPassContainerView ()

@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;

@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

//Constraints
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *userInfoViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *backButtonViewLeadingConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *qliqImageViewLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *qliqImageViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *typeLabelLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *backArrowImageViewLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *backArrowImageViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *switchUserButtonLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *switchUserButtonWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *switchUserButtonTrailingConstraint;

@end

@implementation EnterPassContainerView

- (void)dealloc
{
    self.avatarImageView = nil;
    self.nameLabel = nil;
    self.phoneLabel = nil;
    self.emailLabel = nil;
    
    self.switchUserButton = nil;
    self.signInButton = nil;
    self.createAccountButton = nil;
    self.forgotPasswordButton = nil;
    
    self.emailTextField = nil;
    self.passTextField = nil;
    
    self.badgeLabel = nil;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
    }
    return self;
}

- (void)configureDefaultText {

    [self.switchUserButton setTitle:QliqLocalizedString(@"65-ButtonSwitchUser") forState:UIControlStateNormal];
    
    self.descriptionLabel.text = QliqLocalizedString(@"2306-TitleEnterYourEmailAndPassword");
    
    self.emailTextField.placeholder = QliqLocalizedString(@"2304-TitleEmailPlaceholder");
    self.passTextField.placeholder = QliqLocalizedString(@"2305-TitlePasswordPlaceholder");
    
    [self.signInButton setTitle:QliqLocalizedString(@"57-ButtonSignIn") forState:UIControlStateNormal];
    
    [self.createAccountButton setTitle:QliqLocalizedString(@"62-ButtonCreateAccout") forState:UIControlStateNormal];
    
    [self.forgotPasswordButton setTitle:QliqLocalizedString(@"Forgot Password?") forState:UIControlStateNormal];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureDefaultText];
    [self configureController];
    [self configureSignUpButton];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(configureSignUpButton)
                                                 name:@"ConfigureSignUpButton" object:nil];
}

#pragma mark - Private

- (void)configureController
{
    self.nameLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:19.f];
    
    [self.emailTextField setTintColor:[UIColor whiteColor]];
    
    [self.passTextField setTintColor:[UIColor whiteColor]];
    
    self.avatarImageView.layer.cornerRadius = self.avatarImageView.frame.size.width/2.f;
    self.avatarImageView.layer.masksToBounds = YES;
    self.avatarImageView.backgroundColor = [UIColor redColor];
    self.badgeLabel.layer.cornerRadius = 7.f;
    self.badgeLabel.clipsToBounds = YES;
}

- (void)configureSignUpButton {
    BOOL hide = ![[NSUserDefaults standardUserDefaults] boolForKey:kUDKeyShowSignUpButton];
    self.createAccountButton.hidden = hide;
}

- (void)updateTypeLableSize {
    
    //TypeLable
    NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [UIFont fontWithName:@"HelveticaNeue" size:19.0f], NSFontAttributeName,
                                          nil];
    
    CGRect typeLableRect = [self.typeLabel.text boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, self.typeLabelHeightConstraint.constant)
                                                             options:NSStringDrawingUsesLineFragmentOrigin| NSStringDrawingUsesFontLeading
                                                          attributes:attributesDictionary
                                                             context:nil];
    
    self.typeLabelWidthConstraint.constant = typeLableRect.size.width + 1;
    
    //Calculating Total Free Space For Badge Label
    self.totalFreeSpaceForBadgeLabel = self.backButtonView.frame.size.width -
    self.backArrowImageViewLeadingConstraint.constant -
    self.backArrowImageViewWidthConstraint.constant -
    self.qliqImageViewLeadingConstraint.constant -
    self.qliqImageViewWidthConstraint.constant -
    self.typeLabelLeadingConstraint.constant -
    self.typeLabelWidthConstraint.constant;
    
}

#pragma mark - Public

- (void)configureHeaderWithUser:(QliqUser *)contact andGroup:(QliqGroup *)group
{
    self.nameLabel.text = contact.firstName;
    
    self.phoneLabel.text = contact.profession;
    
    self.emailLabel.text = [contact email];
    
    self.avatarImageView.image = [[QliqAvatar sharedInstance] getAvatarForItem:contact withTitle:nil];
}

#pragma mark - Actions

- (IBAction)onBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onInfo:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:SVProgressHUDDidReceiveTouchEventNotification object:nil];
}

@end
