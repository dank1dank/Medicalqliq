//
//  CreateFaxContactViewController.h
//  qliq
//
//  Created by Valeriy Lider on 1/9/18.
//

#import <UIKit/UIKit.h>



@protocol CreateFaxContactsViewControllerDelegate<NSObject>

@optional

- (void)didSelectedNewParticipant:(NSMutableArray *)participants;

@end

@interface CreateFaxContactViewController : UIViewController

@property (nonatomic, weak) id<CreateFaxContactsViewControllerDelegate> delegate;


@end
