//
//  Recipients.m
//  qliq
//
//  Created by Aleksey Garbarev on 23.11.12.
//
//

#import "Recipients.h"

#import "QliqGroup.h"
#import "ContactList.h"
#import "QliqDBService.h"

@interface Recipients ()

@property (nonatomic, readwrite) NSInteger recipientsId;

@end

@implementation Recipients

- (id)init {
    self = [super init];
    if (self) {
        self.recipientsArray = [[NSMutableArray alloc] init];
    }
    return self;
}

#pragma mark - NSCopying -

- (id)copyWithZone:(NSZone *)zone
{
    Recipients *copied = [[Recipients alloc] init];
    copied.name = self.name;
    copied.qliqId = self.qliqId;
    
    for (id <Recipient> recipient in self.recipientsArray)
    {
        [copied addRecipient:recipient];
    }
    
    return copied;
}

#pragma mark - DBCoding -

- (id)initWithDBCoder:(DBCoder *)decoder
{
    self = [super init];
    if (self) {
        
        __block NSMutableArray *array = [[NSMutableArray alloc] init];
        
        DBTableConnection * connection = [DBTableConnection connectionWithTable:@"recipients_qliq_id" connectedOn:@"recipients_id" by:[Recipients dbPKColumn]];
        
        self.name = [decoder decodeObjectForColumn:@"name"];
        self.qliqId = [decoder decodeObjectForColumn:@"recipients_qliq_id"];
        
        [decoder decodeObjectsFromConnection:connection decoding:^(DBCoder *table_coder) {
            
            Class recipientClass   = NSClassFromString([table_coder decodeObjectForColumn:@"recipient_class"]);
            //retrieving object by class and id ..
            id <Recipient> recipient = (id <Recipient>)[table_coder decodeObjectOfClass:recipientClass forColumn:@"recipient_id"];
            
            if (recipient) {
                [array addObject:recipient];
            }
        }];
        
        self.recipientsArray = array;
    }
    return self;
}

- (void)encodeWithDBCoder:(DBCoder *)coder
{
    if (!self.name)
        self.name = @"";
    
    [coder encodeObject:self.name forColumn:@"name"];
    [coder encodeObject:self.qliqId forColumn:@"recipients_qliq_id"];
    
    DBTableConnection * connection = [DBTableConnection connectionWithTable:@"recipients_qliq_id" connectedOn:@"recipients_id" by:[Recipients dbPKColumn]];

    [coder encodeObjects:self.recipientsArray connection:connection coding:^(DBCoder *table_coder, id<Recipient> object) {
        [table_coder encodeObject:[object recipientQliqId] forColumn:@"recipient_id"];
        [table_coder encodeObject:NSStringFromClass([object class]) forColumn:@"recipient_class"];
    }];
    
    coder.skipZeroValues = NO;
}

+ (NSString *)dbTable {
    return @"recipients";
}

+ (NSString *)dbPKColumn {
    return @"recipients_id";
}

- (NSString *)dbPKProperty {
    return @"recipientsId";
}

#pragma mark - Getters

- (NSString *)qliqId
{
    if ([self isSingleUser] || [self isGroup])
        _qliqId = [[self recipient] recipientQliqId];
    
    return _qliqId;
}

#pragma mark - Public

- (BOOL)isSingleUser {
    return [self count] == 1 && [[self recipient] isKindOfClass:[QliqUser class]];
}

- (BOOL)isMultiparty {
    return [self count] > 1;
}

- (BOOL)isMultipartyWithoutCurrentUser {
    return [self allRecipientsWithoutCurrentUser].count > 1;
}

- (BOOL)isGroup {
    return [self count] == 1 && [[self recipient] isKindOfClass:[QliqGroup class]];
}

- (BOOL)containsRecipient:(id<Recipient>)containedRecipient
{
    BOOL containsRecipient = NO;
    
    for (id<Recipient> recipient in self.recipientsArray)
    {
        if ([[recipient recipientQliqId] isEqualToString:[containedRecipient recipientQliqId]])
            containsRecipient = YES;
    }
    
    return containsRecipient;
}

#pragma mark -

- (void)setRecipient:(id<Recipient>)recipient
{
    [self.recipientsArray removeAllObjects];
    [self addRecipient:recipient];
}

- (id<Recipient>)recipient {
    return [self recipientAtIndex:0];
}

#pragma mark -

- (void)addRecipient:(id<Recipient>)recipient
{
    if ([recipient conformsToProtocol:@protocol(Recipient)]) {
        [self.recipientsArray addObject:recipient];
    }
    else {
        DDLogError(@"Class %@ is not conforms to Recipient protocol",[recipient class]);
    }
}

- (void)removeRecipient:(id<Recipient>)recipient {
    [self resetToNoPersonalGroup];
    [self.recipientsArray removeObjectIdenticalTo:recipient];
}

- (void)addRecipientsFromArray:(NSArray *)recipients {
    
    for (id<Recipient> recipient in recipients)
    {
        [self addRecipient:recipient];
    }
}

