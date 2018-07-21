#import "HorizontalPickerView.h"
#import "HorizontalPickerCell.h"
#import <QuartzCore/CALayer.h>

static const float MagnificationCoeffitient = 0.1f;

@interface HorizontalPickerView (Private)

- (void) defineSelectedCell;
- (void) snapScrollView;

@end

@implementation HorizontalPickerView

@synthesize delegate;
@synthesize dividerView;
@dynamic rowWidth;

#pragma mark -
#pragma mark -- Generic --

- (id) initWithFrame: (CGRect) frame
{
    
    self = [super initWithFrame: frame];
    if (self)
    {
        selectedCell = -1;
        
        // Init horizontal table view
        horizontalTableView = [[[UITableView alloc] initWithFrame: CGRectZero] autorelease];
        horizontalTableView.transform = CGAffineTransformMakeRotation(M_PI / 2);
        horizontalTableView.dataSource = self;
        horizontalTableView.delegate = self;
        horizontalTableView.frame = CGRectMake(0.0f, 0.0f, 320, 55);
        horizontalTableView.rowHeight = 60;
        horizontalTableView.showsVerticalScrollIndicator = NO;
        horizontalTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        horizontalTableView.separatorColor = [UIColor whiteColor];
        
        gradientView = [[[UIImageView alloc] initWithImage: [UIImage imageNamed: @"picker-gradient.png"]] autorelease];
        
        // Init divider view
        self.dividerView = [[[UIView alloc] initWithFrame: CGRectMake(CGRectGetMinX(horizontalTableView.frame) + (CGRectGetWidth(horizontalTableView.frame) - horizontalTableView.rowHeight) / 2, CGRectGetMinY(horizontalTableView.frame),
                                                                     horizontalTableView.rowHeight, CGRectGetHeight(horizontalTableView.frame))] autorelease];
        dividerView.userInteractionEnabled = NO;

        // Set content inset so the first cell will be at the center
        float contentInset = (CGRectGetWidth(horizontalTableView.frame) - self.rowWidth) / 2;
        horizontalTableView.contentInset = UIEdgeInsetsMake(contentInset, 0.0f, contentInset, 0.0f);
        
        
        [self addSubview: horizontalTableView];
        [self addSubview: gradientView];
        [self addSubview: dividerView];
    }
    return self;
} // [HorizontalPickerView initWithFrame:]


- (void) layoutSubviews
{
    dividerView.frame = CGRectMake(CGRectGetMinX(horizontalTableView.frame) + (CGRectGetWidth(horizontalTableView.frame) - CGRectGetWidth(dividerView.frame)) / 2, CGRectGetMinY(horizontalTableView.frame) + 6,
                                   CGRectGetWidth(dividerView.frame), CGRectGetHeight(horizontalTableView.frame) - 12);


    // Layout magnified cells
    int offset = horizontalTableView.contentOffset.y + (CGRectGetWidth(horizontalTableView.frame) - self.rowWidth) / 2;
    int newSelectedCell = offset / horizontalTableView.rowHeight;
    
    
    
    HorizontalPickerCell* cells[2];
    cells[0] = (HorizontalPickerCell*)[horizontalTableView cellForRowAtIndexPath: [NSIndexPath indexPathForRow: newSelectedCell inSection: 0]];
    cells[1] = (HorizontalPickerCell*)[horizontalTableView cellForRowAtIndexPath: [NSIndexPath indexPathForRow: newSelectedCell + 1 inSection: 0]];
    
    if (newSelectedCell != selectedCell)
    {
        selectedCell = newSelectedCell;
        
        for (int i = 0; i < 2; i++)
        {
            if (!magnifierOverlayCells[i].dateLabel.text || [magnifierOverlayCells[i].dateLabel.text isEqualToString: @""])
            {
                [magnifierOverlayCells[i] setNeedsLayout];
            }
            magnifierOverlayCells[i].dateLabel.text = cells[i].dateLabel.text;
            magnifierOverlayCells[i].dayLabel.text = cells[i].dayLabel.text;
        }
    }
    
    int modOffset = offset % (int)self.rowWidth;
    
    for (int i = 0; i < 2; i++)
    {
        magnifierOverlayCells[i].center = CGPointMake((int)(CGRectGetWidth(dividerView.frame) / 2 + modOffset - i * self.rowWidth), CGRectGetHeight(dividerView.frame) / 2);
    }
    magnifierOverlayCells[0].transform = CGAffineTransformMakeScale(1.0 + ((self.rowWidth - modOffset) / self.rowWidth) * MagnificationCoeffitient, 
                                                                    1.0 + ((self.rowWidth - modOffset) / self.rowWidth) * MagnificationCoeffitient);
    magnifierOverlayCells[1].transform = CGAffineTransformMakeScale(1.0 + (modOffset / self.rowWidth) * MagnificationCoeffitient, 
                                                                    1.0 + (modOffset / self.rowWidth) * MagnificationCoeffitient);

    float contentInset = (CGRectGetWidth(horizontalTableView.frame) - self.rowWidth) / 2;
    horizontalTableView.contentInset = UIEdgeInsetsMake(contentInset, 0.0f, contentInset, 0.0f);   
} // [HorizontalPickerView layoutSubviews]


