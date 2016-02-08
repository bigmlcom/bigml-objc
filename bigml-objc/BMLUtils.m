// Copyright 2014-2015 BigML
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

#import "BMLUtils.h"
#import "PredictionTree.h"
#import "Predicates.h"

#define zDistributionDefault 1.96

@implementation ML4iOSUtils

/**
 * We convert the Array to a dictionary for ease of manipulation
 *
 * @param distribution current distribution as an NSArray
 * @return the distribution as an NSDictionary
 */
+ (NSMutableDictionary*)dictionaryFromDistributionArray:(NSArray*)distribution {
    
    NSMutableDictionary* newDistribution = [NSMutableDictionary new];
    for (NSArray* distValue in distribution) {
        [newDistribution setObject:distValue[1] forKey:distValue[0]];
    }
    return newDistribution;
}

/**
 * Convert a dictionary to an array. Dual of dictionaryFromDistributionArray:
 *
 * @param distribution current distribution as an NSDictionary
 * @return the distribution as an NSArray
 */
+ (NSArray*)arrayFromDistributionDictionary:(NSDictionary*)distribution {
    
    NSMutableArray* newDistribution = [NSMutableArray new];
    for (id key in [distribution.allKeys sortedArrayUsingSelector:@selector(compare:)]) {
        [newDistribution addObject:@[key, distribution[key]]];
    }
    return newDistribution;
}

/**
 * Adds up a new distribution structure to a map formatted distribution
 *
 * @param dist1
 * @param dist2
 * @return
 */
+ (NSMutableDictionary*)mergeDistribution:(NSMutableDictionary*)dist1
                          andDistribution:(NSDictionary*)dist2 {
 
    for (id key in dist2.allKeys) {
        if (!dist1[key]) {
            [dist1 setObject:@(0) forKey:key];
        }
        [dist1 setObject:@([dist1[key] intValue] + [dist2[key] intValue])
                  forKey:key];
    }
    return dist1;
}

/**
 * Merges the bins of a regression distribution to the given limit number
 */
+ (NSArray*)mergeBins:(NSArray*)distribution limit:(NSInteger)limit {
    
    NSInteger length = distribution.count;
    if (limit < 1 || length <= limit || length < 2) {
        return  distribution;
    }
    NSInteger indexToMerge = 2;
    double shortest = HUGE_VAL;
    for (NSUInteger index = 1; index < length; ++index) {
        double distance = [[distribution[index] firstObject] doubleValue] -
        [[distribution[index -1] firstObject] doubleValue];
        
        if (distance < shortest) {
            shortest = distance;
            indexToMerge = index;
        }
    }
    
    NSMutableArray* newDistribution = [NSMutableArray arrayWithArray:
                                       [distribution subarrayWithRange:(NSRange){0, indexToMerge-1}]];
    NSArray* left = distribution[indexToMerge - 1];
    NSArray* right = distribution[indexToMerge];
    NSArray* newBin = @[@0,
                        @(([left[0] doubleValue] * [left[1] doubleValue] +
                           [right[0] doubleValue] * [right[1] doubleValue]) /
                        ([left[1] doubleValue] * [right[1] doubleValue])),
                        @1,
                        @([left[1] longValue] * [right[1] longValue])];
    [newDistribution addObject:newBin];
    
    if (indexToMerge < length -1) {
        [newDistribution addObjectsFromArray:
         [distribution subarrayWithRange:(NSRange){indexToMerge+1, distribution.count - indexToMerge}]];
    }
    
    return [self mergeBins:newDistribution limit:limit];
}

+ (NSMutableDictionary*)mergeBinsDictionary:(NSDictionary*)distribution limit:(NSInteger)limit {
    
    NSArray* distributionArray = [self mergeBins:[self arrayFromDistributionDictionary:distribution]
                                           limit:limit];
    return [self dictionaryFromDistributionArray:distributionArray];
}

/**
 * Computes the mean of a distribution in the [[point, instances]] syntax
 *
 * @param distribution
 * @return
 */
+ (double)meanOfDistribution:(NSArray*)distribution {
    
    double accumulator = 0.0;
    long count = 0;
    for (NSArray* bin in distribution) {
        double point = [bin.firstObject doubleValue];
        long instances = [bin.lastObject doubleValue];
        accumulator += point * instances;
        count += instances;
    }
    if (count > 0)
        return accumulator / count;

    return NAN;
}

