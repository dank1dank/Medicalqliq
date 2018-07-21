#import "StatesPickerViewController.h"
#import "State.h"

@implementation StatesPickerViewController

-(void) clickDone: (NSInteger) selectedItem 
{
    [delegate pickerWithSearchViewControllerdidPickItem: ((State*)[searchArray objectAtIndex: selectedItem]).stateCode
                                            forItemName: @"stateCode"];

    [delegate pickerWithSearchViewControllerdidPickItem: ((State*)[searchArray objectAtIndex: selectedItem]).stateName
                                            forItemName: @"stateName"];
    
    [super clickDone: selectedItem];
}


- (NSArray*) fillDataArray
{
    return [[State getAllStatesToDisplay] retain];
}

- (NSString*) selfTitle
{
    return @"State List";
}

- (NSString*) textForObjectAtIndex: (NSUInteger) anIndex
{
    NSString* result = @"";
    
    if ([searchArray count] > 0)
    {   
        State *stateObj = nil;
        stateObj = [searchArray objectAtIndex: anIndex];
        result = stateObj.stateName;
    }
        
    return result;
}

- (NSString*) codeForObjectAtIndex: (NSUInteger) anIndex
{
    NSString* result = @"";
    
    if ([searchArray count] > 0)
    {   
        State *stateObj = nil;
        stateObj = [searchArray objectAtIndex: anIndex];
        result = stateObj.stateCode;
    }
    
    return result;
}

- (NSString*) searchPredicate
{
    return @"stateCode like [c] %@ OR stateName like [c] %@";
}


@end
