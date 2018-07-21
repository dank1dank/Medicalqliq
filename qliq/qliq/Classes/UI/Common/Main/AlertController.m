//
//  AlertController.m
//  qliq
//
//  Created by Valerii Lider on 5/1/18.
//
//

#import "AlertController.h"
#import "QliqSignHelper.h"

@interface AlertController ()

@end

@implementation AlertController

+ (AlertController *)sharedInstance
{
    static AlertController *instance = nil;
    if (instance == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            instance = [[AlertController alloc] init];
        });
    }
    return instance;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private

+ (void)showAlertWithStyle:(UIAlertControllerStyle *)alertStyle withTitle:(NSString *)title message:(NSString *)message withTitleButtons:(NSArray *)buttonsArray destructiveButtonTitle:(NSString *)destructiveButtonTitle cancelButtonTitle:(NSString *)cancelButtonTitle inController:(UIViewController *)controller completion:(void (^)(NSUInteger buttonIndex))completion {
    
    __block NSInteger buttonsCount = buttonsArray.count;
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:alertStyle];
    
    if (destructiveButtonTitle && destructiveButtonTitle.length) {
        
        UIAlertAction *destructiveButton = [UIAlertAction actionWithTitle:destructiveButtonTitle style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            
            NSUInteger *buttonIndex = buttonsCount;
            if (completion){
                completion(buttonIndex);
            }
        }];
        [alert addAction:destructiveButton];
    }
    
    for (int buttonIndex = 0; buttonIndex<buttonsArray.count; buttonIndex++) {
        
        UIAlertAction *buttonAction = [UIAlertAction actionWithTitle:[buttonsArray objectAtIndex:buttonIndex] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            
            if (completion){
                completion(buttonIndex);
            }
        }];
        [alert addAction:buttonAction];
    }
    
    if (cancelButtonTitle && cancelButtonTitle.length){
        
        UIAlertAction *cancelButton = [UIAlertAction actionWithTitle:cancelButtonTitle style:isiPad ? UIAlertActionStyleDefault : UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            
            buttonsCount = (destructiveButtonTitle && destructiveButtonTitle.length) ? buttonsCount + 1 : buttonsCount;
            NSUInteger *buttonIndex = buttonsCount;
            if (completion){
                completion(buttonIndex);
            }
        }];
        [alert addAction:cancelButton];
    }
    
    UIViewController *currentController = controller ? controller : [QliqSignHelper currentTopViewController];
    
    if (isiPad) {
        alert.preferredContentSize = CGSizeMake(450, 350.f);
        UIView *contentView = currentController.view;
        alert.popoverPresentationController.sourceView = contentView;
        alert.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(contentView.bounds), CGRectGetMaxY(contentView.bounds)-50.f, 0.f, 0.f);
        alert.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    }
    
    [currentController presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Public

+ (void) showAlertWithTitle:(NSString *)title message:(NSString *)message buttonTitle:(NSString *)buttonTitle cancelButtonTitle:(NSString *)cancelButtonTitle completion:(void (^)(NSUInteger buttonIndex))completion;
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    if (buttonTitle && buttonTitle.length) {
        UIAlertAction *buttonAction = [UIAlertAction actionWithTitle:buttonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            
            if (completion){
                //Button index = 0
                completion(0);
            }
        }];
        [alert addAction:buttonAction];
    }
    
    if (cancelButtonTitle && cancelButtonTitle.length){
        UIAlertAction *cancelButton = [UIAlertAction actionWithTitle:cancelButtonTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            
            if (completion) {
                //Button index = 1
                completion(1);
            }
        }];
        [alert addAction:cancelButton];
    }
    [[QliqSignHelper currentTopViewController] presentViewController:alert animated:YES completion:nil];
}

+ (void) showAlertWithTitle:(NSString *)title message:(NSString *)message withTitleButtons:(NSArray *)buttonsArray cancelButtonTitle:(NSString *)cancelButtonTitle completion:(void (^)(NSUInteger buttonIndex))completion;
{
    [self showAlertWithStyle:UIAlertControllerStyleAlert withTitle:title message:message withTitleButtons:buttonsArray destructiveButtonTitle:nil cancelButtonTitle:cancelButtonTitle inController:nil completion:completion];
}

+ (void) showActionSheetAlertWithTitle:(NSString *)title message:(NSString *)message withTitleButtons:(NSArray *)buttonsArray cancelButtonTitle:(NSString *)cancelButtonTitle completion:(void (^)(NSUInteger buttonIndex))completion {
    
    [self showAlertWithStyle:UIAlertControllerStyleActionSheet withTitle:title message:message withTitleButtons:buttonsArray destructiveButtonTitle:nil cancelButtonTitle:cancelButtonTitle inController:nil completion:completion];
}

+ (void) showActionSheetAlertWithTitle:(NSString *)title message:(NSString *)message withTitleButtons:(NSArray *)buttonsArray cancelButtonTitle:(NSString *)cancelButtonTitle inController:(UIViewController *)controller completion:(void (^)(NSUInteger buttonIndex))completion  {
    [self showAlertWithStyle:UIAlertControllerStyleActionSheet withTitle:title message:message withTitleButtons:buttonsArray destructiveButtonTitle:nil cancelButtonTitle:cancelButtonTitle inController:controller completion:completion];
}

+ (void) showActionSheetAlertWithTitle:(NSString *)title message:(NSString *)message withTitleButtons:(NSArray *)buttonsArray destructiveButtonTitle:(NSString *)destructiveButtonTitle cancelButtonTitle:(NSString *)cancelButtonTitle inController:(UIViewController *)controller completion:(void (^)(NSUInteger buttonIndex))completion {
    [self showAlertWithStyle:UIAlertControllerStyleActionSheet withTitle:title message:message withTitleButtons:buttonsArray destructiveButtonTitle:destructiveButtonTitle cancelButtonTitle:cancelButtonTitle inController:controller completion:completion];
}

@end

