//
//  SelectContactsViewController.h
//  qliq
//
//  Created by Valerii Lider on 11.11.14.
//
//

#import <UIKit/UIKit.h>

@class ContactList;
@class SelectContactsViewController;

typedef NS_ENUM(NSInteger, SelectionType) {
    STForInviting,
    STForFavorites,
    STForPersonalGroup,
    STForForwarding,
    STForNewConversation,
    STForCareChannelEditPaticipants,
    STForConversationEditParticipants,
    STForQliqSign
};

typedef void (^SelectParticipantsCallBack)(NSArray *selectedContacts, SelectContactsViewController*);

@protocol SelectContactsViewControllerDelegate<NSObject>

@optional
- (void)didSelectRecipient:(id)contact;
- (void)didSelectedParticipants:(NSMutableArray *)participants;

@end

@interface SelectContactsViewController : UIViewController

@property (nonatomic, weak) id<SelectContactsViewControllerDelegate> delegate;

@property (nonatomic, strong) NSString *firstFilterCharacter;
@property (nonatomic, strong) NSMutableArray *participants;
@property (nonatomic, strong) ContactList *list;
@property (nonatomic, assign) BOOL faxSearch;

@property (nonatomic, copy) SelectParticipantsCallBack selectParticipantsCallBack;

@property (nonatomic, assign) SelectionType typeController; // to assign for what purpose contacts will be shosen

@end
