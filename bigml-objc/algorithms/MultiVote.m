// Copyright 2014-2016 BigML
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may
// not use this file except in compliance with the License. You may obtain
// a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.

#import "MultiVote.h"
#import "BMLUtils.h"

#define BINS_LIMIT 32

static NSString* const kNullCategory = @"kNullCategory";

@interface MultiVote ()

@property (nonatomic, strong) NSMutableArray* predictions;

@end

/**
 * MultiVote: combiner class for ensembles voting predictions.
 *
 */
@implementation MultiVote

+ (NSString*)combinationWeightsForMethod:(BMLPredictionMethod)method {
    
    return @[kNullCategory, @"confidence", @"probability", kNullCategory][method];
}

+ (NSArray*)weightLabels {
    return @[@"plurality", @"confidence", @"probability", @"threshold"];
}

+ (NSArray*)weightKeys {
    return @[@[], @[@"confidence"], @[@"distribution", @"count"], @[]];
}

- (instancetype)init {
    
    return [self initWithPredictions:nil];
}


/**
 * MultiVote: combiner class for ensembles voting predictions.
 *
 * @param predictions: Array of model's predictions
 */
- (instancetype)initWithPredictions:(NSArray*)predictions {
    
    if (self = [super init]) {
        
        _predictions = predictions ?: [@[] mutableCopy];
        
        BOOL ordered = YES;
        for (NSDictionary* prediction in _predictions) {
            if (!prediction[@"order"]) {
                ordered = NO;
                break;
            }
        }
        if (!ordered) {
            int count = 0;
            for (NSMutableDictionary* prediction in _predictions) {
                [prediction setObject:@(count++) forKey:@"order"];
            }
        }
    }
    return self;
}

/**
 * Return the next order to be assigned to a prediction
 *
 * Predictions in MultiVote are ordered in arrival sequence when
 * added using the constructor or the append and extend methods.
 * This order is used to break even cases in combination
 * methods for classifications.
 *
 * @return the next order to be assigned to a prediction
 */
- (NSInteger)nextOrder {
    
    if (_predictions && _predictions.count > 0) {
        return [[_predictions.lastObject valueForKey:@"order"] intValue] + 1;
    }
    return 0;
}

/**
 * Given a MultiVote instance, extends its prediction array
 * with another MultiVote's predictions and adds the order information.
 *
 * For instance, predictions_info could be:
 *
 *  [{'prediction': 'Iris-virginica', 'confidence': 0.3},
 *      {'prediction': 'Iris-versicolor', 'confidence': 0.8}]
 *
 *  where the expected prediction keys are: prediction (compulsory),
 *  confidence, distribution and count.
 *
 * @param votes
 */
- (MultiVote*)extendWithMultiVote:(MultiVote*)votes {
    
    NSAssert(votes && votes.predictions.count > 0, @"MultiVote extendWithMultiVote: contract unfulfilled");
    if (votes && votes.predictions.count > 0) {
        
        NSInteger order = [self nextOrder];
        for (NSMutableDictionary* prediction in votes.predictions) {
            [prediction setObject:@(order++) forKey:@"order"];
            [_predictions addObject:prediction];
        }
    }
    return self;
}

- (BOOL)areKeysValid:(NSArray*)keys {
    
    for (NSDictionary* prediction in _predictions) {
        for (NSString* key in keys) {
            if (!prediction[key])
                return NO;
        }
    }
    return YES;
}

/**
 * Checks the presence of each of the keys in each of the predictions
 *
 * @param keys {array} keys Array of key strings
 */
- (NSArray*)weigthKeysForMethod:(NSUInteger)method {
 
    NSArray* keys = MultiVote.weightKeys[method];
    return [self areKeysValid:keys] ? keys : nil;
}

/**
 * Check if this is a regression model
 *
 * @return {boolean} True if all the predictions are numbers.
 */
- (BOOL)isRegression {
    
    for (NSDictionary* prediction in _predictions) {
        if (![prediction[@"prediction"] isKindOfClass:[NSNumber class]])
             return NO;
    }
    return YES;
}

/**
 * Returns a distribution formed by grouping the distributions of each predicted node.
 */
