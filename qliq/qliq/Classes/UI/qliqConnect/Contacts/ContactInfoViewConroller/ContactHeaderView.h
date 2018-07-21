//
//  ContactHeaderView.h
//  qliq
//
//  Created by Paul Bar on 4/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Contact, StatusView;

@protocol ContactHeaderViewDelegate <NSObject>

@optional
- (void)headerWasTapped;
- (void)favoritesButtonPressed;
- (void)changeAvatar;

@end

@interface ContactHeaderView : UIView <UIGestureRecognizerDelegate>

@property (nonatomic, assign) id <ContactHeaderViewDelegate> delegate;

@property (nonatomic, weak) IBOutlet UIImageView *avatarView;
@property (nonatomic, weak) IBOutlet StatusView *statusView;

@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UILabel *phoneLabel;
@property (nonatomic, weak) IBOutlet UILabel *emailLabel;
@property (nonatomic, weak) IBOutlet UIButton *favoritesButton;
@property (nonatomic, weak) IBOutlet UIImageView *arrowView;

@property (nonatomic, strong) UITapGestureRecognizer *tapRecognizer;

- (void)fillWithContact:(id)contact;
- (void)setContactIsFavorite:(BOOL)contactIsFavorite;
- (UIImage*)getAvatar;

@end
