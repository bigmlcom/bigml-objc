//
//  TimeSeries.m
//  bigml-objc
//
//  Created by sergio on 19/07/17.
//  Copyright © 2017 BigML Inc. All rights reserved.
//

#import "TimeSeries.h"
#import "Predicates.h"

#define REQUIRED_INPUT @"horizon"

typedef NSArray*(*SubmodelFunc)(NSDictionary*, NSInteger, BOOL);

NSString* gSubmodelKeys[] = {@"indices", @"names", @"criterion", @"limit"};

NSDictionary* gDefaultSubmodel() {
    
    static NSDictionary* _gDefaultSubmodel = nil;
    if (!_gDefaultSubmodel) {
        _gDefaultSubmodel = @{@"criterion": @"aic", @"limit": @1};
    }
    return _gDefaultSubmodel;
}

NSArray* gOperators() {

    static NSArray* _gOperators = nil;
    if (!_gOperators) {
        _gOperators = @[@"=", @"!=", @"/=", @"<", @"<=", @">", @">=", @"in"];
    }
    return _gOperators;
}

/**
 * Computing the contribution of each season component
 *
 */
double seasonContribution(NSArray* submodel, NSInteger horizon) {
    
    if (submodel) {
        NSInteger m = submodel.count;
        NSInteger i = labs(1 - m + horizon % m);
        return [submodel[i] doubleValue];
    }
    return 0;
}

/**
 * Computing the forecast for the trivial models
 *
 * @param {object} available submodels
 * @param {integer} number of points to compute
 */
NSArray* trivialForecast(NSDictionary* submodel, NSInteger horizon, BOOL seasonality) {
    
    NSMutableArray* points = [NSMutableArray new];
    NSArray* submodelPoints = submodel[@"value"];
    NSInteger period = submodelPoints.count;
    if (period > 1) {
        for (NSInteger h = 0; h < horizon; ++h) {
            [points addObject:submodel[@"value"][h % period]];
        }
    } else {
        for (NSInteger h = 0; h < horizon; ++h) {
            [points addObject:submodel[@"value"][0]];
        }
    }
    return points;
}

/**
 * Computing the forecast for the mean model
 *
 * @param {object} available submodels
 * @param {integer} number of points to compute
 */
NSArray* driftForecast(NSDictionary* submodel, NSInteger horizon, BOOL seasonality) {

    NSMutableArray* points = [NSMutableArray new];
    for (NSInteger h = 0; h < horizon; ++h) {
        [points addObject:@([submodel[@"value"] doubleValue] +
         [submodel[@"slope"] doubleValue] * (h + 1))];
    }
    return points;
}

/**
 * Computing the forecast for the trend=N model
 *
 * ŷ_t+h|t = l_t
 * ŷ_t+h|t = l_t + s_f(s, h) (if seasonality = "A")
 * ŷ_t+h|t = l_t * s_f(s, h) (if seasonality = "M")
 *
 * @param {object} available submodels
 * @param {integer} number of points to compute
 */
NSArray* NForecast(NSDictionary* submodel, NSInteger horizon, BOOL seasonality) {

    NSMutableArray* points = [NSMutableArray new];
    NSDictionary* finalState = submodel[@"final_state"] ?: @{};
    double l = [finalState[@"l"] doubleValue];
    NSArray* s = finalState[@"s"];
    for (NSInteger h = 0; h < horizon; ++h) {
        double sh = seasonContribution(s, h);
        Predicate* p = [[Predicate alloc] initWithOperator:gOperators()[seasonality]
                                                     field:@"ls"
                                                     value:@(sh)
                                                      term:nil];
        [points addObject:@([p apply:@{ @"ls" : @(l) } fields:nil])];
    }
    return points;
}

NSDictionary* gSubmodels() {
    
    static NSDictionary* _submodels = nil;
    if (!_submodels) {
        _submodels = @{ @"naive" : [NSValue valueWithPointer:trivialForecast],
                        @"mean" : [NSValue valueWithPointer:trivialForecast],
                        @"drift" : [NSValue valueWithPointer:trivialForecast],
                        @"N" : [NSValue valueWithPointer:trivialForecast],
                        @"A" : [NSValue valueWithPointer:trivialForecast],
                        @"Ad" : [NSValue valueWithPointer:trivialForecast],
                        @"M" : [NSValue valueWithPointer:trivialForecast],
                        @"Md" : [NSValue valueWithPointer:trivialForecast]};
    }
    return _submodels;
}


@interface TimeSeries ()

@property (nonatomic) BOOL allNumericObjectives;
@property (nonatomic) NSInteger period;
@property (nonatomic) NSMutableDictionary* submodels;
@property (nonatomic) NSInteger dampedTrend;
@property (nonatomic) NSInteger seasonality;
@property (nonatomic) NSInteger trend;
@property (nonatomic) NSDictionary* timeRange;
@property (nonatomic) NSDictionary* fieldParameters;

