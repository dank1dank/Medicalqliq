#import "FacilityTypeViewController.h"
#import "Facility_old.h"

@implementation FacilityTypeViewController

-(void) clickDone: (NSInteger) selectedItem 
{
    [delegate pickerWithSearchViewControllerdidPickItem: ((FacilityType*)[searchArray objectAtIndex: selectedItem]).name
                                            forItemName: @"facilityType"];
    [super clickDone: selectedItem];
}


- (NSArray*) fillDataArray
{
    return [[FacilityType getFacilityTypesToDisplay] retain];
}

- (NSString*) selfTitle
{
    return @"Facility Type";
}

- (NSString*) textForObjectAtIndex: (NSUInteger) anIndex
{
    NSString* result = @"";
    
    if ([searchArray count] > 0)
    {   
        FacilityType* facilityType = nil;
        facilityType = [searchArray objectAtIndex: anIndex];
        result = facilityType.name;
    }
    
    return result;
}

- (NSString*) codeForObjectAtIndex: (NSUInteger) anIndex
{
    return nil;
}

- (NSString*) searchPredicate
{
    return @"name like [c] %@";
}


@end
