//
//  QliqAssistedView.h
//  qliq
//
//  Created by Valerii Lider on 5/23/16.
//
//

#import <UIKit/UIKit.h>

#import "ChatMessage.h"

@class QliqAssistedView;

typedef NS_ENUM(NSInteger, QliqAssistedViewState) {
    QliqAssistedViewStateChecked = 0,
    QliqAssistedViewStateUnchecked
};

@protocol QliqAssistedViewDelegate <NSObject>

- (void)tapDetectedForQliqAssistedView:(QliqAssistedView*)qliqAssistedView;
- (void)replaceQliqAssistedView:(QliqAssistedView*)qliqAssistedView;

@end

@interface QliqAssistedView : UIView

/** Delegate */
@property (nonatomic, assign) id<QliqAssistedViewDelegate> delegate;


/** IBOUtlets */
@property (nonatomic, strong) IBOutlet UILabel *qliqAssistedTitleLabel;


@property (nonatomic, strong) NSMutableArray *phoneNumbers;

+ (CGSize)getQliqAssistedViewSizeWithMarginsVertical:(CGFloat)verticalMargin horizontal:(CGFloat)horizontalMargin avatarOffset:(CGFloat)avatarOffset;
//+ (CGSize)getQliqAssistedTitleLableSize;
+ (NSArray *)isPhoneNumbersDetectedForChatMessage:(ChatMessage*)message;
- (BOOL)configureQliqAssistedViewWithMessage:(ChatMessage*)message;
- (NSString *)getCorrectedPhoneNumberForPhoneUrl:(NSString *)phoneUrl;
+ (NSString *)getCorrectedPhoneNumberForMessage:(ChatMessage *)message;

@end


