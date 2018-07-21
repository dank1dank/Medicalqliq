//
//  EditTableViewCell.h
//  qliq
//
//  Created by Valerii Lider on 5/31/16.
//
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, EditTableTitle) {
    EditParticipants = 0,
    ForwardMessage,
    DeleteMessages,
    DeleteConversation,
    RestoreConversation,
    ArchiveConversation,
    UploadToEMR,
    UploadToKiteworks,
    PatientInfo,
    CareChannelInfo,
    MuteConversation,
    UnMuteConversation
};

@interface EditTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *rowLabel;
@property (assign, nonatomic) EditTableTitle rowTitle;

- (EditTableViewCell *)setCellForTitleType:(EditTableTitle)editTableTitle isCareChannel:(BOOL)isCareChannel;

@end
