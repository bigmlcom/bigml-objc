//
//  TimeSeries.m
//  bigml-objc
//
//  Created by sergio on 19/07/17.
//  Copyright © 2017 BigML Inc. All rights reserved.
//

#import "TimeSeries.h"

NSString* gSubmodelKeys[] = [@"indices", @"names", @"criterion", @"limit"];

@interface TimeSeries ()

@property (nonatomic) BOOL allNumericObjectives;
@property (nonatomic) NSInteger period;
@property (nonatomic) NSMutableDictionary* submodels;
@property (nonatomic) NSInteger dampedTrend;
@property (nonatomic) NSInteger seasonality;
@property (nonatomic) NSInteger trend;
@property (nonatomic) NSDictionary* timeRange;
@property (nonatomic) NSDictionary* fieldParameters;

@property (nonatomic) NSDictionary* timeSeriesInfo;
@property (nonatomic) NSMutableArray* inputFields;
@property (nonatomic) NSString* objectiveField;
@property (nonatomic) NSArray* objectiveFields;

@end


@implementation TimeSeries

/**
 * Auxiliary function to load the resource info in the Model structure.
 *
 * @param {object} error Error info
 * @param {object} resource TimeSeries's resource info
 */
- (void)fillStructure:(NSDictionary*)resource error:(NSError*)error {

    NSAssert(error == nil, @"Cannot create local TimeSeries.");
    NSAssert([resource[@"resource"] isKindOfClass:[NSString class]],
             @"TimeSeries: wrong resource id.");
    NSAssert([resource[@"status"][@"code"] intValue] == 5,
             @"TimeSeries: Resource not ready");
    NSAssert(resource[@"objective_fields"], @"TimeSeries: objective fields not found.");
    NSAssert(resource[@"time_series"], @"TimeSeries: time series not found.");
    
    NSMutableArray* fieldIds = [NSMutableArray new];
    if (resource[@"input_fields"]) {
        self.inputFields = resource[@"input_fields"]; //-- mutableCopy?
    }
    if (resource[@"objective_fields"]) {
        self.objectiveFields = resource[@"objective_fields"];
        self.objectiveField = resource[@"objective_field"];
    }
    if (resource[@"time_series"]) {
        self.timeSeriesInfo = resource[@"time_series"];
        if (self.timeSeriesInfo[@"fields"]) {
            self.fields = self.timeSeriesInfo[@"fields"];
            if (!self.inputFields) {
                self.inputFields = [NSMutableArray new];
                for (NSString* fieldId in self.fields) {
                    if (self.objectiveFieldId != fieldId) {
                        [fieldIds addObject:@[fieldId,
                                              self.fields[fieldId][@"column_number"]]];
                    }
                }
                fieldIds = [fieldIds
                            sortedArrayUsingComparator:^NSComparisonResult(NSArray* a, NSArray* b) {
                                a = a[1];
                                b = b[1];
                                return a < b ? -1 :(a > b ? 1 : 0);
                            }];
                for (NSString* fieldId in fieldIds) {
                    [self.inputFields addObject:fieldId];
                }
            }
            for (NSString* field in self.fields) {
                
            }
        }
    }
}

- (instancetype)initWithJSONTimeSeries:(NSDictionary*)timeseries {
    
    if ([super initWithFields:fields]) {
        
        self.period = 1;
    }
    return self;
}

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
