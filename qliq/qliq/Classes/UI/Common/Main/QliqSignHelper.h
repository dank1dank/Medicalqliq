//
//  QliqSignHelper.h
//  qliq
//
//  Created by Valerii Lider on 11/28/16.
//
//

#import <Foundation/Foundation.h>
#import <QliqSign/QliqSign.h>

typedef NS_ENUM(NSUInteger, QliqSignCallBackType) {
    QliqSignCallBackJustMe,
    QliqSignCallBackMeAndOthers,
    QliqSignCallBackOthersOnly
};

@interface QliqSignHelper : NSObject <QSEditingDoneDelegate>

@property (nonatomic, assign) BOOL returnToFaxView;

+ (UIViewController *)currentTopViewController;
+ (void)openPDFInMediaViewController:(NSString *)path iSaving:(BOOL)iSaving needReturnToFaxView:(BOOL)returnToFaxView needOpenQliqSTOR:(BOOL)needToOpenQliqSTOR;

//Callbacks

- (void)saveBlockImplementationForController:(UIViewController *)controller temporaryFilePath:(NSString *)temporaryFilePath existingFile:(BOOL)isExisting;
- (BOOL)fillSignAuthorizationBlockImplementation;
- (void)setContactsBlockImplementationForController:(UIViewController *)controller callBackType:(QliqSignCallBackType)callBackType isExisting:(BOOL)isExisting;


@end