+ (double)medianOfDistribution:(NSArray*)distribution instances:(long)instances {
    
    long count = 0;
    long previousPoint = NAN;
    for (NSArray* bin in distribution) {
        double point = [bin.firstObject doubleValue];
        count += [bin.lastObject doubleValue];
        if (count > (instances / 2)) {
            if ((instances % 2 != 0) && count - 1 == instances / 2 && previousPoint != NAN) {
                return (point + previousPoint) / 2;
            }
            return point;
        }
        previousPoint = point;
    }
    
    return NAN;
}


+ (double)varianceOfDistribution:(NSArray*)distribution mean:(double)mean {
    
    double accumulator = 0.0;
    long count = 0;
    for (NSArray* bin in distribution) {
        double point = [bin.firstObject doubleValue];
        long instances = [bin.lastObject doubleValue];
        accumulator += (point - mean) * (point - mean) * instances;
        count += instances;
    }
    if (count > 0)
        return accumulator / count;
    
    return NAN;
}

+ (double)regressionErrorWithVariance:(double)variance
                            instances:(long)instances
                                   rz:(double)rz {
    
    NSAssert(NO, @"Not implemented Yet (Missing strategy MissingStrategyProportional not supported)");
    return 0.0;
}

/**
 * Wilson score interval computation of the distribution for the prediction
 *
 * @param prediction Value of the prediction for which confidence is computed
 * @param distribution Distribution-like structure of predictions
 *        and the associated weights (only for categoricals). E.g.
 *        [['Iris-setosa', 10], ['Iris-versicolor', 5]]
 * @param n Total number of instances in the distribution. If 0,
 *        the number is computed as the sum of weights in the
 *        provided distribution
 * @param z Percentile of the standard normal distribution
 */
+ (double)wsConfidence:(id)prediction
          distribution:(NSDictionary*)distribution
                 count:(NSInteger)n
                     z:(double)z {

    double z2 = 0.0;
    double wsSqrt = 0.0;
    double wsFactor = 0.0;
    double p = [distribution[prediction] doubleValue];
    NSAssert(p >= 0, @"Distribution weight must be a positive value");
    
    double norm = 0.0;
    for (NSString* value in distribution.allValues) {
        norm += [value doubleValue];
    }
    if (norm != 1.0) {
        p = p / norm;
    }

    z2 = z * z;
    wsFactor = z2 / n;
    wsSqrt = sqrt((p * (1 - p) + wsFactor / 4) / n);
    return (p + wsFactor / 2 - z * wsSqrt) / (1 + wsFactor);
}

+ (double)wsConfidence:(id)prediction
          distribution:(NSDictionary*)distribution
                 count:(NSInteger)n {
    
    return [self wsConfidence:prediction
                 distribution:distribution
                        count:n
                            z:zDistributionDefault];
}

+ (double)wsConfidence:(id)prediction
          distribution:(NSDictionary*)distribution {
    
    double norm = 0.0;
    for (NSString* value in distribution.allValues) {
        norm += [value doubleValue];
    }
    NSAssert(norm != 0.0, @"Invalid distribution norm");
    
    return [self wsConfidence:prediction
                 distribution:distribution
                        count:floor(norm)
                            z:zDistributionDefault];
}

+ (NSString*)splitNodes:(NSArray*)nodes {
    
    NSMutableSet* fields = [NSMutableSet new];
    for (PredictionTree* node in nodes) {
        if (![node isPredicate]) {
            [fields addObject:node.predicate.field];
        }
    }
    return fields.count > 0 ? fields.allObjects.firstObject : nil;
}

+ (NSString*)stripAffixesFromValue:(NSString*)value field:(NSDictionary*)field {
    
    if (field[@"prefix"]) {
        NSRange r = [value rangeOfString:field[@"prefix"]];
        if (r.location == 0)
            value = [value substringFromIndex:r.length];
    }

    if (field[@"suffix"]) {
        NSRange r = [value rangeOfString:field[@"suffix"]];
        if (r.location == value.length - [field[@"suffix"] length])
            value = [value substringToIndex:r.location - 1];
    }
    return value;
}

+ (NSDictionary*)cast:(NSDictionary*)inputData fields:(NSDictionary*)fields {
    
    NSMutableDictionary* output = [NSMutableDictionary dictionaryWithCapacity:inputData.allKeys.count];
    for (id fieldId in inputData.allKeys) {
        id value = inputData[fieldId];
        NSDictionary* field = fields[fieldId];
        NSString* opType = field[@"optype"];
        
        if ([opType isEqualToString:@"numeric"] && [value isKindOfClass:[NSString class]]) {
            value = [self stripAffixesFromValue:value field:field];
        }
        output[fieldId] = value;
    }
    return output;
}

@end