@property (nonatomic) NSDictionary* etsModels;

@property (nonatomic) NSString* locale;

@property (nonatomic) NSDictionary* forecast;

@property (nonatomic) NSDictionary* error;
@property (nonatomic) NSDictionary* timeSeriesInfo;
@property (nonatomic) NSMutableArray* inputFields;
@property (nonatomic) NSString* objectiveField;
@property (nonatomic) NSArray* objectiveFields;

@end


@implementation TimeSeries

+ (NSDictionary*)forecastWithJSONTimeSeries:(NSDictionary*)timeSeries
                                  inputData:(NSDictionary*)inputData
                                    options:(NSDictionary*)options {
    
    TimeSeries* ts = [[TimeSeries alloc] initWithJSONTimeSeries:timeSeries];
    return [ts forecastWith:inputData
            addUnusedFields:NO
                 completion:^NSDictionary *(NSDictionary *error, NSDictionary *data) {
                     NSLog(@"TimeSeries Forecast Completed");
                     return data;
                 }];
}

/**
 * Auxiliary function to load the resource info in the Model structure.
 *
 * @param {object} error Error info
 * @param {object} resource TimeSeries's resource info
 */
- (void)fillStructure:(NSDictionary*)resource {

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
                NSLog(@"FIELD IDS: %@", fieldIds);
                for (NSString* fieldId in fieldIds) {
                    [self.inputFields addObject:fieldId];
                }
            }
            for (NSString* field in self.fields.allKeys) {
                NSDictionary* fieldInfo = self.timeSeriesInfo[@"fields"][field];
                self.fields[field][@"summary"] = fieldInfo[@"summary"];
                self.fields[field][@"name"] = fieldInfo[@"name"];
            }
        } else {
            self.fields = self.timeSeriesInfo[@"fields"];
        }
        //    self.invertedFields = utils.invertObject(fields);
        self.allNumericObjectives = [self.timeSeriesInfo[@"all_numeric_objectives"] boolValue];
//        self.submodels = self.timeSeriesInfo[@"submodles"] ?: @{};
        self.etsModels = self.timeSeriesInfo[@"ets_models"] ?: @{};
        self.period = [(self.timeSeriesInfo[@"period"] ?: @1) intValue];
        self.error = self.timeSeriesInfo[@"error"];
        self.dampedTrend = [self.timeSeriesInfo[@"damped_trend"] intValue];
        self.seasonality = [self.timeSeriesInfo[@"seasonality"] boolValue];
        self.trend = [self.timeSeriesInfo[@"trend"] intValue];
        self.timeRange = self.timeSeriesInfo[@"time_range"];
        self.fieldParameters = self.timeSeriesInfo[@"field_parameters"];
        self.locale = resource[@"locale"] ?: @"";
    }
}

- (instancetype)initWithJSONTimeSeries:(NSDictionary*)timeseries {
    
    if ([super initWithFields:@{}]) {
        
        self.period = 1;
        [self fillStructure:timeseries];
    }
    return self;
}

/**
 * Makes a forecast for a horizon based on the selected submodels
 *
 * The input fields must be keyed by field name or field id.
 * @param {NSDictionary} inputData Input data to predict
 * @param {BOOL} inputData Input data to predict
 * @param {function} completion Callback
 */
- (NSDictionary*)forecastWith:(NSDictionary*)inputData
         addUnusedFields:(BOOL)addUnusedFields
              completion:(NSDictionary*(^)(NSDictionary* error, NSDictionary* data))completion {
    
//    NSMutableDictionary* newInputData = [NSMutableDictionary new];
    NSDictionary* (^localForecast)(NSDictionary* error, NSDictionary* data) =
    ^NSDictionary*(NSDictionary* error, NSDictionary* data) {
        /**
         * Creates a local forecast using the model's tree info.
         *
         * @param {object} error Error message
         * @param {object} data Input data to predict from. If the addUnusedFields
         *                      flag is set, it also includes the fields in
         *                      inputData that were not used in the model
         */
        
        if (error) {
            return completion(error, nil);
        }
        NSMutableDictionary* forecast = [self tsForecast:data[@"inputData"]];
        if (addUnusedFields) {
            forecast[@"unusedFields"] = data[@"unusedFields"];
        }
        return completion(nil, forecast);
    };
    
    if (!completion) {
        [self filterObjectives:inputData
               addUnusedFields:addUnusedFields
                    completion:localForecast];
    } else {
        NSDictionary* validatedInput = [self filterObjectives:inputData
                                              addUnusedFields:addUnusedFields
                                                   completion: completion];
        NSMutableDictionary* forecast = [self tsForecast:validatedInput[@"inputData"]];
        if (addUnusedFields) {
            forecast[@"unusedFields"] = validatedInput[@"unusedFields"];
        }
        return forecast;
    }
    return nil;
}

