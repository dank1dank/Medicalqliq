//
//  GroupListPopover.m
//  qliq
//
//  Created by Valerii Lider on 1/13/15.
//
//

#import "GroupListPopover.h"
#import "ContactListPopoverCell.h"

#define kCellIdentifierContactSortOption @"CONTACT_SORT_OPTION";
#define kValueRowHeight 30.f

@implementation GroupListPopover

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {

        self.heightForRow = kValueRowHeight;
        [self setTableContent];
    }
    return self;
}

#pragma mark - Private

- (void)setTableContent
{
    self.content = nil;
    self.content = [NSMutableArray new];
    
    [self.content addObject:@(GroupListQrgGroups)];
    [self.content addObject:@(GroupListMyGroups)];
    [self.content addObject:@(GroupListOnCallGroups)];
}

#pragma mark - UITableviewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.heightForRow;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    if (self.content)
        count = self.content.count;
        
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = kCellIdentifierContactSortOption;
    ContactListPopoverCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    GroupList groupList = [[self.content objectAtIndex:indexPath.row] integerValue];
    switch (groupList)
    {
        case GroupListQrgGroups:    cell.nameSortOption.text = QliqLocalizedString(@"2120-TitleOrgGroups");   break;
        case GroupListMyGroups:     cell.nameSortOption.text = QliqLocalizedString(@"2121-TitleMyGroups");    break;
        case GroupListOnCallGroups: cell.nameSortOption.text = QliqLocalizedString(@"2122-TitleOnCall");    break;
        default: cell.nameSortOption.text = QliqLocalizedString(@"2124-TitleGroups"); break;
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < self.content.count)
    {
        GroupList groupList = [[self.content objectAtIndex:indexPath.row] integerValue];
        self.currentGroup = groupList;
        if ([self.delegate respondsToSelector:@selector(pressedSortOption:)])
            [self.delegate pressedGroupSortOption:groupList];
    }
    
    [tableView reloadData];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
