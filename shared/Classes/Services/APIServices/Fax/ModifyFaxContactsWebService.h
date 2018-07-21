 //
//  Created by Adam Sowa.
//
#import <Foundation/Foundation.h>

@class FaxContact;

typedef NS_ENUM(NSInteger, ModifyFaxContactOperation) {
    AddModifyFaxContactOperation = 0,
    RemoveModifyFaxContactOperation = 1,
};

@interface ModifyFaxContactsWebService : NSObject

- (void) callForContact:(FaxContact *)contact operation:(ModifyFaxContactOperation)operation withCompletition:(CompletionBlock)completitionBlock;

@end
