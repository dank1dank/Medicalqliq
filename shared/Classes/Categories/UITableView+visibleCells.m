//
//  UITableView+visibleCells.m
//  StartFX
//
//  Created by Aleksey Garbarev on 03.09.13.
//
//

#import "UITableView+visibleCells.h"
#import "NSArray+RangeCheck.h"

@implementation UITableView (visibleCells)

- (UITableViewCell *)visibleCellAtIndexPath:(NSIndexPath *)indexPath
{
    __block UITableViewCell *resultCell = nil;
    
    NSArray *visibleCells = [self visibleCells];
    NSArray *indexPaths = [self indexPathsForVisibleRows];
    
    NSUInteger visibleIndex = [indexPaths indexOfObject:indexPath];
    if (visibleIndex != NSNotFound && [visibleCells containsIndex:visibleIndex]) {
        resultCell = visibleCells[visibleIndex];
    }
    
    return resultCell;
}

@end
