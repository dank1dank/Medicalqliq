//
//  ContactHeaderView.m
//  qliq
//
//  Created by Paul Bar on 4/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ContactHeaderView.h"

#import "StatusView.h"

#import "QliqListService.h"
#import "QliqUserDBService.h"

#import "Invitation.h"
#import "QliqGroup.h"
#import "OnCallGroup.h"
#import "QliqButton.h"
#import "ContactList.h"
#import "FhirResources.h"
#import "Conversation.h"

#define kValueInfoViewHeight 60.f

@interface ContactHeaderView()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *infoViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *emailLavelTopConstraint;

@property (nonatomic,  strong) UIImage *avatar;

@end

@implementation ContactHeaderView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
        self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
        self.tapRecognizer.delegate = self;
        [self addGestureRecognizer:self.tapRecognizer];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
        self.tapRecognizer.delegate = self;
        [self addGestureRecognizer:self.tapRecognizer];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

#pragma mark - Public -

- (void)fillWithContact:(id)contact
{
    id localContact = contact;
    
    self.favoritesButton.hidden = ![contact isKindOfClass:[QliqUser class]];
    
    if ([localContact isKindOfClass:[Invitation class]])
    {
        Invitation *invitation = localContact;
        
        localContact = invitation.contact;
        if (invitation.contact.contactType == ContactTypeQliqUser)
        {
            QliqUser * user = [[QliqUserDBService sharedService] getUserForContact:invitation.contact];
            if (user) {
                localContact = user;
                
                if (user.contact.lastName.length ) {
                    self.nameLabel.text  = [user.contact nameDescription];
                }
                
                if (user.contact.email.length) {
                    self.emailLabel.text = [user.contact email];
                }
                
                if (user.contact.phone.length) {
                    self.phoneLabel.text = user.contact.phone;
                }
            }
        }
    } else if ([localContact isKindOfClass:[Contact class]] || [localContact isKindOfClass:[QliqUser class]])
    {
        Contact *contactLocal = localContact;
        self.nameLabel.text  = [contactLocal nameDescription];
        self.emailLabel.text = [contactLocal email];
        self.phoneLabel.text = @"";
        
        if ([localContact isKindOfClass:[QliqUser class]])
        {
            if ([((QliqUser *)localContact).qliqId isEqualToString:[UserSessionService currentUserSession].user.qliqId]) {
                localContact = [UserSessionService currentUserSession].user;
                ((QliqUser *)localContact).presenceStatus = [QliqUser presenceStatusFromString:[UserSessionService currentUserSession].userSettings.presenceSettings.currentPresenceType];
                ((QliqUser *)localContact).presenceMessage = [[QliqAvatar sharedInstance] getSelfPresenceMessage];
            }
            
            UIColor *color = [[QliqAvatar sharedInstance] colorForPresenceStatus:((QliqUser *)localContact).presenceStatus];
            self.statusView.statusColorView.backgroundColor = color;
            self.phoneLabel.text      = [[QliqAvatar sharedInstance] getPrecenseStatusMessage:((QliqUser *)localContact)];
            self.phoneLabel.textColor = [[QliqAvatar sharedInstance] colorShadowForPresenceStatus:((QliqUser *)localContact).presenceStatus];
            //            self.phoneLabel.font      = [UIFont boldSystemFontOfSize:self.phoneLabel.font.pointSize];
        }
    }
    else if ([localContact isKindOfClass:[QliqGroup class]] || [localContact isKindOfClass:[ContactList class]])
    {
        QliqGroup *contactLocal = localContact;
        self.nameLabel.text = contactLocal.name;
        self.phoneLabel.text = @"";
        self.emailLabel.text = @"";
    }
    else if ([localContact isKindOfClass:[FhirPatient class]]) {
        FhirPatient *patient = localContact;
        
        if (patient.fullName.length !=0) {
            self.nameLabel.text = [patient fullName];
        } else {
            self.nameLabel.text = @"";
        }
        
        if (patient.gender.length !=0 && patient.age != 0) {
            self.emailLabel.text = QliqFormatLocalizedString2(@"3000-TitleGender{gender}{yo}YearsOld", [patient gender], [patient age]);
        } else if (patient.gender.length !=0){
            self.emailLabel.text = patient.gender;
        } else if (patient.age !=0){
            self.emailLabel.text = QliqFormatLocalizedString1(@"3018-Title{yo}YearsOld", [patient age]);
        } else {
            self.emailLabel.text = @"";
        }
        
        self.phoneLabel.text = @"";
        
    } else if ([localContact isKindOfClass:[Conversation class]] && [(Conversation *)localContact isCareChannel]) {
        FhirEncounter *encounter = ((Conversation *)localContact).encounter;
        
        if (encounter.patient.fullName.length !=0) {
            self.nameLabel.text = [encounter.patient fullName];
        } else {
            self.nameLabel.text = @"";
        }
        
        if (encounter.patient.gender.length !=0 && encounter.patient.age != 0) {
            self.emailLabel.text = QliqFormatLocalizedString2(@"3000-TitleGender{gender}{yo}YearsOld", [encounter.patient gender], [encounter.patient age]);
        } else if (encounter.patient.gender.length !=0){
            self.emailLabel.text = encounter.patient.gender;
        } else if (encounter.patient.age !=0){
            self.emailLabel.text = QliqFormatLocalizedString1(@"3018-Title{yo}YearsOld", [encounter.patient age]);
        } else {
            self.emailLabel.text = @"";
        }
        
        self.arrowView.hidden = NO;
        
        self.phoneLabel.text = @"";
    
    } else if ([localContact isKindOfClass:[OnCallMemberNotes class]]) {
        
        localContact = [[QliqUserDBService sharedService] getUserWithId:((OnCallMemberNotes *)localContact).memberQliqId];
        
        if (localContact) {
            
            if ([((QliqUser *)localContact).qliqId isEqualToString:[UserSessionService currentUserSession].user.qliqId]) {
                localContact = [UserSessionService currentUserSession].user;
                ((QliqUser *)localContact).presenceStatus = [QliqUser presenceStatusFromString:[UserSessionService currentUserSession].userSettings.presenceSettings.currentPresenceType];
                ((QliqUser *)localContact).presenceMessage = [[QliqAvatar sharedInstance] getSelfPresenceMessage];
            }
            
            UIColor *color = [[QliqAvatar sharedInstance] colorForPresenceStatus:((QliqUser *)localContact).presenceStatus];
            self.statusView.statusColorView.backgroundColor = color;
            self.phoneLabel.text      = [[QliqAvatar sharedInstance] getPrecenseStatusMessage:((QliqUser *)localContact)];
            self.phoneLabel.textColor = [[QliqAvatar sharedInstance] colorShadowForPresenceStatus:((QliqUser *)localContact).presenceStatus];
            
            self.nameLabel.text  = [((QliqUser *)localContact) nameDescription];
            self.emailLabel.text = ((QliqUser *)localContact).profession;
        }
    }
    
    [self setInfoViewSizes];
    
    //Set Avatar
    if ([localContact isKindOfClass:[Conversation class]] && [(Conversation *)localContact isCareChannel]) {
        self.avatar = [[QliqAvatar sharedInstance] getAvatarForItem:((Conversation *)localContact).encounter.patient withTitle:nil];
    } else {
        self.avatar = [[QliqAvatar sharedInstance] getAvatarForItem:localContact withTitle:nil];
    }
    
    self.avatarView.image = self.avatar;
    self.statusView.hidden = ![localContact isKindOfClass:[QliqUser class]];
}

