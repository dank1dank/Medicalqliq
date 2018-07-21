//
//  FirstLaunchViewController.h
//  qliq
//
//  Created by Valerii Lider on 5/27/14.
//
//

#import <UIKit/UIKit.h>
#import "Login.h"

@interface FirstLaunchViewController : UIViewController


//type view
@property (assign, nonatomic) StartViewType viewType;

//blocks
@property (copy, nonatomic) void(^runLoginBlock)(void);
@property (copy, nonatomic) void(^unlockBlock)(void);

- (void)setViewType:(StartViewType)viewType animated:(BOOL)animated withCompletition:(void(^)(void))completition;

@end
