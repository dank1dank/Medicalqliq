//
//  SearchPatientsViewController.h
//  qliq
//
//  Created by Valerii Lider on 01/03/2017.
//
//

#import <UIKit/UIKit.h>
#import "Conversation.h"

@class MediaFile;

@interface SearchPatientsViewController : UIViewController

@property (nonatomic, strong) Conversation *conversation;
@property (nonatomic, strong) MediaFile *mediaFile;

- (void)uploadCareChannelConversation:(Conversation *)conversation;

@end
