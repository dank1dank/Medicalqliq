//
//  SettingsItem.h
//  qliq
//
//  Created by Aleksey Garbarev on 18.10.12.
//
//

#import <Foundation/Foundation.h>

@interface SettingsSection : NSObject <NSCopying>

@property (nonatomic, strong) NSString * title;
@property (nonatomic, readwrite) NSInteger order;

+ (SettingsSection *) newWithTitle:(NSString *)title order:(NSInteger) order;

@end


typedef enum {SettingsItemStyleKeyValueRight = 10, SettingsItemStyleKeyValueLeft, SettingsItemStyleCustomView, SettingsItemStyleSingleTitle} SettingsItemStyle;

@interface SettingsItem : NSObject

@property (nonatomic, strong) NSString * title;
@property (nonatomic, strong) NSString * info;
@property (nonatomic, strong) UIView * valueView;
@property (nonatomic, strong) UIView * secondLineView;
@property (nonatomic, readwrite) NSUInteger secondLineHeight;
@property (nonatomic, readwrite) NSUInteger rowHeight;
@property (nonatomic, readwrite) SettingsItemStyle style;
@property (nonatomic, readwrite) NSUInteger tag;
@property (nonatomic, readwrite) BOOL showShevron;
@property (nonatomic, strong) id context;
@property (nonatomic, readwrite) NSUInteger keyWidth;

- (id) initWithStyle:(SettingsItemStyle) _style;

@end

/*
 
 */

@interface SettingsItems : NSObject

- (void) setItems:(NSArray *) items forSection:(SettingsSection *) section;

- (NSArray *) allItemsForSection:(NSUInteger) section;

- (NSUInteger) numberOfSections;
- (NSUInteger) numberOfItemsInSection:(NSUInteger) section;
- (NSString *) titleForHeaderInSection:(NSUInteger) section;

- (SettingsItem *) itemWithTitle:(NSString *) title andTag:(NSUInteger) tag;
- (SettingsItem *) itemForIndexPath:(NSIndexPath *) indexPath;
- (void) deleteItemAtIndexPath:(NSIndexPath *) indexPath;
- (void) insertItem: (SettingsItem *) item atIndexPath:(NSIndexPath *) indexPath;

- (NSIndexPath *) indexPathForItem:(SettingsItem *) item;
@end
