//
//  InvitationListViewController.h
//  qliq
//
//  Created by Valerii Lider on 3/17/15.
//
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, InvitationType) {
    InvitationTypeAll,
    InvitationTypeSend,
    InvitationTypeReceived
};

@interface InvitationListViewController : UIViewController

@property (nonatomic, assign) InvitationType invitationType;

@property (nonatomic, strong) NSObject<InvitationGroup> *group;

@end
