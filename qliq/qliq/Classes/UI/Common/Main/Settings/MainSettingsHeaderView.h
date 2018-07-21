//
//  MainSettingsHeaderView.h
//  qliq
//
//  Created by Valeriy Lider on 17.11.14.
//
//

#import <UIKit/UIKit.h>

@protocol MainSettingsHeaderViewDelegate <NSObject>

- (void)showUserProfile;
- (void)changeAvatar;

@end

@interface MainSettingsHeaderView : UIView

@property (nonatomic, assign) id <MainSettingsHeaderViewDelegate> delegate;

@property (nonatomic, weak) IBOutlet UIImageView *avatarView;
@property (nonatomic, weak) UIImage *avatar;

- (void)fillWithContact:(id)contact;

@end