- (NSDictionary*)groupedDistributionPrediction:(NSMutableDictionary*)prediction {
    
    NSMutableDictionary* joinedDist = [NSMutableDictionary new];
    NSString* distributionUnit = @"counts";
    for (NSMutableDictionary* p in _predictions) {
        
        NSDictionary* distribution = p[@"distribution"];
        if ([distribution isKindOfClass:[NSArray class]]) {
            distribution = [BMLUtils dictionaryFromDistributionArray:(id)distribution];
        }
        joinedDist = [BMLUtils mergeDistribution:joinedDist andDistribution:distribution];
        if ([distributionUnit isEqualToString:@"counts"] && joinedDist.count > BINS_LIMIT) {
            distributionUnit = @"bins";
        }
        joinedDist = [BMLUtils mergeBinsDictionary:joinedDist limit:BINS_LIMIT];
    }
    [prediction setObject:[BMLUtils arrayFromDistributionDictionary:joinedDist] forKey:@"distribution"];
    [prediction setObject:distributionUnit forKey:@"distributionUnit"];
    
    return prediction;
}

/*
 * Shifts and scales predictions errors to [0, top_range]. Then
 * builds e^-[scaled error] and returns the normalization factor to
 * fit them between [0, 1]
 */
- (double)normalizeErrorRange:(double)errorRange topRange:(double)topRange rangeMin:(double)min {
    
    double normalizeFactor = 0.0;
    if (errorRange > 0.0) {
        for (NSMutableDictionary* prediction in _predictions) {
            double delta = min - [prediction[@"confidence"] doubleValue];
            [prediction setObject:@(exp(delta / errorRange * topRange)) forKey:@"errorWeight"];
            normalizeFactor += [prediction[@"errorWeight"] doubleValue];
        }
    } else {
        for (NSMutableDictionary* prediction in _predictions)
            [prediction setObject:@(1.0) forKey:@"errorWeight"];
        normalizeFactor = self.predictions.count;
    }
    return normalizeFactor;
}

/**
 * Normalizes error to a [0, top_range] range and builds probabilities
 *
 * @param topRange {number} The top range of error to which the original error is
 *        normalized.
 * @return {number} The normalization factor as the sum of the normalized
 *         error weights.
 */
- (double)normalizedError:(double)topRange {
    
    double error = 0.0;
    double errorRange = 0.0;
    double maxError = 0.0;
    double minError = HUGE_VAL;
    for (NSDictionary* prediction in _predictions) {
        NSAssert(prediction[@"confidence"], @"No confidence data to use the selected prediction method");
        error = [prediction[@"confidence"] doubleValue];
        maxError = fmax(error, maxError);
        minError = fmin(error, minError);
    }
    errorRange = maxError - minError;
    return [self normalizeErrorRange:errorRange topRange:topRange rangeMin:minError];
}

/**
 * Returns the prediction combining votes using error to compute weight
 *
 * @return {{'prediction': {string|number}, 'confidence': {number}}} The
 *         combined error is an average of the errors in the MultiVote
 *         predictions.
 */
- (NSDictionary*)weightedErrorWithConfidence:(BOOL)confidence
                                distribution:(BOOL)distribution
                                       count:(BOOL)count
                                      median:(BOOL)median
                                         min:(BOOL)addMin
                                         max:(BOOL)addMax {

    NSAssert([self areKeysValid:@[@"confidence"]],
             @"MultiVote weightedErrorWithConfidence's contract unfulfilled: missing confidence key");
    
    long instances = 0;
    double combinedError = 0.0;
    double topRange = 10.0;
    double result = 0.0;
    double medianResult = 0.0;
    double min = NAN;
    double max = -NAN;
    double normalizationFactor = [self normalizedError:topRange];

    NSMutableDictionary* newPrediction = [NSMutableDictionary new];
    if (normalizationFactor == 0.0) {
        [newPrediction setObject:@(NAN) forKey:@"prediction"];
        [newPrediction setObject:@(0) forKey:@"confidence"];
    }
    for (NSDictionary* prediction in _predictions) {
        
        double medianError = [prediction[@"median"] doubleValue] * [prediction[@"errorWeight"] doubleValue];
        result += medianError;
        if (median) {
            medianResult += medianError;
        }
        if (count) {
            instances += [prediction[@"count"] longValue];
        }
        if (addMin && min > [prediction[@"min"] doubleValue]) {
            min = [prediction[@"min"] doubleValue];
        }
        if (addMax && max < [prediction[@"max"] doubleValue]) {
            max = [prediction[@"max"] doubleValue];
        }
        if (confidence) {
            combinedError += [prediction[@"confidence"] doubleValue] * [prediction[@"errorWeight"] doubleValue];
        }
    }
    [newPrediction setObject:@(result/normalizationFactor) forKey:@"prediction"];
    if (confidence) {
        [newPrediction setObject:@(combinedError/normalizationFactor) forKey:@"confidence"];
    }
    if (count) {
        [newPrediction setObject:@(instances) forKey:@"count"];
    }
    if (median) {
        [newPrediction setObject:@(medianResult/normalizationFactor) forKey:@"median"];
    }
    if (addMin) {
        [newPrediction setObject:@(min) forKey:@"min"];
    }
    if (addMax) {
        [newPrediction setObject:@(max) forKey:@"max"];
    }
    
    return [self groupedDistributionPrediction:newPrediction];
}

