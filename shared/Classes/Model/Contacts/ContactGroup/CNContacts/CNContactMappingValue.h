//
//  CNContactMappingValue.h
//  qliq
//
//  Created by Valerii Lider on 8/16/16.
//
//

#import <Foundation/Foundation.h>
#import <Contacts/Contacts.h>

typedef BOOL(^CNContactMappingValueTestBlock)(id labelValue);

@interface CNContactMappingValue : NSObject

@property (nonatomic) NSString *key;

@property (nonatomic, copy) CNContactMappingValueTestBlock multivalueTestBlock;

+ (id) newWithKey:(NSString *)key;
+ (id) newWithKey:(NSString *)key andLabelType:(NSString *)label;
+ (id) newWithKey:(NSString *)key andNotLabelType:(NSString *)label;

@end

