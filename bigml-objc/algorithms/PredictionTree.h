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

#import <Foundation/Foundation.h>
#import "BMLEnums.h"

@class Predicate;
@class TreePrediction;

/**
 * A tree that represents a node in the predictive model
 */
@interface PredictionTree : NSObject

@property (nonatomic, strong) Predicate* predicate;
@property (nonatomic) BOOL isPredicate;
@property (nonatomic) NSInteger maxBins;
@property (nonatomic, readonly) NSArray* objectiveFields;

/**
 * Initializes a PredictionTree object
 * @param aRoot A json object that acts as root of this tree
 * @param aFields The fields of the predictive model
 * @param aObjectiveField The objective field id (ej: 0000001, 0000002, etc)
 */
- (PredictionTree*)initWithRoot:(NSDictionary*)aRoot
                             fields:(NSDictionary*)aFields
                     objectiveField:(NSString*)aObjectiveField
                   rootDistribution:(NSDictionary*)rootDistribution
                           parentId:(NSNumber*)parentId
                             idsMap:(NSMutableDictionary*)idsMap
                            subtree:(BOOL)subtree
                            maxBins:(NSInteger)maxBins;

/**
 * Create the prediction with current model and input data passed as parameter
 * @param inputData The input data to create the prediction
 * @return A NSDictionary with the result of the prediction keyed with "value" string and the confidence of the prediction keyed with "confidence" string.
 */
- (NSDictionary*)predict:(NSDictionary*)inputData;

/**
 * Makes a prediction based on a number of field values.
 *
 * The input fields must be keyed by Id.
 *
 * .predict({"petal length": 1})
 *
 */
- (TreePrediction*)predict:(NSDictionary*)inputData
                      path:(NSMutableArray*)path
                  strategy:(BMLMissingStrategy)strategy;

/**
 * Checks if the subtree structure can be a regression
 *
 * @return true if it's a regression or false if it's a classification
 */
- (BOOL)isRegression;

@end