/**
 * Returns the average of a list of numeric values.
 
 * If with_confidence is True, the combined confidence (as the
 * average of confidences of the multivote predictions) is also
 * returned
 *
 */
- (NSDictionary*)averageWithConfidence:(BOOL)confidence
                          distribution:(BOOL)distribution
                                 count:(BOOL)count
                                median:(BOOL)median
                                   min:(BOOL)min
                                   max:(BOOL)max {

    NSInteger total = _predictions.count;
    double result = 0.0;
    double confidenceValue = 0.0;
    double medianResult = 0.0;
    double dMin = INFINITY;
    double dMax = -INFINITY;
    long instances = 0;
    for (NSDictionary* prediction in _predictions) {
        result += [prediction[@"prediction"] doubleValue];
        if (median) {
            medianResult += [prediction[@"median"] doubleValue];
        }
        if (confidence) {
            confidenceValue += [prediction[@"confidence"] doubleValue];
        }
        if (count) {
            instances += [prediction[@"count"] intValue];
        }
        if (min) {
            dMin += [prediction[@"min"] doubleValue];
        }
        if (max) {
            dMax += [prediction[@"max"] doubleValue];
        }
    }

    if (total > 0.0) {
        result /= total;
        confidenceValue /= total;
        medianResult /= total;
    } else {
        result = NAN;
        confidenceValue = 0.0;
        medianResult = NAN;
    }

    NSMutableDictionary* output = [@{ @"prediction" : @(result),
                                      @"confidence" : @(confidenceValue) } mutableCopy];
    if (confidence) {
        [output setObject:@(confidenceValue) forKey:@"confidence"];
    }
    if (distribution) {
        [self groupedDistributionPrediction:output];
    }
    if (count) {
        [output setObject:@(instances) forKey:@"count"];
    }
    if (median) {
        [output setObject:@(medianResult) forKey:@"median"];
    }
    if (min) {
        [output setObject:@(dMin) forKey:@"min"];
    }
    if (max) {
        [output setObject:@(dMax) forKey:@"max"];
    }
    return output;
}

/**
 * Singles out the votes for a chosen category and returns a prediction
 *  for this category if the number of votes reaches at least the given
 *  threshold.
 *
 * @param threshold the number of the minimum positive predictions needed for
 *                    a final positive prediction.
 * @param category the positive category
 * @return MultiVote instance
 */
- (MultiVote*)singleOutCategory:(NSString*)category threshold:(NSInteger)threshold {
    
    NSAssert(threshold > 0 && category.length > 0, @"MultiVote singleOutCategory contract unfulfilled");
    NSAssert(threshold <= _predictions.count, @"MultiVote singleOutCategory: threshold higher than prediction count");
    NSMutableArray* categoryPredictions = [NSMutableArray new];
    NSMutableArray* restOfPredictions = [NSMutableArray new];
    for (NSDictionary* prediction in _predictions) {
        if ([category isEqualToString:prediction[@"prediction"]]) {
            [categoryPredictions addObject:prediction];
        } else {
            [restOfPredictions addObject:prediction];
        }
    }
    if (categoryPredictions.count >= threshold) {
        return [[MultiVote alloc] initWithPredictions:categoryPredictions];
    } else {
        return [[MultiVote alloc] initWithPredictions:restOfPredictions];
    }
}

/**
 * Compute the combined weighted confidence from a list of predictions
 *
 * @param combinedPrediction {object} combinedPrediction Prediction object
 * @param weightLabel {string} weightLabel Label of the value in the prediction object
 *        that will be used to weight confidence
 */
