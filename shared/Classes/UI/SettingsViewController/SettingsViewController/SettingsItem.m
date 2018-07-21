//
//  SettingsItem.m
//  qliq
//
//  Created by Aleksey Garbarev on 18.10.12.
//
//

#import "SettingsItem.h"

/**
    SettingsItem implementation
 **/
#define kHeightNotSet NSUIntegerMax
#define kDefaultRowHeight 44

@implementation SettingsItem
@synthesize title, info, rowHeight, valueView, style;
@synthesize tag, showShevron, secondLineView, secondLineHeight;
@synthesize context;
@synthesize keyWidth;


- (NSUInteger)rowHeight{
    
    NSUInteger height = rowHeight;
    if (height == kHeightNotSet){
        height = kDefaultRowHeight;
        if (self.style == SettingsItemStyleCustomView)
            height = valueView.bounds.size.height;
    }
    
    return height;
}

- (id) init{
    self = [super init];
    if (self) {
        rowHeight = kHeightNotSet;
    }
    return self;
}

- (id) initWithStyle:(SettingsItemStyle) _style{
    self = [self init];
    if (self){
        self.style = _style;
        
    }
    return self;
}

- (BOOL)isEqual:(SettingsItem *)object{
    if ([object isKindOfClass:[SettingsItem class]]) {
        return title ? ([self.title isEqual:object.title] &&  self.tag == object.tag) : self.tag == object.tag;
    }else{
        return [super isEqual:object];
    }
}



-(NSString *)description{
    return [NSString stringWithFormat:@"%@<title = %@, valueView = %@>",[super description],self.title, [self.valueView class]];
}


@end

/**
     SettingsSection implementation
**/
@implementation SettingsSection
@synthesize title;
@synthesize order;

+ (SettingsSection *) newWithTitle:(NSString *)title order:(NSInteger) order{
    return [[SettingsSection alloc] initWithTitle:title order:order];
}

- (id) initWithTitle:(NSString *) _title order:(NSInteger) _order{
    self = [super init];
    if (self){
        self.order = _order;
        self.title = _title;
    }
    return self;
}

- (NSComparisonResult) compare: (SettingsSection *) object{
    return self.order > object.order ? NSOrderedDescending : self.order < object.order ? NSOrderedAscending : NSOrderedSame;
}

- (id)copyWithZone:(NSZone *)zone{
    return [[SettingsSection allocWithZone:zone] initWithTitle:self.title order:self.order];
}
@end

/**
      SettingsItems implementation
 **/
@implementation SettingsItems{
    NSMutableDictionary * dictionary;
    NSMutableDictionary * sections;
}

- (id) init{
    self = [super init];
    if (self){
        dictionary = [[NSMutableDictionary alloc] init];
        sections = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void) setItems:(NSArray *) items forSection:(SettingsSection *) section{
    NSNumber * key = [NSNumber numberWithInteger:section.order];
    if (items) {
        [dictionary setObject:[items mutableCopy] forKey:key];
        [sections setObject:section forKey:key];
    } else {
        [dictionary removeObjectForKey:key];
        [sections removeObjectForKey:key];
    }
}


- (NSArray *) allItemsForSection:(NSUInteger) section{
    return [dictionary objectForKey:[NSNumber numberWithInteger:section]];
}

- (NSString *) titleForSection:(NSUInteger) _section{
    SettingsSection * section = (SettingsSection *)[sections objectForKey:[NSNumber numberWithInteger:_section]];
    return section.title;
}

- (NSUInteger) numberOfSections{
    return [[dictionary allKeys] count];
}

- (NSUInteger) numberOfItemsInSection:(NSUInteger) section{
    return [[dictionary objectForKey:[NSNumber numberWithInteger:section]] count];
}

- (SettingsItem *) itemForIndexPath:(NSIndexPath *) indexPath{
    return [[dictionary objectForKey:[NSNumber numberWithInteger:indexPath.section]] objectAtIndex:indexPath.row];
}

- (NSIndexPath *) indexPathForItem:(SettingsItem *) item{
    __block NSIndexPath * indexPath = nil;
    
    [dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber * section, NSArray * objects, BOOL *stop) {
       
        NSUInteger index = [objects indexOfObject:item];
        if (index != NSNotFound){
            indexPath = [NSIndexPath indexPathForRow:index inSection:[section integerValue]];
            * stop = YES;
        }
        
    }];

    return indexPath;
}

- (SettingsItem *) itemWithTitle:(NSString *) title andTag:(NSUInteger) tag{

    for (NSArray * sectionArray in [dictionary allValues]){
        for (SettingsItem * item in sectionArray){
            if ( (item.title && ([item.title isEqualToString:title] && item.tag == tag)) || item.tag == tag ){
                return item;
            }
        }
    }
    
    return nil;
}


- (void) deleteItemAtIndexPath:(NSIndexPath *) indexPath{
    [[dictionary objectForKey:[NSNumber numberWithInteger:indexPath.section]] removeObjectAtIndex:indexPath.row];
}

- (void) insertItem: (SettingsItem *) item atIndexPath:(NSIndexPath *) indexPath{
    [[dictionary objectForKey:[NSNumber numberWithInteger:indexPath.section]] insertObject:item atIndex:indexPath.row];
}


- (NSString *) titleForHeaderInSection:(NSUInteger) section{
    return [self titleForSection:section];
}



@end
