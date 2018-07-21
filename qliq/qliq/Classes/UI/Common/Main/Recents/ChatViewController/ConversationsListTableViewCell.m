//
//  ConversationsListTableViewCell.m
//  qliq
//
//  Created by Valerii Lider on 10/08/15.
//
//

#import "ConversationsListTableViewCell.h"

#import "Conversation.h"
#import "Recipients.h"
#import "FhirResources.h"

@interface ConversationsListTableViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UIImageView *checkmarkImageView;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *subjectLabel;
@property (weak, nonatomic) IBOutlet UILabel *textMessageLabel;

@end

@implementation ConversationsListTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self layoutIfNeeded];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    [self prepareForReuse];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.avatarImageView.image = nil;
    self.avatarImageView.layer.masksToBounds = YES;
    self.avatarImageView.layer.cornerRadius = self.avatarImageView.frame.size.height/2;
    
    self.checkmarkImageView.image = [UIImage imageNamed:@"ConversationUnChecked"];

    self.nameLabel.text = @"";
    self.subjectLabel.text = @"";
    self.textMessageLabel.text = @"";
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - Public -

- (void)configureCellWithConversation:(Conversation*)conversation cellIsChecked:(BOOL)isChecked {
    
    self.nameLabel.text = [conversation.recipients displayNameWrappedToWidth:self.nameLabel.frame.size.width font:self.nameLabel.font];
    
    //Set Avatar
    self.avatarImageView.image = [[QliqAvatar sharedInstance] getAvatarForItem:conversation.recipients withTitle:self.nameLabel.text];
    self.textMessageLabel.text = conversation.lastMsg;
    
    if (conversation.isBroadcast) {
        if ([conversation.subject length] == 0) {
            self.subjectLabel.text = @"[Broadcast]";
        }
        else {
            self.subjectLabel.text = [@"[Broadcast] " stringByAppendingString:conversation.subject];
        }
    }
    else if (conversation.isCareChannel) {
        self.textMessageLabel.text = self.nameLabel.text;
        //self.nameLabel.text =
        FhirEncounter *encounter = [FhirEncounterDao findOneWithUuid:conversation.uuid];
        if (encounter) {
            self.nameLabel.text = encounter.patient.fullName;
        }
    }
    else {
        self.subjectLabel.text = conversation.subject;
        
        if (conversation.broadcastType == NotBroadcastType) {
            
            NSString *presenseStatusText = [[UserSessionService currentUserSession].userSettings.presenceSettings convertPresenceStatusForSubjectType:conversation.subject];
            if (presenseStatusText) {
                self.subjectLabel.text = presenseStatusText;
            }
        }
    }
    
    self.checkmarkImageView.image = isChecked ? [UIImage imageNamed:@"ConversationChecked"] : [UIImage imageNamed:@"ConversationUnChecked"];
}

@end
