//
//  RoleTextFieldDataSourceObject.h
//  qliq
//
//  Created by Valerii Lider on 7/22/16.
//
//

#import <Foundation/Foundation.h>
#import "MLPAutoCompleteTextFieldDataSource.h"

@interface RoleTextFieldDataSourceObject : NSObject <MLPAutoCompleteTextFieldDataSource>
//Set this to true to return an array of autocomplete objects to the autocomplete textfield instead of strings.
//The objects returned respond to the MLPAutoCompletionObject protocol.
@property (assign) BOOL testWithAutoCompleteObjectsInsteadOfStrings;


//Set this to true to prevent auto complete terms from returning instantly.
@property (assign) BOOL simulateLatency;

+ (RoleTextFieldDataSourceObject *)shared;

- (void)autoCompleteTextField:(MLPAutoCompleteTextField *)textField
 possibleCompletionsForString:(NSString *)string
            completionHandler:(void (^)(NSArray *))handler;

- (NSArray *)autoCompleteTextField:(MLPAutoCompleteTextField *)textField
      possibleCompletionsForString:(NSString *)string;



@end
