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

#import <Foundation/Foundation.h>

@interface BMLUtils : NSObject

/**
 * We convert the Array to a dictionary for ease of manipulation
 *
 * @param distribution current distribution as an NSArray
 * @return the distribution as an NSDictionary
 */
+ (NSMutableDictionary*)dictionaryFromDistributionArray:(NSArray*)distribution;

/**
 * Convert a dictionary to an array. Dual of dictionaryFromDistributionArray:
 *
 * @param distribution current distribution as an NSDictionary
 * @return the distribution as an NSArray
 */
+ (NSArray*)arrayFromDistributionDictionary:(NSDictionary*)distribution;

/**
 * Adds up a new distribution structure to a map formatted distribution
 *
 * @param dist1
 * @param dist2
 * @return
 */
+ (NSMutableDictionary*)mergeDistribution:(NSMutableDictionary*)dist1
                          andDistribution:(NSDictionary*)dist2;

/**
 * Merges the bins of a regression distribution to the given limit number
 */
+ (NSArray*)mergeBins:(NSArray*)distribution limit:(NSInteger)limit;

+ (NSMutableDictionary*)mergeBinsDictionary:(NSDictionary*)distribution limit:(NSInteger)limit;

/**
 * Computes the mean of a distribution in the [[point, instances]] syntax
 *
 * @param distribution
 * @return
 */
+ (double)meanOfDistribution:(NSArray*)distribution;

/**
 * Returns the median value for a distribution
 *
 * @param distribution
 * @param count
 * @return
 */
+ (double)medianOfDistribution:(NSArray*)distribution instances:(long)instances;

/**
 * Computes the standard deviation of a distribution in the
 *  [[point, instances]] syntax
 *
 * @param distribution
 * @param distributionMean
 * @return
 */
+ (double)varianceOfDistribution:(NSArray*)distribution mean:(double)mean;

/**
 * Computes the variance error
 *
 * @param distributionVariance
 * @param population
 * @param rz
 * @return
 */
+ (double)regressionErrorWithVariance:(double)variance
                            instances:(long)instances
                                   rz:(double)rz;


/**
 * Wilson score interval computation of the distribution for the prediction
 *
 * @param prediction {object} prediction Value of the prediction for which confidence
 *        is computed
 * @param distribution {array} distribution Distribution-like structure of predictions
 *        and the associated weights (only for categoricals). (e.g.
 *        {'Iris-setosa': 10, 'Iris-versicolor': 5})
 * @param n {integer} n Total number of instances in the distribution. If
 *        absent, the number is computed as the sum of weights in the
 *        provided distribution
 * @param z {float} z Percentile of the standard normal distribution
 */
+ (double)wsConfidence:(id)prediction
          distribution:(NSDictionary*)distribution
                 count:(NSInteger)n
                     z:(double)z;

+ (double)wsConfidence:(id)prediction
          distribution:(NSDictionary*)distribution
                 count:(NSInteger)n;

+ (double)wsConfidence:(id)prediction
          distribution:(NSDictionary*)distribution;

/**
 * Returns the field that is used by the node to make a decision.
 *
 * @param children
 * @return
 */
+ (NSString*)splitNodes:(NSArray*)nodes;

/**
 * Checks expected type in input data values, strips affixes and casts
 *
 * @param inputData
 * @param fields
 * @return
 */
+ (NSDictionary*)cast:(NSDictionary*)inputData fields:(NSDictionary*)fields;

@end
