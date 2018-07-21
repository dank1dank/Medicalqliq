//
//  EditTableViewCell.m
//  qliq
//
//  Created by Valerii Lider on 5/31/16.
//
//

#import "EditTableViewCell.h"

@implementation EditTableViewCell

- (void)dealloc
{
    
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
     [self prepareForReuse];
}

- (void)prepareForReuse {
    [super prepareForReuse];

    self.rowTitle = nil;
    self.rowLabel.text = nil;
}

- (EditTableViewCell *)setCellForTitleType:(EditTableTitle)editTableTitle isCareChannel:(BOOL)isCareChannel {

    self.rowTitle = editTableTitle;
    
    NSString *labelText = @"";
    
    switch (editTableTitle) {
        case EditParticipants:
        {
            labelText = isCareChannel ? QliqLocalizedString(@"2362-TitleEditCareTeam") : QliqLocalizedString(@"2186-TitleEditParticipants");
            break;
        }
        case ForwardMessage:
        {
            labelText = QliqLocalizedString(@"2409-TitleForwardMessage");
            break;
        }
        case DeleteMessages:
        {
            labelText = QliqLocalizedString(@"2410-TitleDeleteMessages");
            break;
        }
        case DeleteConversation:
        {
            labelText = isCareChannel ? QliqLocalizedString(@"2350-TitleDeleteCareChannel") : QliqLocalizedString(@"2188-TitleDeleteConversation");
            break;
        }
        case RestoreConversation:
        {
            labelText = isCareChannel ?  QliqLocalizedString(@"2351-TitleRestoreCareChannel") : QliqLocalizedString(@"2002-TitleRestoreConversation");
            break;
        }
        case ArchiveConversation:
        {
            labelText = isCareChannel ?  QliqLocalizedString(@"2352-TitleArchiveCareChannel") : QliqLocalizedString(@"2003-TitleArchiveConversation");
            break;
        }
        case UploadToEMR:
        {
            labelText = QliqLocalizedString(@"2189-TitleUploadToEMR");
            break;
        }
        case UploadToKiteworks:
        {
            labelText = QliqLocalizedString(@"2321-TitleUploadToKiteworks");
            break;
        }
        case PatientInfo:
        {
            labelText = QliqLocalizedString(@"3005-TitlePatientInfo");
            break;
        }
        case CareChannelInfo:
        {
            labelText = QliqLocalizedString(@"2348-TitleCareChannelInfo");
            break;
        }
        case MuteConversation:
        {
            labelText = isCareChannel ?  QliqLocalizedString(@"2357-TitleMuteCareChannel") : QliqLocalizedString(@"2359-TitleMuteConversation");
            break;
        }
        case UnMuteConversation:
        {
            labelText = isCareChannel ?  QliqLocalizedString(@"2358-TitleUnMuteCareChannel") : QliqLocalizedString(@"2360-TitleUnMuteConversation");
            break;
        }
        default:
            break;
    }
    
    self.rowLabel.text = labelText;
    
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


@end
