//
//  MainSettingsHeaderView.m
//  qliq
//
//  Created by Valeriy Lider on 17.11.14.
//
//

#import "MainSettingsHeaderView.h"
#import "QliqGroupDBService.h"
#import "QliqConnectModule.h"
#import "StatusView.h"



@interface MainSettingsHeaderView () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) IBOutlet UIView *avatarContainerView;

@property (nonatomic, weak) IBOutlet StatusView *statusView;
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UILabel *phoneLabel;
@property (nonatomic, weak) IBOutlet UILabel *emailLabel;
@property (nonatomic, weak) IBOutlet UIImageView *arrow;

@end

@implementation MainSettingsHeaderView

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    [self layoutIfNeeded];
    if(self)
    {
        //Gesture
        {
            UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
            tapRecognizer.delegate = self;
            [self addGestureRecognizer:tapRecognizer];
        }
        
        //Notifications
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onPresenceChangeNotification:) name: PresenceChangeStatusNotification object: nil];
    }
    return self;
}

#pragma mark - Public

- (void)fillWithContact:(id)contact
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self updatePresenceWithUser:contact];
        
        self.nameLabel.text = [contact nameDescription];
        self.emailLabel.text = [contact email];
        self.avatarView.image = [[QliqAvatar sharedInstance] getAvatarForItem:contact withTitle:nil];
    });
}

#pragma  mark - Private

- (void)tapAction:(UITapGestureRecognizer *)sender
{
    if ([self.delegate respondsToSelector:@selector(changeAvatar)]) {
        [self.delegate changeAvatar];
        return;
    } else if ([self.delegate respondsToSelector:@selector(showUserProfile)]) {
        [self.delegate showUserProfile];
    }
}

//OfflinePresenceStatus
//OnlinePresenceStatus
//AwayPresenceStatus
//DoNotDisturbPresenceStatus
- (PresenceStatus)getPresenceStatus:(NSString *)type
{
    PresenceStatus presenceStatus = OfflinePresenceStatus;
    
    if ([type isEqualToString: PresenceTypeAway])
        presenceStatus = AwayPresenceStatus;
    else if ([type isEqualToString:PresenceTypeDoNotDisturb])
        presenceStatus = DoNotDisturbPresenceStatus;
    else if ([type isEqualToString:PresenceTypeOnline])
        presenceStatus = OnlinePresenceStatus;
    
    return presenceStatus;
}

- (void)updatePresenceWithUser:(QliqUser*)user
{
    NSString *presenceType         = [[[QliqAvatar sharedInstance] getSelfPresenceMessage] lowercaseString];
    PresenceStatus *presenceStatus = [self getPresenceStatus:presenceType];
    NSString *presenceMessage      = [presenceType capitalizedString];
    
    if (!presenceStatus) {
        DDLogSupport(@"Presence status for current user is nil");
        presenceStatus = OnlinePresenceStatus;
    }
    self.statusView.statusColorView.backgroundColor = [[QliqAvatar sharedInstance] colorForPresenceStatus:presenceStatus];
    self.phoneLabel.text      = presenceMessage;
}

#pragma mark - Notiifcations

- (void)onPresenceChangeNotification:(NSNotification *)notification
{
    if ([notification.userInfo[@"isForMyself"] boolValue] == YES) {
        [self updatePresenceWithUser:[UserSessionService currentUserSession].user];
    }
}

@end
