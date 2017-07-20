//
//  TimeSeries.m
//  bigml-objc
//
//  Created by sergio on 19/07/17.
//  Copyright © 2017 BigML Inc. All rights reserved.
//

#import "TimeSeries.h"

NSString* gSubmodelKeys[] = [@"indices", @"names", @"criterion", @"limit"];

@implementation TimeSeries

/**
 * Computes the forecasts for each of the models in the submodels
 * array. The number of forecasts is set by horizon.
 *
 * @param {object} available submodels
 * @param {integer} number of points to compute
 */
- (NSArray*)forecasts:(NSArray*)submodels horizon:(NSInteger)horizon {
    
    NSMutableArray* forecasts = [NSMutableArray new];
    for (NSDictionary* submodel in submodels) {
        NSString* name = submodel[@"name"];
        NSString* seasonality = nil;
        id pointForecast = nil;
        if ([name containsString:@","]) {
            NSArray* labels = [name componentsSeparatedByString:@"'"];
            NSError* error = labels[0];
            NSString* trend = labels[1];
            seasonality = labels[2];
            pointForecast =  SUBMODELS[trend](submodel, horizon, seasonality);
        } else {
            pointForecast =  SUBMODELS[name](submodel, horizon);
        }
        [forecasts addObject:@{ @"submodel" : name,
                                @"pointForecast" : pointForecast }];
    }
    return forecasts;
}

- (NSArray*)matches:(NSString*)text
            pattern:(NSString*)pattern
      caseSensitive:(BOOL)caseSensitive {
    
    NSRange searchedRange = NSMakeRange(0, [text length]);
    NSError* error = nil;
    NSRegularExpression* regex = [NSRegularExpression
                                  regularExpressionWithPattern:pattern
                                  options:0
                                  error:&error];
    
    NSMutableArray* matches = [NSMutableArray new];
    if (!error) {
        for (NSTextCheckingResult* match in
             [regex matchesInString:text options:0 range:searchedRange]) {
            
            NSString* matchText = [text substringWithRange:[match range]];
            NSLog(@"Timeseries matches: %@", matchText);
            if (!caseSensitive) {
                matchText = [matchText lowercaseString];
            }
            [matches addObject:matchText];
        }
    }
    return matches;
}

/**
 * Filters the submodels available for the field in the time-series
 * model according to the criteria provided in the forecast input data
 * for the field
 *
 * @param {object} available submodels
 * @param {object} description of the filters to select the submodels
 */
- (NSArray*)filteredSubmodels:(NSArray*)submodels filter:(NSDictionary*)filterInfo {
    
    NSMutableArray* fieldSubmodels = [NSMutableArray new];
    NSMutableArray* submodelNames = [NSMutableArray new];
    NSArray* indices = filterInfo[gSubmodelKeys[0]] ?: @[];
    NSArray* names = filterInfo[gSubmodelKeys[1]] ?: @[];
    id criterion = filterInfo[gSubmodelKeys[2]];
    id limit = filterInfo[gSubmodelKeys[3]];

    if (indices.count == names.count == 0) {
        return @[];
    }
    for (NSNumber* index in indices) {
        [fieldSubmodels addObject:submodels[index.intValue]];
    }
    for (id submodel in fieldSubmodels) {
        [submodelNames addObject:submodel[@"name"]];
    }
    if (names.count > 0) {
        NSString* pattern = [names componentsJoinedByString:@"|"];
        for (id submodel in submodels) {
            if (![submodelNames containsObject:submodel[@"name"]] &&
                [self matches:submodel[@"name"]
                      pattern:pattern
                caseSensitive:NO].count > 0) {
                    
                    [fieldSubmodels addObject:submodel];
                }
        }
    }
    
    NSArray* (^filter)(NSArray* submodels, id criterion, id limit) =
    NSArray* ^(NSArray* submodels, id criterion, id limit) {
        
        if (criterion) {
            NSInteger c = [criterion intValue];
            submodels = [submodels
                         sortedArrayUsingComparator:^NSComparisonResult(NSArray* a, NSArray* b) {
                             if (([a[c] intValue] || INFINITY) > ([b[c] intValue] || INFINITY)) {
                                 return 1;
                             } else if ((a[c] || INFINITY) < (b[c] || INFINITY)) {
                                 return -1;
                             } else {
                                 return 0;
                             }
                         }];
        }
        if (limit) {
            NSInteger l = [limit intValue];
            submodels = [submodels subarrayWithRange:NSMakeRange(0, l)];
        }
        return submodels;
    };
    
    return filter(fieldSubmodels, criterion, limit);
}


@end
