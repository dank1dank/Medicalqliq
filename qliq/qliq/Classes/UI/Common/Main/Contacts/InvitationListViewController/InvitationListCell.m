//
//  InvitationListCell.m
//  qliq
//
//  Created by Valerii Lider on 3/17/15.
//
//

#import "InvitationListCell.h"
#import "Invitation.h"

@interface InvitationListCell ()

/**
 IBOutlet
 */
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *personNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *specialityLabel;

@property (weak, nonatomic) IBOutlet UIButton *viewButton;

/* Constraints */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *buttonWidthConsttraint;

/**
 Data
 */
@property (nonatomic, strong) Invitation *currentInvitation;

@end

@implementation InvitationListCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.iconImageView.layer.cornerRadius = self.iconImageView.frame.size.width/2.f;
    self.iconImageView.layer.masksToBounds = YES;
    
    [self prepareForReuse];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.iconImageView.image = nil;
    self.iconImageView.hidden = NO;
    
    self.personNameLabel.text = @"";
    self.specialityLabel.text = @"";
    
    [self.viewButton setTitle:@"" forState:UIControlStateNormal];
    
    [self layoutIfNeeded];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - Public -

- (void)setCellInvitation:(Invitation *)invitation
{
    self.currentInvitation = invitation;
    
    NSString * titleText = [self.currentInvitation.contact simpleName];
    if (titleText.length == 0)
        titleText = [self.currentInvitation.contact email];
    if (titleText.length == 0)
        titleText = [self.currentInvitation.contact mobile];
    
    self.personNameLabel.text = titleText;
    self.personNameLabel.adjustsFontSizeToFitWidth = YES;
    
    NSString *titleButton = @"";
    switch (self.currentInvitation.status)
    {
        case InvitationStatusAccepted: {
            titleButton = QliqLocalizedString(@"2142-TitleAccepted");
            break;
        }
        case InvitationStatusDeclined: {
            titleButton = QliqLocalizedString(@"2143-TitleDeclined");
            break;
        }
        default: {
            
            if (self.currentInvitation.operation == InvitationOperationSent) {
                titleButton = QliqLocalizedString(@"2144-TitlePending");
            }
            else {
                titleButton = QliqLocalizedString(@"2145-TitleView");
            }
            break;
        }
    }
            
    [self.viewButton setTitle:titleButton forState:UIControlStateNormal];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMM d, YYYY"];
    
    NSDate *invitationDate = [NSDate dateWithTimeIntervalSinceReferenceDate:self.currentInvitation.invitedAt];
    
    self.specialityLabel.text = [dateFormatter stringFromDate:invitationDate];
    
    self.iconImageView.hidden = self.currentInvitation.contact.contactType != ContactTypeQliqUser;
    self.iconImageView.image = [[QliqAvatar sharedInstance] getAvatarForItem:nil withTitle:self.personNameLabel.text];
}

#pragma mark - Actions -

- (IBAction)onButon:(id)sender
{
    [self.delegate invitationListCell:self viewDidTappedWithInvitation:self.currentInvitation];
}

@end
