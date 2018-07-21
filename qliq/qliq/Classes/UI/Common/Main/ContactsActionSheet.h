//
//  ContactsActionSheet.h
//  qliq
//
//  Created by Valerii Lider on 8/17/15.
//
//

#import <UIKit/UIKit.h>

@class ContactsActionSheet;
@class Contact;

typedef void (^ContactActionSheetErrorBlock)(BOOL success, NSError *error);

@protocol ContactsActionSheetDelegate <NSObject>

@optional
- (void)actionSheet:(ContactsActionSheet *)actionSheet onDirectCallTo:(NSString *)calleePhoneNumber;

- (void)actionSheet:(ContactsActionSheet *)actionSheet onQliqAssistedCallTo:(NSString *)calleePhoneNumber;

@end

@interface ContactsActionSheet : UIViewController

@property (nonatomic, assign) id<ContactsActionSheetDelegate> delegate;

//- (instancetype)initWithContact:(Contact *)contact;
- (instancetype)initWithContacts:(NSMutableArray *)contacts;
- (void)presentInView:(UIView *)parentView animated:(BOOL)animated withErrorHandler:(ContactActionSheetErrorBlock)handler;

@end
