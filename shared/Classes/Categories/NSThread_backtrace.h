//
//  NSThread_backtrace.h
//  qliq
//
//  Created by Aleksey Garbarev on 15.11.12.
//
//

#import <Foundation/Foundation.h>

@interface NSThread (Backtrace)

+ (NSString *) callStackSymbolsWithLimit:(NSUInteger) depth;

@end

@implementation NSThread (Backtrace)

+ (NSString *) callStackSymbolsWithLimit:(NSUInteger) depth{
    NSRange stackSymbolsRange;
    stackSymbolsRange.length = depth;
    stackSymbolsRange.location = 1;//from first symbol (excluding)
    
    NSUInteger counter = 0;
    NSMutableString * symbols = [[NSMutableString alloc] init];
    NSRange resultRange;
    for (NSObject * symbol in [NSThread callStackSymbols]){
        counter++;
        if (counter > stackSymbolsRange.location){
            NSString * symbolDescription = [symbol description];
            NSRange first = [symbolDescription rangeOfString:@"["];
            NSRange last  = [symbolDescription rangeOfString:@"]" options:NSBackwardsSearch];
            resultRange.location = first.location - 1;
            resultRange.length = last.location - resultRange.location + 1;
            if ([symbols length] > 0) [symbols appendString:@"\n"];
            
            if (first.location != NSNotFound){
                
                [symbols appendFormat:@"%@",[symbolDescription substringWithRange:resultRange]];
            }else{
                NSArray * array = [symbolDescription componentsSeparatedByString:@" "];
                [symbols appendFormat:@"%@ + %@",[array objectAtIndex:[array count]- 3],[array objectAtIndex:[array count] - 1]];
            }
        }
        if (counter == stackSymbolsRange.location + stackSymbolsRange.length) break;
    }
    
    return symbols;
}

@end