- (NSDictionary*)weightedConfidence:(id)combinedPrediction weightLabel:(id)weightLabel {
    
    double finalConfidence = 0.0;
    double weight = 1.0;
    double totalWeight = 0.0;
    NSMutableArray* predictionList = [NSMutableArray new];
    
    for (NSDictionary* prediction in _predictions) {
        if ([prediction[@"prediction"] isEqual:combinedPrediction]) {
            [predictionList addObject:prediction];
        }
    }
    if (weightLabel && weightLabel != kNullCategory) {
        for (NSDictionary* prediction in _predictions) {
            NSAssert(prediction[@"confidence"] && prediction[weightLabel],
                     @"MultiVote weightedConfidence: not enough data to use selected method (missing %@)",
                     weightLabel);
        }
    }
    
    for (NSDictionary* prediction in _predictions) {
        if (weightLabel && weightLabel != kNullCategory) {
            weight = [prediction[@"confidence"] doubleValue];
        }
        finalConfidence += weight * [prediction[@"confidence"] doubleValue];
        totalWeight += weight;
    }
    
    if (totalWeight > 0) {
        finalConfidence = finalConfidence / totalWeight;
    } else {
        finalConfidence = 0.0;
    }
    
    NSMutableDictionary* result = [NSMutableDictionary new];
    [result setObject:combinedPrediction forKey:@"prediction"];
    [result setObject:@(finalConfidence) forKey:@"confidence"];
    
    return result;
}

/**
 * Builds a distribution based on the predictions of the MultiVote
 *
 * @param weightLabel {string} weightLabel Label of the value in the prediction object
 *        whose sum will be used as count in the distribution
 */
- (NSArray*)combineDistribution:(NSString*)weightLabel {
    
    NSInteger total = 0;
    NSMutableDictionary* distribution = [NSMutableDictionary new];
    
    if (weightLabel.length == 0) {
        weightLabel = [MultiVote weightLabels][BMLPredictionMethodProbability];
    }
    for (NSDictionary* prediction in _predictions) {
        NSAssert(prediction[weightLabel], @"MultiVote combineDistribution contract unfulfilled");
        
        NSString* predictionName = prediction[@"prediction"];
        if (!distribution[predictionName]) {
            [distribution setObject:@(0.0) forKey:predictionName];
        }
        [distribution setObject:@([distribution[predictionName] doubleValue] + [prediction[weightLabel] doubleValue])
                        forKey:predictionName];
        total += [prediction[@"count"] intValue];
    }
    return @[distribution, @(total)];
    
}

- (NSDictionary*)combineCategorical:(NSString*)weightLabel confidence:(BOOL)confidence {
    
    double weight = 1.0;
    id category;
    NSMutableDictionary* mode = [NSMutableDictionary new];
    NSMutableArray* tuples = [NSMutableArray new];
    
    for (NSDictionary* prediction in _predictions) {
        if (weightLabel != kNullCategory) {
            NSAssert([[MultiVote weightLabels] indexOfObject:weightLabel] != NSNotFound,
                     @"MultiVote combineCategorical: wrong weightLabel");
            NSAssert(prediction[weightLabel],
                     @"MultiVote combineCategorical: Not enough data to use the selected prediction method.");
            if (prediction[weightLabel])
                weight = [prediction[weightLabel] doubleValue];
        }
        category = prediction[@"prediction"];
        
        NSMutableDictionary* categoryHash = [NSMutableDictionary new];
        if (mode[category]) {
            [categoryHash setObject:@([mode[category][@"count"] doubleValue] + weight) forKey:@"count"];
            [categoryHash setObject:mode[category][@"order"] forKey:@"order"];
        } else {
            [categoryHash setObject:@(weight) forKey:@"count"];
            [categoryHash setObject:prediction[@"order"] forKey:@"order"];
        }
        [mode setObject:categoryHash forKey:category];
    }
    for (id key in mode.allKeys) {
        if (mode[key]) {
            NSArray* tuple = @[key, mode[key]];
            [tuples addObject:tuple];
        }
    }
    NSArray* tuple =
    [tuples sortedArrayUsingComparator:^NSComparisonResult(NSArray*  _Nonnull obj1,
                                                           NSArray*  _Nonnull obj2) {
        
        NSDictionary* d1 = obj1[1];
        NSDictionary* d2 = obj2[1];
        double w1 = [d1[@"count"] doubleValue];
        double w2 = [d2[@"count"] doubleValue];
        int order1 = [d1[@"order"] intValue];
        int order2 = [d2[@"order"] intValue];
        return w1 > w2 ? -1 : (w1 < w2 ? 1 : order1 < order2 ? -1 : 1);
    }].firstObject;
    id predictionName = tuple.firstObject;
    
    NSMutableDictionary* result = [NSMutableDictionary new];
    [result setObject:predictionName forKey:@"prediction"];
    
    if (confidence) {
        if ([_predictions.firstObject valueForKey:@"confidence"]) {
            return [self weightedConfidence:predictionName weightLabel:weightLabel];
        }
        
        NSArray* distributionInfo = [self combineDistribution:weightLabel];
        NSInteger count = [distributionInfo[1] intValue];
        NSDictionary* distribution = distributionInfo[0];
        double combinedConfidence = [BMLUtils wsConfidence:predictionName
                                                 distribution:distribution
                                                        count:count];
        [result setObject:@(combinedConfidence) forKey:@"confidence"];
    }
    return result;
}