- (void)setContactIsFavorite:(BOOL)contactIsFavorite
{    
   UIImage *image = [UIImage imageNamed:contactIsFavorite ? @"starFuel" : @"starEmpty"];
   [self.favoritesButton setBackgroundImage:image forState:UIControlStateNormal];
}

#pragma  mark - Private -

- (void)setInfoViewSizes
{
    CGFloat height = 0.f;
    CGFloat labelHeight = 20.f;
    
    if ([self.nameLabel.text length] > 0)
        height = height + labelHeight;
    
    if ([self.emailLabel.text length] > 0)
    {
        self.emailLavelTopConstraint.constant = height;
        height = height + labelHeight;
    }
        
    if ([self.phoneLabel.text length] > 0)
        height = height + labelHeight;
    
    if (height == 0)
        height = kValueInfoViewHeight;
        
    self.infoViewHeightConstraint.constant = height;
}

- (UIImage*)getAvatar
{
    return self.avatar;
}

#pragma mark - Action

- (IBAction)onBack:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(favoritesButtonPressed)])
        [self.delegate favoritesButtonPressed];
}

#pragma mark - GestureRecognizer

- (void)tapAction:(UITapGestureRecognizer *)sender
{
    CGPoint touchPoint = [sender locationInView:self];
    if(CGRectContainsPoint(self.avatarView.frame, touchPoint))
    {
        if ([self.delegate respondsToSelector:@selector(changeAvatar)]) {
            [self.delegate changeAvatar];
        }
    } else {
        
        if ([self.delegate respondsToSelector:@selector(headerWasTapped)]) {
            [self.delegate headerWasTapped];
        }
        
    }
}

//- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
//{
//    BOOL rez = NO;
//    
//    CGPoint touchPoint = [touch locationInView:self];
//    if(CGRectContainsPoint(self.avatarView.frame, touchPoint))
//        rez = YES;
//
//    return rez;
//}

@end