- (void)removeAllRecipients {
    [self.recipientsArray removeAllObjects];
}

- (id<Recipient>)recipientAtIndex:(NSUInteger)index
{
    if (index < self.recipientsArray.count) {
        return self.recipientsArray[index];
    }
    else {
        DDLogError(@"Index %lu out of bounds [0..%lu]", (long)index, (unsigned long)self.recipientsArray.count);
        return nil;
    }
}

- (NSArray *)allRecipients {
    return [NSArray arrayWithArray:self.recipientsArray];
}

- (NSArray *)allRecipientsWithoutCurrentUser {
    NSMutableArray *recipientsWitoutCurrentUser = [self.recipientsArray mutableCopy];
    
    QliqUser *currentUser = [UserSessionService currentUserSession].user;
    
    NSInteger index = NSNotFound;
    index = [self.recipientsArray indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[QliqUser class]]) {
             QliqUser *participant = (QliqUser*)obj;
            return [participant.qliqId isEqualToString:currentUser.qliqId];
        }
        return NO;
    }];

    if (index != NSNotFound && index < recipientsWitoutCurrentUser.count) {
        [recipientsWitoutCurrentUser removeObjectAtIndex:index];
    }
    
    return [NSArray arrayWithArray:recipientsWitoutCurrentUser];
}

- (NSUInteger)count {
    return self.recipientsArray.count;
}

#pragma mark -

- (NSString *)displayNameWrappedToWidth:(CGFloat)width font:(UIFont *)font
{
    NSMutableString * titles = [[NSMutableString alloc] init];
    __block NSInteger printedRecipients = 0;
    NSInteger count = self.recipientsArray.count;
    
    [self.recipientsArray enumerateObjectsUsingBlock:^(id<Recipient> obj, NSUInteger idx, BOOL *stop) {
        
        NSString * recipientString = [NSString stringWithFormat:@"%@%@", printedRecipients == 0 ? @"" : @", ", [obj recipientTitle]];
        NSString * moreString = @"";
        printedRecipients++;
        
        NSInteger remains = count - printedRecipients;
        if (remains > 0) {
            moreString = [NSString stringWithFormat:@" and %ld more",(long)remains];
        }
        
        CGSize sizeOriginal = [titles sizeWithAttributes:@{NSFontAttributeName : font}];
        CGSize labelSize = CGSizeMake(ceilf(sizeOriginal.width), ceilf(sizeOriginal.height));
        
        CGFloat titlesWidth = labelSize.width;
        
        sizeOriginal = [recipientString sizeWithAttributes:@{NSFontAttributeName : font}];
        labelSize = CGSizeMake(ceilf(sizeOriginal.width), ceilf(sizeOriginal.height));
        
        CGFloat recipientStringWidth = labelSize.width;
        
        sizeOriginal = [moreString sizeWithAttributes:@{NSFontAttributeName : font}];
        labelSize = CGSizeMake(ceilf(sizeOriginal.width), ceilf(sizeOriginal.height));
        
        CGFloat moreStringWidth = labelSize.width;
        
        if (titlesWidth + recipientStringWidth + moreStringWidth > width) {
            [titles appendFormat:@"%@%@", recipientString, moreString];
            *stop = YES;
        }
        else {
            [titles appendString:recipientString];
        }
    }];
    
    return titles;
}

- (NSString *)displayName
{
    NSString *result = self.name;
    
    if (!result || result.length == 0 || [result isEqualToString:@"NULL"]) {
        result = [self recipientsTitles];
    }
    
    return result;
}

#pragma mark - Private -

- (void)resetToNoPersonalGroup
{
    if (self.isPersonalGroup)
    {
        self.name = @"";
        self.qliqId = @"";
        self.isPersonalGroup = NO;
    }
}

- (NSString *)recipientsTitles
{
    NSMutableString * titles = [[NSMutableString alloc] init];
    
    __block NSInteger printedRecipients = 0;
    
    [self.recipientsArray enumerateObjectsUsingBlock:^(id<Recipient> obj, NSUInteger idx, BOOL *stop) {
        [titles appendFormat:@"%@%@", printedRecipients == 0 ? @"" : @", ", [obj recipientTitle]];
        printedRecipients++;
    }];
    
    return titles;
}

/* Equal if another recipients contain all self recipients and other properties are same */
- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[Recipients class]]) {
        
        BOOL isEqual = YES;
        
        Recipients *anotherRecipients = object;
        
        isEqual &= [self count] == [anotherRecipients count];
        isEqual &= [self.name isEqualToString:anotherRecipients.name];
        
        if (isEqual) {
            for (id <Recipient> recipient in self.recipientsArray)
            {
                isEqual &= [anotherRecipients containsRecipient:recipient];
            }
        }
        
        return isEqual;
        
    }
    else {
        return [super isEqual:object];
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@\nqliqId = %@,\nrecipientsId = %ld,\nname = %@,\nrecipients = %@",[super description],[self qliqId], (long)self.recipientsId, self.name, self.recipientsArray];
}

@end
