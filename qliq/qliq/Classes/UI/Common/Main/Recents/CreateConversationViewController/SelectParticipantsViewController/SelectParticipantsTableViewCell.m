//
//  SelectParticipantsTableViewCell.m
//  qliq
//
//  Created by Valerii Lider on 8/4/14.
//
//

#import "SelectParticipantsTableViewCell.h"

#import "QliqGroup.h"
#import "QliqUser.h"
#import "QliqGroupDBService.h"

@interface SelectParticipantsTableViewCell ()

@property (weak, nonatomic) IBOutlet UIView *statusColor;
@property (weak, nonatomic) IBOutlet UIView *statusView;

@property (weak, nonatomic) IBOutlet UIView *detailView;
@property (weak, nonatomic) IBOutlet UILabel *titleOnDetailView;
@property (weak, nonatomic) IBOutlet UILabel *detailTitleOnDetailView;

@property (nonatomic, weak) IBOutlet UIButton *checkBox;

@end

@implementation SelectParticipantsTableViewCell

#pragma mark - Setters

- (void)setUser:(QliqUser *)user
{
    [self showDetailView:NO];
    
    NSString *title = @"";
    NSString *detailTitle = @"";
    
    //Set Tittle
    {
        if (user.firstName && user.lastName)
            title = [NSString stringWithFormat:@"%@ %@", user.firstName, user.lastName];
        else if (user.firstName && !user.lastName)
            title = user.firstName;
        else if (!user.firstName && user.lastName)
            title = user.lastName;
        
        self.title.text = self.titleOnDetailView.text = [user nameDescription];// title;
        
        if ([user isKindOfClass:[QliqUser class]])
            detailTitle = user.profession ? user.profession : detailTitle;
        else if ([user isKindOfClass:[Contact class]])
            detailTitle = user.email.length > 0 ? user.email : user.phone.length > 0 ? user.phone : @"";
        
        if (![detailTitle isEqualToString:@""] && detailTitle)
            [self showDetailView:YES];
        
        self.detailTitleOnDetailView.text = detailTitle;
    }
    
    //Set StatusView
    {
        [self settingsStatusViewWithItem:user];
    }
}

- (void)setGroup:(QliqGroup *)group
{
    [self showDetailView:NO];
    
    NSString *title = @"";
    
    //Set Tittle
    {
        title = group.name ? group.name : @"Group";
        self.title.text = self.titleOnDetailView.text = title;
    }
    
    //Set StatusView
    {
        [self settingsStatusViewWithItem:group];
    }
}

#pragma mark - Public

- (void)setData:(id)item
{
    if ([item isKindOfClass:[Contact class]] || [item isKindOfClass:[QliqUser class]] )
    {
        self.user = ((QliqUser *)item);
    }
    else if ([item isKindOfClass:[QliqGroup class]])
    {
        self.group = ((QliqGroup *) item);
    }
    
    self.avatarImageView.image = [[QliqAvatar sharedInstance] getAvatarForItem:item withTitle:nil];
}

- (void)setCheckedBox:(BOOL)isCheked
{
    UIImage *image = nil;
    image = isCheked ? [UIImage imageNamed:@"ConversationChecked"] : [UIImage imageNamed:@"ConversationUnChecked"];
    [self.checkBox setImage:image forState:UIControlStateNormal];
}

#pragma mark - Private

/**
 DetailView have TittleLabel & DetailLabel
 */
- (void)showDetailView:(BOOL)show
{
    self.detailView.hidden = !show;
}

- (void)settingsStatusViewWithItem:(id)item
{
    if ([item isKindOfClass:[QliqUser class]])
    {
        QliqUser *user = item;
        
        self.statusView.hidden = NO;
        self.statusColor.backgroundColor = [[QliqAvatar sharedInstance] colorForPresenceStatus:user.presenceStatus];
    }
    else
    {
        self.statusView.hidden = YES;
    }
}

@end
