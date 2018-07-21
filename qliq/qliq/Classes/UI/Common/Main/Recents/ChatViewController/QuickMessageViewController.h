//
//  QuickMessageViewController.h
//  qliq
//
//  Created by Valerii Lider on 9/26/14.
//
//

#import <UIKit/UIKit.h>

@protocol QuickMessageDelegate <NSObject>

- (void)quickMessageSelected:(NSString*)quickMessageText;

@end

@interface QuickMessageViewController : UIViewController

@property (nonatomic, assign) id <QuickMessageDelegate> delegate;

@end
