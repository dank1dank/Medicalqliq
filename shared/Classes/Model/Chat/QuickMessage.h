//
//  QuickMessage.h
//  qliq
//
//  Created by Paul Bar on 2/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QuickMessage : NSObject{
	NSInteger quickMessageId;
	NSString *message;
    NSString *uuid;
    NSString *category;
    
}
@property (nonatomic) NSInteger quickMessageId;
@property (nonatomic, strong) NSString  *message;
@property (nonatomic) NSInteger displayOrder;
@property (nonatomic, strong) NSString  *uuid;
@property (nonatomic, strong) NSString  *category;


//Static methods.
+ (NSMutableArray *) getQuickMessages;
+ (NSInteger) addQuickMessage:(QuickMessage *)newQuickMsg;
+ (BOOL) updateQuickMessage:(QuickMessage *)quickMsg;
+ (BOOL) updateQuickMessageOrder:(QuickMessage *)quickMsg;
+ (BOOL) deleteQuickMessage:(QuickMessage *)quickMsg;
+ (BOOL) isQuickMessageExistWithMessage:(NSString*)message;
+ (BOOL) deletePriorQuickMessages;

//Instance methods.
- (id) initWithPrimaryKey:(NSInteger)pk;

@end