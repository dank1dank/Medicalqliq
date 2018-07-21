#import <UIKit/UIKit.h>

@class HorizontalPickerView;
@class HorizontalPickerCell;

// HorizontalPickerView protocol defines main interface for interaction with picker
@protocol HorizontalPickerViewDelegate

- (NSString*) horizontalPickerView: (HorizontalPickerView*) pickerView 
                        dateForRow: (NSInteger) row;

- (NSString*) horizontalPickerView: (HorizontalPickerView*) pickerView 
                        dayForRow: (NSInteger) row;

- (NSInteger) horizontalPickerViewNumberOfRows: (HorizontalPickerView*) pickerView;

- (void) horizontalPickerView: (HorizontalPickerView*) pickerView
                 didSelectRow: (NSInteger) row;

@end


@interface HorizontalPickerView: UIView <UITableViewDataSource, UITableViewDelegate>
{
    UITableView* horizontalTableView;
    UIImageView* gradientView;
    UIView* dividerView;
    
    BOOL snapped;
    
    NSObject<HorizontalPickerViewDelegate>* delegate;
    
    HorizontalPickerCell* magnifierOverlayCells[2];
    
    int selectedCell;
}

@property (nonatomic, retain) NSObject<HorizontalPickerViewDelegate>* delegate;
@property (nonatomic, assign) UIView* dividerView;
@property (nonatomic, assign) float rowWidth;

- (void) reload;

- (void) selectRow: (NSInteger)row
          animated: (BOOL)animated;

- (UITableViewCell*) dequeueReusableCellWithIdentifier: (NSString*) identifier;

- (void) forceMagnifierReresh;

@end