/**
 * Computes the forecast based on the models in the time-series
 *
 * The input fields must be keyed by field name or field id.
 * @param {object} inputData Input data to predict
 */
- (NSMutableDictionary*)tsForecast:(NSDictionary*)inputData {
    
    NSMutableDictionary* filteredSubmodels = [NSMutableDictionary new];
    NSMutableDictionary* forecasts = [NSMutableDictionary new];
    
    if (inputData.allKeys.count == 0) {
        for (NSString* fieldId in self.forecast.allKeys) {
            forecasts[fieldId] = [NSMutableArray new];
            for (NSDictionary* forecast in self.forecast[fieldId]) {
                NSMutableDictionary* localForecast = [NSMutableDictionary new];
                localForecast[@"pointForecast"] = forecast[@"point_forecast"];
                localForecast[@"model"] = forecast[@"model"];
                [forecasts[fieldId] addObject:localForecast];
            }
        }
        return forecasts;
    }
    for (NSString* fieldId in inputData.allKeys) {
        id fieldInput = inputData[fieldId];
        NSDictionary* filterInfo = fieldInput[@"ets_models"] ?: gDefaultSubmodel();
        filteredSubmodels[fieldId] = [self filteredSubmodels:self.etsModels[fieldId]
                                                      filter:filterInfo];
    }
    for (NSString* fieldId in filteredSubmodels.allKeys) {
        forecasts[fieldId] = [self forecasts:filteredSubmodels[fieldId]
                                     horizon:[inputData[fieldId][@"horizon"] intValue]];
    }
    return forecasts;
}

/**
 * Filters the keys given in input_data checking against the
 * objective fields in the time-series model fields.
 * If `add_unused_fields` is set to True, it also
 * provides information about the ones that are not used.
 * @param {object} inputData Input data to predict
 * @param {boolean} addUnusedFields Causes the validation to return the
 *                                  list of fields in inputData that are
 *                                  not used
 * @param {function} cb Callback
 */
- (NSDictionary*)filterObjectives:(NSDictionary*)inputData
                  addUnusedFields:(BOOL)addUnusedFields
                       completion:(NSDictionary*(^)(NSDictionary* error, NSDictionary* data))completion {


    NSMutableDictionary* newInputData = [NSMutableDictionary new];
    NSMutableArray* unusedFields = [NSMutableArray new];
    for (NSString* fieldId in inputData.allKeys) {
        NSDictionary* value = inputData[fieldId];
        NSAssert(value[REQUIRED_INPUT] != nil,
                 @"Each field in input data must contain at least a %@ attribute.",
                 REQUIRED_INPUT);
/*
 ADD HERE CHECK FOR keys in submodel filter
 */
        if (!self.fields[fieldId] /*&&
            !self.invertedFields[fieldId] */) {
            if (inputData[fieldId])
                [unusedFields addObject:fieldId];
        } else {
            NSString* inputDataKey;
            if (self.fields[fieldId]) {
                inputDataKey = fieldId;
            } else {
                inputDataKey = self.invertedFields[fieldId];
            }
            newInputData[inputDataKey] = inputData[fieldId];
        }
    }
    if (completion) {
        return completion(nil, @{ @"inputData" : newInputData,
                                  @"unusedFields" : unusedFields });
    }
    return @{ @"inputData" : newInputData,
              @"unusedFields" : unusedFields };
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
            NSArray* labels = [name componentsSeparatedByString:@","];
//            NSError* error = labels[0];
            NSString* trend = labels[1];
            seasonality = labels[2];
            SubmodelFunc f = (SubmodelFunc)[gSubmodels()[trend] pointerValue];
            pointForecast = f(submodel, horizon, [seasonality boolValue]);
        } else {
            SubmodelFunc f = (SubmodelFunc)[gSubmodels()[name] pointerValue];
            pointForecast =  f(submodel, horizon, NO);
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

    if (indices.count == 0 && names.count == 0) {
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
    ^NSArray*(NSArray* submodels, id criterion, id limit) {
        
        if (criterion) {
            submodels = [submodels
                         sortedArrayUsingComparator:^NSComparisonResult(NSDictionary* a, NSDictionary* b) {
                             NSLog(@"EXTRACTING: %f -- %f", [a[criterion] doubleValue], [b[criterion] doubleValue]);
                             if ([(a[criterion] ?: @(INFINITY)) doubleValue] >
                                 [(b[criterion] ?: @(INFINITY)) doubleValue]) {
                                 return 1;
                             } else if ([(a[criterion] ?: @(INFINITY)) doubleValue] <
                                        [(b[criterion] ?: @(INFINITY)) doubleValue]) {
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
