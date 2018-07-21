//
//  CallAlertService.h
//  qliq
//
//  Created by Valerii Lider on 6/2/16.
//
//

#import <Foundation/Foundation.h>
#import "CustomAlertView.h"

//typedef void (^voidBlock)(void);

@interface CallAlertService : NSObject 

@property (strong, nonatomic) VoidBlock customAlertsPreShowBlock;
@property (strong, nonatomic) VoidBlock customAlertsAfterDismissBlock;

- (instancetype)initWithPresenterViewController:(UIViewController *)presenterViewController;

- (void)phoneNumberWasSelectedForAction:(NSString *)calleePhoneNumber;
- (void)onQliqAssistedCallTo:(NSString *)calleePhoneNumber;
- (void)onDirectCallTo:(NSString *)calleePhoneNumber;

@end
