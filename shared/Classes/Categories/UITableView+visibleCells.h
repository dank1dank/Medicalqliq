//
//  UITableView+visibleCells.h
//  StartFX
//
//  Created by Aleksey Garbarev on 03.09.13.
//
//

#import <UIKit/UIKit.h>

@interface UITableView (visibleCells)

- (UITableViewCell *)visibleCellAtIndexPath:(NSIndexPath *)indexPath;

@end