- (void) dealloc 
{
    delegate = nil;
    dividerView = nil;
    
    [super dealloc];
} // [HorizontalPickerView dealloc]


#pragma mark -
#pragma mark -- UITableViewDataSource --

- (NSInteger) tableView: (UITableView*) tableView
  numberOfRowsInSection: (NSInteger)section
{
    NSInteger result = 0;
    
    if (delegate)
    {
        result = [delegate horizontalPickerViewNumberOfRows: self];
    }
        
    return result;
} // [HorizontalPickerView tableView: numberOfRowsInSection:]


- (UITableViewCell*) tableView: (UITableView*) tableView
         cellForRowAtIndexPath: (NSIndexPath*) indexPath
{
	NSLog(@" horizontal picker row : %d",indexPath.row);
    HorizontalPickerCell* cell = (HorizontalPickerCell*)[tableView dequeueReusableCellWithIdentifier: @"cell"];
	
	if (cell == nil)
	{
        cell = [[[HorizontalPickerCell alloc] initWithStyle: UITableViewCellStyleDefault
                                           reuseIdentifier: @"cell"] autorelease];
    }
    
    if (delegate) 
    {
        cell.dateLabel.text = [delegate horizontalPickerView: self dateForRow: indexPath.row];
        cell.dayLabel.text = [delegate horizontalPickerView: self dayForRow: indexPath.row];
    }

    cell.contentView.transform = CGAffineTransformMakeRotation(-M_PI / 2);
    
    return cell;
} // [HorizontalPickerView tableView: cellForRowAtIndexPath:]


#pragma mark -
#pragma mark -- UITableViewDelegate --


- (void)        tableView: (UITableView*) tableView 
  didSelectRowAtIndexPath: (NSIndexPath*) indexPath
{
    [tableView deselectRowAtIndexPath: indexPath animated: YES];
    
    [self selectRow: indexPath.row animated: YES];
} // [HorizontalPickerView tableView: didSelectRowAtIndexPath:]

- (void) tableView: (UITableView*) tableView
   willDisplayCell: (UITableViewCell*) cell
 forRowAtIndexPath: (NSIndexPath*) indexPath
{
    // Here we rely on the fact that there will be more than one cell in the list so we'll releayout
    // magnifier glass
    static int willDisplayCellCounter = 0;
    if (willDisplayCellCounter < 2)
    {
        willDisplayCellCounter++;
        if (willDisplayCellCounter == 2)
        {
            [self setNeedsLayout];
            selectedCell = -1;
        }
    }
} // [HorizontalPickerView tableView: didSelectRowAtIndexPath:]


#pragma mark -
#pragma mark -- UIScrollViewDataSource --


- (void) scrollViewDidEndDecelerating: (UIScrollView*) scrollView
{
    // Check to avoid duplicate call
    if (!snapped)
    {
        [self snapScrollView];
    }
} // [HorizontalPickerView scrollViewDidEndDecelerating:]


- (void) scrollViewDidEndDragging: (UIScrollView*) scrollView
                   willDecelerate: (BOOL) decelerate
{
    if (decelerate == NO)
    {
        [self snapScrollView];
    }
} // [HorizontalPickerView scrollViewDidEndDragging: willDecelerate:]


- (void) scrollViewDidEndScrollingAnimation: (UIScrollView*) scrollView
{
    [self defineSelectedCell];
} // [HorizontalPickerView scrollViewDidEndScrollingAnimation:]


- (void) scrollViewDidScroll: (UIScrollView*) scrollView
{
    snapped = NO;
    [self setNeedsLayout];
} // [HorizontalPickerView scrollViewDidScroll:]


#pragma mark -
#pragma mark -- Private functionality --

- (void) defineSelectedCell
{
    float selectedCellOffset = horizontalTableView.contentOffset.y + (CGRectGetWidth(horizontalTableView.frame) - self.rowWidth) / 2;
    int selectedCell = selectedCellOffset / horizontalTableView.rowHeight;
    
    if (delegate)
    {
        [delegate horizontalPickerView: self didSelectRow: selectedCell];
    }
} // [HorizontalPickerView defineSelectedCell]


