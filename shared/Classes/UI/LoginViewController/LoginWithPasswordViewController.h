//
//  LoginWithPasswordViewController.h
//  qliq
//
//  Created by Paul Bar on 2/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqBaseViewController.h"
#import "UsernamePasswordView.h"

@protocol LoginWithPasswordViewControllerDelegate <NSObject>

-(void) loginWithUsername:(NSString*)username andPassword:(NSString *)password;
-(void) retrievePassword;

@end

@interface LoginWithPasswordViewController : QliqBaseViewController<UsernamePasswordViewDelegate>
{
    UsernamePasswordView *loginView;
}
@property (nonatomic, assign) id<LoginWithPasswordViewControllerDelegate> delegate;

-(void) focusUsername;
-(void) focusPassword;
-(void) clearPassword;
-(void) prefillUsername:(NSString*)username;
-(void) prefillPassword:(NSString*)password;
-(void) unmaskPassword;
-(void) maskPassword;

- (void) closeKeyboard;

@end