- (NSArray*)probabilityWeight {
    
    NSMutableArray* predictions = [NSMutableArray new];
    
    for (NSDictionary* prediction in _predictions) {
     
        NSAssert(prediction[@"distribution"] && prediction[@"count"],
                 @"Wrong prediction found: no distribution/count info");
        long total = [prediction[@"count"] longValue];
        NSAssert(total > 0, @"Wrong total in probabilityWeight");
        
        NSMutableDictionary* distribution = prediction[@"distribution"];
        for (NSString* key in distribution.allKeys) {
            int instances = [distribution[key] intValue];
            [predictions addObject:@{ @"prediction" : key,
                                      @"probability" : @((double)instances / total),
                                      @"count" : @(instances),
                                      @"order" : prediction[@"order"]
                                     }];
        }
    }
    return predictions;
}

/**
 * Reduces a number of predictions voting for classification and averaging
 * predictions for regression.
 *
 * @param method {0|1|2|3} method Code associated to the voting method (plurality,
 *        confidence weighted or probability weighted or threshold).
 * @param withConfidence if withConfidence is true, the combined confidence
 *                       (as a weighted of the prediction average of the confidences
 *                       of votes for the combined prediction) will also be given.
 * @return {{"prediction": prediction, "confidence": combinedConfidence}}
 */
- (NSDictionary*)combineWithMethod:(BMLPredictionMethod)method
                        confidence:(BOOL)confidence
                      distribution:(BOOL)distribution
                             count:(BOOL)count
                            median:(BOOL)median
                               min:(BOOL)min
                               max:(BOOL)max
                           options:(NSDictionary*)options {
    
    NSAssert(_predictions && _predictions.count > 0,
             @"MultiVote combineWithMethod's contract unfulfilled: missing predictions");
    NSAssert([self weigthKeysForMethod:method],
             @"MultiVote combineWithMethod's contract unfulfilled: missing keys");
    
    if ([self isRegression]) {
        
        for (NSMutableDictionary* prediction in _predictions) {
            if (!prediction[@"confidence"])
                prediction[@"confidence"] = @(0);
        }
        if (method == BMLPredictionMethodConfidence) {
            return [self weightedErrorWithConfidence:confidence
                                        distribution:(BOOL)distribution
                                               count:(BOOL)count
                                              median:(BOOL)median
                                                 min:(BOOL)min
                                                 max:(BOOL)max];
        }
        return [self averageWithConfidence:confidence
                              distribution:(BOOL)distribution
                                     count:(BOOL)count
                                    median:(BOOL)median
                                       min:(BOOL)min
                                       max:(BOOL)max];
    }
    
    MultiVote* votes = nil;
    if (method == BMLPredictionMethodThreshold) {
        NSInteger threshold = [options[@"threshold-k"] intValue];
        NSString* category = options[@"threshold-category"];
        votes = [self singleOutCategory:category threshold:threshold];
    } else if (method == BMLPredictionMethodProbability) {
        votes = [[MultiVote alloc] initWithPredictions:[self probabilityWeight]];
    } else {
        votes = self;
    }
    
    return [votes combineCategorical:[MultiVote combinationWeightsForMethod:method]
                          confidence:confidence];
}

/**
 * Adds a new prediction into a list of predictions
 *
 * prediction_info should contain at least:
 *      - prediction: whose value is the predicted category or value
 *
 * for instance:
 *      {'prediction': 'Iris-virginica'}
 *
 * it may also contain the keys:
 *      - confidence: whose value is the confidence/error of the prediction
 *      - distribution: a list of [category/value, instances] pairs
 *                      describing the distribution at the prediction node
 *      - count: the total number of instances of the training set in the
 *                  node
 *
 * @param predictionInfo the prediction to be appended
 * @return the this instance
 */
- (void)append:(NSDictionary*)predictionInfo {
    
    NSAssert(predictionInfo.allKeys.count > 0 && predictionInfo[@"prediction"],
             @"Failed to append prediction");

    NSMutableDictionary* dict = [predictionInfo mutableCopy];
 
    NSInteger order = [self nextOrder];
    [dict setObject:@(order) forKey:@"order"];
    [_predictions addObject:dict];
}

- (void)addMedian {
    
    for (NSMutableDictionary* prediction in _predictions) {
        [prediction setObject:prediction[@"median"] forKey:@"prediction"];
    }
}

@end