- (void) snapScrollView
{
    snapped = YES;
    
    int offset = horizontalTableView.contentOffset.y + (CGRectGetWidth(horizontalTableView.frame) - self.rowWidth) / 2;
    
    int intOffset = offset / self.rowWidth;
    int modOffset = offset % (int)self.rowWidth;
    int newModOffset;
    
    if (modOffset > self.rowWidth / 2)
    {
        newModOffset = self.rowWidth;
    }
    else 
    {
        newModOffset = 0;
    }
    
    offset = intOffset * self.rowWidth + newModOffset - (CGRectGetWidth(horizontalTableView.frame) - self.rowWidth) / 2;
    
    if (newModOffset == modOffset)
    {
        [self defineSelectedCell];
    }
    else
    {
        [horizontalTableView setContentOffset: CGPointMake(0, offset)
                              animated: YES];
    }
} // [HorizontalPickerView snapScrollView]


#pragma mark -
#pragma mark -- Public functionality --


- (void) reload
{
    [horizontalTableView reloadData];
} // [HorizontalPickerView snapScrollView]
                

- (void) selectRow: (NSInteger) row
          animated: (BOOL) animated
{
    [horizontalTableView setContentOffset: CGPointMake(0, self.rowWidth * row - (CGRectGetWidth(horizontalTableView.frame) - self.rowWidth) / 2)
                                 animated: animated];
} // [HorizontalPickerView selectRow: animated:]


- (UITableViewCell*) dequeueReusableCellWithIdentifier: (NSString*) identifier
{
    return [horizontalTableView dequeueReusableCellWithIdentifier: identifier];
} // [HorizontalPickerView dequeueReusableCellWithIdentifier:]


- (float) rowWidth
{
    return horizontalTableView.rowHeight;
} // [HorizontalPickerView rowWidth]


- (void) setRowWidth: (float) aWidth
{
    horizontalTableView.rowHeight = aWidth;
    [self setNeedsLayout];
} // [HorizontalPickerView setRowWidth:]


- (void) setDividerView: (UIView*) aView
{
    [dividerView removeFromSuperview];
    
    [self addSubview: aView];
    dividerView = aView;
    dividerView.clipsToBounds = YES;
    
    // Init magnifier overlay cells
    for (int i = 0; i < 2; i++)
    {
        magnifierOverlayCells[i] = [[[HorizontalPickerCell alloc] initWithStyle: UITableViewCellStyleDefault
                                                                reuseIdentifier: nil] autorelease];
        magnifierOverlayCells[i].backgroundColor = [UIColor clearColor];
        
        magnifierOverlayCells[i].verticalAlignedContent = YES;
        
        magnifierOverlayCells[i].dateLabel.backgroundColor = [UIColor clearColor];
        magnifierOverlayCells[i].dayLabel.backgroundColor = [UIColor clearColor];
        
        magnifierOverlayCells[i].dateLabel.textColor = [UIColor whiteColor];
        magnifierOverlayCells[i].dayLabel.textColor = [UIColor whiteColor];
        
        magnifierOverlayCells[i].frame = CGRectMake(0.0f, 0.0f, 
                                                    self.rowWidth, CGRectGetHeight(dividerView.frame));

        
        [dividerView addSubview: magnifierOverlayCells[i]];
    }
    
    [self setNeedsLayout];
    
} // [HorizontalPickerView setDividerView:]

- (void) forceMagnifierReresh
{
    // Layout magnified cells
    int offset = horizontalTableView.contentOffset.y + (CGRectGetWidth(horizontalTableView.frame) - self.rowWidth) / 2;
    int newSelectedCell = offset / horizontalTableView.rowHeight;
	
    HorizontalPickerCell* cells[2];
    cells[0] = (HorizontalPickerCell*)[horizontalTableView cellForRowAtIndexPath: [NSIndexPath indexPathForRow: newSelectedCell inSection: 0]];
    cells[1] = (HorizontalPickerCell*)[horizontalTableView cellForRowAtIndexPath: [NSIndexPath indexPathForRow: newSelectedCell + 1 inSection: 0]];
	
	for (int i = 0; i < 2; i++) {
		magnifierOverlayCells[i].dateLabel.text = cells[i].dateLabel.text;
		magnifierOverlayCells[i].dayLabel.text = cells[i].dayLabel.text;		
		[magnifierOverlayCells[i] setNeedsLayout];
		//[magnifierOverlayCells[i] setNeedsDisplay];
	}
}

@end
